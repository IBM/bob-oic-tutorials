from flask import Flask, request, jsonify
from flask_cors import CORS
from pymongo import MongoClient
import os
import time
import random

# Initialize Instana for distributed tracing and MongoDB discovery
try:
    import instana
    instana.init()
    print("Instana initialized successfully")
except Exception as e:
    print(f"Instana initialization failed: {e}")

app = Flask(__name__)
CORS(app)

# MongoDB connection
MONGO_URI = os.getenv('MONGO_URI', 'mongodb://mongodb:27017/')
MONGO_DATABASE = os.getenv('MONGO_DATABASE', 'library')

try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    # Test the connection
    client.admin.command('ping')
    print(f"Successfully connected to MongoDB at {MONGO_URI}")
except Exception as e:
    print(f"Failed to connect to MongoDB: {e}")
    raise

db = client[MONGO_DATABASE]
users_collection = db['users']
transactions_collection = db['transactions']

# Latency configuration
LATENCY_MIN_MS = int(os.getenv('LATENCY_MIN_MS', '0'))
LATENCY_MAX_MS = int(os.getenv('LATENCY_MAX_MS', '0'))

def add_artificial_latency():
    """Add artificial latency to simulate slow operations"""
    if LATENCY_MIN_MS > 0 or LATENCY_MAX_MS > 0:
        delay_ms = random.randint(LATENCY_MIN_MS, LATENCY_MAX_MS)
        time.sleep(delay_ms / 1000.0)
        return delay_ms
    return 0

# Initialize some sample data
def init_data():
    if users_collection.count_documents({}) == 0:
        sample_users = [
            {"id": "1", "name": "Alice Johnson", "email": "alice@example.com", "membershipId": "MEM-001", "borrowedBooks": []},
            {"id": "2", "name": "Bob Smith", "email": "bob@example.com", "membershipId": "MEM-002", "borrowedBooks": []},
            {"id": "3", "name": "Carol White", "email": "carol@example.com", "membershipId": "MEM-003", "borrowedBooks": []}
        ]
        users_collection.insert_many(sample_users)
        print("Sample users initialized")

@app.route('/health', methods=['GET'])
def health():
    add_artificial_latency()
    latency_info = {}
    if LATENCY_MIN_MS > 0 or LATENCY_MAX_MS > 0:
        latency_info = {"latency_range_ms": f"{LATENCY_MIN_MS}-{LATENCY_MAX_MS}"}
    return jsonify({"status": "healthy", "service": "users-api", **latency_info}), 200

@app.route('/users', methods=['GET'])
def get_users():
    try:
        add_artificial_latency()
        users = list(users_collection.find({}, {'_id': 0}))
        return jsonify({"users": users, "count": len(users)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/users/<user_id>', methods=['GET'])
def get_user(user_id):
    try:
        add_artificial_latency()
        user = users_collection.find_one({"id": user_id}, {'_id': 0})
        if user:
            return jsonify(user), 200
        return jsonify({"error": "User not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/users', methods=['POST'])
def add_user():
    try:
        add_artificial_latency()
        data = request.get_json()
        if not data or 'name' not in data or 'email' not in data:
            return jsonify({"error": "Missing required fields"}), 400
        
        # Generate ID
        count = users_collection.count_documents({})
        data['id'] = str(count + 1)
        data['membershipId'] = f"MEM-{str(count + 1).zfill(3)}"
        data['borrowedBooks'] = []
        
        users_collection.insert_one(data)
        return jsonify({"message": "User added", "user": {k: v for k, v in data.items() if k != '_id'}}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/users/<user_id>', methods=['PUT'])
def update_user(user_id):
    try:
        data = request.get_json()
        result = users_collection.update_one({"id": user_id}, {"$set": data})
        if result.modified_count > 0:
            return jsonify({"message": "User updated"}), 200
        return jsonify({"error": "User not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    try:
        result = users_collection.delete_one({"id": user_id})
        if result.deleted_count > 0:
            return jsonify({"message": "User deleted"}), 200
        return jsonify({"error": "User not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/users/borrow', methods=['POST'])
def borrow_book():
    try:
        add_artificial_latency()
        data = request.get_json()
        user_id = data.get('userId')
        book_id = data.get('bookId')
        
        if not user_id or not book_id:
            return jsonify({"error": "Missing userId or bookId"}), 400
        
        # Check if user exists
        user = users_collection.find_one({"id": user_id})
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        # Add book to user's borrowed books
        users_collection.update_one(
            {"id": user_id},
            {"$addToSet": {"borrowedBooks": book_id}}
        )
        
        # Record transaction
        transaction = {
            "userId": user_id,
            "bookId": book_id,
            "action": "borrow",
            "timestamp": "2024-01-01T00:00:00Z"
        }
        transactions_collection.insert_one(transaction)
        
        return jsonify({"message": "Book borrowed successfully", "userId": user_id, "bookId": book_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/users/return', methods=['POST'])
def return_book():
    try:
        add_artificial_latency()
        data = request.get_json()
        user_id = data.get('userId')
        book_id = data.get('bookId')
        
        if not user_id or not book_id:
            return jsonify({"error": "Missing userId or bookId"}), 400
        
        # Remove book from user's borrowed books
        result = users_collection.update_one(
            {"id": user_id},
            {"$pull": {"borrowedBooks": book_id}}
        )
        
        if result.modified_count == 0:
            return jsonify({"error": "User not found or book not borrowed"}), 404
        
        # Record transaction
        transaction = {
            "userId": user_id,
            "bookId": book_id,
            "action": "return",
            "timestamp": "2024-01-01T00:00:00Z"
        }
        transactions_collection.insert_one(transaction)
        
        return jsonify({"message": "Book returned successfully", "userId": user_id, "bookId": book_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/users/<user_id>/borrowed', methods=['GET'])
def get_borrowed_books(user_id):
    try:
        add_artificial_latency()
        user = users_collection.find_one({"id": user_id}, {'_id': 0})
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        borrowed_books = user.get('borrowedBooks', [])
        return jsonify({"userId": user_id, "borrowedBooks": borrowed_books, "count": len(borrowed_books)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    init_data()
    app.run(host='0.0.0.0', port=8082, debug=False)

# Made with Bob

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
books_collection = db['books']

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
    if books_collection.count_documents({}) == 0:
        sample_books = [
            {"id": "1", "title": "The Great Gatsby", "author": "F. Scott Fitzgerald", "isbn": "978-0743273565", "available": True},
            {"id": "2", "title": "To Kill a Mockingbird", "author": "Harper Lee", "isbn": "978-0061120084", "available": True},
            {"id": "3", "title": "1984", "author": "George Orwell", "isbn": "978-0451524935", "available": True},
            {"id": "4", "title": "Pride and Prejudice", "author": "Jane Austen", "isbn": "978-0141439518", "available": True},
            {"id": "5", "title": "The Catcher in the Rye", "author": "J.D. Salinger", "isbn": "978-0316769174", "available": True}
        ]
        books_collection.insert_many(sample_books)
        print("Sample books initialized")

@app.route('/health', methods=['GET'])
def health():
    add_artificial_latency()
    latency_info = {}
    if LATENCY_MIN_MS > 0 or LATENCY_MAX_MS > 0:
        latency_info = {"latency_range_ms": f"{LATENCY_MIN_MS}-{LATENCY_MAX_MS}"}
    return jsonify({"status": "healthy", "service": "books-api", **latency_info}), 200

@app.route('/books', methods=['GET'])
def get_books():
    try:
        delay = add_artificial_latency()
        books = list(books_collection.find({}, {'_id': 0}))
        response = {"books": books, "count": len(books)}
        if delay > 0:
            response["artificial_delay_ms"] = delay
        return jsonify(response), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/books/<book_id>', methods=['GET'])
def get_book(book_id):
    try:
        add_artificial_latency()
        book = books_collection.find_one({"id": book_id}, {'_id': 0})
        if book:
            return jsonify(book), 200
        return jsonify({"error": "Book not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/books', methods=['POST'])
def add_book():
    try:
        add_artificial_latency()
        data = request.get_json()
        if not data or 'title' not in data or 'author' not in data:
            return jsonify({"error": "Missing required fields"}), 400
        
        # Generate ID
        count = books_collection.count_documents({})
        data['id'] = str(count + 1)
        data['available'] = data.get('available', True)
        
        books_collection.insert_one(data)
        return jsonify({"message": "Book added", "book": {k: v for k, v in data.items() if k != '_id'}}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/books/<book_id>', methods=['PUT'])
def update_book(book_id):
    try:
        add_artificial_latency()
        data = request.get_json()
        result = books_collection.update_one({"id": book_id}, {"$set": data})
        if result.modified_count > 0:
            return jsonify({"message": "Book updated"}), 200
        return jsonify({"error": "Book not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/books/<book_id>', methods=['DELETE'])
def delete_book(book_id):
    try:
        add_artificial_latency()
        result = books_collection.delete_one({"id": book_id})
        if result.deleted_count > 0:
            return jsonify({"message": "Book deleted"}), 200
        return jsonify({"error": "Book not found"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/books/search', methods=['GET'])
def search_books():
    try:
        add_artificial_latency()
        query = request.args.get('q', '')
        if not query:
            return jsonify({"books": [], "count": 0}), 200
        
        books = list(books_collection.find({
            "$or": [
                {"title": {"$regex": query, "$options": "i"}},
                {"author": {"$regex": query, "$options": "i"}},
                {"isbn": {"$regex": query, "$options": "i"}}
            ]
        }, {'_id': 0}))
        
        return jsonify({"books": books, "count": len(books)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    init_data()
    app.run(host='0.0.0.0', port=8081, debug=False)

# Made with Bob

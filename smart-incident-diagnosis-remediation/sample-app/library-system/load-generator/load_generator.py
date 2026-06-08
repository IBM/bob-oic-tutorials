#!/usr/bin/env python3
import requests
import time
import random
import os
import sys
from datetime import datetime

# Configuration - All traffic goes through web-ui
WEB_UI_URL = os.getenv('WEB_UI_URL', 'http://web-ui:8080')
REQUESTS_PER_MINUTE = int(os.getenv('REQUESTS_PER_MINUTE', '30'))
DURATION_MINUTES = int(os.getenv('DURATION_MINUTES', '0'))  # 0 = infinite

class LoadGenerator:
    def __init__(self):
        self.session = requests.Session()
        self.request_count = 0
        self.error_count = 0
        self.start_time = datetime.now()
        
    def log(self, message):
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{timestamp}] {message}", flush=True)
    
    def make_request(self, method, url, **kwargs):
        try:
            response = self.session.request(method, url, timeout=10, **kwargs)
            self.request_count += 1
            return response
        except Exception as e:
            self.error_count += 1
            self.log(f"Error: {str(e)}")
            return None
    
    def get_books(self):
        """Get all books via web-ui"""
        response = self.make_request('GET', f'{WEB_UI_URL}/api/books')
        if response and response.status_code == 200:
            self.log(f"✓ GET /api/books - {response.status_code}")
            return response.json()
        return None
    
    def search_books(self):
        """Search for books via web-ui"""
        queries = ['great', 'kill', '1984', 'pride', 'catcher']
        query = random.choice(queries)
        response = self.make_request('GET', f'{WEB_UI_URL}/api/books/search', params={'q': query})
        if response and response.status_code == 200:
            self.log(f"✓ GET /api/books/search?q={query} - {response.status_code}")
    
    def add_book(self):
        """Add a new book via web-ui"""
        book = {
            'title': f'Test Book {random.randint(1000, 9999)}',
            'author': f'Author {random.randint(1, 100)}',
            'isbn': f'ISBN-{random.randint(100000, 999999)}',
            'available': True
        }
        response = self.make_request('POST', f'{WEB_UI_URL}/api/books', json=book)
        if response and response.status_code == 201:
            self.log(f"✓ POST /api/books - {response.status_code}")
    
    def get_users(self):
        """Get all users via web-ui"""
        response = self.make_request('GET', f'{WEB_UI_URL}/api/users')
        if response and response.status_code == 200:
            self.log(f"✓ GET /api/users - {response.status_code}")
            return response.json()
        return None
    
    def add_user(self):
        """Add a new user via web-ui"""
        user = {
            'name': f'User {random.randint(1000, 9999)}',
            'email': f'user{random.randint(1000, 9999)}@example.com'
        }
        response = self.make_request('POST', f'{WEB_UI_URL}/api/users', json=user)
        if response and response.status_code == 201:
            self.log(f"✓ POST /api/users - {response.status_code}")
    
    def borrow_book(self):
        """Simulate borrowing a book via web-ui"""
        data = {
            'userId': str(random.randint(1, 3)),
            'bookId': str(random.randint(1, 5))
        }
        response = self.make_request('POST', f'{WEB_UI_URL}/api/users/borrow', json=data)
        if response and response.status_code == 200:
            self.log(f"✓ POST /api/users/borrow - {response.status_code}")
    
    def return_book(self):
        """Simulate returning a book via web-ui"""
        data = {
            'userId': str(random.randint(1, 3)),
            'bookId': str(random.randint(1, 5))
        }
        response = self.make_request('POST', f'{WEB_UI_URL}/api/users/return', json=data)
        if response:
            self.log(f"✓ POST /api/users/return - {response.status_code}")
    
    def access_web_ui(self):
        """Access the web UI"""
        response = self.make_request('GET', f'{WEB_UI_URL}/')
        if response and response.status_code == 200:
            self.log(f"✓ GET / (Web UI) - {response.status_code}")
    
    def check_health(self):
        """Check health of all services via web-ui"""
        response = self.make_request('GET', f'{WEB_UI_URL}/api/health')
        if response and response.status_code == 200:
            self.log(f"✓ Health check - {response.json()}")
    
    def run_scenario(self):
        """Run a random user scenario"""
        scenarios = [
            self.get_books,
            self.search_books,
            self.get_users,
            self.add_book,
            self.add_user,
            self.borrow_book,
            self.return_book,
            self.access_web_ui
        ]
        
        # Pick a random scenario
        scenario = random.choice(scenarios)
        scenario()
    
    def print_stats(self):
        """Print statistics"""
        elapsed = (datetime.now() - self.start_time).total_seconds()
        success_rate = ((self.request_count - self.error_count) / self.request_count * 100) if self.request_count > 0 else 0
        
        self.log("=" * 60)
        self.log(f"Statistics:")
        self.log(f"  Total Requests: {self.request_count}")
        self.log(f"  Successful: {self.request_count - self.error_count}")
        self.log(f"  Errors: {self.error_count}")
        self.log(f"  Success Rate: {success_rate:.2f}%")
        self.log(f"  Elapsed Time: {elapsed:.0f}s")
        self.log(f"  Requests/sec: {self.request_count / elapsed:.2f}")
        self.log("=" * 60)
    
    def run(self):
        """Main run loop"""
        self.log("=" * 60)
        self.log("Library System Load Generator Started")
        self.log(f"Target: {REQUESTS_PER_MINUTE} requests/minute")
        self.log(f"Duration: {'Infinite' if DURATION_MINUTES == 0 else f'{DURATION_MINUTES} minutes'}")
        self.log("=" * 60)
        
        # Initial health check
        self.log("Performing initial health check...")
        self.check_health()
        time.sleep(2)
        
        # Calculate delay between requests
        delay = 60.0 / REQUESTS_PER_MINUTE
        
        end_time = None
        if DURATION_MINUTES > 0:
            end_time = time.time() + (DURATION_MINUTES * 60)
        
        try:
            while True:
                # Check if we should stop
                if end_time and time.time() >= end_time:
                    self.log("Duration reached, stopping...")
                    break
                
                # Run a scenario
                self.run_scenario()
                
                # Print stats every 100 requests
                if self.request_count % 100 == 0:
                    self.print_stats()
                
                # Wait before next request
                time.sleep(delay)
                
        except KeyboardInterrupt:
            self.log("\nStopping load generator...")
        finally:
            self.print_stats()
            self.log("Load generator stopped")

if __name__ == '__main__':
    generator = LoadGenerator()
    generator.run()

# Made with Bob

try {
    require('@instana/collector')({
        tracing: {
            useOpentelemetry: false
        }
    });
    console.log('Instana initialized (OTel disabled)');
} catch (e) {
    console.log('Instana failed:', e.message);
}


const express = require('express');
const axios = require('axios');
const app = express();

const PORT = process.env.PORT || 8080;
const BOOKS_API = process.env.BOOKS_API_URL || 'http://books-api:8081';
const USERS_API = process.env.USERS_API_URL || 'http://users-api:8082';

app.use(express.json());
app.use(express.static('public'));

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'web-ui' });
});

// Home pagey


app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html>
<head>
    <title>Library System</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
        .section { margin: 30px 0; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
        button { padding: 10px 20px; margin: 5px; cursor: pointer; background: #007bff; color: white; border: none; border-radius: 3px; }
        button:hover { background: #0056b3; }
        .result { margin-top: 15px; padding: 15px; background: #f8f9fa; border-radius: 3px; white-space: pre-wrap; }
        .error { background: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <h1>📚 Library Management System</h1>
    
    <div class="section">
        <h2>Books API</h2>
        <button onclick="getBooks()">Get All Books</button>
        <button onclick="addBook()">Add Sample Book</button>
        <button onclick="searchBooks()">Search Books</button>
        <div id="books-result" class="result"></div>
    </div>
    
    <div class="section">
        <h2>Users API</h2>
        <button onclick="getUsers()">Get All Users</button>
        <button onclick="addUser()">Add Sample User</button>
        <button onclick="borrowBook()">Borrow Book</button>
        <div id="users-result" class="result"></div>
    </div>
    
    <div class="section">
        <h2>System Status</h2>
        <button onclick="checkHealth()">Check All Services</button>
        <div id="health-result" class="result"></div>
    </div>

    <script>
        async function getBooks() {
            try {
                const res = await fetch('/api/books');
                const data = await res.json();
                document.getElementById('books-result').textContent = JSON.stringify(data, null, 2);
                document.getElementById('books-result').className = 'result';
            } catch (err) {
                document.getElementById('books-result').textContent = 'Error: ' + err.message;
                document.getElementById('books-result').className = 'result error';
            }
        }

        async function addBook() {
            try {
                const book = {
                    title: 'Sample Book ' + Date.now(),
                    author: 'John Doe',
                    isbn: 'ISBN-' + Date.now(),
                    available: true
                };
                const res = await fetch('/api/books', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(book)
                });
                const data = await res.json();
                document.getElementById('books-result').textContent = JSON.stringify(data, null, 2);
                document.getElementById('books-result').className = 'result';
            } catch (err) {
                document.getElementById('books-result').textContent = 'Error: ' + err.message;
                document.getElementById('books-result').className = 'result error';
            }
        }

        async function searchBooks() {
            try {
                const res = await fetch('/api/books/search?q=sample');
                const data = await res.json();
                document.getElementById('books-result').textContent = JSON.stringify(data, null, 2);
                document.getElementById('books-result').className = 'result';
            } catch (err) {
                document.getElementById('books-result').textContent = 'Error: ' + err.message;
                document.getElementById('books-result').className = 'result error';
            }
        }

        async function getUsers() {
            try {
                const res = await fetch('/api/users');
                const data = await res.json();
                document.getElementById('users-result').textContent = JSON.stringify(data, null, 2);
                document.getElementById('users-result').className = 'result';
            } catch (err) {
                document.getElementById('users-result').textContent = 'Error: ' + err.message;
                document.getElementById('users-result').className = 'result error';
            }
        }

        async function addUser() {
            try {
                const user = {
                    name: 'User ' + Date.now(),
                    email: 'user' + Date.now() + '@example.com',
                    membershipId: 'MEM-' + Date.now()
                };
                const res = await fetch('/api/users', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(user)
                });
                const data = await res.json();
                document.getElementById('users-result').textContent = JSON.stringify(data, null, 2);
                document.getElementById('users-result').className = 'result';
            } catch (err) {
                document.getElementById('users-result').textContent = 'Error: ' + err.message;
                document.getElementById('users-result').className = 'result error';
            }
        }

        async function borrowBook() {
            try {
                const res = await fetch('/api/users/borrow', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({userId: '1', bookId: '1'})
                });
                const data = await res.json();
                document.getElementById('users-result').textContent = JSON.stringify(data, null, 2);
                document.getElementById('users-result').className = 'result';
            } catch (err) {
                document.getElementById('users-result').textContent = 'Error: ' + err.message;
                document.getElementById('users-result').className = 'result error';
            }
        }

        async function checkHealth() {
            try {
                const res = await fetch('/api/health');
                const data = await res.json();
                document.getElementById('health-result').textContent = JSON.stringify(data, null, 2);
                document.getElementById('health-result').className = 'result';
            } catch (err) {
                document.getElementById('health-result').textContent = 'Error: ' + err.message;
                document.getElementById('health-result').className = 'result error';
            }
        }
    </script>
</body>
</html>
    `);
});

// Proxy to Books API
app.get('/api/books', async (req, res) => {
    try {
        const response = await axios.get(`${BOOKS_API}/books`, {
            headers: { 'X-Instana-T': req.headers['x-instana-t'], 'X-Instana-S': req.headers['x-instana-s'] }
        });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/books', async (req, res) => {
    try {
        const response = await axios.post(`${BOOKS_API}/books`, req.body, {
            headers: { 'X-Instana-T': req.headers['x-instana-t'], 'X-Instana-S': req.headers['x-instana-s'] }
        });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/books/search', async (req, res) => {
    try {
        const response = await axios.get(`${BOOKS_API}/books/search`, {
            params: req.query,
            headers: { 'X-Instana-T': req.headers['x-instana-t'], 'X-Instana-S': req.headers['x-instana-s'] }
        });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Proxy to Users API
app.get('/api/users', async (req, res) => {
    try {
        const response = await axios.get(`${USERS_API}/users`, {
            headers: { 'X-Instana-T': req.headers['x-instana-t'], 'X-Instana-S': req.headers['x-instana-s'] }
        });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/users', async (req, res) => {
    try {
        const response = await axios.post(`${USERS_API}/users`, req.body, {
            headers: { 'X-Instana-T': req.headers['x-instana-t'], 'X-Instana-S': req.headers['x-instana-s'] }
        });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/users/borrow', async (req, res) => {
    try {
        const response = await axios.post(`${USERS_API}/users/borrow`, req.body, {
            headers: { 'X-Instana-T': req.headers['x-instana-t'], 'X-Instana-S': req.headers['x-instana-s'] }
        });
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health check all services
app.get('/api/health', async (req, res) => {
    const health = { webui: 'healthy', books: 'unknown', users: 'unknown' };
    
    try {
        await axios.get(`${BOOKS_API}/health`, { timeout: 2000 });
        health.books = 'healthy';
    } catch (e) {
        health.books = 'unhealthy';
    }
    
    try {
        await axios.get(`${USERS_API}/health`, { timeout: 2000 });
        health.users = 'healthy';
    } catch (e) {
        health.users = 'unhealthy';
    }
    
    res.json(health);
});

app.listen(PORT, () => {
    console.log(`Web UI running on port ${PORT}`);
});

// Made with Bob

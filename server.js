const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Database Connection
const pool = new Pool({
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'Tarantula@123',
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'tarantuladb'
});

// Initialize Database
async function initDB() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        location VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✓ Database initialized');
  } catch (err) {
    console.error('✗ Database error:', err.message);
  }
}

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

// POST - Add User
app.post('/api/users', async (req, res) => {
  const { name, location } = req.body;

  if (!name || !location) {
    return res.status(400).json({ error: 'Name and location required' });
  }

  try {
    const result = await pool.query(
      'INSERT INTO users (name, location) VALUES ($1, $2) RETURNING *',
      [name, location]
    );
    res.status(201).json({ message: 'User added', data: result.rows[0] });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// GET - Fetch All Users
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});

// Start Server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  initDB();
});

process.on('SIGTERM', () => {
  console.log('Shutting down...');
  pool.end();
  process.exit(0);
});

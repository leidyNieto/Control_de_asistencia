// src/controllers/auth.controller.js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../db');

// POST /api/register
async function register(req, res) {
  const { nombre, email, password } = req.body;
  try {
    // ¿Existe ya el email?
    const [exists] = await pool.query('SELECT id FROM usuarios WHERE email = ?', [email]);
    if (exists.length > 0) {
      return res.status(409).json({ error: 'El correo ya está registrado' });
    }

    // Cifrado de contraseña con bcrypt
    const hash = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      'INSERT INTO usuarios (nombre, email, password_hash) VALUES (?, ?, ?)',
      [nombre, email, hash]
    );

    const user = { id: result.insertId, nombre, email };
    const token = firmarToken(user);
    return res.status(201).json({ usuario: user, token });
  } catch (err) {
    console.error('Error en register:', err);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
}

// POST /api/login
async function login(req, res) {
  const { email, password } = req.body;
  try {
    const [rows] = await pool.query(
      'SELECT id, nombre, email, password_hash FROM usuarios WHERE email = ?',
      [email]
    );
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    const usuario = rows[0];
    const ok = await bcrypt.compare(password, usuario.password_hash);
    if (!ok) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    const datos = { id: usuario.id, nombre: usuario.nombre, email: usuario.email };
    const token = firmarToken(datos);
    return res.json({ usuario: datos, token });
  } catch (err) {
    console.error('Error en login:', err);
    return res.status(500).json({ error: 'Error interno del servidor' });
  }
}

function firmarToken(user) {
  return jwt.sign(user, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

module.exports = { register, login };

// src/controllers/cursos.controller.js
const { pool } = require('../db');

// GET /api/cursos  -> cursos del usuario autenticado, con conteo de sesiones e inscritos
async function listar(req, res) {
  try {
    const [rows] = await pool.query(
      `SELECT c.*,
              (SELECT COUNT(*) FROM sesiones s WHERE s.curso_id = c.id)       AS total_sesiones,
              (SELECT COUNT(*) FROM inscripciones i WHERE i.curso_id = c.id)   AS total_inscritos
       FROM cursos c
       WHERE c.usuario_id = ?
       ORDER BY c.created_at DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al listar cursos' });
  }
}

// GET /api/cursos/:id
async function obtener(req, res) {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM cursos WHERE id = ? AND usuario_id = ?',
      [req.params.id, req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Curso no encontrado' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener curso' });
  }
}

// POST /api/cursos
async function crear(req, res) {
  const { nombre, codigo, descripcion } = req.body;
  try {
    const [dup] = await pool.query('SELECT id FROM cursos WHERE codigo = ?', [codigo]);
    if (dup.length > 0) return res.status(409).json({ error: 'El código de curso ya existe' });

    const [result] = await pool.query(
      'INSERT INTO cursos (usuario_id, nombre, codigo, descripcion) VALUES (?, ?, ?, ?)',
      [req.user.id, nombre, codigo, descripcion || null]
    );
    const [rows] = await pool.query('SELECT * FROM cursos WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al crear curso' });
  }
}

// PUT /api/cursos/:id
async function actualizar(req, res) {
  const { nombre, codigo, descripcion } = req.body;
  try {
    const [own] = await pool.query(
      'SELECT id FROM cursos WHERE id = ? AND usuario_id = ?',
      [req.params.id, req.user.id]
    );
    if (own.length === 0) return res.status(404).json({ error: 'Curso no encontrado' });

    await pool.query(
      'UPDATE cursos SET nombre = ?, codigo = ?, descripcion = ? WHERE id = ?',
      [nombre, codigo, descripcion || null, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM cursos WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar curso' });
  }
}

// DELETE /api/cursos/:id
async function eliminar(req, res) {
  try {
    const [result] = await pool.query(
      'DELETE FROM cursos WHERE id = ? AND usuario_id = ?',
      [req.params.id, req.user.id]
    );
    if (result.affectedRows === 0) return res.status(404).json({ error: 'Curso no encontrado' });
    res.json({ mensaje: 'Curso eliminado' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al eliminar curso' });
  }
}

module.exports = { listar, obtener, crear, actualizar, eliminar };

// src/controllers/estudiantes.controller.js
const { pool } = require('../db');

// GET /api/estudiantes  (todos los estudiantes del sistema)
async function listar(req, res) {
  try {
    const [rows] = await pool.query('SELECT * FROM estudiantes ORDER BY nombre');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al listar estudiantes' });
  }
}

// POST /api/estudiantes
async function crear(req, res) {
  const { nombre, documento, email } = req.body;
  try {
    const [dup] = await pool.query('SELECT id FROM estudiantes WHERE documento = ?', [documento]);
    if (dup.length > 0) return res.status(409).json({ error: 'El documento ya existe' });

    const [result] = await pool.query(
      'INSERT INTO estudiantes (nombre, documento, email) VALUES (?, ?, ?)',
      [nombre, documento, email || null]
    );
    const [rows] = await pool.query('SELECT * FROM estudiantes WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al crear estudiante' });
  }
}

// GET /api/cursos/:id/estudiantes  (inscritos en un curso)
async function inscritosPorCurso(req, res) {
  try {
    const [rows] = await pool.query(
      `SELECT e.*, i.id AS inscripcion_id, i.fecha_inscripcion
       FROM inscripciones i
       JOIN estudiantes e ON e.id = i.estudiante_id
       JOIN cursos c ON c.id = i.curso_id
       WHERE i.curso_id = ? AND c.usuario_id = ?
       ORDER BY e.nombre`,
      [req.params.id, req.user.id]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al listar inscritos' });
  }
}

// POST /api/cursos/:id/inscripciones  { estudiante_id }
async function inscribir(req, res) {
  const { estudiante_id } = req.body;
  const curso_id = req.params.id;
  try {
    const [curso] = await pool.query(
      'SELECT id FROM cursos WHERE id = ? AND usuario_id = ?',
      [curso_id, req.user.id]
    );
    if (curso.length === 0) return res.status(404).json({ error: 'Curso no encontrado' });

    const [dup] = await pool.query(
      'SELECT id FROM inscripciones WHERE curso_id = ? AND estudiante_id = ?',
      [curso_id, estudiante_id]
    );
    if (dup.length > 0) return res.status(409).json({ error: 'El estudiante ya está inscrito' });

    await pool.query(
      'INSERT INTO inscripciones (curso_id, estudiante_id) VALUES (?, ?)',
      [curso_id, estudiante_id]
    );
    res.status(201).json({ mensaje: 'Estudiante inscrito' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al inscribir estudiante' });
  }
}

// DELETE /api/cursos/:cursoId/inscripciones/:estudianteId
async function desinscribir(req, res) {
  try {
    const [result] = await pool.query(
      `DELETE i FROM inscripciones i JOIN cursos c ON c.id = i.curso_id
       WHERE i.curso_id = ? AND i.estudiante_id = ? AND c.usuario_id = ?`,
      [req.params.cursoId, req.params.estudianteId, req.user.id]
    );
    if (result.affectedRows === 0) return res.status(404).json({ error: 'Inscripción no encontrada' });
    res.json({ mensaje: 'Estudiante retirado del curso' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al retirar estudiante' });
  }
}

module.exports = { listar, crear, inscritosPorCurso, inscribir, desinscribir };

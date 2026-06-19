// src/controllers/sesiones.controller.js
const { pool } = require('../db');

// GET /api/sesiones?curso_id=#   (lista; filtro opcional por curso)
async function listar(req, res) {
  try {
    const { curso_id } = req.query;
    let sql =
      `SELECT s.*, c.nombre AS curso_nombre, c.codigo AS curso_codigo,
              (SELECT COUNT(*) FROM asistencias a WHERE a.sesion_id = s.id AND a.estado = 'presente') AS presentes,
              (SELECT COUNT(*) FROM asistencias a WHERE a.sesion_id = s.id) AS total_registros
       FROM sesiones s
       JOIN cursos c ON c.id = s.curso_id
       WHERE c.usuario_id = ?`;
    const params = [req.user.id];
    if (curso_id) {
      sql += ' AND s.curso_id = ?';
      params.push(curso_id);
    }
    sql += ' ORDER BY s.fecha DESC, s.hora_inicio DESC';
    const [rows] = await pool.query(sql, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al listar sesiones' });
  }
}

// GET /api/sesiones/:id
async function obtener(req, res) {
  try {
    const [rows] = await pool.query(
      `SELECT s.*, c.nombre AS curso_nombre, c.codigo AS curso_codigo
       FROM sesiones s
       JOIN cursos c ON c.id = s.curso_id
       WHERE s.id = ? AND c.usuario_id = ?`,
      [req.params.id, req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Sesión no encontrada' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al obtener sesión' });
  }
}

// POST /api/sesiones
async function crear(req, res) {
  const { curso_id, fecha, hora_inicio, hora_fin, tema } = req.body;
  try {
    // Validar que el curso pertenezca al usuario
    const [curso] = await pool.query(
      'SELECT id FROM cursos WHERE id = ? AND usuario_id = ?',
      [curso_id, req.user.id]
    );
    if (curso.length === 0) return res.status(404).json({ error: 'Curso no encontrado' });

    const [result] = await pool.query(
      'INSERT INTO sesiones (curso_id, fecha, hora_inicio, hora_fin, tema) VALUES (?, ?, ?, ?, ?)',
      [curso_id, fecha, hora_inicio, hora_fin, tema]
    );

    // Al crear la sesión, generar registros de asistencia (ausente) para inscritos
    await pool.query(
      `INSERT INTO asistencias (sesion_id, estudiante_id, estado)
       SELECT ?, i.estudiante_id, 'ausente'
       FROM inscripciones i WHERE i.curso_id = ?`,
      [result.insertId, curso_id]
    );

    const [rows] = await pool.query('SELECT * FROM sesiones WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al crear sesión' });
  }
}

// PUT /api/sesiones/:id
async function actualizar(req, res) {
  const { fecha, hora_inicio, hora_fin, tema } = req.body;
  try {
    const [own] = await pool.query(
      `SELECT s.id FROM sesiones s JOIN cursos c ON c.id = s.curso_id
       WHERE s.id = ? AND c.usuario_id = ?`,
      [req.params.id, req.user.id]
    );
    if (own.length === 0) return res.status(404).json({ error: 'Sesión no encontrada' });

    await pool.query(
      'UPDATE sesiones SET fecha = ?, hora_inicio = ?, hora_fin = ?, tema = ? WHERE id = ?',
      [fecha, hora_inicio, hora_fin, tema, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM sesiones WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar sesión' });
  }
}

// DELETE /api/sesiones/:id
async function eliminar(req, res) {
  try {
    const [result] = await pool.query(
      `DELETE s FROM sesiones s JOIN cursos c ON c.id = s.curso_id
       WHERE s.id = ? AND c.usuario_id = ?`,
      [req.params.id, req.user.id]
    );
    if (result.affectedRows === 0) return res.status(404).json({ error: 'Sesión no encontrada' });
    res.json({ mensaje: 'Sesión eliminada' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al eliminar sesión' });
  }
}

module.exports = { listar, obtener, crear, actualizar, eliminar };

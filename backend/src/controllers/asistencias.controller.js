// src/controllers/asistencias.controller.js
const { pool } = require('../db');

// GET /api/sesiones/:id/asistencias  (lista de asistencia de una sesión)
async function listarPorSesion(req, res) {
  try {
    // Verificar propiedad de la sesión
    const [own] = await pool.query(
      `SELECT s.id FROM sesiones s JOIN cursos c ON c.id = s.curso_id
       WHERE s.id = ? AND c.usuario_id = ?`,
      [req.params.id, req.user.id]
    );
    if (own.length === 0) return res.status(404).json({ error: 'Sesión no encontrada' });

    // Asegura que todos los inscritos tengan un registro de asistencia
    await pool.query(
      `INSERT IGNORE INTO asistencias (sesion_id, estudiante_id, estado)
       SELECT ?, i.estudiante_id, 'ausente'
       FROM inscripciones i
       JOIN sesiones s ON s.curso_id = i.curso_id
       WHERE s.id = ?`,
      [req.params.id, req.params.id]
    );

    const [rows] = await pool.query(
      `SELECT a.id, a.estado, a.observacion, a.hora_registro,
              e.id AS estudiante_id, e.nombre, e.documento
       FROM asistencias a
       JOIN estudiantes e ON e.id = a.estudiante_id
       WHERE a.sesion_id = ?
       ORDER BY e.nombre`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al listar asistencias' });
  }
}

// PUT /api/asistencias/:id  { estado, observacion }
async function actualizar(req, res) {
  const { estado, observacion } = req.body;
  try {
    const [own] = await pool.query(
      `SELECT a.id FROM asistencias a
       JOIN sesiones s ON s.id = a.sesion_id
       JOIN cursos c ON c.id = s.curso_id
       WHERE a.id = ? AND c.usuario_id = ?`,
      [req.params.id, req.user.id]
    );
    if (own.length === 0) return res.status(404).json({ error: 'Registro no encontrado' });

    await pool.query(
      'UPDATE asistencias SET estado = ?, observacion = ?, hora_registro = CURRENT_TIMESTAMP WHERE id = ?',
      [estado, observacion || null, req.params.id]
    );
    const [rows] = await pool.query('SELECT * FROM asistencias WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al actualizar asistencia' });
  }
}

// GET /api/estadisticas/curso/:id  (resumen de asistencia de un curso)
async function estadisticasCurso(req, res) {
  try {
    const [curso] = await pool.query(
      'SELECT * FROM cursos WHERE id = ? AND usuario_id = ?',
      [req.params.id, req.user.id]
    );
    if (curso.length === 0) return res.status(404).json({ error: 'Curso no encontrado' });

    // Conteo global por estado
    const [porEstado] = await pool.query(
      `SELECT a.estado, COUNT(*) AS total
       FROM asistencias a
       JOIN sesiones s ON s.id = a.sesion_id
       WHERE s.curso_id = ?
       GROUP BY a.estado`,
      [req.params.id]
    );

    // Porcentaje de asistencia por estudiante
    const [porEstudiante] = await pool.query(
      `SELECT e.id, e.nombre, e.documento,
              COUNT(a.id) AS total_sesiones,
              SUM(CASE WHEN a.estado IN ('presente','tarde') THEN 1 ELSE 0 END) AS asistencias,
              ROUND(100 * SUM(CASE WHEN a.estado IN ('presente','tarde') THEN 1 ELSE 0 END)
                    / NULLIF(COUNT(a.id),0), 1) AS porcentaje
       FROM estudiantes e
       JOIN asistencias a ON a.estudiante_id = e.id
       JOIN sesiones s ON s.id = a.sesion_id
       WHERE s.curso_id = ?
       GROUP BY e.id, e.nombre, e.documento
       ORDER BY porcentaje DESC`,
      [req.params.id]
    );

    res.json({
      curso: curso[0],
      por_estado: porEstado,
      por_estudiante: porEstudiante,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error al calcular estadísticas' });
  }
}

module.exports = { listarPorSesion, actualizar, estadisticasCurso };

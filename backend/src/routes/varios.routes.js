// src/routes/varios.routes.js
const express = require('express');
const { body } = require('express-validator');
const validate = require('../validators/validate');
const auth = require('../middleware/auth');
const estudiantes = require('../controllers/estudiantes.controller');
const asistencias = require('../controllers/asistencias.controller');

const router = express.Router();
router.use(auth);

// Estudiantes (catálogo global)
router.get('/estudiantes', estudiantes.listar);
router.post(
  '/estudiantes',
  [
    body('nombre').trim().notEmpty().withMessage('El nombre es obligatorio'),
    body('documento').trim().notEmpty().withMessage('El documento es obligatorio'),
  ],
  validate,
  estudiantes.crear
);

// Actualizar un registro de asistencia
router.put(
  '/asistencias/:id',
  [body('estado').isIn(['presente', 'ausente', 'tarde', 'justificado']).withMessage('Estado inválido')],
  validate,
  asistencias.actualizar
);

// Estadísticas de un curso
router.get('/estadisticas/curso/:id', asistencias.estadisticasCurso);

module.exports = router;

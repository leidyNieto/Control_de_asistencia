// src/routes/sesiones.routes.js
const express = require('express');
const { body } = require('express-validator');
const validate = require('../validators/validate');
const auth = require('../middleware/auth');
const sesiones = require('../controllers/sesiones.controller');
const asistencias = require('../controllers/asistencias.controller');

const router = express.Router();
router.use(auth);

const reglasSesion = [
  body('fecha').notEmpty().withMessage('La fecha es obligatoria'),
  body('hora_inicio').notEmpty().withMessage('La hora de inicio es obligatoria'),
  body('hora_fin').notEmpty().withMessage('La hora de fin es obligatoria'),
  body('tema').trim().notEmpty().withMessage('El tema es obligatorio'),
];

// CRUD de sesiones (entidad principal)
router.get('/', sesiones.listar);
router.get('/:id', sesiones.obtener);
router.post(
  '/',
  [body('curso_id').isInt().withMessage('curso_id inválido'), ...reglasSesion],
  validate,
  sesiones.crear
);
router.put('/:id', reglasSesion, validate, sesiones.actualizar);
router.delete('/:id', sesiones.eliminar);

// Asistencias de una sesión
router.get('/:id/asistencias', asistencias.listarPorSesion);

module.exports = router;

// src/routes/cursos.routes.js
const express = require('express');
const { body } = require('express-validator');
const validate = require('../validators/validate');
const auth = require('../middleware/auth');
const cursos = require('../controllers/cursos.controller');
const estudiantes = require('../controllers/estudiantes.controller');

const router = express.Router();
router.use(auth); // todas las rutas requieren token

// CRUD de cursos
router.get('/', cursos.listar);
router.get('/:id', cursos.obtener);
router.post(
  '/',
  [
    body('nombre').trim().notEmpty().withMessage('El nombre es obligatorio'),
    body('codigo').trim().notEmpty().withMessage('El código es obligatorio'),
  ],
  validate,
  cursos.crear
);
router.put(
  '/:id',
  [
    body('nombre').trim().notEmpty().withMessage('El nombre es obligatorio'),
    body('codigo').trim().notEmpty().withMessage('El código es obligatorio'),
  ],
  validate,
  cursos.actualizar
);
router.delete('/:id', cursos.eliminar);

// Inscripciones dentro de un curso
router.get('/:id/estudiantes', estudiantes.inscritosPorCurso);
router.post(
  '/:id/inscripciones',
  [body('estudiante_id').isInt().withMessage('estudiante_id inválido')],
  validate,
  estudiantes.inscribir
);
router.delete('/:cursoId/inscripciones/:estudianteId', estudiantes.desinscribir);

module.exports = router;

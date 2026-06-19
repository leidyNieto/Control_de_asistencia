// src/routes/auth.routes.js
const express = require('express');
const { body } = require('express-validator');
const validate = require('../validators/validate');
const ctrl = require('../controllers/auth.controller');

const router = express.Router();

router.post(
  '/register',
  [
    body('nombre').trim().notEmpty().withMessage('El nombre es obligatorio'),
    body('email').isEmail().withMessage('Correo inválido').normalizeEmail(),
    body('password').isLength({ min: 6 }).withMessage('La contraseña debe tener al menos 6 caracteres'),
  ],
  validate,
  ctrl.register
);

router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Correo inválido').normalizeEmail(),
    body('password').notEmpty().withMessage('La contraseña es obligatoria'),
  ],
  validate,
  ctrl.login
);

module.exports = router;

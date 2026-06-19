// src/validators/validate.js
const { validationResult } = require('express-validator');

// Recolecta los errores de validación y responde 422 si los hay.
function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({
      error: 'Datos inválidos',
      detalles: errors.array().map((e) => ({ campo: e.path, mensaje: e.msg })),
    });
  }
  next();
}

module.exports = validate;

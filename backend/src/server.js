// src/server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { waitForDb } = require('./db');

const authRoutes = require('./routes/auth.routes');
const cursosRoutes = require('./routes/cursos.routes');
const sesionesRoutes = require('./routes/sesiones.routes');
const variosRoutes = require('./routes/varios.routes');

const app = express();
app.use(cors());            // permite acceso desde la app móvil
app.use(express.json());

// Healthcheck
app.get('/', (req, res) => res.json({ servicio: 'Control de Asistencia API', estado: 'ok' }));
app.get('/api/health', (req, res) => res.json({ estado: 'ok', hora: new Date().toISOString() }));

// Rutas
app.use('/api', authRoutes);          // /api/register, /api/login
app.use('/api/cursos', cursosRoutes); // /api/cursos ...
app.use('/api/sesiones', sesionesRoutes);
app.use('/api', variosRoutes);        // /api/estudiantes, /api/asistencias, /api/estadisticas

// 404
app.use((req, res) => res.status(404).json({ error: 'Recurso no encontrado' }));

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    await waitForDb();
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`API escuchando en http://0.0.0.0:${PORT}`);
    });
  } catch (err) {
    console.error('No se pudo iniciar el servidor:', err.message);
    process.exit(1);
  }
})();

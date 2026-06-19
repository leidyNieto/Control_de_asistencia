// src/db.js
// Pool de conexiones a MySQL usando mysql2/promise.
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'control_asistencia',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// Espera a que la base de datos esté lista (útil con Docker Compose,
// donde el contenedor de MySQL puede tardar unos segundos en arrancar).
async function waitForDb(retries = 15, delayMs = 3000) {
  for (let i = 1; i <= retries; i++) {
    try {
      const conn = await pool.getConnection();
      await conn.ping();
      conn.release();
      console.log('Conexión a MySQL establecida.');
      return;
    } catch (err) {
      console.log(`Intento ${i}/${retries} - MySQL no disponible aún (${err.code || err.message})`);
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  throw new Error('No fue posible conectar a MySQL tras varios intentos.');
}

module.exports = { pool, waitForDb };

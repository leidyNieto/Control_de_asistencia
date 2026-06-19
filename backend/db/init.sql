-- ============================================================
--  Proyecto: Control de Asistencia
--  Motor: MySQL 8 / MariaDB
--  Modelo relacional con 5 tablas de dominio + 1 tabla de auth
-- ============================================================

CREATE DATABASE IF NOT EXISTS control_asistencia
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE control_asistencia;

-- ------------------------------------------------------------
-- Tabla de soporte / autenticación (NO cuenta como tabla de dominio)
-- Representa al docente / usuario que administra los cursos.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nombre        VARCHAR(120)  NOT NULL,
  email         VARCHAR(150)  NOT NULL UNIQUE,
  password_hash VARCHAR(255)  NOT NULL,
  created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
--  TABLAS DE DOMINIO (5)
-- ============================================================

-- 1) cursos: asignaturas que administra un docente (usuario)
CREATE TABLE IF NOT EXISTS cursos (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id  INT           NOT NULL,
  nombre      VARCHAR(150)  NOT NULL,
  codigo      VARCHAR(30)   NOT NULL UNIQUE,
  descripcion VARCHAR(255),
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cursos_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- 2) estudiantes: personas a las que se les controla la asistencia
CREATE TABLE IF NOT EXISTS estudiantes (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  nombre     VARCHAR(150)  NOT NULL,
  documento  VARCHAR(30)   NOT NULL UNIQUE,
  email      VARCHAR(150),
  created_at TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3) inscripciones: relación N:M entre cursos y estudiantes
CREATE TABLE IF NOT EXISTS inscripciones (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  curso_id         INT       NOT NULL,
  estudiante_id    INT       NOT NULL,
  fecha_inscripcion DATE     NOT NULL DEFAULT (CURRENT_DATE),
  CONSTRAINT fk_insc_curso
    FOREIGN KEY (curso_id) REFERENCES cursos(id) ON DELETE CASCADE,
  CONSTRAINT fk_insc_estudiante
    FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE CASCADE,
  CONSTRAINT uq_insc UNIQUE (curso_id, estudiante_id)
) ENGINE=InnoDB;

-- 4) sesiones: clases programadas de un curso (ENTIDAD PRINCIPAL del CRUD)
CREATE TABLE IF NOT EXISTS sesiones (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  curso_id    INT           NOT NULL,
  fecha       DATE          NOT NULL,
  hora_inicio TIME          NOT NULL,
  hora_fin    TIME          NOT NULL,
  tema        VARCHAR(200)  NOT NULL,
  created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sesiones_curso
    FOREIGN KEY (curso_id) REFERENCES cursos(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 5) asistencias: registro del estado de cada estudiante por sesión
CREATE TABLE IF NOT EXISTS asistencias (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  sesion_id     INT       NOT NULL,
  estudiante_id INT       NOT NULL,
  estado        ENUM('presente','ausente','tarde','justificado') NOT NULL DEFAULT 'ausente',
  observacion   VARCHAR(255),
  hora_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_asist_sesion
    FOREIGN KEY (sesion_id) REFERENCES sesiones(id) ON DELETE CASCADE,
  CONSTRAINT fk_asist_estudiante
    FOREIGN KEY (estudiante_id) REFERENCES estudiantes(id) ON DELETE CASCADE,
  CONSTRAINT uq_asist UNIQUE (sesion_id, estudiante_id)
) ENGINE=InnoDB;

-- ============================================================
--  Índices auxiliares
-- ============================================================
CREATE INDEX idx_sesiones_curso ON sesiones(curso_id);
CREATE INDEX idx_asist_sesion   ON asistencias(sesion_id);
CREATE INDEX idx_insc_curso     ON inscripciones(curso_id);

-- ============================================================
--  DATOS DE PRUEBA (seed)
--  Usuario de prueba: docente@uni.edu  /  contraseña: 123456
--  (hash bcrypt generado para "123456")
-- ============================================================
INSERT INTO usuarios (nombre, email, password_hash) VALUES
  ('Docente Demo', 'docente@uni.edu',
   '$2b$10$N9qo8uLOickgx2ZMRZoMy.MQDr8s4z6E1L9xH0Q8X8X8X8X8X8Xa');
-- Nota: el hash anterior es ilustrativo. Al registrarte desde la app
-- se genera un hash bcrypt real. Si quieres usar este usuario,
-- regístralo nuevamente desde la app o usa el endpoint /api/register.

INSERT INTO estudiantes (nombre, documento, email) VALUES
  ('Ana Torres',     '1001', 'ana@uni.edu'),
  ('Bruno Díaz',     '1002', 'bruno@uni.edu'),
  ('Carla Méndez',   '1003', 'carla@uni.edu'),
  ('Diego Salas',    '1004', 'diego@uni.edu'),
  ('Elena Ríos',     '1005', 'elena@uni.edu');

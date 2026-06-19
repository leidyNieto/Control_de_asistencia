# Control de Asistencia — Proyecto Final

Aplicación móvil **cliente/servidor** para el control de asistencia de estudiantes
a las sesiones de clase de un curso. Permite a un docente registrarse, iniciar sesión,
gestionar cursos y sesiones (CRUD), inscribir estudiantes, tomar asistencia por sesión
y consultar estadísticas.

- **Frontend:** Flutter (Dart) — un solo código base compilado a **nativo** para Android e iOS.
- **Backend:** Node.js + Express (API REST / JSON, bcrypt, JWT).
- **Base de datos:** MySQL 8 (relacional, 5 tablas de dominio + 1 de autenticación).
- **Despliegue:** Docker Compose (`api`, `db`, `adminer`).

---

## 1. Arquitectura

```
┌──────────────────────┐        HTTP/JSON (REST)        ┌──────────────────────┐
│   App Flutter         │  ───────────────────────────► │   API Node/Express    │
│  (Android / iOS)      │  ◄─────────────────────────── │   (JWT + bcrypt)      │
└──────────────────────┘                                └──────────┬───────────┘
                                                                    │ SQL
                                                         ┌──────────▼───────────┐
                                                         │   MySQL 8             │
                                                         └──────────────────────┘
```

---

## 2. Modelo Entidad–Relación

Tablas de **dominio** (5) + tabla de **autenticación** (`usuarios`, no cuenta):

```
usuarios (auth)
   └──< cursos
           ├──< sesiones ──< asistencias >── estudiantes
           └──< inscripciones >── estudiantes
```

| Tabla           | Descripción                                   | Claves foráneas                       |
|-----------------|-----------------------------------------------|---------------------------------------|
| `usuarios`      | Docente / usuario del sistema (auth)          | —                                     |
| `cursos`        | Asignaturas administradas por un docente      | `usuario_id → usuarios`               |
| `estudiantes`   | Personas a las que se controla la asistencia  | —                                     |
| `inscripciones` | Relación N:M entre cursos y estudiantes       | `curso_id`, `estudiante_id`           |
| `sesiones`      | Clases programadas (entidad principal CRUD)   | `curso_id → cursos`                   |
| `asistencias`   | Estado de cada estudiante por sesión          | `sesion_id`, `estudiante_id`          |

El esquema completo con claves foráneas y datos de prueba está en
[`backend/db/init.sql`](backend/db/init.sql).

---

## 3. Cómo ejecutar el backend

### Opción A — Docker Compose (recomendada)

Requisitos: Docker y Docker Compose.

```bash
# Desde la raíz del proyecto
docker-compose up --build
```

Esto levanta tres servicios:

| Servicio | URL                       | Descripción                          |
|----------|---------------------------|--------------------------------------|
| api      | http://localhost:3000     | API REST                             |
| db       | localhost:3306            | MySQL 8 (usuario `root` / `rootpass`)|
| adminer  | http://localhost:8080     | Administrador web de la BD           |

El script `init.sql` crea las tablas y carga estudiantes de prueba automáticamente
la primera vez que se crea el contenedor de la base de datos.

Para reiniciar la base de datos desde cero:

```bash
docker-compose down -v   # elimina el volumen de datos
docker-compose up --build
```

### Opción B — Ejecución local sin Docker

Requisitos: Node.js 20+ y un MySQL local.

```bash
cd backend
cp .env.example .env      # ajusta credenciales de tu MySQL
# crea la base ejecutando backend/db/init.sql en tu MySQL
npm install
npm run dev
```

### Verificar que el backend funciona

```bash
curl http://localhost:3000/api/health
# {"estado":"ok","hora":"..."}
```

---

## 4. Cómo ejecutar la app móvil

Requisitos: Flutter SDK 3.x.

```bash
cd mobile
flutter create .          # genera las carpetas nativas android/ e ios/ (solo la 1ª vez)
flutter pub get
flutter run               # selecciona emulador Android, simulador iOS o dispositivo físico
```

> `flutter create .` regenera el andamiaje nativo (Android/iOS) sin sobreescribir
> el código en `lib/` ni `pubspec.yaml`, que ya vienen completos en este repositorio.

### Configurar la URL del backend

Edita [`mobile/lib/config/api_config.dart`](mobile/lib/config/api_config.dart)
según dónde corra tu backend:

| Escenario                               | `baseUrl`                          |
|-----------------------------------------|------------------------------------|
| Emulador Android + backend local        | `http://10.0.2.2:3000`             |
| Simulador iOS + backend local           | `http://localhost:3000`            |
| Dispositivo físico (misma red WiFi)     | `http://<IP-de-tu-PC>:3000`        |
| Túnel ngrok / LocalTunnel               | `https://xxxx.ngrok-free.app`      |
| Despliegue en la nube                   | `https://tu-dominio.com`           |

### Permitir HTTP en desarrollo (importante)

Si usas `http://` (no HTTPS), habilita el tráfico en texto plano:

**Android** — en `android/app/src/main/AndroidManifest.xml`, dentro de `<application ...>`:
```xml
android:usesCleartextTraffic="true"
```

**iOS** — en `ios/Runner/Info.plist`, agrega:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```
Con un túnel HTTPS (ngrok) o despliegue HTTPS no necesitas estos ajustes.

### Exponer el backend con un túnel (Escenario A de la guía)

```bash
# con el backend corriendo en el puerto 3000
npx localtunnel --port 3000
# o
ngrok http 3000
```
Copia la URL pública resultante en `api_config.dart`.

---

## 5. Credenciales de prueba

La forma más sencilla es **registrar** un usuario nuevo desde la app (pantalla de registro).
El backend cifra la contraseña con bcrypt.

Estudiantes de prueba ya cargados: Ana Torres, Bruno Díaz, Carla Méndez, Diego Salas, Elena Ríos.

Flujo sugerido para la demostración:
1. Registrarse / iniciar sesión.
2. Crear un curso.
3. Entrar al curso → pestaña **Inscritos** → inscribir estudiantes.
4. Pestaña **Sesiones** → crear una sesión.
5. Abrir la sesión → marcar asistencia (presente / tarde / ausente / justificado).
6. Botón de **estadísticas** (gráfico de barras superior) → ver porcentajes.

---

## 6. Endpoints de la API

Todos bajo el prefijo `/api`. Las rutas de dominio requieren header
`Authorization: Bearer <token>`.

| Método | Ruta                                         | Descripción                          |
|--------|----------------------------------------------|--------------------------------------|
| POST   | `/api/register`                              | Registro de usuario                  |
| POST   | `/api/login`                                 | Inicio de sesión (devuelve token)    |
| GET    | `/api/cursos`                                | Listar cursos del usuario            |
| GET    | `/api/cursos/{id}`                           | Obtener un curso                     |
| POST   | `/api/cursos`                                | Crear curso                          |
| PUT    | `/api/cursos/{id}`                           | Editar curso                         |
| DELETE | `/api/cursos/{id}`                           | Eliminar curso                       |
| GET    | `/api/sesiones?curso_id={id}`                | Listar sesiones (entidad principal)  |
| GET    | `/api/sesiones/{id}`                          | Obtener sesión                       |
| POST   | `/api/sesiones`                              | Crear sesión                         |
| PUT    | `/api/sesiones/{id}`                          | Editar sesión                        |
| DELETE | `/api/sesiones/{id}`                          | Eliminar sesión                      |
| GET    | `/api/sesiones/{id}/asistencias`             | Lista de asistencia de una sesión    |
| PUT    | `/api/asistencias/{id}`                       | Cambiar estado de asistencia         |
| GET    | `/api/estudiantes`                           | Catálogo de estudiantes              |
| POST   | `/api/estudiantes`                           | Crear estudiante                     |
| GET    | `/api/cursos/{id}/estudiantes`               | Estudiantes inscritos en un curso    |
| POST   | `/api/cursos/{id}/inscripciones`             | Inscribir estudiante                 |
| DELETE | `/api/cursos/{cId}/inscripciones/{eId}`      | Retirar estudiante del curso         |
| GET    | `/api/estadisticas/curso/{id}`               | Estadísticas de asistencia           |

Ejemplos de uso en [`API.http`](API.http).

---

## 7. Pantallas de la app

**Autenticación:** Registro, Inicio de sesión.

**Dominio (6 pantallas):**
1. Lista de cursos (listado + eliminar).
2. Crear / editar curso (formulario).
3. Detalle de curso (pestañas: sesiones e inscritos).
4. Crear / editar sesión (formulario con fecha y hora).
5. Detalle de sesión — toma de asistencia.
6. Estadísticas de asistencia del curso.

---

## 8. Lista de verificación de la guía

- [x] Registro e inicio de sesión funcionales (bcrypt + JWT).
- [x] CRUD completo en backend (cursos y sesiones).
- [x] Base de datos relacional SQL con 5 tablas de dominio y claves foráneas.
- [x] Conexión App ↔ backend por red local / túnel / nube (configurable).
- [x] Opción de despliegue documentada (Docker Compose).
- [x] App móvil multiplataforma (Flutter → Android e iOS).
- [x] Más de 5 pantallas del dominio principal.
- [x] Documentación con README y endpoints.
- [ ] Video demostrativo de máximo 3 minutos (a grabar por el estudiante).

---

## 9. Estructura del proyecto

```
control-asistencia/
├── docker-compose.yml
├── README.md
├── API.http
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── .env.example
│   ├── db/
│   │   └── init.sql
│   └── src/
│       ├── server.js
│       ├── db.js
│       ├── middleware/auth.js
│       ├── validators/validate.js
│       ├── controllers/
│       └── routes/
└── mobile/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── config/api_config.dart
        ├── models/modelos.dart
        ├── services/api_service.dart
        ├── providers/auth_provider.dart
        └── screens/
```

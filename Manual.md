# Guía de instalación y ejecución — Control de Asistencia
## 1. Programas a instalar


Extensiones / plugins necesarios:
- En **Android Studio**: plugins **Flutter** y **Dart** (Settings → Plugins → buscar "Flutter" e instalar; Dart se instala junto).
- (Si usaras VS Code en su lugar: extensión **Flutter**.)

---

## 2. Preparación por única vez

1. **Instalar Docker Desktop** y abrirlo.
   - Requiere **WSL 2**. Si no lo tienes, abre PowerShell como administrador y ejecuta:
     ```
     wsl --install
     ```
     Luego reinicia el PC.
   - La **virtualización** debe estar activada.


2. **Instalar el Flutter SDK.**
   - Si la extensión de Flutter muestra "Could not find a Flutter SDK", usa el botón **Download SDK** y elige una ruta simple (ej: `C:\flutter`).
   - Verifica en una terminal nueva:
     ```
     flutter --version
     ```

4. **Configurar Flutter en Android Studio** (si pide "Dart SDK is not configured"):
   - Settings → Languages & Frameworks → Flutter → **Flutter SDK path** = ruta de Flutter (ej: `C:\flutter`) → Apply / OK.

5. **Aceptar las licencias de Android** (lo pide `flutter doctor`):
   ```
   flutter doctor --android-licenses
   ```
   Responder `y` a todas.

6. **Crear el emulador** en Android Studio:
   - Device Manager → Add Device → elegir un **Pixel** (ej: Pixel 8) → imagen del sistema **API 34 o 35**, variante **x86_64** con **Google Play** → Finish.
---

## 3. Cómo correr el proyecto (cada vez)

### Paso 1 — Levantar el backend con Docker
1. Abrir **Docker Desktop** y esperar a que el motor esté listo.
2. Abrir una terminal (PowerShell o la de VS Code) en la **carpeta raíz** del proyecto (donde está `docker-compose.yml`) y ejecutar:
   ```
   docker-compose up --build
   ```
   (Las siguientes veces basta con `docker-compose up`.)
3. Cuando aparezca esto, el backend está listo:
   ```
   ca_api | Conexión a MySQL establecida.
   ca_api | API escuchando en http://0.0.0.0:3000
   ```
4. Verificar en el navegador del PC: http://localhost:3000/api/health → debe responder `{"estado":"ok"}`.
5. **Dejar esa terminal abierta.** Si se cierra, el backend se apaga.

> Administrador visual de la base de datos (opcional): http://localhost:8080 (Adminer). Sistema: MySQL · Servidor: `db` · Usuario: `root` · Contraseña: `rootpass` · Base: `control_asistencia`.

### Paso 2 — Encender el emulador
En Android Studio: Device Manager → botón ▶ junto al emulador. Esperar a que cargue Android.

### Paso 3 — Configurar la URL del backend
En `mobile/lib/config/api_config.dart`, dejar:
```dart
static const String baseUrl = "http://10.0.2.2:3000";
```
(`10.0.2.2` es la dirección que usa el emulador de Android para llegar al PC.)

### Paso 4 — Generar carpetas nativas (solo la primera vez)
En la terminal de Android Studio, dentro de la carpeta `mobile/`:
```
flutter create .
```
Esto genera `android/` e `ios/` sin tocar el código de `lib/`.

### Paso 5 — Permitir conexión HTTP en Android (solo la primera vez)
En `mobile/android/app/src/main/AndroidManifest.xml`, dentro de la etiqueta `<application ...>`, agregar:
```xml
android:usesCleartextTraffic="true"
```

### Paso 6 — Ejecutar la app
1. Arriba, seleccionar el dispositivo **Pixel ... (mobile)** (no "Windows desktop").
2. Pulsar el **botón verde ▶**.
3. La primera compilación tarda varios minutos (descarga dependencias y, si hace falta, el NDK).

---


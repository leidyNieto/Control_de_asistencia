// lib/config/api_config.dart
//
// Configura aquí la URL base del backend según tu escenario de prueba.
//
//  - Emulador Android (backend local en tu PC):   http://10.0.2.2:3000
//  - Simulador iOS (backend local en tu PC):       http://localhost:3000
//  - Dispositivo físico en la misma red WiFi:      http://<IP_DE_TU_PC>:3000
//      (ej: http://192.168.1.20:3000)
//  - Backend expuesto con ngrok / LocalTunnel:     https://xxxx.ngrok-free.app
//  - Backend desplegado en la nube:                https://tu-dominio.com
//
class ApiConfig {
  // Cambia este valor según el escenario en el que estés probando.
  static const String baseUrl = "http://10.0.2.2:3000";

  static const String apiUrl = "$baseUrl/api";
}

// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/modelos.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api = ApiService();

  Usuario? _usuario;
  String? _token;
  bool _cargando = true;

  Usuario? get usuario => _usuario;
  bool get autenticado => _token != null;
  bool get cargando => _cargando;

  /// Carga el token guardado al iniciar la app (sesión persistente).
  Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final nombre = prefs.getString('nombre');
    final email = prefs.getString('email');
    final id = prefs.getInt('id');
    if (_token != null && id != null) {
      _usuario = Usuario(id: id, nombre: nombre ?? '', email: email ?? '');
      api.setToken(_token);
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> _guardar(Map<String, dynamic> data) async {
    _token = data['token'];
    _usuario = Usuario.fromJson(data['usuario']);
    api.setToken(_token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setInt('id', _usuario!.id);
    await prefs.setString('nombre', _usuario!.nombre);
    await prefs.setString('email', _usuario!.email);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await api.login(email, password);
    await _guardar(data);
  }

  Future<void> register(String nombre, String email, String password) async {
    final data = await api.register(nombre, email, password);
    await _guardar(data);
  }

  Future<void> logout() async {
    _token = null;
    _usuario = null;
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}

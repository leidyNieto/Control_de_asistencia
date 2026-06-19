// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/modelos.dart';

/// Cliente REST. Maneja el token y todas las llamadas al backend.
class ApiService {
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.apiUrl}$path');

  // Decodifica la respuesta y lanza una excepción legible si hubo error.
  dynamic _procesar(http.Response r) {
    final body = r.body.isNotEmpty ? jsonDecode(r.body) : null;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = (body is Map && body['error'] != null)
        ? body['error']
        : 'Error ${r.statusCode}';
    throw ApiException(msg.toString(), r.statusCode);
  }

  // ---------------- AUTH ----------------
  Future<Map<String, dynamic>> register(
      String nombre, String email, String password) async {
    final r = await http.post(_uri('/register'),
        headers: _headers,
        body: jsonEncode({'nombre': nombre, 'email': email, 'password': password}));
    return _procesar(r) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await http.post(_uri('/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}));
    return _procesar(r) as Map<String, dynamic>;
  }

  // ---------------- CURSOS ----------------
  Future<List<Curso>> getCursos() async {
    final r = await http.get(_uri('/cursos'), headers: _headers);
    final data = _procesar(r) as List;
    return data.map((e) => Curso.fromJson(e)).toList();
  }

  Future<Curso> crearCurso(String nombre, String codigo, String? desc) async {
    final r = await http.post(_uri('/cursos'),
        headers: _headers,
        body: jsonEncode({'nombre': nombre, 'codigo': codigo, 'descripcion': desc}));
    return Curso.fromJson(_procesar(r));
  }

  Future<Curso> actualizarCurso(int id, String nombre, String codigo, String? desc) async {
    final r = await http.put(_uri('/cursos/$id'),
        headers: _headers,
        body: jsonEncode({'nombre': nombre, 'codigo': codigo, 'descripcion': desc}));
    return Curso.fromJson(_procesar(r));
  }

  Future<void> eliminarCurso(int id) async {
    final r = await http.delete(_uri('/cursos/$id'), headers: _headers);
    _procesar(r);
  }

  // ---------------- SESIONES ----------------
  Future<List<Sesion>> getSesiones({int? cursoId}) async {
    final path = cursoId != null ? '/sesiones?curso_id=$cursoId' : '/sesiones';
    final r = await http.get(_uri(path), headers: _headers);
    final data = _procesar(r) as List;
    return data.map((e) => Sesion.fromJson(e)).toList();
  }

  Future<Sesion> crearSesion(int cursoId, String fecha, String hi, String hf, String tema) async {
    final r = await http.post(_uri('/sesiones'),
        headers: _headers,
        body: jsonEncode({
          'curso_id': cursoId,
          'fecha': fecha,
          'hora_inicio': hi,
          'hora_fin': hf,
          'tema': tema,
        }));
    return Sesion.fromJson(_procesar(r));
  }

  Future<Sesion> actualizarSesion(int id, String fecha, String hi, String hf, String tema) async {
    final r = await http.put(_uri('/sesiones/$id'),
        headers: _headers,
        body: jsonEncode({'fecha': fecha, 'hora_inicio': hi, 'hora_fin': hf, 'tema': tema}));
    return Sesion.fromJson(_procesar(r));
  }

  Future<void> eliminarSesion(int id) async {
    final r = await http.delete(_uri('/sesiones/$id'), headers: _headers);
    _procesar(r);
  }

  // ---------------- ASISTENCIAS ----------------
  Future<List<Asistencia>> getAsistencias(int sesionId) async {
    final r = await http.get(_uri('/sesiones/$sesionId/asistencias'), headers: _headers);
    final data = _procesar(r) as List;
    return data.map((e) => Asistencia.fromJson(e)).toList();
  }

  Future<void> actualizarAsistencia(int id, String estado, {String? observacion}) async {
    final r = await http.put(_uri('/asistencias/$id'),
        headers: _headers,
        body: jsonEncode({'estado': estado, 'observacion': observacion}));
    _procesar(r);
  }

  // ---------------- ESTUDIANTES / INSCRIPCIONES ----------------
  Future<List<Estudiante>> getEstudiantes() async {
    final r = await http.get(_uri('/estudiantes'), headers: _headers);
    final data = _procesar(r) as List;
    return data.map((e) => Estudiante.fromJson(e)).toList();
  }

  Future<Estudiante> crearEstudiante(String nombre, String documento, String? email) async {
    final r = await http.post(_uri('/estudiantes'),
        headers: _headers,
        body: jsonEncode({'nombre': nombre, 'documento': documento, 'email': email}));
    return Estudiante.fromJson(_procesar(r));
  }

  Future<List<Estudiante>> getInscritos(int cursoId) async {
    final r = await http.get(_uri('/cursos/$cursoId/estudiantes'), headers: _headers);
    final data = _procesar(r) as List;
    return data.map((e) => Estudiante.fromJson(e)).toList();
  }

  Future<void> inscribir(int cursoId, int estudianteId) async {
    final r = await http.post(_uri('/cursos/$cursoId/inscripciones'),
        headers: _headers, body: jsonEncode({'estudiante_id': estudianteId}));
    _procesar(r);
  }

  Future<void> desinscribir(int cursoId, int estudianteId) async {
    final r = await http.delete(_uri('/cursos/$cursoId/inscripciones/$estudianteId'),
        headers: _headers);
    _procesar(r);
  }

  // ---------------- ESTADÍSTICAS ----------------
  Future<Map<String, dynamic>> getEstadisticas(int cursoId) async {
    final r = await http.get(_uri('/estadisticas/curso/$cursoId'), headers: _headers);
    return _procesar(r) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final String mensaje;
  final int statusCode;
  ApiException(this.mensaje, this.statusCode);
  @override
  String toString() => mensaje;
}

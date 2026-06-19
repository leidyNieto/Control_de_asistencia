// lib/models/modelos.dart

class Usuario {
  final int id;
  final String nombre;
  final String email;

  Usuario({required this.id, required this.nombre, required this.email});

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'],
        nombre: j['nombre'] ?? '',
        email: j['email'] ?? '',
      );
}

class Curso {
  final int id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final int totalSesiones;
  final int totalInscritos;

  Curso({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    this.totalSesiones = 0,
    this.totalInscritos = 0,
  });

  factory Curso.fromJson(Map<String, dynamic> j) => Curso(
        id: j['id'],
        nombre: j['nombre'] ?? '',
        codigo: j['codigo'] ?? '',
        descripcion: j['descripcion'],
        totalSesiones: j['total_sesiones'] ?? 0,
        totalInscritos: j['total_inscritos'] ?? 0,
      );
}

class Sesion {
  final int id;
  final int cursoId;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String tema;
  final String? cursoNombre;
  final int presentes;
  final int totalRegistros;

  Sesion({
    required this.id,
    required this.cursoId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.tema,
    this.cursoNombre,
    this.presentes = 0,
    this.totalRegistros = 0,
  });

  factory Sesion.fromJson(Map<String, dynamic> j) => Sesion(
        id: j['id'],
        cursoId: j['curso_id'],
        fecha: (j['fecha'] ?? '').toString().split('T').first,
        horaInicio: (j['hora_inicio'] ?? '').toString(),
        horaFin: (j['hora_fin'] ?? '').toString(),
        tema: j['tema'] ?? '',
        cursoNombre: j['curso_nombre'],
        presentes: j['presentes'] ?? 0,
        totalRegistros: j['total_registros'] ?? 0,
      );
}

class Estudiante {
  final int id;
  final String nombre;
  final String documento;
  final String? email;

  Estudiante({
    required this.id,
    required this.nombre,
    required this.documento,
    this.email,
  });

  factory Estudiante.fromJson(Map<String, dynamic> j) => Estudiante(
        id: j['id'],
        nombre: j['nombre'] ?? '',
        documento: j['documento'] ?? '',
        email: j['email'],
      );
}

class Asistencia {
  final int id;
  final int estudianteId;
  final String nombre;
  final String documento;
  String estado; // mutable: se cambia desde la UI
  String? observacion;

  Asistencia({
    required this.id,
    required this.estudianteId,
    required this.nombre,
    required this.documento,
    required this.estado,
    this.observacion,
  });

  factory Asistencia.fromJson(Map<String, dynamic> j) => Asistencia(
        id: j['id'],
        estudianteId: j['estudiante_id'],
        nombre: j['nombre'] ?? '',
        documento: j['documento'] ?? '',
        estado: j['estado'] ?? 'ausente',
        observacion: j['observacion'],
      );
}

// lib/screens/estadisticas_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/modelos.dart';

class EstadisticasScreen extends StatefulWidget {
  final Curso curso;
  const EstadisticasScreen({super.key, required this.curso});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  Map<String, dynamic>? _data;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final api = context.read<AuthProvider>().api;
    try {
      final d = await api.getEstadisticas(widget.curso.id);
      setState(() => _data = d);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  Color _colorPorcentaje(num p) {
    if (p >= 80) return Colors.green;
    if (p >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _contenido(),
    );
  }

  Widget _contenido() {
    final porEstado = (_data!['por_estado'] as List);
    final porEstudiante = (_data!['por_estudiante'] as List);

    int totalEstado(String e) {
      final m = porEstado.firstWhere((x) => x['estado'] == e, orElse: () => null);
      return m == null ? 0 : (m['total'] as num).toInt();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(widget.curso.nombre,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tarjeta('Presentes', totalEstado('presente'), Colors.green),
            _tarjeta('Tarde', totalEstado('tarde'), Colors.orange),
            _tarjeta('Ausentes', totalEstado('ausente'), Colors.red),
            _tarjeta('Justif.', totalEstado('justificado'), Colors.blue),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Asistencia por estudiante',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (porEstudiante.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aún no hay registros de asistencia.'),
          )
        else
          ...porEstudiante.map((e) {
            final pct = (e['porcentaje'] ?? 0) as num;
            return Card(
              child: ListTile(
                title: Text(e['nombre'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (pct / 100).clamp(0, 1).toDouble(),
                      color: _colorPorcentaje(pct),
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 4),
                    Text('${e['asistencias']}/${e['total_sesiones']} sesiones'),
                  ],
                ),
                trailing: Text('$pct%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _colorPorcentaje(pct))),
              ),
            );
          }),
      ],
    );
  }

  Widget _tarjeta(String titulo, int valor, Color color) {
    return Column(children: [
      CircleAvatar(
        radius: 26,
        backgroundColor: color.withOpacity(0.15),
        child: Text('$valor',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      const SizedBox(height: 4),
      Text(titulo, style: const TextStyle(fontSize: 12)),
    ]);
  }
}

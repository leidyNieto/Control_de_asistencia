// lib/screens/sesion_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/modelos.dart';

class SesionDetalleScreen extends StatefulWidget {
  final Sesion sesion;
  const SesionDetalleScreen({super.key, required this.sesion});

  @override
  State<SesionDetalleScreen> createState() => _SesionDetalleScreenState();
}

class _SesionDetalleScreenState extends State<SesionDetalleScreen> {
  late ApiService api;
  List<Asistencia> _lista = [];
  bool _cargando = true;

  // Colores y etiquetas por estado
  final Map<String, Color> _colores = {
    'presente': Colors.green,
    'ausente': Colors.red,
    'tarde': Colors.orange,
    'justificado': Colors.blue,
  };

  @override
  void initState() {
    super.initState();
    api = context.read<AuthProvider>().api;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data = await api.getAsistencias(widget.sesion.id);
      setState(() => _lista = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstado(Asistencia a, String estado) async {
    final anterior = a.estado;
    setState(() => a.estado = estado); // actualización optimista
    try {
      await api.actualizarAsistencia(a.id, estado);
    } catch (e) {
      setState(() => a.estado = anterior); // revertir si falla
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentes = _lista.where((a) => a.estado == 'presente').length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.sesion.tema)),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                width: double.infinity,
                color: const Color(0xFFE8F5E9),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.sesion.fecha} · ${widget.sesion.horaInicio} - ${widget.sesion.horaFin}'),
                  const SizedBox(height: 4),
                  Text('Presentes: $presentes de ${_lista.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ),
              Expanded(
                child: _lista.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                              'No hay estudiantes inscritos en el curso.\n'
                              'Inscribe estudiantes desde el detalle del curso.',
                              textAlign: TextAlign.center),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _lista.length,
                        itemBuilder: (_, i) {
                          final a = _lista[i];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CircleAvatar(
                                      backgroundColor: _colores[a.estado],
                                      child: Text(a.nombre.isNotEmpty ? a.nombre[0] : '?',
                                          style: const TextStyle(color: Colors.white)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a.nombre,
                                              style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text('Doc: ${a.documento}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: ['presente', 'tarde', 'ausente', 'justificado']
                                        .map((estado) => ChoiceChip(
                                              label: Text(estado),
                                              selected: a.estado == estado,
                                              selectedColor: _colores[estado]!.withOpacity(0.25),
                                              onSelected: (_) => _cambiarEstado(a, estado),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]),
    );
  }
}

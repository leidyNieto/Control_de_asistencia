// lib/screens/curso_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/modelos.dart';
import 'sesion_form_screen.dart';
import 'sesion_detalle_screen.dart';
import 'estadisticas_screen.dart';

class CursoDetalleScreen extends StatefulWidget {
  final Curso curso;
  const CursoDetalleScreen({super.key, required this.curso});

  @override
  State<CursoDetalleScreen> createState() => _CursoDetalleScreenState();
}

class _CursoDetalleScreenState extends State<CursoDetalleScreen>
    with SingleTickerProviderStateMixin {
  late ApiService api;
  late TabController _tab;

  List<Sesion> _sesiones = [];
  List<Estudiante> _inscritos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    api = context.read<AuthProvider>().api;
    _tab = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final s = await api.getSesiones(cursoId: widget.curso.id);
      final ins = await api.getInscritos(widget.curso.id);
      setState(() {
        _sesiones = s;
        _inscritos = ins;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.curso.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadísticas',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => EstadisticasScreen(curso: widget.curso))),
          ),
        ],
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'Sesiones', icon: Icon(Icons.event_note)),
          Tab(text: 'Inscritos', icon: Icon(Icons.people)),
        ]),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tab,
        builder: (_, __) => _tab.index == 0
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final r = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SesionFormScreen(cursoId: widget.curso.id)));
                  if (r == true) _cargar();
                },
                icon: const Icon(Icons.add),
                label: const Text('Sesión'),
              )
            : FloatingActionButton.extended(
                onPressed: _mostrarInscribir,
                icon: const Icon(Icons.person_add),
                label: const Text('Inscribir'),
              ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [_tabSesiones(), _tabInscritos()]),
    );
  }

  Widget _tabSesiones() {
    if (_sesiones.isEmpty) {
      return const Center(child: Text('Sin sesiones. Crea la primera.'));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _sesiones.length,
        itemBuilder: (_, i) {
          final s = _sesiones[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.event, color: Color(0xFF2E7D32)),
              title: Text(s.tema, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${s.fecha}  ·  ${s.horaInicio} - ${s.horaFin}\n'
                  'Presentes: ${s.presentes}/${s.totalRegistros}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'editar') {
                    final r = await Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) =>
                                SesionFormScreen(cursoId: widget.curso.id, sesion: s)));
                    if (r == true) _cargar();
                  } else if (v == 'eliminar') {
                    await api.eliminarSesion(s.id);
                    _cargar();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
              ),
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SesionDetalleScreen(sesion: s)));
                _cargar();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _tabInscritos() {
    if (_inscritos.isEmpty) {
      return const Center(child: Text('Sin estudiantes inscritos.'));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _inscritos.length,
        itemBuilder: (_, i) {
          final e = _inscritos[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(e.nombre.isNotEmpty ? e.nombre[0] : '?')),
              title: Text(e.nombre),
              subtitle: Text('Doc: ${e.documento}'),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove, color: Colors.red),
                onPressed: () async {
                  await api.desinscribir(widget.curso.id, e.id);
                  _cargar();
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _mostrarInscribir() async {
    try {
      final todos = await api.getEstudiantes();
      final idsInscritos = _inscritos.map((e) => e.id).toSet();
      final disponibles = todos.where((e) => !idsInscritos.contains(e.id)).toList();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => disponibles.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Todos los estudiantes ya están inscritos.'))
            : ListView(
                children: disponibles
                    .map((e) => ListTile(
                          title: Text(e.nombre),
                          subtitle: Text('Doc: ${e.documento}'),
                          trailing: const Icon(Icons.add),
                          onTap: () async {
                            Navigator.pop(context);
                            await api.inscribir(widget.curso.id, e.id);
                            _cargar();
                          },
                        ))
                    .toList(),
              ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

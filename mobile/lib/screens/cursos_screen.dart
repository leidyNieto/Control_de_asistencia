// lib/screens/cursos_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/modelos.dart';
import 'curso_form_screen.dart';
import 'curso_detalle_screen.dart';

class CursosScreen extends StatefulWidget {
  const CursosScreen({super.key});

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  late ApiService api;
  List<Curso> _cursos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    api = context.read<AuthProvider>().api;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await api.getCursos();
      setState(() => _cursos = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar(Curso c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar curso'),
        content: Text('¿Eliminar "${c.nombre}" y todas sus sesiones?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await api.eliminarCurso(c.id);
        _cargar();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cursos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'salir') auth.logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(auth.usuario?.nombre ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final r = await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CursoFormScreen()));
          if (r == true) _cargar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo curso'),
      ),
      body: _construirCuerpo(),
    );
  }

  Widget _construirCuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No se pudo cargar: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
          ]),
        ),
      );
    }
    if (_cursos.isEmpty) {
      return const Center(child: Text('Aún no tienes cursos. Crea el primero.'));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _cursos.length,
        itemBuilder: (_, i) {
          final c = _cursos[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(c.codigo.isNotEmpty ? c.codigo[0] : '?')),
              title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Código: ${c.codigo}\n'
                  '${c.totalInscritos} estudiantes · ${c.totalSesiones} sesiones'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'editar') {
                    final r = await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CursoFormScreen(curso: c)));
                    if (r == true) _cargar();
                  } else if (v == 'eliminar') {
                    _eliminar(c);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
              ),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CursoDetalleScreen(curso: c))),
            ),
          );
        },
      ),
    );
  }
}

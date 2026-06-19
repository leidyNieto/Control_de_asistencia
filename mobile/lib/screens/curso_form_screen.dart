// lib/screens/curso_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/modelos.dart';

class CursoFormScreen extends StatefulWidget {
  final Curso? curso; // null = crear, no null = editar
  const CursoFormScreen({super.key, this.curso});

  @override
  State<CursoFormScreen> createState() => _CursoFormScreenState();
}

class _CursoFormScreenState extends State<CursoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombre;
  late TextEditingController _codigo;
  late TextEditingController _desc;
  bool _cargando = false;

  bool get _esEdicion => widget.curso != null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.curso?.nombre ?? '');
    _codigo = TextEditingController(text: widget.curso?.codigo ?? '');
    _desc = TextEditingController(text: widget.curso?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    final api = context.read<AuthProvider>().api;
    try {
      if (_esEdicion) {
        await api.actualizarCurso(
            widget.curso!.id, _nombre.text.trim(), _codigo.text.trim(), _desc.text.trim());
      } else {
        await api.crearCurso(_nombre.text.trim(), _codigo.text.trim(), _desc.text.trim());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar curso' : 'Nuevo curso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                  labelText: 'Nombre del curso', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigo,
              decoration: const InputDecoration(
                  labelText: 'Código (único)', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _cargando ? null : _guardar,
                child: _cargando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_esEdicion ? 'Guardar cambios' : 'Crear curso'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

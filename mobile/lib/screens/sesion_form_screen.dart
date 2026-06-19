// lib/screens/sesion_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/modelos.dart';

class SesionFormScreen extends StatefulWidget {
  final int cursoId;
  final Sesion? sesion; // null = crear
  const SesionFormScreen({super.key, required this.cursoId, this.sesion});

  @override
  State<SesionFormScreen> createState() => _SesionFormScreenState();
}

class _SesionFormScreenState extends State<SesionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tema;
  DateTime _fecha = DateTime.now();
  TimeOfDay _inicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _fin = const TimeOfDay(hour: 10, minute: 0);
  bool _cargando = false;

  bool get _esEdicion => widget.sesion != null;

  @override
  void initState() {
    super.initState();
    _tema = TextEditingController(text: widget.sesion?.tema ?? '');
    if (_esEdicion) {
      _fecha = DateTime.tryParse(widget.sesion!.fecha) ?? DateTime.now();
      _inicio = _parseHora(widget.sesion!.horaInicio);
      _fin = _parseHora(widget.sesion!.horaFin);
    }
  }

  TimeOfDay _parseHora(String s) {
    final p = s.split(':');
    if (p.length >= 2) {
      return TimeOfDay(hour: int.tryParse(p[0]) ?? 8, minute: int.tryParse(p[1]) ?? 0);
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _tema.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    final api = context.read<AuthProvider>().api;
    final fechaStr = DateFormat('yyyy-MM-dd').format(_fecha);
    try {
      if (_esEdicion) {
        await api.actualizarSesion(
            widget.sesion!.id, fechaStr, _hhmm(_inicio), _hhmm(_fin), _tema.text.trim());
      } else {
        await api.crearSesion(
            widget.cursoId, fechaStr, _hhmm(_inicio), _hhmm(_fin), _tema.text.trim());
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
      appBar: AppBar(title: Text(_esEdicion ? 'Editar sesión' : 'Nueva sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _tema,
              decoration: const InputDecoration(
                  labelText: 'Tema de la sesión', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4)),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_fecha)),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _fecha,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _fecha = d);
              },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4)),
                  title: const Text('Inicio'),
                  subtitle: Text(_hhmm(_inicio)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _inicio);
                    if (t != null) setState(() => _inicio = t);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4)),
                  title: const Text('Fin'),
                  subtitle: Text(_hhmm(_fin)),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _fin);
                    if (t != null) setState(() => _fin = t);
                  },
                ),
              ),
            ]),
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
                    : Text(_esEdicion ? 'Guardar cambios' : 'Crear sesión'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

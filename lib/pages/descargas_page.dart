import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../layout/app_layout.dart';

const _kAzul = Color(0xFF1A237E);
const _kApi  = 'https://superbett-api-production.up.railway.app/api';

class DescargasPage extends StatefulWidget {
  const DescargasPage({super.key});
  @override State<DescargasPage> createState() => _DescargasPageState();
}

class _DescargasPageState extends State<DescargasPage> {
  List<Map<String, dynamic>> _descargas = [];
  bool   _loading = true;
  String _error   = '';
  String _rol     = '';

  void _onSelect(BuildContext context, int i) {
    const rutas = ['/menu','/bancas','/venta','/premios',
                   '/reportes','/usuarios','/limites','/configuracion',
                   '/riferos','/descargas'];
    if (i < rutas.length && rutas[i] != '/descargas')
      Navigator.pushReplacementNamed(context, rutas[i]);
  }

  @override
  void initState() { super.initState(); _cargar(); }

  Future<String> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token') ?? '';
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final prefs = await SharedPreferences.getInstance();
      _rol = jsonDecode(prefs.getString('usuario') ?? '{}')['rol'] ?? '';
      final t = await _token();
      final r = await http.get(
        Uri.parse('$_kApi/admin/descargas'),
        headers: {'Authorization': 'Bearer $t'},
      );
      final data = jsonDecode(r.body);
      setState(() {
        _descargas = List<Map<String, dynamic>>.from(data['descargas'] ?? []);
        _loading   = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // Índice del sidebar según rol
  int get _sidebarIndex => _rol == 'tecnico' ? 9 : 9;

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 9,
    onItemSelected: (i) => _onSelect(context, i),
    child: Column(children: [
      Container(
        color: _kAzul,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(children: [
          const Expanded(child: Text('Descargas',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold))),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _cargar),
        ]),
      ),

      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (_error.isNotEmpty)
        Expanded(child: Center(child: Text(_error,
            style: const TextStyle(color: Colors.red))))
      else
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Descarga e instala la app SuperBett POS en tu dispositivo.',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                )),
              ]),
            ),

            // Cards de descarga
            ..._descargas.map((d) => _DescargaCard(
              descarga: d,
              esAdmin: _rol == 'admin',
              onUpdated: _cargar,
            )),
          ]),
        )),
    ]),
  );
}

// ─────────────────────────────────────────────
// Card de una descarga
// ─────────────────────────────────────────────
class _DescargaCard extends StatelessWidget {
  final Map<String, dynamic> descarga;
  final bool esAdmin;
  final VoidCallback onUpdated;

  const _DescargaCard({
    required this.descarga,
    required this.esAdmin,
    required this.onUpdated,
  });

  IconData get _icono {
    final clave = descarga['clave']?.toString() ?? '';
    if (clave.contains('apk'))  return Icons.android;
    if (clave.contains('exe'))  return Icons.computer;
    return Icons.download;
  }

  Color get _color {
    final clave = descarga['clave']?.toString() ?? '';
    if (clave.contains('apk'))  return Colors.green;
    if (clave.contains('exe'))  return Colors.blue;
    return _kAzul;
  }

  String get _titulo {
    final clave = descarga['clave']?.toString() ?? '';
    if (clave == 'apk_android') return 'SuperBett POS — Android';
    if (clave == 'exe_windows') return 'SuperBett POS — Windows';
    return clave;
  }

  String get _extension {
    final clave = descarga['clave']?.toString() ?? '';
    if (clave.contains('apk')) return '.apk';
    if (clave.contains('exe')) return '.exe';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final url     = descarga['url']?.toString() ?? '';
    final version = descarga['version']?.toString() ?? '1.0.0';
    final notas   = descarga['notas']?.toString() ?? '';
    final tieneUrl = url.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icono, color: _color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Text('v$version',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              if (notas.isNotEmpty)
                Text(notas,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ])),
            if (esAdmin)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: Colors.grey,
                onPressed: () => _abrirEditor(context),
              ),
          ]),

          const SizedBox(height: 12),

          // Botón descarga
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: tieneUrl
                  ? () => _descargar(context, url)
                  : null,
              icon: Icon(tieneUrl ? Icons.download : Icons.link_off, size: 18),
              label: Text(tieneUrl
                  ? 'Descargar $_extension'
                  : 'URL no configurada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tieneUrl ? _color : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _descargar(BuildContext context, String url) {
    html.window.open(url, '_blank');
  }

  void _abrirEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _EditorDescarga(
        descarga: descarga,
        onGuardado: onUpdated,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dialog para editar una descarga (solo admin)
// ─────────────────────────────────────────────
class _EditorDescarga extends StatefulWidget {
  final Map<String, dynamic> descarga;
  final VoidCallback onGuardado;
  const _EditorDescarga({required this.descarga, required this.onGuardado});
  @override State<_EditorDescarga> createState() => _EditorDescargaState();
}

class _EditorDescargaState extends State<_EditorDescarga> {
  late TextEditingController _urlCtrl;
  late TextEditingController _verCtrl;
  late TextEditingController _notCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.descarga['url']     ?? '');
    _verCtrl = TextEditingController(text: widget.descarga['version'] ?? '1.0.0');
    _notCtrl = TextEditingController(text: widget.descarga['notas']   ?? '');
  }

  @override
  void dispose() {
    _urlCtrl.dispose(); _verCtrl.dispose(); _notCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString('token') ?? '';
      final r = await http.put(
        Uri.parse('$_kApi/admin/descargas/${widget.descarga['clave']}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
        body: jsonEncode({
          'url':     _urlCtrl.text.trim(),
          'version': _verCtrl.text.trim(),
          'notas':   _notCtrl.text.trim(),
        }),
      );
      if (r.statusCode == 200) {
        widget.onGuardado();
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception(jsonDecode(r.body)['error'] ?? 'Error al guardar');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar descarga'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: _urlCtrl,
        decoration: const InputDecoration(
          labelText: 'URL del archivo',
          hintText: 'https://superbett-admin.web.app/downloads/...',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _verCtrl,
        decoration: const InputDecoration(
          labelText: 'Versión',
          hintText: '1.0.0',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _notCtrl,
        decoration: const InputDecoration(
          labelText: 'Notas',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
    ]),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar')),
      ElevatedButton(
        onPressed: _guardando ? null : _guardar,
        style: ElevatedButton.styleFrom(
            backgroundColor: _kAzul, foregroundColor: Colors.white),
        child: _guardando
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Guardar')),
    ],
  );
}

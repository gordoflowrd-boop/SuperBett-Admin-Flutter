import 'package:flutter/material.dart';
import '../layout/app_layout.dart';
import '../services/bancas_service.dart';
import '../models/banca.dart';
import '../services/usuarios_service.dart'; // <--- VERIFICA QUE ESTE ARCHIVO EXISTA

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});
  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  List<dynamic> _usuarios = [];
  bool _loading = true;
  String _error = "";
  String _idPropio = "";
  List<Banca> _bancas = [];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = ""; });
    try {
      // Cargamos todo en paralelo para mayor velocidad
      await Future.wait([
        _cargarUsuariosInterno(),
        _cargarIdPropioInterno(),
        _cargarBancasInterno(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarUsuariosInterno() async {
    final data = await UsuariosService.obtenerUsuarios();
    if (mounted) _usuarios = data;
  }

  Future<void> _cargarIdPropioInterno() async {
    final id = await UsuariosService.obtenerIdPropio();
    if (mounted) _idPropio = id ?? '';
  }

  Future<void> _cargarBancasInterno() async {
    final b = await BancasService.obtenerBancas();
    if (mounted) _bancas = b;
  }

  // Helper para recargar solo la lista
  Future<void> _recargarLista() async {
    try {
      final data = await UsuariosService.obtenerUsuarios();
      if (mounted) setState(() => _usuarios = data);
    } catch (e) {
      debugPrint("Error recargando: $e");
    }
  }

  // ── Estadísticas ───────────────────────────────────
  int get _totalUsuarios => _usuarios.length;
  int get _activos => _usuarios.where((u) => u['activo'] == true).length;
  int get _inactivos => _usuarios.where((u) => u['activo'] == false).length;
  int get _admins => _usuarios.where((u) => u['rol'] == 'admin').length;

  // ── UI Helpers ─────────────────────────────────────
  Widget _resumenChip(String label, String val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  Widget _badgeRol(String? rol) {
    Color bg = const Color(0xFFE2E3E5);
    Color fg = const Color(0xFF383D41);
    switch (rol) {
      case 'admin':    bg = const Color(0xFFD4EDDA); fg = const Color(0xFF155724); break;
      case 'central':  bg = const Color(0xFFCCE5FF); fg = const Color(0xFF004085); break;
      case 'rifero':   bg = const Color(0xFFFFF3CD); fg = const Color(0xFF856404); break;
      case 'vendedor': bg = const Color(0xFFE8D5FF); fg = const Color(0xFF6A0DAD); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(rol ?? '-', style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)));
  }

  // ── Formulario ─────────────────────────────────────
  Future<void> _mostrarFormulario({Map<String, dynamic>? usuario}) async {
    final esNuevo = usuario == null;
    final esPropio = !esNuevo && usuario!['id'].toString() == _idPropio;
    
    final nombreCtrl = TextEditingController(text: usuario?['nombre'] ?? '');
    final emailCtrl = TextEditingController(text: usuario?['username'] ?? '');
    final passCtrl = TextEditingController();
    final passActualCtrl = TextEditingController();
    
    String rolSel = usuario?['rol'] ?? 'rifero';
    bool activoSel = usuario?['activo'] != false;
    Set<String> paginasSel = {};

    final List<String> todasPaginas = ['bancas','venta','premios','reportes','usuarios','mensajes','limites','configuracion','contabilidad','descargas'];
    final Map<String,String> labelPaginas = {'bancas':'Bancas', 'venta':'Venta', 'premios':'Premios', 'reportes':'Reportes', 'usuarios':'Usuarios', 'mensajes':'Mensajes', 'limites':'Límites', 'configuracion':'Configuración', 'contabilidad':'Contabilidad', 'descargas':'Descargas'};

    if (!esNuevo) {
      final id = usuario!['id']?.toString();
      if (id != null && (rolSel == 'central' || rolSel == 'rifero')) {
        try {
          final pags = await UsuariosService.obtenerPaginas(id);
          paginasSel = Set<String>.from(pags);
        } catch (_) {}
      }
    }

    String? bancaIdSel;
    final bancasUsuario = usuario?['bancas'] as List?;
    if (bancasUsuario != null && bancasUsuario.isNotEmpty) {
      final primera = bancasUsuario.firstWhere((b) => b != null && b['banca_id'] != null, orElse: () => null);
      if (primera != null) bancaIdSel = primera['banca_id']?.toString();
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(esNuevo ? "Nuevo Usuario" : "Editar Usuario"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre completo")),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Username")),
                if (!esNuevo && esPropio)
                  TextField(controller: passActualCtrl, decoration: const InputDecoration(labelText: "Contraseña actual"), obscureText: true),
                TextField(controller: passCtrl, decoration: InputDecoration(labelText: esNuevo ? "Contraseña" : "Nueva contraseña (opcional)"), obscureText: true),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: rolSel,
                  decoration: const InputDecoration(labelText: "Rol"),
                  items: ['admin', 'central', 'rifero', 'vendedor'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (v) => setModalState(() => rolSel = v!),
                ),
                if (rolSel == 'vendedor')
                  DropdownButtonFormField<String?>(
                    value: _bancas.any((b) => b.id == bancaIdSel) ? bancaIdSel : null,
                    decoration: const InputDecoration(labelText: "Banca"),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("Sin banca")),
                      ..._bancas.map((b) => DropdownMenuItem(value: b.id, child: Text(b.nombre)))
                    ],
                    onChanged: (v) => setModalState(() => bancaIdSel = v),
                  ),
                if (rolSel == 'central' || rolSel == 'rifero') ...[
                  const Divider(),
                  const Text("Permisos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Wrap(
                    spacing: 5,
                    children: todasPaginas.map((p) => FilterChip(
                      label: Text(labelPaginas[p] ?? p, style: const TextStyle(fontSize: 10)),
                      selected: paginasSel.contains(p),
                      onSelected: (v) => setModalState(() => v ? paginasSel.add(p) : paginasSel.remove(p)),
                    )).toList(),
                  )
                ],
                if (!esNuevo) SwitchListTile(title: const Text("Activo"), value: activoSel, onChanged: (v) => setModalState(() => activoSel = v)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (esNuevo) {
                    final res = await UsuariosService.crearUsuarioConRespuesta(username: emailCtrl.text, nombre: nombreCtrl.text, password: passCtrl.text, rol: rolSel);
                    final nuevoId = res['usuario']?['id']?.toString();
                    if (nuevoId != null) {
                      if (paginasSel.isNotEmpty) await UsuariosService.guardarPaginas(nuevoId, paginasSel.toList());
                      if (rolSel == 'vendedor' && bancaIdSel != null) await UsuariosService.asignarBanca(usuarioId: nuevoId, bancaId: bancaIdSel!);
                    }
                  } else {
                    final id = usuario!['id'].toString();
                    await UsuariosService.editarUsuario(id, nombre: nombreCtrl.text, username: emailCtrl.text, rol: rolSel, activo: activoSel, password: passCtrl.text.isEmpty ? null : passCtrl.text, passwordActual: passActualCtrl.text.isEmpty ? null : passActualCtrl.text);
                    if (rolSel == 'vendedor' && bancaIdSel != null) await UsuariosService.asignarBanca(usuarioId: id, bancaId: bancaIdSel!);
                    if (rolSel == 'central' || rolSel == 'rifero') await UsuariosService.guardarPaginas(id, paginasSel.toList());
                  }
                  if (mounted) Navigator.pop(ctx);
                  _recargarLista();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              },
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 6,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF1A237E),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Expanded(child: Text("Usuarios", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargarTodo),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.white), onPressed: () => _mostrarFormulario()),
            ]),
          ),
          if (!_loading && _error.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  _resumenChip("Total", "$_totalUsuarios", Colors.blueGrey),
                  _resumenChip("Activos", "$_activos", Colors.green),
                  _resumenChip("Admins", "$_admins", const Color(0xFF1A237E)),
                ],
              ),
            ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : _error.isNotEmpty 
                ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                : ListView.builder(
                    itemCount: _usuarios.length,
                    itemBuilder: (ctx, i) {
                      final u = _usuarios[i];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFF1A237E).withOpacity(0.1), child: Text(u['nombre']?[0].toUpperCase() ?? '?')),
                        title: Text(u['nombre'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${u['username']}"),
                        trailing: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _badgeRol(u['rol']),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _mostrarFormulario(usuario: u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../layout/app_layout.dart';
import '../services/bancas_service.dart';
import '../models/banca.dart';
import '../services/usuarios_service.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});
  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  List<dynamic> _usuarios = [];
  bool   _loading  = true;
  String _error    = "";
  String _idPropio  = ""; 
  List<Banca> _bancas = [];  

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarIdPropio();
    _cargarBancas();
  }

  Future<void> _cargarBancas() async {
    try {
      final b = await BancasService.obtenerBancas();
      if (mounted) setState(() => _bancas = b);
    } catch (_) {}
  }

  Future<void> _cargarIdPropio() async {
    final id = await UsuariosService.obtenerIdPropio();
    if (mounted) setState(() => _idPropio = id ?? '');
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = ""; });
    try {
      final data = await UsuariosService.obtenerUsuarios();
      if (mounted) setState(() { _usuarios = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Estadísticas ───────────────────────────────────
  int get _totalUsuarios  => _usuarios.length;
  int get _activos   => _usuarios.where((u) => u['activo'] == true).length;
  int get _inactivos => _usuarios.where((u) => u['activo'] == false).length;
  int get _admins    => _usuarios.where((u) => u['rol'] == 'admin').length;

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

  Widget _badgeEstado(bool? activo) {
    final isActivo = activo == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActivo ? const Color(0xFFD4EDDA) : const Color(0xFFF8D7DA),
        borderRadius: BorderRadius.circular(10)),
      child: Text(isActivo ? "Activo" : "Inactivo",
          style: TextStyle(color: isActivo ? const Color(0xFF155724) : const Color(0xFF721C24), fontWeight: FontWeight.bold, fontSize: 11)));
  }

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

  Widget _filaUsuario(Map<String, dynamic> u) {
    final String nombreStr = (u['nombre'] ?? u['username'] ?? '?').toString();
    final String inicial = nombreStr.isNotEmpty ? nombreStr[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(inicial, style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u['nombre'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(u['username'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ])),
          _badgeRol(u['rol']?.toString()),
          const SizedBox(width: 8),
          _badgeEstado(u['activo'] as bool?),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _mostrarFormulario(usuario: u),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit, size: 16, color: Color(0xFF1A237E)),
                SizedBox(width: 4),
                Text("Editar", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              ])),
          ),
        ])),
    );
  }

  Widget _encabezado() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      SizedBox(width: 48),
      Expanded(flex: 4, child: Text("Nombre / Email", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
      SizedBox(width: 72, child: Text("Rol", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey), textAlign: TextAlign.center)),
      SizedBox(width: 8),
      SizedBox(width: 72, child: Text("Estado", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey), textAlign: TextAlign.center)),
      SizedBox(width: 8),
      SizedBox(width: 72, child: Text("Acción", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey), textAlign: TextAlign.center)),
    ]),
  );

  Future<void> _mostrarFormulario({Map<String, dynamic>? usuario}) async {
    final esNuevo   = usuario == null;
    final esPropio  = !esNuevo && usuario!['id'].toString() == _idPropio;
    final nombreCtrl    = TextEditingController(text: usuario?['nombre'] ?? '');
    final emailCtrl     = TextEditingController(text: usuario?['username'] ?? '');
    final passCtrl      = TextEditingController();
    final passActualCtrl = TextEditingController();
    String rolSel     = usuario?['rol'] ?? 'rifero';
    bool   activoSel  = usuario?['activo'] != false;

    final List<String> todasPaginas = ['bancas','venta','premios','reportes','usuarios','mensajes','limites','configuracion','contabilidad','descargas'];
    final Map<String,String> labelPaginas = {'bancas':'Bancas', 'venta':'Venta', 'premios':'Premios', 'reportes':'Reportes', 'usuarios':'Usuarios', 'mensajes':'Mensajes', 'limites':'Límites', 'configuracion':'Configuración', 'contabilidad':'Contabilidad', 'descargas':'Descargas'};
    
    Set<String> paginasSel = {};

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
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre completo")),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Username")),
              const SizedBox(height: 8),
              if (!esNuevo && esPropio) ...[
                TextField(controller: passActualCtrl, decoration: InputDecoration(labelText: "Contraseña actual", filled: true, fillColor: Colors.amber.shade50), obscureText: true),
                const SizedBox(height: 8),
              ],
              TextField(controller: passCtrl, decoration: InputDecoration(labelText: esNuevo ? "Contraseña" : "Nueva contraseña (opcional)"), obscureText: true),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: rolSel,
                decoration: const InputDecoration(labelText: "Rol"),
                items: const [
                  DropdownMenuItem(value: 'admin',    child: Text("Admin")),
                  DropdownMenuItem(value: 'central',  child: Text("Central")),
                  DropdownMenuItem(value: 'rifero',   child: Text("Rifero")),
                  DropdownMenuItem(value: 'vendedor', child: Text("Vendedor")),
                ],
                onChanged: (v) => setModalState(() => rolSel = v!),
              ),
              if (rolSel == 'vendedor') ...[ 
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _bancas.any((b) => b.id == bancaIdSel) ? bancaIdSel : null,
                  decoration: const InputDecoration(labelText: "Banca asignada"),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text("-- Sin banca --")),
                    ..._bancas.map((b) => DropdownMenuItem<String?>(value: b.id, child: Text(b.nombre))),
                  ],
                  onChanged: (v) => setModalState(() => bancaIdSel = v),
                ),
              ],
              if (rolSel == 'central' || rolSel == 'rifero') ...[
                const Divider(),
                const Text('Páginas permitidas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 6,
                  children: todasPaginas.map((p) => FilterChip(
                    label: Text(labelPaginas[p] ?? p),
                    selected: paginasSel.contains(p),
                    onSelected: (v) => setModalState(() {
                      if (v) paginasSel.add(p); else paginasSel.remove(p);
                    }),
                  )).toList(),
                ),
              ],
              if (!esNuevo) SwitchListTile(title: const Text("Usuario activo"), value: activoSel, onChanged: (v) => setModalState(() => activoSel = v)),
            ],
          )),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreCtrl.text.trim();
                final username = emailCtrl.text.trim();
                final pass = passCtrl.text.trim();
                if (nombre.isEmpty || username.isEmpty) return;

                Navigator.pop(ctx);
                try {
                  if (esNuevo) {
                    final nuevo = await UsuariosService.crearUsuarioConRespuesta(username: username, nombre: nombre, password: pass, rol: rolSel);
                    final nuevoId = nuevo['usuario']?['id']?.toString();
                    if (nuevoId != null) {
                      if (paginasSel.isNotEmpty) await UsuariosService.guardarPaginas(nuevoId, paginasSel.toList());
                      if (rolSel == 'vendedor' && bancaIdSel != null) await UsuariosService.asignarBanca(usuarioId: nuevoId, bancaId: bancaIdSel!);
                    }
                  } else {
                    await UsuariosService.editarUsuario(usuario!['id'].toString(), nombre: nombre, username: username, rol: rolSel, activo: activoSel, password: pass.isNotEmpty ? pass : null, passwordActual: passActualCtrl.text.isNotEmpty ? passActualCtrl.text : null);
                    if (rolSel == 'vendedor' && bancaIdSel != null) await UsuariosService.asignarBanca(usuarioId: usuario['id'].toString(), bancaId: bancaIdSel!);
                    if (rolSel == 'central' || rolSel == 'rifero') await UsuariosService.guardarPaginas(usuario['id'].toString(), paginasSel.toList());
                  }
                  _cargar();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: Text(esNuevo ? "Crear" : "Guardar")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 6,
      child: Column(children: [
        Container(color: const Color(0xFF1A237E), padding: const EdgeInsets.all(16), child: Row(children: [const Expanded(child: Text("Usuarios", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar)])),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _usuarios.isEmpty ? _emptyView() : ListView.builder(itemCount: _usuarios.length, itemBuilder: (_, i) => _filaUsuario(_usuarios[i]))),
      ]),
    );
  }

  Widget _emptyView() => const Center(child: Text("No hay usuarios registrados"));
  Widget _errorView() => Center(child: Text(_error));
}

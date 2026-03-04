import 'package:flutter/material.dart';
import '../layout/app_layout.dart';
import '../services/usuarios_service.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});
  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  List<dynamic> _usuarios = [];
  bool   _loading = true;
  String _error   = "";

  @override
  void initState() { super.initState(); _cargar(); }

  void _onSelect(int i) {
    const rutas = [
      '/menu', '/bancas', '/premios', '/reportes',
      '/usuarios', '/limites', '/configuracion',
    ];
    if (rutas[i] != '/usuarios') Navigator.pushReplacementNamed(context, rutas[i]);
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ""; });
    try {
      final data = await UsuariosService.obtenerUsuarios();
      setState(() { _usuarios = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Estadísticas ───────────────────────────────────
  int get _totalUsuarios  => _usuarios.length;
  int get _activos   => _usuarios.where((u) => u['activo'] == true).length;
  int get _inactivos => _usuarios.where((u) => u['activo'] == false).length;
  int get _admins    => _usuarios.where((u) => u['rol'] == 'admin').length;

  // ── Badge rol ──────────────────────────────────────
  Widget _badgeRol(String? rol) {
    late Color bg, fg;
    switch (rol) {
      case 'admin':   bg = const Color(0xFFD4EDDA); fg = const Color(0xFF155724); break;
      case 'central': bg = const Color(0xFFCCE5FF); fg = const Color(0xFF004085); break;
      case 'rifero':  bg = const Color(0xFFFFF3CD); fg = const Color(0xFF856404); break;
      default:        bg = const Color(0xFFE2E3E5); fg = const Color(0xFF383D41);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(rol ?? '-',
          style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)));
  }

  // ── Badge estado ───────────────────────────────────
  Widget _badgeEstado(bool? activo) {
    final isActivo = activo == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActivo ? const Color(0xFFD4EDDA) : const Color(0xFFF8D7DA),
        borderRadius: BorderRadius.circular(10)),
      child: Text(isActivo ? "Activo" : "Inactivo",
          style: TextStyle(
            color: isActivo ? const Color(0xFF155724) : const Color(0xFF721C24),
            fontWeight: FontWeight.bold, fontSize: 11)));
  }

  // ── Chip resumen ───────────────────────────────────
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

  // ── Fila de usuario ────────────────────────────────
  Widget _filaUsuario(Map<String, dynamic> u) {
    // Protección contra strings vacíos para el avatar
    final String nombreStr = (u['nombre'] ?? u['email'] ?? '?').toString();
    final String inicial = nombreStr.isNotEmpty ? nombreStr[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 10),

          Expanded(flex: 4, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u['nombre'] ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(u['email'] ?? '-',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ])),

          _badgeRol(u['rol']?.toString()),
          const SizedBox(width: 8),

          _badgeEstado(u['activo'] as bool?),
          const SizedBox(width: 8),

          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _mostrarFormulario(usuario: u),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit, size: 16, color: const Color(0xFF1A237E)),
                const SizedBox(width: 4),
                const Text("Editar",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _encabezado() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      const SizedBox(width: 48),
      const Expanded(flex: 4, child: Text("Nombre / Email",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
      SizedBox(width: 72, child: Text("Rol",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          textAlign: TextAlign.center)),
      const SizedBox(width: 8),
      SizedBox(width: 72, child: Text("Estado",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          textAlign: TextAlign.center)),
      const SizedBox(width: 8),
      SizedBox(width: 72, child: Text("Acción",
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          textAlign: TextAlign.center)),
    ]),
  );

  Future<void> _mostrarFormulario({Map<String, dynamic>? usuario}) async {
    final esNuevo = usuario == null;
    final nombreCtrl  = TextEditingController(text: usuario?['nombre'] ?? '');
    final emailCtrl   = TextEditingController(text: usuario?['email']  ?? '');
    final passCtrl    = TextEditingController();
    String rolSel     = usuario?['rol'] ?? 'rifero';
    bool   activoSel  = usuario?['activo'] != false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(esNuevo ? "Nuevo Usuario" : "Editar Usuario"),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nombreCtrl,
                decoration: const InputDecoration(labelText: "Nombre completo")),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              if (esNuevo) ...[
                TextField(controller: passCtrl,
                  decoration: const InputDecoration(labelText: "Contraseña"),
                  obscureText: true),
                const SizedBox(height: 8),
              ],
              DropdownButtonFormField<String>(
                value: rolSel,
                decoration: const InputDecoration(labelText: "Rol"),
                items: const [
                  DropdownMenuItem(value: 'admin',   child: Text("Admin")),
                  DropdownMenuItem(value: 'central', child: Text("Central")),
                  DropdownMenuItem(value: 'rifero',  child: Text("Rifero")),
                ],
                onChanged: (v) => setModalState(() => rolSel = v!),
              ),
              if (!esNuevo) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text("Usuario activo"),
                  value: activoSel,
                  activeColor: const Color(0xFF1A237E),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setModalState(() => activoSel = v),
                ),
              ],
            ],
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white),
              onPressed: () async {
                final nombre = nombreCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final pass = passCtrl.text.trim();

                if (nombre.isEmpty || email.isEmpty || (esNuevo && pass.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Por favor completa todos los campos"),
                    backgroundColor: Colors.orange));
                  return;
                }

                Navigator.pop(ctx);
                try {
                  if (esNuevo) {
                    await UsuariosService.crearUsuario(
                      nombre:   nombre,
                      email:    email,
                      password: pass,
                      rol:      rolSel,
                    );
                  } else {
                    await UsuariosService.editarUsuario(
                      usuario!['id'].toString(),
                      nombre: nombre,
                      email:  email,
                      rol:    rolSel,
                      activo: activoSel,
                    );
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(esNuevo ? "Usuario creado ✓" : "Usuario actualizado ✓"),
                      backgroundColor: Colors.green));
                  }
                  await _cargar();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
      selectedIndex: 4,
      onItemSelected: _onSelect,
      child: Column(children: [
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            const Expanded(child: Text("Usuarios",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
          ]),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(children: [
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _mostrarFormulario(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Nuevo Usuario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0)),
          ]),
        ),

        if (!_loading && _usuarios.isNotEmpty)
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _resumenChip("Total", "$_totalUsuarios", Colors.blueGrey),
              const SizedBox(width: 6),
              _resumenChip("Activos", "$_activos", const Color(0xFF28A745)),
              const SizedBox(width: 6),
              _resumenChip("Inactivos","$_inactivos", const Color(0xFFDC3545)),
              const SizedBox(width: 6),
              _resumenChip("Admins", "$_admins", const Color(0xFF1A237E)),
            ]),
          ),

        if (!_loading && _usuarios.isNotEmpty) _encabezado(),

        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
            ? _errorView()
            : _usuarios.isEmpty
              ? _emptyView()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    itemCount: _usuarios.length,
                    itemBuilder: (_, i) => _filaUsuario(_usuarios[i] as Map<String, dynamic>),
                  ))),
      ]),
    );
  }

  Widget _errorView() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 10),
      Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
      const SizedBox(height: 14),
      ElevatedButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text("Reintentar")),
    ]));

  Widget _emptyView() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
      const SizedBox(height: 14),
      Text("No hay usuarios registrados", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text("Nuevo Usuario"),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007BFF), foregroundColor: Colors.white)),
    ]));
}

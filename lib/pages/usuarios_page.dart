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
      // Problema 2: Cargamos datos y luego disparamos un solo setState
      final resultados = await Future.wait([
        UsuariosService.obtenerUsuarios(),
        UsuariosService.obtenerIdPropio(),
        BancasService.obtenerBancas(),
      ]);

      if (mounted) {
        setState(() {
          _usuarios = resultados[0] as List<dynamic>;
          _idPropio = (resultados[1] as String?) ?? '';
          _bancas = resultados[2] as List<Banca>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Estadísticas ───────────────────────────────────
  int get _totalUsuarios => _usuarios.length;
  int get _activos => _usuarios.where((u) => u['activo'] == true).length;
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

    // Problema 3 y 4: Manejo seguro de bancas y nulos
    String? bancaIdSel;
    final rawBancas = usuario?['bancas'];
    if (rawBancas is List && rawBancas.isNotEmpty) {
      for (var b in rawBancas) {
        if (b != null && b['banca_id'] != null) {
          bancaIdSel = b['banca_id'].toString();
          break;
        }
      }
    }

    if (!esNuevo) {
      final id = usuario!['id']?.toString();
      if (id != null && (rolSel == 'central' || rolSel == 'rifero')) {
        try {
          final pags = await UsuariosService.obtenerPaginas(id);
          paginasSel = Set<String>.from(pags);
        } catch (_) {}
      }
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
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
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
                      if (rolSel == 'vendedor' && bancaIdSel != null) await UsuariosService.asignarBanca(usuarioId: nuevoId, bancaId: bancaIdSel!);
                    }
                  } else {
                    final id = usuario!['id'].toString();
                    await UsuariosService.editarUsuario(id, nombre: nombreCtrl.text, username: emailCtrl.text, rol: rolSel, activo: activoSel, password: passCtrl.text.isEmpty ? null : passCtrl.text, passwordActual: passActualCtrl.text.isEmpty ? null : passActualCtrl.text);
                    if (rolSel == 'vendedor' && bancaIdSel != null) await UsuariosService.asignarBanca(usuarioId: id, bancaId: bancaIdSel!);
                  }
                  if (mounted) Navigator.pop(ctx);
                  _cargarTodo();
                } catch (e) {
                  // Problema 5: Snackbar seguro
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );

    // Problema 6: Liberación de controladores
    nombreCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    passActualCtrl.dispose();
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
              const Expanded(child: Text("Gestión de Usuarios", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargarTodo),
              IconButton(icon: const Icon(Icons.add_circle, color: Colors.white), onPressed: () => _mostrarFormulario()),
            ]),
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  _resumenChip("Total", "$_totalUsuarios", Colors.blue),
                  _resumenChip("Activos", "$_activos", Colors.green),
                ],
              ),
            ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  itemCount: _usuarios.length,
                  itemBuilder: (ctx, i) {
                    final u = _usuarios[i];
                    // Problema 1: Manejo seguro de iniciales
                    final nombreRaw = (u['nombre'] ?? '').toString();
                    final inicial = nombreRaw.isNotEmpty ? nombreRaw[0].toUpperCase() : '?';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                        child: Text(inicial),
                      ),
                      title: Text(nombreRaw.isEmpty ? (u['username'] ?? 'Sin nombre') : nombreRaw),
                      subtitle: Text("${u['rol']}"),
                      trailing: const Icon(Icons.edit),
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

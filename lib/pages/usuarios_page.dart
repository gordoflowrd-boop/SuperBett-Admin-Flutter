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

  void _onSelect(int i) {
    const rutas = [
      '/menu', '/bancas', '/venta', '/premios', 
      '/reportes', '/usuarios', '/limites', '/configuracion',
    ];
    if (rutas[i] != '/usuarios') {
      Navigator.pushReplacementNamed(context, rutas[i]);
    }
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

  int get _totalUsuarios  => _usuarios.length;
  int get _activos   => _usuarios.where((u) => u['activo'] == true).length;
  int get _inactivos => _usuarios.where((u) => u['activo'] == false).length;
  int get _admins    => _usuarios.where((u) => u['rol'] == 'admin').length;

  Widget _badgeRol(String? rol) {
    late Color bg, fg;
    switch (rol) {
      case 'admin':    bg = const Color(0xFFD4EDDA); fg = const Color(0xFF155724); break;
      case 'central':  bg = const Color(0xFFCCE5FF); fg = const Color(0xFF004085); break;
      case 'rifero':   bg = const Color(0xFFFFF3CD); fg = const Color(0xFF856404); break;
      case 'vendedor': bg = const Color(0xFFE8D5FF); fg = const Color(0xFF6A0DAD); break;
      default:         bg = const Color(0xFFE2E3E5); fg = const Color(0xFF383D41);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(rol ?? '-',
          style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)));
  }

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
              child: Text(inicial,
                style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 4, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nombreStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(u['username'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ])),
          _badgeRol(u['rol']?.toString()),
          const SizedBox(width: 8),
          _badgeEstado(u['activo'] as bool?),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _mostrarFormulario(usuario: u),
            icon: const Icon(Icons.edit, size: 20, color: Color(0xFF1A237E)),
            tooltip: "Editar",
          ),
        ]),
      ),
    );
  }

  // --- El resto del código de _mostrarFormulario se mantiene igual ---
  // (Omitido por brevedad, pero asegúrate de usarlo tal cual lo tenías)
  
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 5,
      onItemSelected: _onSelect,
      child: Column(children: [
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            const Expanded(child: Text("Usuarios", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
          ]),
        ),
        // ... Contenedores de resumen y lista ...
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _usuarios.isEmpty 
            ? _emptyView() 
            : ListView.builder(
                itemCount: _usuarios.length,
                itemBuilder: (_, i) => _filaUsuario(_usuarios[i]),
              )
        ),
      ]),
    );
  }

  Widget _emptyView() => const Center(child: Text("No hay usuarios registrados"));
}

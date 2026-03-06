import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/banca.dart';
import '../services/bancas_service.dart';
import '../layout/app_layout.dart';

class BancasPage extends StatefulWidget {
  const BancasPage({super.key});
  @override
  State<BancasPage> createState() => _BancasPageState();
}

class _BancasPageState extends State<BancasPage> {
  List<Banca> _bancas = [];
  bool   _loading = true;
  String _error   = "";

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = ""; });
    try {
      final b = await BancasService.obtenerBancas();
      if (mounted) setState(() { _bancas = b; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSelect(int i) {
    const rutas = ['/menu', '/bancas', '/venta', '/premios', '/reportes', '/usuarios', '/limites', '/configuracion'];
    if (i < rutas.length && rutas[i] != '/bancas') Navigator.pushReplacementNamed(context, rutas[i]);
  }

  Widget _fila(Banca b) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(b.nombre.isNotEmpty ? b.nombre[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A237E))))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (b.codigo != null && b.codigo!.isNotEmpty)
            Text("Código: ${b.codigo}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: b.activa ? const Color(0xFFD1ECF1) : const Color(0xFFF8D7DA), borderRadius: BorderRadius.circular(12)),
          child: Text(b.activa ? "Activa" : "Inactiva", style: TextStyle(color: b.activa ? const Color(0xFF0D6EFD) : const Color(0xFFDC3545), fontWeight: FontWeight.w700, fontSize: 12))),
        IconButton(
          onPressed: () async {
            await showDialog(context: context, builder: (_) => _BancaModal(banca: b));
            _cargar();
          },
          icon: const Icon(Icons.edit, color: Color(0xFF1A237E)),
        ),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 1,
    onItemSelected: _onSelect,
    child: Column(children: [
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            const Expanded(child: Text("Control de Bancas", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.add_circle, color: Colors.white), 
              onPressed: () async {
                // Para crear una nueva banca, pasamos un objeto Banca vacío
                await showDialog(context: context, builder: (_) => _BancaModal(banca: null));
                _cargar();
              }
            ),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
          ]),
        ),
        Expanded(child: _loading 
          ? const Center(child: CircularProgressIndicator())
          : _bancas.isEmpty ? const Center(child: Text("No hay bancas")) : ListView.builder(itemCount: _bancas.length, itemBuilder: (_, i) => _fila(_bancas[i]))
        )
    ]),
  );
}

// El modal ahora detecta si es creación o edición
class _BancaModal extends StatefulWidget {
  final Banca? banca; // Si es null, es creación
  const _BancaModal({this.banca});
  @override State<_BancaModal> createState() => _BancaModalState();
}

class _BancaModalState extends State<_BancaModal> {
  final _nombreCtrl = TextEditingController();
  bool _activa = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.banca != null) {
      _nombreCtrl.text = widget.banca!.nombre;
      _activa = widget.banca!.activa;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.banca == null ? "Nueva Banca" : "Editar Banca"),
      content: TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: "Nombre de la banca")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: _guardando ? null : () async {
            setState(() => _guardando = true);
            try {
              if (widget.banca == null) {
                // Aquí llamarías a BancasService.crearBanca si existiera
              } else {
                await BancasService.guardarBanca(widget.banca!.id, {
                  'nombre': _nombreCtrl.text.trim(),
                  'activa': _activa,
                });
              }
              if (mounted) Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
            } finally {
              setState(() => _guardando = false);
            }
          }, 
          child: const Text("Guardar")
        )
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../layout/app_layout.dart';
import '../services/venta_service.dart';

class VentaPage extends StatefulWidget {
  const VentaPage({super.key});
  @override
  State<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  DateTime _fecha        = DateTime.now();
  String?  _loteriaId;          
  bool     _loading      = true;
  bool     _loadingLot   = true;
  String   _error        = "";

  List<dynamic> _loterias = [];
  List<dynamic> _filas    = [];

  final _fmt     = NumberFormat('#,##0.00');
  final _modOrden = const ['Q', 'P', 'T', 'SP'];

  @override
  void initState() { super.initState(); _cargarLoterias(); }

  String get _fechaStr {
    final f = _fecha;
    return "${f.year}-${f.month.toString().padLeft(2,'0')}-${f.day.toString().padLeft(2,'0')}";
  }

  double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  void _onSelect(int i) {
    const rutas = [
      '/menu', '/bancas', '/premios', '/reportes',
      '/usuarios', '/limites', '/configuracion',
    ];
    // Ajustado para que coincida con el index 1 de Venta
    if (i < rutas.length && rutas[i] != '/venta') Navigator.pushReplacementNamed(context, rutas[i]);
  }

  Future<void> _cargarLoterias() async {
    setState(() => _loadingLot = true);
    try {
      final data = await VentaService.obtenerLoterias();
      setState(() { _loterias = data; _loadingLot = false; });
    } catch (_) {
      setState(() => _loadingLot = false);
    }
    await _cargarVenta();
  }

  Future<void> _cargarVenta() async {
    setState(() { _loading = true; _error = ""; });
    try {
      var data = await VentaService.obtenerVentaDia(
        fecha:     _fechaStr,
        loteriaId: _loteriaId,
      );
      if (_loteriaId == 'SP_ONLY') {
        data = data.where((r) => r['modalidad'] == 'SP').toList();
      }
      setState(() { _filas = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Map<String, List<dynamic>> get _grupos {
    final g = <String, List<dynamic>>{};
    for (final m in _modOrden) { g[m] = []; }
    
    for (final r in _filas) {
      final m = r['modalidad']?.toString() ?? '';
      if (g.containsKey(m)) {
        g[m]!.add(r);
      } else {
        g.putIfAbsent(m, () => []).add(r);
      }
    }
    return g;
  }

  double get _totalGeneral =>
      _filas.fold(0.0, (s, r) => s + _toDouble(r['monto_total']));

  Future<void> _pickFecha() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (p != null) { setState(() => _fecha = p); await _cargarVenta(); }
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

  Color _colorMod(String m) {
    switch (m) {
      case 'Q':  return const Color(0xFF1A237E);
      case 'P':  return const Color(0xFF007BFF);
      case 'T':  return const Color(0xFF28A745);
      case 'SP': return const Color(0xFFFF9800);
      default:   return Colors.blueGrey;
    }
  }

  String _nombreMod(String m) {
    switch (m) {
      case 'Q':  return 'Quiniela';
      case 'P':  return 'Palé';
      case 'T':  return 'Tripleta';
      case 'SP': return 'Super Palé';
      default:   return m;
    }
  }

  Widget _seccionModalidad(String mod, List<dynamic> filas) {
    final color = _colorMod(mod);
    final total = filas.fold(0.0, (s, r) => s + _toDouble(r['monto_total']));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        child: Row(children: [
          Text(_nombreMod(mod), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          Text("Total: ${_fmt.format(total)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        color: color.withOpacity(0.08),
        child: Row(children: [
          Expanded(flex: 3, child: Text("Lotería(s)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
          Expanded(flex: 2, child: Text("Jugada", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
          Expanded(flex: 1, child: Text("Cant.", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
          Expanded(flex: 1, child: Text("Tick.", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
          Expanded(flex: 2, child: Text("Bancas", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
          Expanded(flex: 2, child: Text("Monto", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
        ]),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
        child: Column(children: filas.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value as Map<String, dynamic>;
            final monto = _toDouble(r['monto_total']);
            final loteriasRaw = r['loteria']?.toString() ?? '-';
            final loterias = mod == 'SP' ? loteriasRaw.split(' + ') : [loteriasRaw];

            return Container(
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : Colors.grey.shade50,
                border: i == filas.length - 1 ? null : Border(bottom: BorderSide(color: Colors.grey.shade100))),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(children: [
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: loterias.map((l) => Text(l.trim(), style: const TextStyle(fontSize: 12))).toList())),
                Expanded(flex: 2, child: Text(r['jugada']?.toString() ?? '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text(r['cantidad_total']?.toString() ?? '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                Expanded(flex: 1, child: Text(r['tickets']?.toString() ?? '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                Expanded(flex: 2, child: Text(r['bancas']?.toString() ?? '-', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                Expanded(flex: 2, child: Text(_fmt.format(monto), textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 1, 
      onItemSelected: _onSelect,
      child: Column(children: [
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            const Expanded(child: Text("Venta del Día", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargarVenta),
          ]),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(children: [
            GestureDetector(
              onTap: _pickFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today, color: Colors.grey.shade700, size: 15),
                  const SizedBox(width: 8),
                  Text(_fechaStr, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () { setState(() => _fecha = DateTime.now()); _cargarVenta(); },
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700, backgroundColor: Colors.grey.shade200, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Hoy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            const SizedBox(width: 10),
            if (!_loadingLot)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _loteriaId,
                      isExpanded: true,
                      onChanged: (v) { setState(() => _loteriaId = v); _cargarVenta(); },
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Todas")),
                        const DropdownMenuItem(value: 'SP_ONLY', child: Text("Super Palé")),
                        ..._loterias.map((l) => DropdownMenuItem(value: l['id']?.toString(), child: Text(l['nombre']?.toString() ?? '-'))),
                      ],
                    ),
                  ),
                ),
              ),
          ]),
        ),

        if (!_loading && _filas.isNotEmpty)
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                ..._modOrden.where((m) => (_grupos[m] ?? []).isNotEmpty).map((m) {
                  final subtotal = (_grupos[m] ?? []).fold(0.0, (s, r) => s + _toDouble(r['monto_total']));
                  return Padding(padding: const EdgeInsets.only(right: 6), child: _resumenChip(_nombreMod(m), _fmt.format(subtotal), _colorMod(m)));
                }),
                _resumenChip("TOTAL", _fmt.format(_totalGeneral), Colors.blueGrey),
              ]),
            ),
          ),

        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
            ? _errorView()
            : _filas.isEmpty
              ? _emptyView()
              : RefreshIndicator(
                  onRefresh: _cargarVenta,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      ..._modOrden.map((m) {
                        final filas = _grupos[m] ?? [];
                        return filas.isEmpty ? const SizedBox.shrink() : _seccionModalidad(m, filas);
                      }),
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2))),
                        child: Row(children: [
                          const Expanded(child: Text("TOTAL GENERAL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1A237E)))),
                          Text(_fmt.format(_totalGeneral), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A237E))),
                        ]),
                      ),
                    ],
                  ),
                )),
      ]),
    );
  }

  Widget _errorView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, color: Colors.red, size: 48),
    const SizedBox(height: 10),
    Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
    const SizedBox(height: 14),
    ElevatedButton.icon(onPressed: _cargarVenta, icon: const Icon(Icons.refresh), label: const Text("Reintentar")),
  ]));

  Widget _emptyView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
    const SizedBox(height: 14),
    Text("No hay ventas para $_fechaStr", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
  ]));
}

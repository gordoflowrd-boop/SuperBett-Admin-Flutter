import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../layout/app_layout.dart';
import '../services/reportes_service.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});
  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  List<dynamic> _resumen   = [];
  List<dynamic> _ganadores = [];
  bool   _loading  = false;
  String _error    = "";
  String _tipoVista = "ventas"; // "ventas" | "ganadores"
  DateTime _fecha  = DateTime.now();

  @override
  void initState() { 
    super.initState(); 
    _cargar(); 
  }

  String get _fechaStr => DateFormat('yyyy-MM-dd').format(_fecha);
  final _fmt = NumberFormat('#,##0.00');

  double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  // --- Totales ---
  double get _totalVenta     => _resumen.fold(0.0, (s, r) => s + _toDouble(r['total_venta']));
  double get _totalComision  => _resumen.fold(0.0, (s, r) => s + _toDouble(r['total_comision']));
  double get _totalPremios   => _resumen.fold(0.0, (s, r) => s + _toDouble(r['total_premios']));
  double get _totalResultado => _resumen.fold(0.0, (s, r) => s + _toDouble(r['resultado']));

  // --- Lógica de Carga ---
  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ""; });
    try {
      if (_tipoVista == "ventas") {
        final data = await ReportesService.obtenerResumen(_fechaStr);
        List<dynamic> lista = [];
        if (data is List) {
          lista = data;
        } else if (data is Map && data.isNotEmpty) {
          lista = [data];
        }
        setState(() { _resumen = lista; _loading = false; });
      } else {
        final raw = await ReportesService.obtenerGanadores(_fechaStr);
        final lista = raw is List ? raw : <dynamic>[];
        setState(() { 
          _ganadores = lista.where((g) => _toDouble(g['total_ganado']) > 0).toList(); 
          _loading = false; 
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickFecha() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (p != null) { 
      setState(() => _fecha = p); 
      _cargar(); 
    }
  }

  // --- Widgets de UI ---

  Widget _tabToggle(String label, String value) {
    final sel = _tipoVista == value;
    return GestureDetector(
      onTap: () {
        if (_tipoVista != value) {
          setState(() { _tipoVista = value; _resumen = []; _ganadores = []; });
          _cargar();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF1A237E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _resumenChip(String label, String val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600)),
    ]));

  Widget _filaVenta(Map<String, dynamic> r) {
    final res = _toDouble(r['resultado']);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(flex: 3, child: Text(r['banca'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(_fmt.format(_toDouble(r['total_venta'])), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(_fmt.format(res), textAlign: TextAlign.right, 
            style: TextStyle(color: res >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 4,
      child: Column(children: [
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            const Expanded(child: Text("Reportes", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _tabToggle("Ventas", "ventas"),
              const SizedBox(width: 8),
              _tabToggle("Ganadores", "ganadores"),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: _pickFecha,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_today, color: Colors.grey.shade700, size: 14),
                    const SizedBox(width: 6),
                    Text(_fechaStr, style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () {
                  setState(() => _fecha = DateTime.now());
                  _cargar();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text("Hoy",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            ]),
          ]),
        ),
        if (!_loading && _tipoVista == "ventas" && _resumen.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.grey.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _resumenChip("VENTA", _fmt.format(_totalVenta), Colors.black87),
                const SizedBox(width: 6),
                _resumenChip("NETO", _fmt.format(_totalResultado), _totalResultado >= 0 ? Colors.green : Colors.red),
              ]),
            ),
          ),
        Expanded(
          child: _loading 
            ? const Center(child: CircularProgressIndicator()) 
            : _error.isNotEmpty 
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: _tipoVista == "ventas" ? _resumen.length : _ganadores.length,
                  itemBuilder: (_, i) => _tipoVista == "ventas" 
                    ? _filaVenta(_resumen[i]) 
                    : ListTile(
                        title: Text("Ticket: ${_ganadores[i]['numero_ticket']}"),
                        subtitle: Text("${_ganadores[i]['banca']} - ${_ganadores[i]['loteria']}"),
                        trailing: Text(_fmt.format(_toDouble(_ganadores[i]['total_ganado'])), 
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                ),
        ),
      ]),
    );
  }
}

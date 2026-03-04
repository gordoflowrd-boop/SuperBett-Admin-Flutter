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
  void initState() { super.initState(); _cargar(); }

  String get _fechaStr {
    final f = _fecha;
    return "${f.year}-${f.month.toString().padLeft(2,'0')}-${f.day.toString().padLeft(2,'0')}";
  }

  final _fmt = NumberFormat('#,##0.00');

  double _toDouble(dynamic v) =>
      v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

  double get _totalVenta     => _resumen.fold(0.0, (s, r) => s + _toDouble(r['total_venta']));
  double get _totalComision  => _resumen.fold(0.0, (s, r) => s + _toDouble(r['total_comision']));
  double get _totalPremios   => _resumen.fold(0.0, (s, r) => s + _toDouble(r['total_premios']));
  double get _totalResultado => _resumen.fold(0.0, (s, r) => s + _toDouble(r['resultado']));

  void _onSelect(int i) {
    const rutas = [
      '/menu', '/bancas', '/premios', '/reportes',
      '/usuarios', '/limites', '/configuracion',
    ];
    if (rutas[i] != '/reportes') Navigator.pushReplacementNamed(context, rutas[i]);
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ""; });
    try {
      if (_tipoVista == "ventas") {
        final data = await ReportesService.obtenerResumen(_fechaStr);
        setState(() { _resumen = data; _loading = false; });
      } else {
        final data = await ReportesService.obtenerGanadores(_fechaStr);
        setState(() { _ganadores = data; _loading = false; });
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
    if (p != null) { setState(() => _fecha = p); await _cargar(); }
  }

  // ── Badges de estado ──────────────────────────────
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

  // ── Tab toggle Ventas / Ganadores ─────────────────
  Widget _tabToggle(String label, String value) {
    final sel = _tipoVista == value;
    return GestureDetector(
      onTap: () {
        if (_tipoVista != value) {
          setState(() {
            _tipoVista = value;
            _resumen   = [];
            _ganadores = [];
            _error     = "";
          });
          _cargar();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF1A237E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? const Color(0xFF1A237E) : Colors.grey.shade300)),
        child: Text(label,
          style: TextStyle(
            color: sel ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  // ── Encabezado columnas ventas ────────────────────
  Widget _encabezadoVentas() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      const Expanded(flex: 3, child: Text("Banca",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
      _thCol("Venta"),
      _thCol("Comisión"),
      _thCol("Premios"),
      _thCol("Resultado"),
    ]),
  );

  Widget _thCol(String t) => Expanded(
    flex: 2,
    child: Text(t,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)));

  // ── Encabezado columnas ganadores ─────────────────
  Widget _encabezadoGanadores() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      const Expanded(flex: 2, child: Text("Ticket",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
      const Expanded(flex: 3, child: Text("Banca",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
      const Expanded(flex: 3, child: Text("Lotería",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
      SizedBox(width: 80, child: Text("Premio",
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
    ]),
  );

  // ── Fila de venta por banca ───────────────────────
  Widget _filaVenta(Map<String, dynamic> r) {
    final resultado = _toDouble(r['resultado']);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Expanded(flex: 3,
            child: Text(r['banca'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          _celdaNum(_fmt.format(_toDouble(r['total_venta'])),   Colors.black87),
          _celdaNum(_fmt.format(_toDouble(r['total_comision'])), Colors.grey),
          _celdaNum(_fmt.format(_toDouble(r['total_premios'])),  const Color(0xFFDC3545)),
          _celdaNum(_fmt.format(resultado),
              resultado >= 0 ? const Color(0xFF28A745) : const Color(0xFFDC3545),
              bold: true),
        ]),
      ),
    );
  }

  // ── Fila TOTAL ────────────────────────────────────
  Widget _filaTotal() => Card(
    margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
    color: const Color(0xFF1A237E).withOpacity(0.06),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: const Color(0xFF1A237E).withOpacity(0.2))),
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        const Expanded(flex: 3,
          child: Text("TOTAL",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14,
                color: Color(0xFF1A237E)))),
        _celdaNum(_fmt.format(_totalVenta),     const Color(0xFF1A237E), bold: true),
        _celdaNum(_fmt.format(_totalComision),  Colors.grey,             bold: true),
        _celdaNum(_fmt.format(_totalPremios),   const Color(0xFFDC3545), bold: true),
        _celdaNum(_fmt.format(_totalResultado),
            _totalResultado >= 0 ? const Color(0xFF28A745) : const Color(0xFFDC3545),
            bold: true),
      ]),
    ),
  );

  Widget _celdaNum(String val, Color color, {bool bold = false}) =>
    Expanded(flex: 2,
      child: Text(val,
        textAlign: TextAlign.right,
        style: TextStyle(color: color, fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal)));

  // ── Fila ganador ──────────────────────────────────
  Widget _filaGanador(Map<String, dynamic> g) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Colors.grey.shade200)),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(6)),
            child: Text(g['numero_ticket']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                  color: Color(0xFF1A237E))),
          ),
        ),
        Expanded(flex: 3,
          child: Text(g['banca'] ?? '-',
            style: const TextStyle(fontSize: 13))),
        Expanded(flex: 3,
          child: Text(g['loteria'] ?? '-',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
        SizedBox(width: 80,
          child: Text(_fmt.format(_toDouble(g['total_ganado'])),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Color(0xFF28A745),
                fontWeight: FontWeight.bold, fontSize: 14))),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 3,
      onItemSelected: _onSelect,
      child: Column(children: [

        // ── Navbar azul ──────────────────────────────
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            const Expanded(child: Text("Reportes Generales",
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold))),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _cargar),
          ]),
        ),

        // ── Barra de filtros ─────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(children: [

            // Tabs Ventas / Ganadores
            _tabToggle("Ventas",    "ventas"),
            const SizedBox(width: 6),
            _tabToggle("Ganadores", "ganadores"),
            const SizedBox(width: 10),

            // Selector fecha
            GestureDetector(
              onTap: _pickFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today, color: Colors.grey.shade700, size: 15),
                  const SizedBox(width: 8),
                  Text(_fechaStr,
                    style: TextStyle(color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(width: 6),

            // Botón Hoy
            TextButton(
              onPressed: () { setState(() => _fecha = DateTime.now()); _cargar(); },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                backgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Hoy",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),

            const Spacer(),

            // Botón Cargar
            ElevatedButton.icon(
              onPressed: _loading ? null : _cargar,
              icon: const Icon(Icons.search, size: 16),
              label: const Text("Cargar",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0)),
          ]),
        ),

        // ── Chips resumen (solo ventas) ──────────────
        if (!_loading && _tipoVista == "ventas" && _resumen.isNotEmpty)
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _resumenChip("Bancas",    "${_resumen.length}",           Colors.blueGrey),
              const SizedBox(width: 6),
              _resumenChip("Venta",     _fmt.format(_totalVenta),       const Color(0xFF1A237E)),
              const SizedBox(width: 6),
              _resumenChip("Premios",   _fmt.format(_totalPremios),     const Color(0xFFDC3545)),
              const SizedBox(width: 6),
              _resumenChip("Resultado", _fmt.format(_totalResultado),
                  _totalResultado >= 0 ? const Color(0xFF28A745) : const Color(0xFFDC3545)),
            ]),
          ),

        // ── Encabezados de tabla ─────────────────────
        if (!_loading && _tipoVista == "ventas"    && _resumen.isNotEmpty)   _encabezadoVentas(),
        if (!_loading && _tipoVista == "ganadores" && _ganadores.isNotEmpty) _encabezadoGanadores(),

        // ── Contenido ────────────────────────────────
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
            ? _errorView()
            : _tipoVista == "ventas"
              ? _resumen.isEmpty
                ? _emptyView()
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.builder(
                      itemCount: _resumen.length + 1, // +1 fila TOTAL
                      itemBuilder: (_, i) => i < _resumen.length
                          ? _filaVenta(_resumen[i] as Map<String, dynamic>)
                          : _filaTotal(),
                    ))
              : _ganadores.isEmpty
                ? _emptyView()
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.builder(
                      itemCount: _ganadores
                          .where((g) => _toDouble(g['total_ganado']) > 0)
                          .length,
                      itemBuilder: (_, i) {
                        final validos = _ganadores
                            .where((g) => _toDouble(g['total_ganado']) > 0)
                            .toList();
                        return _filaGanador(validos[i] as Map<String, dynamic>);
                      },
                    ))),
      ]),
    );
  }

  Widget _errorView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, color: Colors.red, size: 48),
    const SizedBox(height: 10),
    Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
    const SizedBox(height: 14),
    ElevatedButton.icon(onPressed: _cargar,
      icon: const Icon(Icons.refresh), label: const Text("Reintentar")),
  ]));

  Widget _emptyView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.bar_chart_outlined, size: 56, color: Colors.grey.shade300),
    const SizedBox(height: 14),
    Text("No hay datos para $_fechaStr",
        style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
    const SizedBox(height: 6),
    Text("Selecciona otra fecha o presiona Cargar.",
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
  ]));
}

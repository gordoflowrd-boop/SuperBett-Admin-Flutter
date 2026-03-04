import 'package:flutter/material.dart';
import '../models/jornada.dart';
import '../services/premios_service.dart';
import '../widgets/jornada_modal.dart';
import '../layout/app_layout.dart';

class PremiosPage extends StatefulWidget {
  const PremiosPage({super.key});
  @override
  State<PremiosPage> createState() => _PremiosPageState();
}

class _PremiosPageState extends State<PremiosPage> {
  List<Jornada> _jornadas = [];
  bool   _loading  = true;
  String _error    = "";
  DateTime _fecha  = DateTime.now();

  @override
  void initState() { super.initState(); _cargar(); }

  String get _fechaStr {
    final f = _fecha;
    return "${f.year}-${f.month.toString().padLeft(2,'0')}-${f.day.toString().padLeft(2,'0')}";
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ""; });
    try {
      final j = await PremiosService.obtenerJornadas(_fechaStr);
      setState(() { _jornadas = j; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSelect(int i) {
    const rutas = [
      '/menu', '/bancas', '/premios', '/reportes',
      '/usuarios', '/limites', '/configuracion',
    ];
    if (rutas[i] != '/premios') Navigator.pushReplacementNamed(context, rutas[i]);
  }

  Future<void> _generar() async {
    final confirm = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Generar Jornadas"),
        content: Text("¿Generar jornadas para $_fechaStr?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007BFF), foregroundColor: Colors.white),
            child: const Text("Generar")),
        ],
      ));
    if (confirm != true) return;
    try {
      await PremiosService.generar(_fechaStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Jornadas generadas para $_fechaStr ✓"),
          backgroundColor: Colors.green));
      }
      await _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickFecha() async {
    final p = await showDatePicker(context: context, initialDate: _fecha,
        firstDate: DateTime(2024), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (p != null) { setState(() => _fecha = p); await _cargar(); }
  }

  String _fmtHora(String? h) {
    if (h == null || h.isEmpty) return '--:--';
    final p  = h.split(':');
    if (p.length < 2) return h;
    final hh = int.tryParse(p[0]) ?? 0;
    return "${hh % 12 == 0 ? 12 : hh % 12}:${p[1].padLeft(2,'0')} ${hh >= 12 ? 'PM' : 'AM'}";
  }

  Widget _badge(String estado) {
    late Color bg, fg;
    switch (estado) {
      case 'abierto':    bg = const Color(0xFFD4EDDA); fg = const Color(0xFF155724); break;
      case 'cerrado':    bg = const Color(0xFFF8D7DA); fg = const Color(0xFF721C24); break;
      case 'completado': bg = const Color(0xFFCCE5FF); fg = const Color(0xFF004085); break;
      default:           bg = const Color(0xFFE2E3E5); fg = const Color(0xFF383D41);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(estado, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)));
  }

  Widget _fila(Jornada j) {
    final premioListo = j.q1 != null && j.q1!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(j.loteria ?? "-",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 3),
              Text("${_fmtHora(j.horaInicio)} - ${_fmtHora(j.horaCierre)}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ]),
          ])),
          Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _qChip("Q1", j.q1),
            const SizedBox(width: 3),
            _qChip("Q2", j.q2),
            const SizedBox(width: 3),
            _qChip("Q3", j.q3),
          ])),
          const SizedBox(width: 8),
          _badge(j.estado),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              await showDialog(context: context,
                  builder: (_) => JornadaModal(jornada: j));
              await _cargar();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: premioListo ? Colors.green.shade50 : const Color(0xFF1A237E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(premioListo ? Icons.emoji_events : Icons.edit,
                    size: 16,
                    color: premioListo ? Colors.green.shade700 : const Color(0xFF1A237E)),
                const SizedBox(width: 4),
                Text(premioListo ? "Ver" : "Editar",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: premioListo ? Colors.green.shade700 : const Color(0xFF1A237E))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _qChip(String label, String? val) {
    final tiene = val != null && val.isNotEmpty && val != '00';
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      Container(
        width: 28, height: 26,
        decoration: BoxDecoration(
          color: tiene ? const Color(0xFF1A237E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: tiene ? const Color(0xFF1A237E) : Colors.grey.shade300)),
        child: Center(child: Text(
          tiene ? val! : "--",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
              color: tiene ? Colors.white : Colors.grey.shade400))),
      ),
    ]);
  }

  Widget _encabezado() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      const Expanded(flex: 3, child: Text("Lotería / Horario",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey))),
      Expanded(flex: 2, child: Center(child: Text("Q1  Q2  Q3",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)))),
      const SizedBox(width: 8),
      SizedBox(width: 72, child: Text("Estado",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          textAlign: TextAlign.center)),
      const SizedBox(width: 8),
      SizedBox(width: 58, child: Text("Acción",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
          textAlign: TextAlign.center)),
    ]),
  );

  Widget _resumenChip(String label, String val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  @override
  Widget build(BuildContext context) {
    final total      = _jornadas.length;
    final abiertas   = _jornadas.where((j) => j.estado == 'abierto').length;
    final cerradas   = _jornadas.where((j) => j.estado == 'cerrado').length;
    final conPremio  = _jornadas.where((j) => j.q1 != null && j.q1!.isNotEmpty).length;

    return AppLayout(
      selectedIndex: 2,
      onItemSelected: _onSelect,
      child: Column(children: [
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            const Expanded(child: Text("Premios y Jornadas",
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
          ]),
        ),

        // ── Barra fecha (CORREGIDO: Color dentro de BoxDecoration) ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white, // Movido aquí para evitar conflicto
            border: Border(bottom: BorderSide(color: Colors.grey.shade200))
          ),
          child: Row(children: [
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
                  Text(_fechaStr, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () { setState(() => _fecha = DateTime.now()); _cargar(); },
              style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  backgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Hoy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _generar,
              icon: const Icon(Icons.add, size: 16),
              label: const Text("Generar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0)),
          ]),
        ),

        if (!_loading && _jornadas.isNotEmpty)
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              _resumenChip("Total", "$total", Colors.blueGrey),
              const SizedBox(width: 6),
              _resumenChip("Abiertas", "$abiertas", const Color(0xFF28A745)),
              const SizedBox(width: 6),
              _resumenChip("Cerradas", "$cerradas", const Color(0xFFDC3545)),
              const SizedBox(width: 6),
              _resumenChip("Con Premio", "$conPremio", const Color(0xFFFF9800)),
            ]),
          ),

        if (!_loading && _jornadas.isNotEmpty) _encabezado(),

        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
            ? _errorView()
            : _jornadas.isEmpty
              ? _emptyView()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    itemCount: _jornadas.length,
                    itemBuilder: (_, i) => _fila(_jornadas[i]),
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
    ElevatedButton.icon(onPressed: _cargar,
      icon: const Icon(Icons.refresh), label: const Text("Reintentar")),
  ]));

  Widget _emptyView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.calendar_today_outlined, size: 56, color: Colors.grey.shade300),
    const SizedBox(height: 14),
    Text("No hay jornadas para $_fechaStr",
        style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
    const SizedBox(height: 6),
    Text('Usa "Generar" para crearlas.',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
    const SizedBox(height: 20),
    ElevatedButton.icon(
      onPressed: _generar,
      icon: const Icon(Icons.add),
      label: const Text("Generar Jornadas"),
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007BFF), foregroundColor: Colors.white)),
  ]));
}

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
    setState(() { _loading = true; _error = ""; });
    try {
      final b = await BancasService.obtenerBancas();
      setState(() { _bancas = b; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSelect(int i) {
    const rutas = [
      '/menu',          // 0
      '/bancas',        // 1
      '/venta',         // 2
      '/premios',       // 3
      '/reportes',      // 4
      '/usuarios',      // 5
      '/limites',       // 6
      '/configuracion', // 7
    ];
    if (i < rutas.length && rutas[i] != '/bancas') Navigator.pushReplacementNamed(context, rutas[i]);
  }

  Widget _fila(Banca b) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Colors.grey.shade200)),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (b.codigo != null && b.codigo!.isNotEmpty)
              Text("Código: ${b.codigo}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: b.activa ? const Color(0xFFD1ECF1) : const Color(0xFFF8D7DA),
              borderRadius: BorderRadius.circular(12)),
            child: Text(b.activa ? "Activa" : "Inactiva",
              style: TextStyle(
                color: b.activa ? const Color(0xFF0D6EFD) : const Color(0xFFDC3545),
                fontWeight: FontWeight.w700, fontSize: 12))),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              await showDialog(context: context,
                  builder: (_) => _BancaModal(banca: b));
              await _cargar();
            },
            icon: const Icon(Icons.edit, size: 15),
            label: const Text("Editar", style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _infoGrid("Límites", [
            _kv("Q",  b.limiteQ),
            _kv("P",  b.limiteP),
            _kv("T",  b.limiteT),
            _kv("SP", b.limiteSP),
          ])),
          const SizedBox(width: 12),
          Expanded(child: _infoGrid("Comisiones %", [
            _kv("Q",  b.comisionQ,  pct: true),
            _kv("P",  b.comisionP,  pct: true),
            _kv("T",  b.comisionT,  pct: true),
            _kv("SP", b.comisionSP, pct: true),
          ])),
        ]),
      ]),
    ),
  );

  Widget _infoGrid(String titulo, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(titulo, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 4, children: items),
    ]);

  Widget _kv(String label, double? val, {bool pct = false}) {
    final str = val != null
        ? (pct ? "${val.toStringAsFixed(1)}%" : val.toStringAsFixed(0))
        : "-";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: Text("$label: $str",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
  }

  Widget _chip(String label, String val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(
          color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 1,
    onItemSelected: _onSelect,
    child: _loading
      ? const Center(child: CircularProgressIndicator())
      : _error.isNotEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 10),
            Text(_error, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 14),
            ElevatedButton.icon(onPressed: _cargar,
                icon: const Icon(Icons.refresh), label: const Text("Reintentar")),
          ]))
        : Column(children: [
            // Header
            Container(
              color: const Color(0xFF1A237E),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(children: [
                const Expanded(child: Text("Control Operativo de Bancas",
                  style: TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _cargar),
              ]),
            ),
            // Resumen chips
            if (_bancas.isNotEmpty)
              Container(
                color: Colors.grey.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  _chip("Total",    "${_bancas.length}", Colors.blueGrey),
                  const SizedBox(width: 6),
                  _chip("Activas",  "${_bancas.where((b) => b.activa).length}",
                      const Color(0xFF0D6EFD)),
                  const SizedBox(width: 6),
                  _chip("Inactivas","${_bancas.where((b) => !b.activa).length}",
                      const Color(0xFFDC3545)),
                ])),
            // Lista
            Expanded(child: _bancas.isEmpty
              ? const Center(child: Text("No hay bancas",
                  style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    itemCount: _bancas.length,
                    itemBuilder: (_, i) => _fila(_bancas[i])))),
          ]),
  );
}

// ═══════════════════════════════════════════════════
// MODAL EDITAR BANCA
// ═══════════════════════════════════════════════════
class _BancaModal extends StatefulWidget {
  final Banca banca;
  const _BancaModal({required this.banca});
  @override State<_BancaModal> createState() => _BancaModalState();
}

class _BancaModalState extends State<_BancaModal> {
  final _nombreCtrl       = TextEditingController();
  final _nombreTicketCtrl = TextEditingController();
  final _codigoCtrl       = TextEditingController();
  bool _activa = true;

  List<Esquema> _esqPrecios = [];
  List<Esquema> _esqPagos   = [];
  String? _esquemaPrecioId;
  String? _esquemaPagoId;

  final _limQCtrl  = TextEditingController();
  final _limPCtrl  = TextEditingController();
  final _limTCtrl  = TextEditingController();
  final _limSPCtrl = TextEditingController();

  final _comQCtrl  = TextEditingController();
  final _comPCtrl  = TextEditingController();
  final _comTCtrl  = TextEditingController();
  final _comSPCtrl = TextEditingController();

  final _topeQCtrl  = TextEditingController();
  final _topePCtrl  = TextEditingController();
  final _topeTCtrl  = TextEditingController();
  final _topeSPCtrl = TextEditingController();

  bool   _cargando  = false;
  bool   _guardando = false;
  String _msg       = "";
  Color  _msgColor  = Colors.grey;

  @override
  void initState() {
    super.initState();
    _poblar(widget.banca);
    _cargarEsquemas();
  }

  void _poblar(Banca b) {
    _nombreCtrl.text       = b.nombre;
    _nombreTicketCtrl.text = b.nombreTicket ?? '';
    _codigoCtrl.text       = b.codigo ?? '';
    _activa                = b.activa;
    _esquemaPrecioId       = b.esquemaPrecioId;
    _esquemaPagoId         = b.esquemaPagoId;

    _limQCtrl.text  = b.limiteQ?.toStringAsFixed(0)  ?? '';
    _limPCtrl.text  = b.limiteP?.toStringAsFixed(0)  ?? '';
    _limTCtrl.text  = b.limiteT?.toStringAsFixed(0)  ?? '';
    _limSPCtrl.text = b.limiteSP?.toStringAsFixed(0) ?? '';

    _comQCtrl.text  = b.comisionQ?.toString()  ?? '';
    _comPCtrl.text  = b.comisionP?.toString()  ?? '';
    _comTCtrl.text  = b.comisionT?.toString()  ?? '';
    _comSPCtrl.text = b.comisionSP?.toString() ?? '';

    _topeQCtrl.text  = b.topeQ?.toString()  ?? '';
    _topePCtrl.text  = b.topeP?.toString()  ?? '';
    _topeTCtrl.text  = b.topeT?.toString()  ?? '';
    _topeSPCtrl.text = b.topeSP?.toString() ?? '';
  }

  Future<void> _cargarEsquemas() async {
    setState(() => _cargando = true);
    try {
      final futures = await Future.wait([
        BancasService.obtenerEsquemasPrecios(),
        BancasService.obtenerEsquemasPagos(),
      ]);
      setState(() { _esqPrecios = futures[0]; _esqPagos = futures[1]; _cargando = false; });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombreCtrl, _nombreTicketCtrl, _codigoCtrl,
      _limQCtrl, _limPCtrl, _limTCtrl, _limSPCtrl,
      _comQCtrl, _comPCtrl, _comTCtrl, _comSPCtrl,
      _topeQCtrl, _topePCtrl, _topeTCtrl, _topeSPCtrl,
    ]) c.dispose();
    super.dispose();
  }

  double? _val(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  Future<void> _guardar() async {
    setState(() { _guardando = true; _msg = "Guardando..."; _msgColor = Colors.grey; });
    try {
      await BancasService.guardarBanca(widget.banca.id, {
        'nombre':            _nombreCtrl.text.trim(),
        'nombre_ticket':     _nombreTicketCtrl.text.trim(),
        'activa':            _activa,
        'esquema_precio_id': _esquemaPrecioId,
        'esquema_pago_id':   _esquemaPagoId,
        'limite_q':  _val(_limQCtrl),  'limite_p':  _val(_limPCtrl),
        'limite_t':  _val(_limTCtrl),  'limite_sp': _val(_limSPCtrl),
        'comision_q': _val(_comQCtrl), 'comision_p': _val(_comPCtrl),
        'comision_t': _val(_comTCtrl), 'comision_sp': _val(_comSPCtrl),
        'tope_q': _val(_topeQCtrl),    'tope_p': _val(_topePCtrl),
        'tope_t': _val(_topeTCtrl),    'tope_sp': _val(_topeSPCtrl),
      });
      setState(() { _msg = "✓ Guardado correctamente"; _msgColor = Colors.green; });
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _msg = "Error: $e"; _msgColor = Colors.red; });
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFF1A237E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [
            const Icon(Icons.storefront, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text("Editar Banca — ${widget.banca.nombre}",
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 15))),
          ]),
        ),
        // Body
        Flexible(child: _cargando
          ? const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator()))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _titulo("Datos de la banca"),
                const SizedBox(height: 8),
                _campo("Nombre", _nombreCtrl),
                const SizedBox(height: 8),
                _campo("Nombre en ticket", _nombreTicketCtrl),
                const SizedBox(height: 8),
                _campo("Código", _codigoCtrl),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)),
                  child: Row(children: [
                    Switch(value: _activa,
                      onChanged: (v) => setState(() => _activa = v),
                      activeColor: const Color(0xFF0D6EFD)),
                    const SizedBox(width: 8),
                    Text(_activa ? "Banca activa" : "Banca inactiva",
                      style: TextStyle(fontWeight: FontWeight.w600,
                        color: _activa ? const Color(0xFF0D6EFD) : const Color(0xFFDC3545))),
                  ])),
                const SizedBox(height: 14),
                const Divider(),
                _titulo("Esquemas"),
                const SizedBox(height: 8),
                _dropdown("Esquema de precios", _esqPrecios, _esquemaPrecioId,
                    (v) => setState(() => _esquemaPrecioId = v)),
                const SizedBox(height: 8),
                _dropdown("Esquema de pagos", _esqPagos, _esquemaPagoId,
                    (v) => setState(() => _esquemaPagoId = v)),
                const SizedBox(height: 14),
                const Divider(),
                _titulo("Límites por número"),
                const SizedBox(height: 8),
                _grid4([
                  _campoNum("Límite Q",  _limQCtrl),
                  _campoNum("Límite P",  _limPCtrl),
                  _campoNum("Límite T",  _limTCtrl),
                  _campoNum("Límite SP", _limSPCtrl),
                ]),
                const SizedBox(height: 14),
                const Divider(),
                _titulo("Comisión de la banca (%)"),
                const SizedBox(height: 8),
                _grid4([
                  _campoNum("Com. Q",  _comQCtrl,  dec: true),
                  _campoNum("Com. P",  _comPCtrl,  dec: true),
                  _campoNum("Com. T",  _comTCtrl,  dec: true),
                  _campoNum("Com. SP", _comSPCtrl, dec: true),
                ]),
                const SizedBox(height: 14),
                const Divider(),
                _titulo("Tope máximo combinado (%)"),
                const SizedBox(height: 8),
                _grid4([
                  _campoNum("Tope Q",  _topeQCtrl,  dec: true),
                  _campoNum("Tope P",  _topePCtrl,  dec: true),
                  _campoNum("Tope T",  _topeTCtrl,  dec: true),
                  _campoNum("Tope SP", _topeSPCtrl, dec: true),
                ]),
                if (_msg.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _msgColor == Colors.green ? const Color(0xFFD4EDDA)
                           : _msgColor == Colors.red   ? const Color(0xFFF8D7DA)
                           : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(_msgColor == Colors.green ? Icons.check_circle
                           : _msgColor == Colors.red ? Icons.error_outline
                           : Icons.info_outline,
                           color: _msgColor, size: 17),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_msg, style: TextStyle(
                          color: _msgColor, fontWeight: FontWeight.w500, fontSize: 13))),
                    ])),
                ],
              ]),
            )),
        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 17),
              label: const Text("Cancelar")),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save, size: 17),
              label: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11))),
          ])),
      ]),
    ),
  );

  Widget _titulo(String t) => Text(t,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
        color: Colors.grey, letterSpacing: 0.8));

  Widget _campo(String label, TextEditingController ctrl) => TextField(
    controller: ctrl,
    decoration: InputDecoration(labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));

  Widget _campoNum(String label, TextEditingController ctrl, {bool dec = false}) => TextField(
    controller: ctrl,
    keyboardType: dec
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.number,
    inputFormatters: dec
        ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
        : [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)));

  Widget _grid4(List<Widget> items) => Column(children: [
    Row(children: [
      Expanded(child: items[0]), const SizedBox(width: 8), Expanded(child: items[1]),
    ]),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: items[2]), const SizedBox(width: 8), Expanded(child: items[3]),
    ]),
  ]);

  Widget _dropdown(String label, List<Esquema> lista, String? valor,
      void Function(String?) onChange) {
    final existe = lista.any((e) => e.id == valor);
    return DropdownButtonFormField<String>(
      value: existe ? valor : null,
      decoration: InputDecoration(labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      items: [
        const DropdownMenuItem(value: null, child: Text("-- Ninguno --")),
        ...lista.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre))),
      ],
      onChanged: onChange);
  }
}

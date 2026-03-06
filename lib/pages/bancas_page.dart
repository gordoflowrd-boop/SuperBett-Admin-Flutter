import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/banca.dart';
import '../services/bancas_service.dart';
import '../layout/app_layout.dart';

// ── Constantes ───────────────────────────────────────────
const _kPri  = Color(0xFF1A237E);
const _kAzul = Color(0xFF0D6EFD);
const _kRojo = Color(0xFFDC3545);
const _deco8 = OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)));
const _dense = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

class BancasPage extends StatefulWidget {
  const BancasPage({super.key});
  @override State<BancasPage> createState() => _BancasPageState();
}

class _BancasPageState extends State<BancasPage> {
  List<Banca> _bancas = [];
  bool   _loading = true;
  String _error   = '';

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final b = await BancasService.obtenerBancas();
      setState(() { _bancas = b; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _onSelect(int i) {
    const r = ['/menu','/bancas','/venta','/premios','/reportes','/usuarios','/limites','/configuracion'];
    if (i < r.length && r[i] != '/bancas') Navigator.pushReplacementNamed(context, r[i]);
  }

  Widget _chip(String label, String val, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
      border: Border.all(color: c.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 14)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: c.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  Widget _fila(Banca b) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Colors.grey.shade200)),
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: _kPri.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(b.nombre.isNotEmpty ? b.nombre[0].toUpperCase() : '?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _kPri)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (b.codigo != null && b.codigo!.isNotEmpty)
            Text('Código: ${b.codigo}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: b.activa ? const Color(0xFFD1ECF1) : const Color(0xFFF8D7DA),
            borderRadius: BorderRadius.circular(12)),
          child: Text(b.activa ? 'Activa' : 'Inactiva',
            style: TextStyle(color: b.activa ? _kAzul : _kRojo,
              fontWeight: FontWeight.w700, fontSize: 12))),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () async {
            await showDialog(context: context, builder: (_) => _BancaModal(banca: b));
            await _cargar();
          },
          icon: const Icon(Icons.edit, size: 15),
          label: const Text('Editar', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(backgroundColor: _kPri, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
      ])));

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 1, onItemSelected: _onSelect,
    child: _loading ? const Center(child: CircularProgressIndicator())
      : _error.isNotEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48), const SizedBox(height: 10),
            Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 14),
            ElevatedButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ]))
        : Column(children: [
            Container(color: _kPri, padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(children: [
                const Expanded(child: Text('Control Operativo de Bancas',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargar),
              ])),
            if (_bancas.isNotEmpty)
              Container(color: Colors.grey.shade50, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  _chip('Total',    '${_bancas.length}',                          Colors.blueGrey),
                  const SizedBox(width: 6),
                  _chip('Activas',  '${_bancas.where((b) => b.activa).length}',   _kAzul),
                  const SizedBox(width: 6),
                  _chip('Inactivas','${_bancas.where((b) => !b.activa).length}',  _kRojo),
                ])),
            Expanded(child: _bancas.isEmpty
              ? const Center(child: Text('No hay bancas', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(onRefresh: _cargar,
                  child: ListView.builder(
                    itemCount: _bancas.length, itemBuilder: (_, i) => _fila(_bancas[i])))),
          ]));
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
  final _nom  = TextEditingController();
  final _tick = TextEditingController();
  final _cod  = TextEditingController();
  bool _activa = true;

  List<Esquema> _esqP = [], _esqPag = [];
  String? _precioId, _pagoId;

  // Límites / Comisiones / Topes  Q P T SP
  final _lQ = TextEditingController(), _lP = TextEditingController();
  final _lT = TextEditingController(), _lS = TextEditingController();
  final _cQ = TextEditingController(), _cP = TextEditingController();
  final _cT = TextEditingController(), _cS = TextEditingController();
  final _tQ = TextEditingController(), _tP = TextEditingController();
  final _tT = TextEditingController(), _tS = TextEditingController();

  bool   _load = false, _save = false;
  String _msg  = '';
  Color  _col  = Colors.grey;

  @override
  void initState() { super.initState(); _poblar(widget.banca); _cargarEsq(); }

  void _poblar(Banca b) {
    _nom.text  = b.nombre;       _tick.text = b.nombreTicket ?? '';
    _cod.text  = b.codigo ?? ''; _activa    = b.activa;
    _precioId  = b.esquemaPrecioId; _pagoId = b.esquemaPagoId;
    _lQ.text = b.limiteQ?.toStringAsFixed(0)  ?? ''; _lP.text = b.limiteP?.toStringAsFixed(0)  ?? '';
    _lT.text = b.limiteT?.toStringAsFixed(0)  ?? ''; _lS.text = b.limiteSP?.toStringAsFixed(0) ?? '';
    _cQ.text = b.comisionQ?.toString() ?? ''; _cP.text = b.comisionP?.toString() ?? '';
    _cT.text = b.comisionT?.toString() ?? ''; _cS.text = b.comisionSP?.toString() ?? '';
    _tQ.text = b.topeQ?.toString()  ?? ''; _tP.text = b.topeP?.toString()  ?? '';
    _tT.text = b.topeT?.toString()  ?? ''; _tS.text = b.topeSP?.toString() ?? '';
  }

  Future<void> _cargarEsq() async {
    setState(() => _load = true);
    try {
      final f = await Future.wait([BancasService.obtenerEsquemasPrecios(), BancasService.obtenerEsquemasPagos()]);
      setState(() { _esqP = f[0] as List<Esquema>; _esqPag = f[1] as List<Esquema>; _load = false; });
    } catch (_) { setState(() => _load = false); }
  }

  @override
  void dispose() {
    for (final c in [_nom,_tick,_cod,_lQ,_lP,_lT,_lS,_cQ,_cP,_cT,_cS,_tQ,_tP,_tT,_tS]) c.dispose();
    super.dispose();
  }

  double? _v(TextEditingController c) => c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  Future<void> _guardar() async {
    setState(() { _save = true; _msg = 'Guardando...'; _col = Colors.grey; });
    try {
      await BancasService.guardarBanca(widget.banca.id, {
        'nombre': _nom.text.trim(), 'nombre_ticket': _tick.text.trim(), 'activa': _activa,
        'esquema_precio_id': _precioId, 'esquema_pago_id': _pagoId,
        'limite_q':  _v(_lQ), 'limite_p':  _v(_lP), 'limite_t':  _v(_lT), 'limite_sp':  _v(_lS),
        'comision_q':_v(_cQ), 'comision_p':_v(_cP), 'comision_t':_v(_cT), 'comision_sp':_v(_cS),
        'tope_q':    _v(_tQ), 'tope_p':    _v(_tP), 'tope_t':    _v(_tT), 'tope_sp':    _v(_tS),
      });
      setState(() { _msg = '✓ Guardado correctamente'; _col = Colors.green; });
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _msg = 'Error: $e'; _col = Colors.red; });
    } finally { setState(() => _save = false); }
  }

  // ── Helpers del modal ─────────────────────────────────
  Widget _sec(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
      color: Colors.grey, letterSpacing: 0.8)));

  Widget _f(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(controller: c,
      decoration: InputDecoration(labelText: label, border: _deco8, isDense: true, contentPadding: _dense)));

  Widget _n(String label, TextEditingController c, {bool d = false}) => TextField(
    controller: c,
    keyboardType: d ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
    inputFormatters: [d ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')) : FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12),
      border: _deco8, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)));

  Widget _g4(List<Widget> w) => Column(children: [
    Row(children: [Expanded(child: w[0]), const SizedBox(width: 8), Expanded(child: w[1])]),
    const SizedBox(height: 8),
    Row(children: [Expanded(child: w[2]), const SizedBox(width: 8), Expanded(child: w[3])]),
  ]);

  Widget _drop(String label, List<Esquema> lista, String? val, void Function(String?) fn) =>
    DropdownButtonFormField<String>(
      value: lista.any((e) => e.id == val) ? val : null,
      decoration: InputDecoration(labelText: label, border: _deco8, isDense: true, contentPadding: _dense),
      items: [
        const DropdownMenuItem(value: null, child: Text('-- Ninguno --')),
        ...lista.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre))),
      ],
      onChanged: fn);

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(color: _kPri,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [
            const Icon(Icons.storefront, color: Colors.white, size: 20), const SizedBox(width: 8),
            Expanded(child: Text('Editar Banca — ${widget.banca.nombre}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
          ])),
        Flexible(child: _load
          ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          : SingleChildScrollView(padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sec('Datos de la banca'),
                _f('Nombre', _nom), _f('Nombre en ticket', _tick), _f('Código', _cod),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)),
                  child: Row(children: [
                    Switch(value: _activa, onChanged: (v) => setState(() => _activa = v), activeColor: _kAzul),
                    const SizedBox(width: 8),
                    Text(_activa ? 'Banca activa' : 'Banca inactiva',
                      style: TextStyle(fontWeight: FontWeight.w600, color: _activa ? _kAzul : _kRojo)),
                  ])),
                const Divider(height: 24),
                _sec('Esquemas'),
                _drop('Esquema de precios', _esqP,   _precioId, (v) => setState(() => _precioId = v)),
                const SizedBox(height: 8),
                _drop('Esquema de pagos',   _esqPag, _pagoId,   (v) => setState(() => _pagoId   = v)),
                const Divider(height: 24),
                _sec('Límites por número'),
                _g4([_n('Límite Q',_lQ), _n('Límite P',_lP), _n('Límite T',_lT), _n('Límite SP',_lS)]),
                const Divider(height: 24),
                _sec('Comisión de la banca (%)'),
                _g4([_n('Com. Q',_cQ,d:true), _n('Com. P',_cP,d:true), _n('Com. T',_cT,d:true), _n('Com. SP',_cS,d:true)]),
                const Divider(height: 24),
                _sec('Tope máximo combinado (%)'),
                _g4([_n('Tope Q',_tQ,d:true), _n('Tope P',_tP,d:true), _n('Tope T',_tT,d:true), _n('Tope SP',_tS,d:true)]),
                if (_msg.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                      color: _col == Colors.green ? const Color(0xFFD4EDDA)
                           : _col == Colors.red   ? const Color(0xFFF8D7DA) : Colors.grey.shade100),
                    child: Row(children: [
                      Icon(_col == Colors.green ? Icons.check_circle
                         : _col == Colors.red   ? Icons.error_outline : Icons.info_outline,
                         color: _col, size: 17),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_msg,
                        style: TextStyle(color: _col, fontWeight: FontWeight.w500, fontSize: 13))),
                    ])),
                ],
              ]))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 17), label: const Text('Cancelar')),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _save ? null : _guardar,
              icon: _save
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save, size: 17),
              label: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11))),
          ])),
      ])));
}



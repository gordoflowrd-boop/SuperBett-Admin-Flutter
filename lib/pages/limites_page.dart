import 'package:flutter/material.dart';
import '../layout/app_layout.dart';
import '../services/limites_service.dart';

class LimitesPage extends StatefulWidget {
  const LimitesPage({super.key});
  @override
  State<LimitesPage> createState() => _LimitesPageState();
}

class _LimitesPageState extends State<LimitesPage> {
  final _svc = LimitesService();

  List<LoteriasModel> _loterias    = [];
  LoteriasModel?      _seleccionada;
  bool   _cargando  = true;
  bool   _guardando = false;
  String? _error;
  String? _exito;

  final _ctrlQ  = TextEditingController();
  final _ctrlP  = TextEditingController();
  final _ctrlT  = TextEditingController();
  final _ctrlSp = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _ctrlQ.dispose(); _ctrlP.dispose();
    _ctrlT.dispose(); _ctrlSp.dispose();
    super.dispose();
  }

  void _navegar(BuildContext ctx, int i) {
    const rutas = [
      '/menu', '/bancas', '/venta', '/premios',
      '/reportes', '/usuarios', '/limites', '/configuracion',
    ];
    if (rutas[i] != '/limites') Navigator.pushReplacementNamed(ctx, rutas[i]);
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final lista = await _svc.getLoterias();
      setState(() {
        _loterias = lista;
        _cargando = false;
        if (lista.isNotEmpty) _seleccionar(lista.first);
      });
    } catch (e) {
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  void _seleccionar(LoteriasModel l) {
    setState(() {
      _seleccionada = l;
      _exito = null;
      _error = null;
      _ctrlQ.text  = l.limiteQ  != null ? l.limiteQ!.toStringAsFixed(0)  : '';
      _ctrlP.text  = l.limiteP  != null ? l.limiteP!.toStringAsFixed(0)  : '';
      _ctrlT.text  = l.limiteT  != null ? l.limiteT!.toStringAsFixed(0)  : '';
      _ctrlSp.text = l.limiteSp != null ? l.limiteSp!.toStringAsFixed(0) : '';
    });
  }

  Future<void> _guardar() async {
    if (_seleccionada == null) return;
    setState(() { _guardando = true; _exito = null; _error = null; });
    try {
      await _svc.guardarLimites(
        loteriaId: _seleccionada!.id,
        limiteQ:   _ctrlQ.text.isNotEmpty  ? double.tryParse(_ctrlQ.text)  : null,
        limiteP:   _ctrlP.text.isNotEmpty  ? double.tryParse(_ctrlP.text)  : null,
        limiteT:   _ctrlT.text.isNotEmpty  ? double.tryParse(_ctrlT.text)  : null,
        limiteSp:  _ctrlSp.text.isNotEmpty ? double.tryParse(_ctrlSp.text) : null,
      );
      final lista = await _svc.getLoterias();
      setState(() {
        _loterias     = lista;
        _guardando    = false;
        _exito        = 'Límites guardados';
        _seleccionada = lista.firstWhere(
          (l) => l.id == _seleccionada!.id,
          orElse: () => lista.first,
        );
      });
    } catch (e) {
      setState(() { _error = e.toString(); _guardando = false; });
    }
  }

  // ── Campo individual ────────────────────────
  Widget _campo({
    required String label,
    required TextEditingController ctrl,
    required Color  color,
    required String modalidad,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        decoration: InputDecoration(
          labelText: label,
          hintText:  'Sin límite',
          prefixIcon: CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(.15),
            child: Text(modalidad,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: color)),
          ),
          suffixText: 'unid.',
          border:        const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 2)),
          labelStyle: TextStyle(color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 8,
      child: Column(children: [

        // ── Navbar ─────────────────────────────
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: const Row(children: [
            Expanded(child: Text('Límites por Lotería',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.bold))),
            Icon(Icons.tune, color: Colors.white, size: 20),
          ]),
        ),

        // ── Body ───────────────────────────────
        Expanded(child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _loterias.isEmpty
            ? Center(child: Text('No hay loterías',
                style: TextStyle(color: Colors.grey.shade500)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // ── Selector de lotería ─────
                    const Text('Seleccionar Lotería',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<LoteriasModel>(
                          value: _seleccionada,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: _loterias.map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l.nombre,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          )).toList(),
                          onChanged: (l) { if (l != null) _seleccionar(l); },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Info ────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Text(
                        'Límite global por número — aplica al total de todas las bancas.\n'
                        'Deja vacío para no limitar.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Campos ──────────────────
                    _campo(label: 'Quiniela (Q)',    ctrl: _ctrlQ,
                           color: Colors.blue,   modalidad: 'Q'),
                    _campo(label: 'Palé (P)',        ctrl: _ctrlP,
                           color: Colors.green,  modalidad: 'P'),
                    _campo(label: 'Tripleta (T)',    ctrl: _ctrlT,
                           color: Colors.orange, modalidad: 'T'),
                    _campo(label: 'Super Palé (SP)', ctrl: _ctrlSp,
                           color: Colors.purple, modalidad: 'SP'),

                    // ── Error / Éxito ───────────
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(_error!,
                          style: const TextStyle(color: Colors.red,
                              fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_exito != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(_exito!,
                            style: const TextStyle(color: Colors.green,
                                fontSize: 13)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Botón guardar ───────────
                    ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                      label: Text(_guardando ? 'Guardando...' : 'Guardar Límites'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ]),
    );
  }
}

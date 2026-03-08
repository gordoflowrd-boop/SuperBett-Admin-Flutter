import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../layout/app_layout.dart';
import '../services/configuracion_service.dart';
import '../services/esquemas_service.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});
  @override State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage>
    with SingleTickerProviderStateMixin {

  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _onSelect(BuildContext context, int i) {
    const rutas = ['/menu','/bancas','/venta','/premios',
                   '/reportes','/usuarios','/limites','/configuracion'];
    if (i < rutas.length && rutas[i] != '/configuracion')
      Navigator.pushReplacementNamed(context, rutas[i]);
  }

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 7,
    onItemSelected: (i) => _onSelect(context, i),
    child: Column(children: [
      // ── Navbar ─────────────────────────────────
      Container(
        color: const Color(0xFF1A237E),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: const [
              Expanded(child: Text("Configuración",
                  style: TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.bold))),
              Icon(Icons.settings_outlined, color: Colors.white, size: 20),
            ]),
          ),
          TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(icon: Icon(Icons.timer_outlined,    size: 18), text: "Anulaciones"),
              Tab(icon: Icon(Icons.attach_money,      size: 18), text: "Precios"),
              Tab(icon: Icon(Icons.emoji_events_outlined, size: 18), text: "Pagos"),
            ],
          ),
        ]),
      ),

      // ── Tabs ───────────────────────────────────
      Expanded(child: TabBarView(
        controller: _tab,
        children: const [
          _TabAnulacion(),
          _TabEsquema(tipo: 'precios'),
          _TabEsquema(tipo: 'pagos'),
        ],
      )),
    ]),
  );
}

// ═════════════════════════════════════════════
// TAB 1 — ANULACIONES
// ═════════════════════════════════════════════
class _TabAnulacion extends StatefulWidget {
  const _TabAnulacion();
  @override State<_TabAnulacion> createState() => _TabAnulacionState();
}

class _TabAnulacionState extends State<_TabAnulacion> {
  final _ctrl = TextEditingController();
  bool _loading = true, _guardando = false;
  String _msg = '', _error = '';

  @override
  void initState() { super.initState(); _cargar(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final t = await ConfiguracionService.obtenerTiempoAnulacion();
      _ctrl.text = t.toString();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _guardar() async {
    final m = int.tryParse(_ctrl.text.trim()) ?? 0;
    if (m < 0) return;
    setState(() { _guardando = true; _msg = ''; _error = ''; });
    try {
      await ConfiguracionService.guardarTiempoAnulacion(m);
      setState(() { _guardando = false; _msg = '✓ Guardado'; });
    } catch (e) {
      setState(() { _guardando = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) => _loading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _cargar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    "Tiempo máximo para anular un ticket desde que fue emitido.\n"
                    "Coloca 0 para no aplicar límite.",
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 16),

              // Campo
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Tiempo límite de anulación",
                  hintText:  "Minutos — 0 = sin límite",
                  prefixIcon: Icon(Icons.timer_outlined),
                  suffixText: "min",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Chips rápidos
              Wrap(spacing: 8, children: [
                for (final m in [0, 2, 5, 10, 15, 30])
                  ActionChip(
                    label: Text(m == 0 ? "Sin límite" : "$m min"),
                    backgroundColor: _ctrl.text == m.toString()
                        ? const Color(0xFF1A237E) : Colors.grey.shade100,
                    labelStyle: TextStyle(
                        color: _ctrl.text == m.toString()
                            ? Colors.white : Colors.black87,
                        fontWeight: _ctrl.text == m.toString()
                            ? FontWeight.bold : FontWeight.normal),
                    onPressed: () => setState(() => _ctrl.text = m.toString()),
                  ),
              ]),
              const SizedBox(height: 24),

              if (_msg.isNotEmpty) _banner(_msg, true),
              if (_error.isNotEmpty) _banner(_error, false),

              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? "Guardando..." : "Guardar"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14)),
                )),
            ]),
          ));

  Widget _banner(String msg, bool ok) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ok ? Colors.green.shade50 : Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: ok ? Colors.green.shade300 : Colors.red.shade200)),
    child: Text(msg, style: TextStyle(
        color: ok ? Colors.green : Colors.red, fontWeight: FontWeight.bold)));
}

// ═════════════════════════════════════════════
// TAB 2 y 3 — ESQUEMAS (Precios / Pagos)
// ═════════════════════════════════════════════
class _TabEsquema extends StatefulWidget {
  final String tipo; // 'precios' o 'pagos'
  const _TabEsquema({required this.tipo});
  @override State<_TabEsquema> createState() => _TabEsquemaState();
}

class _TabEsquemaState extends State<_TabEsquema> {
  List<EsquemaPrecio> _precios = [];
  List<EsquemaPago>   _pagos   = [];
  bool   _loading = true;
  String _error   = '';
  int    _selIdx  = 0;   // índice del esquema seleccionado

  bool get _esPrecios => widget.tipo == 'precios';

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      if (_esPrecios) {
        _precios = await EsquemasService.getEsquemasPrecios();
      } else {
        _pagos = await EsquemasService.getEsquemasPagos();
      }
      setState(() { _loading = false; _selIdx = 0; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _nuevoEsquema() async {
    final nombre = await _dialogNombre("Nuevo esquema de ${_esPrecios ? 'precios' : 'pagos'}");
    if (nombre == null || nombre.isEmpty) return;
    try {
      if (_esPrecios) {
        await EsquemasService.crearEsquemaPrecio(nombre);
      } else {
        await EsquemasService.crearEsquemaPago(nombre);
      }
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✓ Esquema creado"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<String?> _dialogNombre(String titulo) async {
    final ctrl = TextEditingController();
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
          child: const Text("Crear")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text(_error,
        style: const TextStyle(color: Colors.red)));

    final esquemas = _esPrecios ? _precios : _pagos;

    return Column(children: [
      // ── Selector de esquema + botón nuevo ────
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Row(children: [
          Expanded(child: esquemas.isEmpty
            ? const Text("Sin esquemas", style: TextStyle(color: Colors.grey))
            : DropdownButtonFormField<int>(
                value: _selIdx,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                items: List.generate(esquemas.length, (i) {
                  final n = _esPrecios ? _precios[i].nombre : _pagos[i].nombre;
                  return DropdownMenuItem(value: i, child: Text(n));
                }),
                onChanged: (v) => setState(() => _selIdx = v ?? 0),
              )),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _nuevoEsquema,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Nuevo"),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
          ),
        ]),
      ),
      const SizedBox(height: 8),

      // ── Detalle del esquema seleccionado ─────
      Expanded(child: esquemas.isEmpty
        ? const Center(child: Text("Crea tu primer esquema", style: TextStyle(color: Colors.grey)))
        : RefreshIndicator(
            onRefresh: _cargar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _esPrecios
                  ? _PreciosEditor(key: ValueKey(_precios[_selIdx].id), esquema: _precios[_selIdx], onSaved: _cargar)
                  : _PagosEditor(key: ValueKey(_pagos[_selIdx].id), esquema: _pagos[_selIdx], onSaved: _cargar),
            ))),
    ]);
  }
}

// ─────────────────────────────────────────────
// Editor de PRECIOS
// ─────────────────────────────────────────────
class _PreciosEditor extends StatefulWidget {
  final EsquemaPrecio esquema;
  final VoidCallback onSaved;
  const _PreciosEditor({required this.esquema, required this.onSaved});
  @override State<_PreciosEditor> createState() => _PreciosEditorState();
}

class _PreciosEditorState extends State<_PreciosEditor> {
  // modalidad → TextEditingController
  late Map<String, TextEditingController> _ctrls;

  static const _modalidades = ['Q', 'P', 'T', 'SP'];
  static const _labels = {'Q': 'Quiniela', 'P': 'Palé', 'T': 'Tripleta', 'SP': 'Super Palé'};
  static const _colors = {
    'Q': Color(0xFF1565C0),
    'P': Color(0xFF2E7D32),
    'T': Color(0xFFE65100),
    'SP': Color(0xFF6A1B9A),
  };

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final m in _modalidades) m: TextEditingController(
        text: _precioActual(m)?.toStringAsFixed(2) ?? '')
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  double? _precioActual(String mod) {
    try {
      return widget.esquema.detalle
          .firstWhere((d) => d.modalidad == mod && d.loteriaId == null).precio;
    } catch (_) { return null; }
  }

  Future<void> _guardar() async {
    try {
      for (final m in _modalidades) {
        final val = double.tryParse(_ctrls[m]!.text.trim());
        if (val != null) {
          await EsquemasService.guardarPrecio(widget.esquema.id, m, val);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✓ Precios guardados"), backgroundColor: Colors.green));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    // Nombre del esquema
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Icon(Icons.price_change_outlined, color: Color(0xFF1A237E)),
        const SizedBox(width: 8),
        Text(widget.esquema.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(width: 4),
        if (!widget.esquema.activo)
          const Chip(label: Text("Inactivo"), backgroundColor: Colors.grey),
      ]),
    ),
    const Divider(),
    const SizedBox(height: 8),

    // Campos por modalidad
    for (final m in _modalidades) ...[
      _campoModalidad(m),
      const SizedBox(height: 12),
    ],
    const SizedBox(height: 8),

    // Botón guardar
    SizedBox(width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _guardar,
        icon: const Icon(Icons.save_outlined),
        label: const Text("Guardar Precios"),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(14)),
      )),
    const SizedBox(height: 16),
  ]);

  Widget _campoModalidad(String m) => TextField(
    controller: _ctrls[m],
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
    decoration: InputDecoration(
      labelText: "${_labels[m]} ($m)",
      hintText: "0.00",
      prefixIcon: CircleAvatar(
          backgroundColor: _colors[m]!.withOpacity(0.15),
          radius: 18,
          child: Text(m, style: TextStyle(color: _colors[m],
              fontWeight: FontWeight.bold, fontSize: 11))),
      suffixText: "RD\$",
      border: const OutlineInputBorder(),
      isDense: true,
    ),
  );
}

// ─────────────────────────────────────────────
// Editor de PAGOS (multiplicadores)
// ─────────────────────────────────────────────
class _PagosEditor extends StatefulWidget {
  final EsquemaPago esquema;
  final VoidCallback onSaved;
  const _PagosEditor({required this.esquema, required this.onSaved});
  @override State<_PagosEditor> createState() => _PagosEditorState();
}

class _PagosEditorState extends State<_PagosEditor> {
  // (modalidad, posicion) → controller
  late Map<String, TextEditingController> _ctrls;

  // Q → posiciones 1,2,3 | P → 12,13,23 | T → 2,3 | SP → 2
  static const _estructura = {
    'Q':  [1, 2, 3],
    'P':  [12, 13, 23],
    'T':  [2, 3],
    'SP': [2],
  };

  static const _posLabels = {
    1: 'Q1', 2: 'Q2 / 2 aciertos', 3: 'Q3 / 3 aciertos',
    12: 'P 1-2', 13: 'P 1-3', 23: 'P 2-3',
  };

  static const _colors = {
    'Q': Color(0xFF1565C0), 'P': Color(0xFF2E7D32),
    'T': Color(0xFFE65100), 'SP': Color(0xFF6A1B9A),
  };

  @override
  void initState() {
    super.initState();
    _ctrls = {};
    for (final entry in _estructura.entries) {
      for (final pos in entry.value) {
        final key = '${entry.key}_$pos';
        final val = _pagoActual(entry.key, pos);
        _ctrls[key] = TextEditingController(
            text: val != null ? val.toStringAsFixed(0) : '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  double? _pagoActual(String mod, int pos) {
    try {
      return widget.esquema.detalle
          .firstWhere((d) => d.modalidad == mod && d.posicion == pos && d.loteriaId == null).pago;
    } catch (_) { return null; }
  }

  Future<void> _guardar() async {
    try {
      for (final entry in _estructura.entries) {
        for (final pos in entry.value) {
          final key = '${entry.key}_$pos';
          final val = double.tryParse(_ctrls[key]!.text.trim());
          if (val != null) {
            await EsquemasService.guardarMultiplicador(
                widget.esquema.id, entry.key, pos, val);
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("✓ Multiplicadores guardados"),
            backgroundColor: Colors.green));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        const Icon(Icons.emoji_events_outlined, color: Color(0xFF1A237E)),
        const SizedBox(width: 8),
        Text(widget.esquema.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    ),
    const Divider(),
    const SizedBox(height: 8),

    for (final entry in _estructura.entries) ...[
      // Header de modalidad
      Row(children: [
        CircleAvatar(
            backgroundColor: _colors[entry.key]!.withOpacity(0.15),
            radius: 14,
            child: Text(entry.key,
                style: TextStyle(color: _colors[entry.key],
                    fontWeight: FontWeight.bold, fontSize: 10))),
        const SizedBox(width: 8),
        Text(_nombreMod(entry.key),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
      const SizedBox(height: 8),

      // Campo por posición
      for (final pos in entry.value) ...[
        TextField(
          controller: _ctrls['${entry.key}_$pos'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          decoration: InputDecoration(
            labelText: _posLabels[pos] ?? 'Pos $pos',
            hintText: "0",
            suffixText: "×",
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 8),
    ],

    SizedBox(width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _guardar,
        icon: const Icon(Icons.save_outlined),
        label: const Text("Guardar Multiplicadores"),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(14)),
      )),
    const SizedBox(height: 16),
  ]);

  String _nombreMod(String m) =>
      {'Q':'Quiniela','P':'Palé','T':'Tripleta','SP':'Super Palé'}[m] ?? m;
}

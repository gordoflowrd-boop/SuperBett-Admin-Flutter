import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../layout/app_layout.dart';
import '../services/configuracion_service.dart';
import '../services/esquemas_service.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});
  @override State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 7,
    onItemSelected: (i) => i != 7 ? Navigator.pushReplacementNamed(context, ['/menu','/bancas','/venta','/premios','/reportes','/usuarios','/limites','/configuracion'][i]) : null,
    child: Column(children: [
      Container(
        color: const Color(0xFF1A237E),
        child: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.timer_outlined), text: "Anulación"),
            Tab(icon: Icon(Icons.attach_money), text: "Precios"),
            Tab(icon: Icon(Icons.emoji_events), text: "Pagos"),
            Tab(icon: Icon(Icons.calendar_today), text: "Jornadas"),
          ],
        ),
      ),
      Expanded(child: TabBarView(
        controller: _tab,
        children: const [
          _TabAnulacion(),
          _TabEsquema(tipo: 'precios'),
          _TabEsquema(tipo: 'pagos'),
          _TabJornadas(),
        ],
      )),
    ]),
  );
}

// ── TAB 1: ANULACIONES ──────────────────────────────────────────────────
class _TabAnulacion extends StatefulWidget {
  const _TabAnulacion();
  @override State<_TabAnulacion> createState() => _TabAnulacionState();
}

class _TabAnulacionState extends State<_TabAnulacion> {
  final _ctrl = TextEditingController();
  bool _loading = true;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    try {
      final t = await ConfiguracionService.obtenerTiempoAnulacion();
      setState(() { _ctrl.text = t.toString(); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _loading
    ? const Center(child: CircularProgressIndicator())
    : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: "Minutos para anular ticket", border: OutlineInputBorder())
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
              onPressed: () async {
                await ConfiguracionService.guardarConfiguracion({'tiempo_anulacion': int.parse(_ctrl.text)});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Tiempo de anulación actualizado")));
                }
              },
              child: const Text("Guardar Cambios"),
            ),
          )
        ]),
      );
}

// ── TAB 2 Y 3: ESQUEMAS (PRECIOS/PAGOS) ──────────────────────────────────
class _TabEsquema extends StatefulWidget {
  final String tipo;
  const _TabEsquema({required this.tipo});
  @override State<_TabEsquema> createState() => _TabEsquemaState();
}

class _TabEsquemaState extends State<_TabEsquema> {
  List<dynamic> _items = [];
  bool _loading = true;
  int _selIdx = 0;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      _items = (widget.tipo == 'precios')
        ? await EsquemasService.getEsquemasPrecios()
        : await EsquemasService.getEsquemasPagos();
      setState(() { _loading = false; _selIdx = 0; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text("No hay esquemas configurados"));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<int>(
          value: _selIdx,
          decoration: const InputDecoration(labelText: "Seleccionar Esquema", border: OutlineInputBorder()),
          items: List.generate(_items.length, (i) => DropdownMenuItem(value: i, child: Text(_items[i].nombre))),
          onChanged: (v) => setState(() => _selIdx = v ?? 0),
        ),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: widget.tipo == 'precios'
          ? _EditorPrecios(key: ValueKey(_items[_selIdx].id), esquema: _items[_selIdx], onSaved: _cargar)
          : _EditorPagos(key: ValueKey(_items[_selIdx].id), esquema: _items[_selIdx], onSaved: _cargar),
      )),
    ]);
  }
}

// ── EDITOR PRECIOS (StatefulWidget) ──────────────────────────────────────
class _EditorPrecios extends StatefulWidget {
  final EsquemaPrecio esquema;
  final VoidCallback onSaved;
  const _EditorPrecios({super.key, required this.esquema, required this.onSaved});
  @override State<_EditorPrecios> createState() => _EditorPreciosState();
}

class _EditorPreciosState extends State<_EditorPrecios> {
  static const _modalidades = ['Q', 'P', 'T', 'SP'];
  final Map<String, TextEditingController> _ctrls = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (var m in _modalidades) {
      final precio = _getPrecio(m);
      _ctrls[m] = TextEditingController(text: precio == 0 ? '' : precio.toString());
    }
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) c.dispose();
    super.dispose();
  }

  double _getPrecio(String modalidad) {
    try {
      return widget.esquema.detalle.firstWhere((d) => d.modalidad == modalidad).precio;
    } catch (_) { return 0; }
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    try {
      for (var m in _modalidades) {
        final val = double.tryParse(_ctrls[m]!.text) ?? 0;
        await EsquemasService.guardarPrecio(widget.esquema.id, m, val);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Precios actualizados")));
      }
      widget.onSaved();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var m in _modalidades)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            controller: _ctrls[m],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Precio $m",
              border: const OutlineInputBorder(),
              prefixText: "RD\$ ",
            ),
          ),
        ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(15),
          ),
          onPressed: _saving ? null : _guardar,
          child: _saving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Guardar Precios"),
        ),
      ),
    ]);
  }
}

// ── EDITOR PAGOS (StatefulWidget) ─────────────────────────────────────────
class _EditorPagos extends StatefulWidget {
  final EsquemaPago esquema;
  final VoidCallback onSaved;
  const _EditorPagos({super.key, required this.esquema, required this.onSaved});
  @override State<_EditorPagos> createState() => _EditorPagosState();
}

class _EditorPagosState extends State<_EditorPagos> {
  // modalidad -> posicion -> controller
  static const _estructura = {
    'Q':  [1, 2, 3],
    'P':  [1, 2, 3],
    'T':  [1, 2, 3],
    'SP': [1],
  };

  static const _nombres = {
    'Q':  'Quiniela',
    'P':  'Pale',
    'T':  'Tripleta',
    'SP': 'Super Pale',
  };

  final Map<String, Map<int, TextEditingController>> _ctrls = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _estructura.forEach((mod, posiciones) {
      _ctrls[mod] = {};
      for (var pos in posiciones) {
        final pago = _getPago(mod, pos);
        _ctrls[mod]![pos] = TextEditingController(text: pago == 0 ? '' : pago.toString());
      }
    });
  }

  @override
  void dispose() {
    for (var m in _ctrls.values) {
      for (var c in m.values) c.dispose();
    }
    super.dispose();
  }

  double _getPago(String modalidad, int posicion) {
    try {
      return widget.esquema.detalle.firstWhere(
        (d) => d.modalidad == modalidad && d.posicion == posicion
      ).pago;
    } catch (_) { return 0; }
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    try {
      for (var entry in _ctrls.entries) {
        final mod = entry.key;
        for (var posEntry in entry.value.entries) {
          final pos = posEntry.key;
          final val = double.tryParse(posEntry.value.text) ?? 0;
          await EsquemasService.guardarMultiplicador(widget.esquema.id, mod, pos, val);
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Pagos actualizados")));
      }
      widget.onSaved();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ..._estructura.entries.map((entry) {
        final mod = entry.key;
        final posiciones = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_nombres[mod] ?? mod,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E), fontSize: 14)),
                const SizedBox(height: 8),
                for (var pos in posiciones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _ctrls[mod]![pos],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: posiciones.length > 1 ? "Posición $pos" : "Multiplicador",
                        border: const OutlineInputBorder(),
                        suffixText: "x",
                        isDense: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(15),
          ),
          onPressed: _saving ? null : _guardar,
          child: _saving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Guardar Pagos"),
        ),
      ),
    ]);
  }
}

// ── TAB 4: JORNADAS (HORARIOS) ──────────────────────────────────────────
class _TabJornadas extends StatefulWidget {
  const _TabJornadas();
  @override State<_TabJornadas> createState() => _TabJornadasState();
}

class _TabJornadasState extends State<_TabJornadas> {
  final _horaCtrl = TextEditingController();
  List<Map<String, dynamic>> _loterias = [];
  int _selIdx = 0;
  bool _loading = true;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    try {
      final h = await ConfiguracionService.obtenerHoraJornada();
      final l = await ConfiguracionService.obtenerLoterias();
      setState(() { _horaCtrl.text = h.toString(); _loterias = l; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _loading
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _horaCtrl,
            decoration: const InputDecoration(labelText: "Hora de Reinicio del Sistema (0-23)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time))
          ),
          const SizedBox(height: 20),
          if (_loterias.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: _selIdx,
              decoration: const InputDecoration(labelText: "Lotería Seleccionada", border: OutlineInputBorder()),
              items: List.generate(_loterias.length, (i) {
                final Map<String, dynamic> item = _loterias[i];
                return DropdownMenuItem(value: i, child: Text(item['nombre'] ?? 'Lotería'));
              }),
              onChanged: (v) => setState(() => _selIdx = v ?? 0),
            ),
            const SizedBox(height: 20),
            _LoteriaHorarioCard(key: ValueKey(_loterias[_selIdx]['id']), loteria: _loterias[_selIdx]),
          ]
        ]),
      );
}

class _LoteriaHorarioCard extends StatefulWidget {
  final Map<String, dynamic> loteria;
  const _LoteriaHorarioCard({super.key, required this.loteria});
  @override State<_LoteriaHorarioCard> createState() => _LoteriaHorarioCardState();
}

class _LoteriaHorarioCardState extends State<_LoteriaHorarioCard> {
  final Map<int, TextEditingController> _inicio = {};
  final Map<int, TextEditingController> _cierre = {};
  bool _loading = true;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final h = await ConfiguracionService.obtenerHorariosLoteria(widget.loteria['id'].toString());

    for (int d = 0; d < 7; d++) {
      _inicio[d] = TextEditingController();
      _cierre[d] = TextEditingController();
    }

    for (var row in h) {
      final dia = row['dia_semana'] as int?;
      if (dia != null && dia >= 0 && dia <= 6) {
        _inicio[dia]?.text = row['hora_inicio']?.toString().substring(0, 5) ?? '';
        _cierre[dia]?.text = row['hora_cierre']?.toString().substring(0, 5) ?? '';
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (var c in _inicio.values) c.dispose();
    for (var c in _cierre.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _loading
    ? const LinearProgressIndicator()
    : Column(children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text("Horarios semanales", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        ),
        const Divider(),
        for (int i = 0; i < 7; i++)
          _fila(i, ["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"][i]),
      ]);

  Widget _fila(int d, String n) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 90, child: Text(n, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      Expanded(child: TextField(controller: _inicio[d], textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "--:--", isDense: true, border: OutlineInputBorder()))),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("a")),
      Expanded(child: TextField(controller: _cierre[d], textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "--:--", isDense: true, border: OutlineInputBorder()))),
      const SizedBox(width: 8),
      IconButton(
        icon: const Icon(Icons.save, color: Color(0xFF1A237E), size: 22),
        onPressed: () async {
          await ConfiguracionService.guardarHorarioLoteria(
            loteriaId: widget.loteria['id'].toString(),
            diaSemana: d,
            horaInicio: _inicio[d]!.text,
            horaCierre: _cierre[d]!.text,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✓ Horario de $n guardado")));
          }
        }
      ),
    ]),
  );
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
    _tab = TabController(length: 4, vsync: this);
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
              Tab(icon: Icon(Icons.timer_outlined, size: 18), text: "Anulaciones"),
              Tab(icon: Icon(Icons.attach_money, size: 18), text: "Precios"),
              Tab(icon: Icon(Icons.emoji_events_outlined, size: 18), text: "Pagos"),
              Tab(icon: Icon(Icons.calendar_today, size: 18), text: "Jornadas"),
            ],
          ),
        ]),
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

// --- TAB 1: ANULACIONES ---
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
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Minutos para anular", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              if (_msg.isNotEmpty) Text(_msg, style: const TextStyle(color: Colors.green)),
              if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
              ElevatedButton(onPressed: _guardando ? null : _guardar, child: const Text("Guardar")),
            ]),
          ));
}

// --- TABS 2 y 3: ESQUEMAS ---
class _TabEsquema extends StatefulWidget {
  final String tipo;
  const _TabEsquema({required this.tipo});
  @override State<_TabEsquema> createState() => _TabEsquemaState();
}

class _TabEsquemaState extends State<_TabEsquema> {
  List<dynamic> _items = [];
  bool _loading = true;
  int _selIdx = 0;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      _items = widget.tipo == 'precios' 
        ? await EsquemasService.getEsquemasPrecios() 
        : await EsquemasService.getEsquemasPagos();
      setState(() => _loading = false);
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<int>(
          value: _selIdx,
          items: List.generate(_items.length, (i) => DropdownMenuItem(value: i, child: Text(_items[i].nombre))),
          onChanged: (v) => setState(() => _selIdx = v ?? 0),
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        ),
      ),
      Expanded(child: widget.tipo == 'precios' 
        ? _PreciosEditor(esquema: _items[_selIdx], onSaved: _cargar)
        : _PagosEditor(esquema: _items[_selIdx], onSaved: _cargar))
    ]);
  }
}

// --- EDITOR DE PRECIOS ---
class _PreciosEditor extends StatefulWidget {
  final dynamic esquema;
  final VoidCallback onSaved;
  const _PreciosEditor({required this.esquema, required this.onSaved});
  @override State<_PreciosEditor> createState() => _PreciosEditorState();
}

class _PreciosEditorState extends State<_PreciosEditor> {
  final Map<String, TextEditingController> _ctrls = {};
  final List<String> _mods = ['Q', 'P', 'T', 'SP'];

  @override
  void initState() {
    super.initState();
    for (var m in _mods) {
      double? val;
      try { val = widget.esquema.detalle.firstWhere((d) => d.modalidad == m && d.loteriaId == null).precio; } catch (_) {}
      _ctrls[m] = TextEditingController(text: val?.toString() ?? '');
    }
  }

  Future<void> _guardar() async {
    try {
      for (var m in _mods) {
        final val = double.tryParse(_ctrls[m]!.text) ?? 0.0;
        await EsquemasService.guardarPrecio(widget.esquema.id, m, val);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Guardado")));
      widget.onSaved();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      for (var m in _mods) TextField(controller: _ctrls[m], decoration: InputDecoration(labelText: "Precio $m")),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _guardar, child: const Text("Guardar Precios"))
    ]),
  );
}

// --- EDITOR DE PAGOS ---
class _PagosEditor extends StatefulWidget {
  final dynamic esquema;
  final VoidCallback onSaved;
  const _PagosEditor({required this.esquema, required this.onSaved});
  @override State<_PagosEditor> createState() => _PagosEditorState();
}

class _PagosEditorState extends State<_PagosEditor> {
  final Map<String, TextEditingController> _ctrls = {};
  final _estructura = {'Q': [1, 2, 3], 'P': [12, 13, 23], 'T': [2, 3], 'SP': [2]};

  @override
  void initState() {
    super.initState();
    _estructura.forEach((mod, posiciones) {
      for (var pos in posiciones) {
        double? val;
        try { val = widget.esquema.detalle.firstWhere((d) => d.modalidad == mod && d.posicion == pos && d.loteriaId == null).pago; } catch (_) {}
        _ctrls['${mod}_$pos'] = TextEditingController(text: val?.toString() ?? '');
      }
    });
  }

  Future<void> _guardar() async {
    try {
      for (var entry in _estructura.entries) {
        for (var pos in entry.value) {
          final val = double.tryParse(_ctrls['${entry.key}_$pos']!.text) ?? 0.0;
          await EsquemasService.guardarMultiplicador(widget.esquema.id, entry.key, pos, val);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Guardado")));
      widget.onSaved();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      for (var mod in _estructura.keys) ...[
        Text(mod, style: const TextStyle(fontWeight: FontWeight.bold)),
        for (var pos in _estructura[mod]!) TextField(controller: _ctrls['${mod}_$pos'], decoration: InputDecoration(labelText: "Pago Pos $pos")),
      ],
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _guardar, child: const Text("Guardar Pagos"))
    ]),
  );
}

// --- TAB 4: JORNADAS (HORARIOS) ---
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
    setState(() => _loading = true);
    try {
      final h = await ConfiguracionService.obtenerHoraJornada();
      _loterias = await ConfiguracionService.obtenerLoterias();
      _horaCtrl.text = h.toString();
      setState(() => _loading = false);
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => _loading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      TextField(controller: _horaCtrl, decoration: const InputDecoration(labelText: "Hora Generación (0-23)")),
      const SizedBox(height: 20),
      DropdownButtonFormField<int>(
        value: _selIdx,
        items: List.generate(_loterias.length, (i) => DropdownMenuItem(value: i, child: Text(_loterias[i]['nombre']))),
        onChanged: (v) => setState(() => _selIdx = v ?? 0),
        decoration: const InputDecoration(labelText: "Lotería", border: OutlineInputBorder()),
      ),
      const SizedBox(height: 12),
      if (_loterias.isNotEmpty) _LoteriaHorarioCard(loteria: _loterias[_selIdx], onSaved: _cargar),
    ]),
  );
}

class _LoteriaHorarioCard extends StatefulWidget {
  final Map<String, dynamic> loteria;
  final VoidCallback onSaved;
  const _LoteriaHorarioCard({required this.loteria, required this.onSaved});
  @override State<_LoteriaHorarioCard> createState() => _LoteriaHorarioCardState();
}

class _LoteriaHorarioCardState extends State<_LoteriaHorarioCard> {
  final Map<int?, TextEditingController> _inicio = {};
  final Map<int?, TextEditingController> _cierre = {};
  String _zona = 'America/Santo_Domingo';
  bool _cargando = true;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final id = widget.loteria['id'];
      final t = await ConfiguracionService.token();
      final r = await http.get(
        Uri.parse('https://superbett-api-production.up.railway.app/api/admin/loterias/$id/horarios'),
        headers: {'Authorization': 'Bearer $t'}
      );
      final rows = List<Map<String, dynamic>>.from(jsonDecode(r.body)['horarios'] ?? []);
      _zona = widget.loteria['zona_horaria'] ?? 'America/Santo_Domingo';
      for (var k in [null, 0, 1, 2, 3, 4, 5, 6]) {
        _inicio[k] = TextEditingController();
        _cierre[k] = TextEditingController();
      }
      for (var row in rows) {
        final d = row['dia_semana'];
        _inicio[d]?.text = row['hora_inicio']?.toString().substring(0, 5) ?? '';
        _cierre[d]?.text = row['hora_cierre']?.toString().substring(0, 5) ?? '';
      }
      setState(() => _cargando = false);
    } catch (e) { setState(() => _cargando = false); }
  }

  Future<void> _guardarDia(int? dia) async {
    try {
      final id = widget.loteria['id'];
      final t = await ConfiguracionService.token();
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'};
      
      // Error corregido: Ruta /zona
      await http.patch(
        Uri.parse('https://superbett-api-production.up.railway.app/api/admin/loterias/$id/zona'),
        headers: headers,
        body: jsonEncode({'zona_horaria': _zona})
      );

      // Error corregido: Ruta plural /horarios y método PUT
      final r = await http.put(
        Uri.parse('https://superbett-api-production.up.railway.app/api/admin/loterias/$id/horarios'),
        headers: headers,
        body: jsonEncode({
          'dia_semana': dia,
          'hora_inicio': _inicio[dia]!.text,
          'hora_cierre': _cierre[dia]!.text,
        })
      );

      if (r.statusCode == 200) widget.onSaved();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
  }

  @override
  Widget build(BuildContext context) => _cargando ? const CircularProgressIndicator() : Column(children: [
    for (int d = 0; d < 7; d++) Row(children: [
      Expanded(child: TextField(controller: _inicio[d], decoration: const InputDecoration(hintText: "Inicio"))),
      const Text("-"),
      Expanded(child: TextField(controller: _cierre[d], decoration: const InputDecoration(hintText: "Cierre"))),
      IconButton(icon: const Icon(Icons.save), onPressed: () => _guardarDia(d))
    ])
  ]);
}

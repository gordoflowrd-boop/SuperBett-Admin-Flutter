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
    if (i < rutas.length && rutas[i] != '/configuracion') {
      Navigator.pushReplacementNamed(context, rutas[i]);
    }
  }

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 7,
    onItemSelected: (i) => _onSelect(context, i),
    child: Column(children: [
      // ── Navbar con Tabs ────────────────────────
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
              Tab(icon: Icon(Icons.timer_outlined,       size: 18), text: "Anulaciones"),
              Tab(icon: Icon(Icons.attach_money,         size: 18), text: "Precios"),
              Tab(icon: Icon(Icons.emoji_events_outlined,size: 18), text: "Pagos"),
              Tab(icon: Icon(Icons.calendar_today,       size: 18), text: "Jornadas"),
            ],
          ),
        ]),
      ),

      // ── Contenido de Tabs ──────────────────────
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
    setState(() { _guardando = true; _msg = ''; _error = ''; });
    try {
      await ConfiguracionService.guardarConfiguracion({'tiempo_anulacion': m});
      setState(() { _guardando = false; _msg = '✓ Guardado correctamente'; });
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    "Tiempo máximo para anular un ticket desde que fue emitido. 0 = sin límite.",
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: "Tiempo límite de anulación",
                  suffixText: "minutos",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                for (final m in [0, 5, 10, 15, 30, 60])
                  ActionChip(
                    label: Text(m == 0 ? "Sin límite" : "$m min"),
                    onPressed: () => setState(() => _ctrl.text = m.toString()),
                  ),
              ]),
              const SizedBox(height: 24),
              if (_msg.isNotEmpty) _banner(_msg, true),
              if (_error.isNotEmpty) _banner(_error, false),
              SizedBox(width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? "Guardando..." : "Guardar Cambios"),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                )),
            ]),
          ));

  Widget _banner(String msg, bool ok) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: ok ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: ok ? Colors.green.shade300 : Colors.red.shade200)),
    child: Text(msg, style: TextStyle(color: ok ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold)));
}

// ═════════════════════════════════════════════
// TAB 2 y 3 — ESQUEMAS (Precios / Pagos)
// ═════════════════════════════════════════════
class _TabEsquema extends StatefulWidget {
  final String tipo; 
  const _TabEsquema({required this.tipo});
  @override State<_TabEsquema> createState() => _TabEsquemaState();
}

class _TabEsquemaState extends State<_TabEsquema> {
  List<EsquemaPrecio> _precios = [];
  List<EsquemaPago>   _pagos   = [];
  bool   _loading = true;
  String _error   = '';
  int    _selIdx  = 0;

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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final esquemas = _esPrecios ? _precios : _pagos;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: esquemas.isEmpty 
            ? const Text("No hay esquemas creados")
            : DropdownButtonFormField<int>(
                value: _selIdx,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: List.generate(esquemas.length, (i) => DropdownMenuItem(value: i, child: Text(esquemas[i].nombre))),
                onChanged: (v) => setState(() => _selIdx = v ?? 0),
              )),
          const SizedBox(width: 10),
          IconButton(onPressed: _cargar, icon: const Icon(Icons.refresh, color: Color(0xFF1A237E))),
        ]),
      ),
      Expanded(child: esquemas.isEmpty
        ? const Center(child: Text("Crea un esquema en la base de datos para continuar"))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _esPrecios 
              ? _PreciosEditor(esquema: _precios[_selIdx], onSaved: _cargar)
              : _PagosEditor(esquema: _pagos[_selIdx], onSaved: _cargar),
          )),
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
  final Map<String, TextEditingController> _ctrls = {};
  final _modalidades = ['Q', 'P', 'T', 'SP'];

  @override
  void initState() {
    super.initState();
    for (var m in _modalidades) {
      final p = widget.esquema.detalle.where((d) => d.modalidad == m && d.loteriaId == null);
      _ctrls[m] = TextEditingController(text: p.isNotEmpty ? p.first.precio.toString() : '');
    }
  }

  Future<void> _guardar() async {
    try {
      for (var m in _modalidades) {
        final val = double.tryParse(_ctrls[m]!.text) ?? 0.0;
        await EsquemasService.guardarPrecio(widget.esquema.id, m, val);
      }
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Precios actualizados")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    const SizedBox(height: 10),
    for (var m in _modalidades)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _ctrls[m],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "Precio $m", border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.money)),
        ),
      ),
    const SizedBox(height: 10),
    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _guardar, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white), child: const Text("Guardar Precios"))),
  ]);
}

// ─────────────────────────────────────────────
// Editor de PAGOS
// ─────────────────────────────────────────────
class _PagosEditor extends StatefulWidget {
  final EsquemaPago esquema;
  final VoidCallback onSaved;
  const _PagosEditor({required this.esquema, required this.onSaved});
  @override State<_PagosEditor> createState() => _PagosEditorState();
}

class _PagosEditorState extends State<_PagosEditor> {
  final Map<String, TextEditingController> _ctrls = {};
  final _estructura = {'Q': [1,2,3], 'P': [12,13,23], 'T': [2,3], 'SP': [2]};

  @override
  void initState() {
    super.initState();
    _estructura.forEach((mod, posiciones) {
      for (var pos in posiciones) {
        final key = '${mod}_$pos';
        final p = widget.esquema.detalle.where((d) => d.modalidad == mod && d.posicion == pos && d.loteriaId == null);
        _ctrls[key] = TextEditingController(text: p.isNotEmpty ? p.first.pago.toString() : '');
      }
    });
  }

  Future<void> _guardar() async {
    try {
      for (var key in _ctrls.keys) {
        final parts = key.split('_');
        final val = double.tryParse(_ctrls[key]!.text) ?? 0.0;
        await EsquemasService.guardarMultiplicador(widget.esquema.id, parts[0], int.parse(parts[1]), val);
      }
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Pagos actualizados")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    const SizedBox(height: 10),
    for (var mod in _estructura.keys) ...[
      Text("Modalidad $mod", style: const TextStyle(fontWeight: FontWeight.bold)),
      const Divider(),
      for (var pos in _estructura[mod]!)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextField(
            controller: _ctrls['${mod}_$pos'],
            decoration: InputDecoration(labelText: "Pago Pos $pos", border: const OutlineInputBorder(), isDense: true),
          ),
        ),
      const SizedBox(height: 15),
    ],
    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _guardar, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white), child: const Text("Guardar Multiplicadores"))),
  ]);
}

// ═════════════════════════════════════════════
// TAB 4 — JORNADAS (HORARIOS POR DÍA)
// ═════════════════════════════════════════════
class _TabJornadas extends StatefulWidget {
  const _TabJornadas();
  @override State<_TabJornadas> createState() => _TabJornadasState();
}

class _TabJornadasState extends State<_TabJornadas> {
  final _horaCtrl = TextEditingController();
  List<Map<String, dynamic>> _loterias = [];
  int _selIdx = 0;
  bool _loading = true, _guardando = false;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final h = await ConfiguracionService.obtenerHoraJornada();
      final l = await ConfiguracionService.obtenerLoterias();
      _horaCtrl.text = h.toString();
      setState(() { _loterias = l; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _loading 
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Generación Automática", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _horaCtrl, decoration: const InputDecoration(labelText: "Hora de reinicio (0-23)", border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _guardando ? null : () async {
                setState(() => _guardando = true);
                await ConfiguracionService.guardarConfiguracion({'hora_jornada': int.parse(_horaCtrl.text)});
                setState(() => _guardando = false);
              }, 
              child: const Text("Guardar"))
          ]),
          const SizedBox(height: 30),
          const Text("Horarios por Lotería", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const Divider(),
          if (_loterias.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: _selIdx,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: List.generate(_loterias.length, (i) => DropdownMenuItem(value: i, child: Text(_loterias[i]['nombre']))),
              onChanged: (v) => setState(() => _selIdx = v ?? 0),
            ),
            const SizedBox(height: 15),
            _LoteriaHorarioCard(loteria: _loterias[_selIdx]),
          ]
        ]),
      );
}

class _LoteriaHorarioCard extends StatefulWidget {
  final Map<String, dynamic> loteria;
  const _LoteriaHorarioCard({required this.loteria});
  @override State<_LoteriaHorarioCard> createState() => _LoteriaHorarioCardState();
}

class _LoteriaHorarioCardState extends State<_LoteriaHorarioCard> {
  final Map<int?, TextEditingController> _inicio = {};
  final Map<int?, TextEditingController> _cierre = {};
  bool _loading = true;

  @override void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final h = await ConfiguracionService.obtenerHorariosLoteria(widget.loteria['id']);
    
    // Inicializar controllers para los 7 días + Defecto (null)
    for (var d in [null, 0, 1, 2, 3, 4, 5, 6]) {
      _inicio[d] = TextEditingController();
      _cierre[d] = TextEditingController();
    }

    for (var row in h) {
      final dia = row['dia_semana'];
      _inicio[dia]?.text = row['hora_inicio'].toString().substring(0,5);
      _cierre[dia]?.text = row['hora_cierre'].toString().substring(0,5);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => _loading 
    ? const Center(child: LinearProgressIndicator())
    : Column(children: [
        _filaHorario(null, "Defecto"),
        const Divider(),
        for (int i=0; i<7; i++) _filaHorario(i, ["Dom","Lun","Mar","Mie","Jue","Vie","Sab"][i]),
      ]);

  Widget _filaHorario(int? dia, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 60, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
      Expanded(child: TextField(controller: _inicio[dia], decoration: const InputDecoration(hintText: "08:00", isDense: true, border: OutlineInputBorder()))),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Text("-")),
      Expanded(child: TextField(controller: _cierre[dia], decoration: const InputDecoration(hintText: "21:00", isDense: true, border: OutlineInputBorder()))),
      IconButton(
        onPressed: () async {
          await ConfiguracionService.guardarHorarioLoteria(
            loteriaId: widget.loteria['id'], 
            diaSemana: dia, 
            horaInicio: _inicio[dia]!.text, 
            horaCierre: _cierre[dia]!.text
          );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Horario $label guardado")));
        }, 
        icon: const Icon(Icons.save, size: 20, color: Color(0xFF1A237E)))
    ]),
  );
}

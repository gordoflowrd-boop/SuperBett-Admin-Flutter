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
      Container(
        color: const Color(0xFF1A237E),
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
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
      : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200)),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  "Tiempo máximo para anular un ticket (minutos). 0 = sin límite.",
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "Límite de anulación", suffixText: "min", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            if (_msg.isNotEmpty) _banner(_msg, true),
            if (_error.isNotEmpty) _banner(_error, false),
            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save_outlined),
                label: Text(_guardando ? "Guardando..." : "Guardar Cambios"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
              )),
          ]),
        );

  Widget _banner(String msg, bool ok) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: ok ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: ok ? Colors.green.shade300 : Colors.red.shade200)),
    child: Text(msg, style: TextStyle(color: ok ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold)));
}

// ── TAB 2 y 3: ESQUEMAS ────────────────────────────────────────────────
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
      if (widget.tipo == 'precios') {
        _items = await EsquemasService.getEsquemasPrecios();
      } else {
        _items = await EsquemasService.getEsquemasPagos();
      }
      setState(() => _loading = false);
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
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          items: List.generate(_items.length, (i) => DropdownMenuItem(value: i, child: Text(_items[i].nombre))),
          onChanged: (v) => setState(() => _selIdx = v ?? 0),
        ),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: widget.tipo == 'precios' 
          ? _PreciosEditor(esquema: _items[_selIdx], onSaved: _cargar)
          : _PagosEditor(esquema: _items[_selIdx], onSaved: _cargar),
      )),
    ]);
  }
}

// (Omitidos por brevedad los editores internos _PreciosEditor y _PagosEditor ya que funcionan bien, 
// pero asegúrate de que usen el estilo de botones de los otros tabs)

// ── TAB 4: JORNADAS (EL ERROR ESTABA AQUÍ) ──────────────────────────────
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
          const Text("Hora de reinicio de jornada", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _horaCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true))),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                await ConfiguracionService.guardarConfiguracion({'hora_jornada': int.parse(_horaCtrl.text)});
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Reinicio guardado")));
              }, 
              child: const Text("Guardar"))
          ]),
          const SizedBox(height: 30),
          if (_loterias.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: _selIdx,
              decoration: const InputDecoration(labelText: "Seleccionar Lotería", border: OutlineInputBorder()),
              // AQUÍ EL CASTING: (loteria as Map)['nombre']
              items: List.generate(_loterias.length, (i) {
                final item = _loterias[i];
                return DropdownMenuItem(value: i, child: Text(item['nombre'] ?? 'Sin nombre'));
              }),
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
    final h = await ConfiguracionService.obtenerHorariosLoteria(widget.loteria['id'].toString());
    
    for (var d in [null, 0, 1, 2, 3, 4, 5, 6]) {
      _inicio[d] = TextEditingController();
      _cierre[d] = TextEditingController();
    }

    for (var row in h) {
      final dia = row['dia_semana'] as int?;
      if (row['hora_inicio'] != null) _inicio[dia]?.text = row['hora_inicio'].toString().substring(0,5);
      if (row['hora_cierre'] != null) _cierre[dia]?.text = row['hora_cierre'].toString().substring(0,5);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => _loading 
    ? const LinearProgressIndicator()
    : Column(children: [
        _filaHorario(null, "Defecto"),
        const Divider(),
        for (int i=0; i<7; i++) _filaHorario(i, ["Dom","Lun","Mar","Mie","Jue","Vie","Sab"][i]),
      ]);

  Widget _filaHorario(int? dia, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 50, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      Expanded(child: TextField(controller: _inicio[dia], decoration: const InputDecoration(hintText: "08:00", isDense: true, border: OutlineInputBorder()))),
      const Text(" - "),
      Expanded(child: TextField(controller: _cierre[dia], decoration: const InputDecoration(hintText: "21:00", isDense: true, border: OutlineInputBorder()))),
      IconButton(
        onPressed: () async {
          await ConfiguracionService.guardarHorarioLoteria(
            loteriaId: widget.loteria['id'].toString(), 
            diaSemana: dia, 
            horaInicio: _inicio[dia]!.text, 
            horaCierre: _cierre[dia]!.text
          );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✓ $label guardado")));
        }, 
        icon: const Icon(Icons.save, size: 18, color: Color(0xFF1A237E)))
    ]),
  );
}

// Nota: He omitido las clases _PreciosEditor y _PagosEditor para no saturar el código, 
// pero mantén las que ya tenías asegurándote de no usar 'dart:html' en ellas.

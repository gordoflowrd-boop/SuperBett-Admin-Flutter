import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../layout/app_layout.dart';
import '../services/configuracion_service.dart';

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
          Center(child: Text("Módulo de Precios")),
          Center(child: Text("Módulo de Pagos")),
          _TabJornadas(),
        ],
      )),
    ]),
  );
}

class _TabAnulacion extends StatefulWidget {
  const _TabAnulacion();
  @override State<_TabAnulacion> createState() => _TabAnulacionState();
}

class _TabAnulacionState extends State<_TabAnulacion> {
  final _ctrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final t = await ConfiguracionService.obtenerTiempoAnulacion();
    setState(() { _ctrl.text = t.toString(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) => _loading 
    ? const Center(child: CircularProgressIndicator())
    : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _ctrl, decoration: const InputDecoration(labelText: "Minutos para anular", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await ConfiguracionService.guardarConfiguracion({'tiempo_anulacion': int.parse(_ctrl.text)});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardado")));
            },
            child: const Text("Guardar"),
          )
        ]),
      );
}

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
    final h = await ConfiguracionService.obtenerHoraJornada();
    final l = await ConfiguracionService.obtenerLoterias();
    setState(() { _horaCtrl.text = h.toString(); _loterias = l; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => _loading 
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _horaCtrl, decoration: const InputDecoration(labelText: "Hora Reinicio (0-23)", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          if (_loterias.isNotEmpty) ...[
            DropdownButtonFormField<int>(
              value: _selIdx,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: List.generate(_loterias.length, (i) {
                // AQUÍ EL FIX: Forzamos a Map<String, dynamic>
                final Map<String, dynamic> item = _loterias[i];
                return DropdownMenuItem(value: i, child: Text(item['nombre'] ?? 'Sin nombre'));
              }),
              onChanged: (v) => setState(() => _selIdx = v ?? 0),
            ),
            const SizedBox(height: 20),
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
  @override void didUpdateWidget(_LoteriaHorarioCard old) { super.didUpdateWidget(old); _cargar(); }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final h = await ConfiguracionService.obtenerHorariosLoteria(widget.loteria['id'].toString());
    for (var d in [null, 0, 1, 2, 3, 4, 5, 6]) {
      _inicio[d] = TextEditingController();
      _cierre[d] = TextEditingController();
    }
    for (var row in h) {
      final dia = row['dia_semana'] as int?;
      _inicio[dia]?.text = row['hora_inicio']?.toString().substring(0,5) ?? '';
      _cierre[dia]?.text = row['hora_cierre']?.toString().substring(0,5) ?? '';
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => _loading ? const LinearProgressIndicator() : Column(
    children: [
      _fila(null, "Base"),
      for(int i=0; i<7; i++) _fila(i, ["Dom","Lun","Mar","Mie","Jue","Vie","Sab"][i]),
    ],
  );

  Widget _fila(int? d, String n) => Row(children: [
    SizedBox(width: 50, child: Text(n)),
    Expanded(child: TextField(controller: _inicio[d])),
    const Text(" - "),
    Expanded(child: TextField(controller: _cierre[d])),
    IconButton(icon: const Icon(Icons.save), onPressed: () async {
      await ConfiguracionService.guardarHorarioLoteria(
        loteriaId: widget.loteria['id'].toString(),
        diaSemana: d,
        horaInicio: _inicio[d]!.text,
        horaCierre: _cierre[d]!.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardado")));
    }),
  ]);
}

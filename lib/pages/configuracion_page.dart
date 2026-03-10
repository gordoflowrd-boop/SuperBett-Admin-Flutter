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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Tiempo de anulación actualizado")));
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
          decoration: const InputDecoration(labelText: "Seleccionar Esquema", border: OutlineInputBorder()),
          items: List.generate(_items.length, (i) => DropdownMenuItem(value: i, child: Text(_items[i].nombre))),
          onChanged: (v) => setState(() => _selIdx = v ?? 0),
        ),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: widget.tipo == 'precios' 
          ? _EditorPrecios(esquema: _items[_selIdx], onSaved: _cargar)
          : _EditorPagos(esquema: _items[_selIdx], onSaved: _cargar),
      )),
    ]);
  }
}

class _EditorPrecios extends StatelessWidget {
  final dynamic esquema;
  final VoidCallback onSaved;
  const _EditorPrecios({required this.esquema, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    final modalidades = ['Q', 'P', 'T', 'SP'];
    return Column(children: [
      for (var m in modalidades) 
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Precio $m", border: const OutlineInputBorder()),
            controller: TextEditingController(text: esquema.getPrecio(m).toString()),
          ),
        ),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onSaved, child: const Text("Actualizar Precios")))
    ]);
  }
}

class _EditorPagos extends StatelessWidget {
  final dynamic esquema;
  final VoidCallback onSaved;
  const _EditorPagos({required this.esquema, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Text("Configuración de multiplicadores de pago"),
      const SizedBox(height: 15),
      TextField(
        decoration: const InputDecoration(labelText: "Pago Quiniela 1ra", border: OutlineInputBorder()),
        controller: TextEditingController(text: esquema.getPago('Q', 1).toString()),
      ),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onSaved, child: const Text("Actualizar Pagos")))
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
  // Solo manejamos los días 0 al 6 (Dom a Sab)
  final Map<int, TextEditingController> _inicio = {};
  final Map<int, TextEditingController> _cierre = {};
  bool _loading = true;

  @override void initState() { super.initState(); _cargar(); }
  @override void didUpdateWidget(_LoteriaHorarioCard old) { 
    super.didUpdateWidget(old); 
    if(old.loteria['id'] != widget.loteria['id']) _cargar(); 
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final h = await ConfiguracionService.obtenerHorariosLoteria(widget.loteria['id'].toString());
    
    // Inicializar controladores para los 7 días
    for (int d = 0; d < 7; d++) {
      _inicio[d] = TextEditingController();
      _cierre[d] = TextEditingController();
    }

    // Llenar solo los días que existen en la base de datos
    for (var row in h) {
      final dia = row['dia_semana'] as int?;
      if (dia != null && dia >= 0 && dia <= 6) {
        _inicio[dia]?.text = row['hora_inicio']?.toString().substring(0,5) ?? '';
        _cierre[dia]?.text = row['hora_cierre']?.toString().substring(0,5) ?? '';
      }
    }
    setState(() => _loading = false);
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
        // Solo mostramos del 0 al 6
        for(int i=0; i<7; i++) _fila(i, ["Domingo","Lunes","Martes","Miércoles","Jueves","Viernes","Sábado"][i]),
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
            diaSemana: d, // Enviamos el día del 0 al 6
            horaInicio: _inicio[d]!.text,
            horaCierre: _cierre[d]!.text,
          );
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✓ Horario de $n guardado")));
        }
      ),
    ]),
  );
}

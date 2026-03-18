import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AppLayout(
    selectedIndex: 9,
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
          const _TabCentral(),
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
  // key: "MODALIDAD_POSICION" -> controller
  final Map<String, TextEditingController> _ctrls = {};
  bool _saving = false;

  static const _nombres = {
    'Q':  'Quiniela',
    'P':  'Pale',
    'T':  'Tripleta',
    'SP': 'Super Pale',
  };

  @override
  void initState() {
    super.initState();
    // Construir controllers dinámicamente desde lo que devuelve el API
    for (var d in widget.esquema.detalle) {
      final key = '${d.modalidad}_${d.posicion}';
      _ctrls[key] = TextEditingController(text: d.pago == 0 ? '' : d.pago.toString());
    }
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) c.dispose();
    super.dispose();
  }

  // Agrupar detalle por modalidad manteniendo orden Q, P, T, SP
  Map<String, List<DetallePago>> _agrupar() {
    final orden = ['Q', 'P', 'T', 'SP'];
    final Map<String, List<DetallePago>> grupos = {};
    for (var d in widget.esquema.detalle) {
      grupos.putIfAbsent(d.modalidad, () => []).add(d);
    }
    // Ordenar posiciones dentro de cada grupo
    for (var lista in grupos.values) {
      lista.sort((a, b) => a.posicion.compareTo(b.posicion));
    }
    // Devolver en orden conocido primero, luego el resto
    final result = <String, List<DetallePago>>{};
    for (var mod in orden) {
      if (grupos.containsKey(mod)) result[mod] = grupos[mod]!;
    }
    for (var entry in grupos.entries) {
      if (!result.containsKey(entry.key)) result[entry.key] = entry.value;
    }
    return result;
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    try {
      for (var d in widget.esquema.detalle) {
        final key = '${d.modalidad}_${d.posicion}';
        final val = double.tryParse(_ctrls[key]?.text ?? '') ?? 0;
        await EsquemasService.guardarMultiplicador(widget.esquema.id, d.modalidad, d.posicion, val);
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
    final grupos = _agrupar();

    if (grupos.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: Text("No hay datos de pagos configurados"),
      ));
    }

    return Column(children: [
      ...grupos.entries.map((entry) {
        final mod = entry.key;
        final items = entry.value;
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
                for (var d in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _ctrls['${d.modalidad}_${d.posicion}'],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: items.length > 1 ? "Posición ${d.posicion}" : "Multiplicador",
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
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: "Hora de Reinicio del Sistema (0-23)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
              onPressed: () async {
                final hora = int.tryParse(_horaCtrl.text) ?? -1;
                if (hora < 0 || hora > 23) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La hora debe estar entre 0 y 23")));
                  return;
                }
                await ConfiguracionService.guardarConfiguracion({'hora_jornada': hora});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✓ Hora de reinicio guardada")));
                }
              },
              child: const Text("Guardar Hora de Reinicio"),
            ),
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

// ═════════════════════════════════════════════
// TAB 5 — CENTRAL
// ═════════════════════════════════════════════
class _TabCentral extends StatefulWidget {
  const _TabCentral();
  @override State<_TabCentral> createState() => _TabCentralState();
}

class _TabCentralState extends State<_TabCentral> {
  final _nomCtrl     = TextEditingController();
  final _msgCtrl     = TextEditingController();
  final _headerCtrl  = TextEditingController();
  final _footerCtrl  = TextEditingController();

  bool   _loading   = true;
  bool   _guardando = false;
  String _msg2      = '';
  String _error     = '';

  static const _kApi = 'https://superbett-api-production.up.railway.app/api';

  @override
  void initState() { super.initState(); _cargar(); }

  @override
  void dispose() {
    _nomCtrl.dispose(); _msgCtrl.dispose();
    _headerCtrl.dispose(); _footerCtrl.dispose();
    super.dispose();
  }

  Future<String> _token() async =>
      html.window.localStorage['token'] ?? '';

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final t = await _token();
      final r = await http.get(
        Uri.parse('$_kApi/admin/central-config'),
        headers: {'Authorization': 'Bearer $t'},
      );
      final data = jsonDecode(r.body)['config'] as Map<String, dynamic>;
      _nomCtrl.text    = data['nombre_central'] ?? '';
      _msgCtrl.text    = data['mensaje_login']  ?? '';
      _headerCtrl.text = data['ticket_header']  ?? '';
      _footerCtrl.text = data['ticket_footer']  ?? '';
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _guardar() async {
    setState(() { _guardando = true; _msg2 = ''; _error = ''; });
    try {
      final t = await _token();
      final r = await http.put(
        Uri.parse('$_kApi/admin/central-config'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'},
        body: jsonEncode({
          'nombre_central': _nomCtrl.text.trim(),
          'mensaje_login':  _msgCtrl.text.trim(),
          'ticket_header':  _headerCtrl.text.trim(),
          'ticket_footer':  _footerCtrl.text.trim(),
        }),
      );
      if (r.statusCode == 200) {
        setState(() { _guardando = false; _msg2 = '✓ Guardado'; });
      } else {
        throw Exception(jsonDecode(r.body)['error'] ?? 'Error');
      }
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
            _campo('Nombre de la central', _nomCtrl,
                hint: 'Ej: Consorcio Ejemplo', icon: Icons.business_outlined),
            const SizedBox(height: 14),

            _campo('Mensaje en login', _msgCtrl,
                hint: 'Sistema exclusivo para...', icon: Icons.message_outlined,
                maxLines: 2),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200)),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text('Los textos del ticket se muestran en cada impresión.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800))),
              ]),
            ),
            const SizedBox(height: 14),

            _campo('Encabezado del ticket', _headerCtrl,
                hint: 'Texto que aparece arriba del ticket',
                icon: Icons.vertical_align_top, maxLines: 2),
            const SizedBox(height: 14),

            _campo('Pie del ticket', _footerCtrl,
                hint: 'Texto que aparece abajo del ticket',
                icon: Icons.vertical_align_bottom, maxLines: 2),
            const SizedBox(height: 24),

            if (_msg2.isNotEmpty) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_msg2, style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold))),
            if (_error.isNotEmpty) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error, style: const TextStyle(color: Colors.red))),

            SizedBox(width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(_guardando ? 'Guardando...' : 'Guardar'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14)),
              )),
          ]),
        ));

  Widget _campo(String label, TextEditingController ctrl,
      {String hint = '', IconData icon = Icons.text_fields, int maxLines = 1}) =>
    TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
}

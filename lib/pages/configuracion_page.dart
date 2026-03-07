import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../layout/app_layout.dart';
import '../services/configuracion_service.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});
  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final _tiempoCtrl = TextEditingController();

  bool   _loading   = true;
  bool   _guardando = false;
  String _error     = "";
  String _msg       = "";

  @override
  void initState() { super.initState(); _cargar(); }

  @override
  void dispose() { _tiempoCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ""; _msg = ""; });
    try {
      final t = await ConfiguracionService.obtenerTiempoAnulacion();
      _tiempoCtrl.text = t.toString();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _guardar() async {
    final minutos = int.tryParse(_tiempoCtrl.text.trim()) ?? 0;
    if (minutos < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El tiempo no puede ser negativo"),
            backgroundColor: Colors.red));
      return;
    }
    setState(() { _guardando = true; _msg = ""; _error = ""; });
    try {
      await ConfiguracionService.guardarTiempoAnulacion(minutos);
      setState(() { _guardando = false; _msg = "✓ Configuración guardada"; });
    } catch (e) {
      setState(() { _guardando = false; _error = e.toString(); });
    }
  }

  void _onSelect(BuildContext context, int i) {
    const rutas = [
      '/menu', '/bancas', '/venta', '/premios',
      '/reportes', '/usuarios', '/limites', '/configuracion',
    ];
    if (i < rutas.length && rutas[i] != '/configuracion')
      Navigator.pushReplacementNamed(context, rutas[i]);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 7,
      onItemSelected: (i) => _onSelect(context, i),
      child: Column(children: [

        // ── Navbar ────────────────────────────────────
        Container(
          color: const Color(0xFF1A237E),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: const Row(children: [
            Expanded(child: Text("Configuración",
                style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.bold))),
            Icon(Icons.settings_outlined, color: Colors.white, size: 20),
          ]),
        ),

        // ── Contenido ─────────────────────────────────
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Título sección ────────────────
                  Row(children: const [
                    Icon(Icons.cancel_outlined, color: Color(0xFF1A237E), size: 20),
                    SizedBox(width: 8),
                    Text("Anulaciones",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E))),
                    SizedBox(width: 8),
                    Expanded(child: Divider(color: Color(0xFF1A237E))),
                  ]),
                  const SizedBox(height: 12),

                  // ── Info ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        "Tiempo máximo que tiene el vendedor para anular un ticket "
                        "desde que fue emitido.\nColoca 0 para no aplicar límite.",
                        style: TextStyle(color: Colors.blue.shade800, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Campo minutos ─────────────────
                  TextField(
                    controller: _tiempoCtrl,
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

                  // ── Chips rápidos ─────────────────
                  Wrap(spacing: 8, children: [
                    for (final min in [0, 2, 5, 10, 15, 30])
                      ActionChip(
                        label: Text(min == 0 ? "Sin límite" : "$min min"),
                        backgroundColor: _tiempoCtrl.text == min.toString()
                            ? const Color(0xFF1A237E)
                            : Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: _tiempoCtrl.text == min.toString()
                              ? Colors.white : Colors.black87,
                          fontWeight: _tiempoCtrl.text == min.toString()
                              ? FontWeight.bold : FontWeight.normal),
                        onPressed: () =>
                            setState(() => _tiempoCtrl.text = min.toString()),
                      ),
                  ]),
                  const SizedBox(height: 28),

                  // ── Mensaje éxito / error ─────────
                  if (_msg.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300)),
                      child: Row(children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                      ] + [Text(_msg, style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold))])),

                  if (_error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200)),
                      child: Text(_error,
                          style: const TextStyle(color: Colors.red))),

                  // ── Botón guardar ─────────────────
                  SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                      label: Text(_guardando ? "Guardando..." : "Guardar Configuración"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    )),
                ]),
              ))),
      ]),
    );
  }
}

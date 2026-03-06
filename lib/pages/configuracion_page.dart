import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../layout/app_layout.dart';
import '../helpers.dart';

class ConfiguracionPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;
  const ConfiguracionPage({
    super.key,
    required this.userData,
    required this.token,
  });
  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final _tiempoCtrl       = TextEditingController();
  final _nombreCtrl       = TextEditingController();
  final _nombreTicketCtrl = TextEditingController();

  bool   _loading   = true;
  bool   _guardando = false;
  String _error     = "";
  String _msg       = "";

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _tiempoCtrl.dispose();
    _nombreCtrl.dispose();
    _nombreTicketCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = ""; _msg = ""; });
    try {
      final cfg   = await apiFetch('/bancas/config', widget.token);
      final banca = cfg['banca'] as Map? ?? {};
      _tiempoCtrl.text = banca['tiempo_anulacion']?.toString() ?? '0';
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _guardar() async {
    final tiempo = int.tryParse(_tiempoCtrl.text.trim()) ?? 0;
    if (tiempo < 0) {
      snack(context, "El tiempo no puede ser negativo", bg: Colors.red);
      return;
    }
    setState(() { _guardando = true; _msg = ""; _error = ""; });
    try {
      await apiFetch('/bancas/config/tiempo-anulacion', widget.token,
        method: "PUT",
        body: { "tiempo_anulacion": tiempo },
      );
      setState(() { _guardando = false; _msg = "✓ Configuración guardada correctamente"; });
    } catch (e) {
      setState(() { _guardando = false; _error = e.toString(); });
    }
  }

  void _onSelect(BuildContext context, int i) {
    const rutas = [
      '/menu', '/bancas', '/premios', '/reportes',
      '/usuarios', '/limites', '/configuracion',
    ];
    if (rutas[i] != '/configuracion')
      Navigator.pushReplacementNamed(context, rutas[i]);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      selectedIndex: 6,
      onItemSelected: (i) => _onSelect(context, i),
      child: Column(children: [

        // ── Navbar azul ──────────────────────────────
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

        // ── Contenido ────────────────────────────────
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ══ Sección: Anulaciones ══════════
                  _titulo(Icons.cancel_outlined, "Anulaciones"),
                  const SizedBox(height: 10),

                  // Card informativa
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
                        "desde que fue emitido.\n"
                        "Coloca 0 para no aplicar límite.",
                        style: TextStyle(color: Colors.blue.shade800, fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // Campo minutos
                  TextField(
                    controller: _tiempoCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Tiempo límite de anulación",
                      hintText:  "Minutos — 0 significa sin límite",
                      prefixIcon: Icon(Icons.timer_outlined),
                      suffixText: "min",
                      border: OutlineInputBorder(),
                      helperText: "Ej: 5 = el vendedor tiene 5 minutos para anular",
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Chips de acceso rápido
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    for (final min in [0, 2, 5, 10, 15, 30])
                      ActionChip(
                        avatar: Icon(
                          min == 0 ? Icons.all_inclusive : Icons.timer,
                          size: 16,
                          color: _tiempoCtrl.text == min.toString()
                              ? Colors.white : const Color(0xFF1A237E)),
                        label: Text(
                          min == 0 ? "Sin límite" : "$min min",
                          style: TextStyle(
                            color: _tiempoCtrl.text == min.toString()
                                ? Colors.white : Colors.black87,
                            fontWeight: _tiempoCtrl.text == min.toString()
                                ? FontWeight.bold : FontWeight.normal)),
                        backgroundColor: _tiempoCtrl.text == min.toString()
                            ? const Color(0xFF1A237E) : Colors.grey.shade100,
                        onPressed: () =>
                            setState(() => _tiempoCtrl.text = min.toString()),
                      ),
                  ]),

                  const SizedBox(height: 28),

                  // ══ Mensajes ══════════════════════
                  if (_msg.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300)),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_msg,
                            style: const TextStyle(
                                color: Colors.green, fontWeight: FontWeight.bold))),
                      ])),

                  if (_error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200)),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error,
                            style: const TextStyle(color: Colors.red))),
                      ])),

                  // ══ Botón Guardar ═════════════════
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                      label: Text(
                        _guardando ? "Guardando..." : "Guardar Configuración"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                        disabledBackgroundColor: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            )),
      ]),
    );
  }

  // ── Helpers UI ────────────────────────────────────
  Widget _titulo(IconData icon, String texto) => Row(children: [
    Icon(icon, color: const Color(0xFF1A237E), size: 20),
    const SizedBox(width: 8),
    Text(texto, style: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
    const SizedBox(width: 10),
    const Expanded(child: Divider(color: Color(0xFF1A237E))),
  ]);

  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icono,
  }) =>
    TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText:  hint,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
      ),
    );
}

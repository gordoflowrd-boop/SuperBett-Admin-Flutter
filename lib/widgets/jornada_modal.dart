import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/jornada.dart';
import '../services/premios_service.dart';

class JornadaModal extends StatefulWidget {
  final Jornada jornada;
  const JornadaModal({super.key, required this.jornada});

  @override
  State<JornadaModal> createState() => _JornadaModalState();
}

class _JornadaModalState extends State<JornadaModal> {
  // Controladores horario
  final _q1Ctrl = TextEditingController();
  final _q2Ctrl = TextEditingController();
  final _q3Ctrl = TextEditingController();

  late String  _estado;
  TimeOfDay?   _horaInicio;
  TimeOfDay?   _horaCierre;

  String _msg      = "";
  Color  _msgColor = Colors.grey;
  bool   _guardandoHorario = false;
  bool   _cambiandoEstado  = false;
  bool   _activandoPremio  = false;
  bool   _premioYaActivado = false;

  @override
  void initState() {
    super.initState();
    final j = widget.jornada;
    _estado          = j.estado;
    _premioYaActivado = j.q1 != null && j.q1!.isNotEmpty;
    _q1Ctrl.text = j.q1 ?? '';
    _q2Ctrl.text = j.q2 ?? '';
    _q3Ctrl.text = j.q3 ?? '';
    _horaInicio = _parseTime(j.horaInicio);
    _horaCierre = _parseTime(j.horaCierre);
  }

  @override
  void dispose() {
    _q1Ctrl.dispose(); _q2Ctrl.dispose(); _q3Ctrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? t) {
    if (t == null || t.isEmpty) return null;
    final parts = t.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h  = t.hour;
    final mm = t.minute.toString().padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$mm ${h >= 12 ? "PM" : "AM"}';
  }

  String _timeToStr(TimeOfDay? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  }

  void _setMsg(String msg, Color color) => setState(() { _msg = msg; _msgColor = color; });

  // ── Cambiar estado ──────────────────────────────────
  Future<void> _cambiarEstado(String nuevo) async {
    setState(() { _cambiandoEstado = true; _msg = "Actualizando..."; _msgColor = Colors.grey; });
    try {
      await PremiosService.cambiarEstado(widget.jornada.id, nuevo);
      setState(() { _estado = nuevo; });
      _setMsg('Estado cambiado a "$nuevo" ✓', Colors.green);
    } catch (e) { _setMsg('Error: $e', Colors.red); }
    finally { setState(() => _cambiandoEstado = false); }
  }

  // ── Guardar horario ─────────────────────────────────
  Future<void> _guardarHorario() async {
    setState(() { _guardandoHorario = true; });
    _setMsg("Guardando horario...", Colors.grey);
    try {
      await PremiosService.guardarHorario(
          widget.jornada.id, _timeToStr(_horaInicio), _timeToStr(_horaCierre));
      _setMsg("Horario guardado ✓", Colors.green);
    } catch (e) { _setMsg('Error: $e', Colors.red); }
    finally { setState(() => _guardandoHorario = false); }
  }

  // ── Activar premio ──────────────────────────────────
  Future<void> _activarPremio() async {
    final q1 = _q1Ctrl.text.trim();
    if (q1.isEmpty) { _setMsg("Q1 es obligatorio", Colors.red); return; }
    setState(() => _activandoPremio = true);
    _setMsg("Registrando premio...", Colors.grey);
    try {
      final ganadores = await PremiosService.activarPremio(
          widget.jornada.id, q1, _q2Ctrl.text.trim(), _q3Ctrl.text.trim());
      setState(() => _premioYaActivado = true);
      _setMsg("✅ Premio activado — $ganadores ganador(es)", Colors.green);
    } catch (e) { _setMsg('Error: $e', Colors.red); }
    finally { setState(() => _activandoPremio = false); }
  }

  // ── Selector de hora ────────────────────────────────
  Future<void> _pickTime(bool esInicio) async {
    final initial = esInicio ? (_horaInicio ?? TimeOfDay.now()) : (_horaCierre ?? TimeOfDay.now());
    final picked  = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() { if (esInicio) _horaInicio = picked; else _horaCierre = picked; });
  }

  // ── Badge de estado ─────────────────────────────────
  Widget _badge(String estado) {
    late Color bg; late Color fg;
    switch (estado) {
      case 'abierto':    bg = const Color(0xFFD4EDDA); fg = const Color(0xFF155724); break;
      case 'cerrado':    bg = const Color(0xFFF8D7DA); fg = const Color(0xFF721C24); break;
      case 'completado': bg = const Color(0xFFCCE5FF); fg = const Color(0xFF004085); break;
      default:           bg = const Color(0xFFE2E3E5); fg = const Color(0xFF383D41);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(estado, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13)));
  }

  // ── Campo Q ─────────────────────────────────────────
  Widget _campoQ(String label, TextEditingController ctrl) => Row(children: [
    SizedBox(width: 30, child: Text(label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
    const SizedBox(width: 8),
    Expanded(child: TextField(
      controller: ctrl,
      enabled: !_premioYaActivado,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 2,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        counterText: "",
        hintText: "--",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        filled: _premioYaActivado,
        fillColor: Colors.grey.shade100,
      ),
    )),
  ]);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(children: [
              const Icon(Icons.access_time, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text("Jornada — ${widget.jornada.loteria ?? '-'}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
              _badge(_estado),
            ]),
          ),

          // ── Cuerpo scrollable
          Flexible(child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── HORARIO ──────────────────────────────
              _seccionTitulo("⏰ Horario"),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _horaCampo("Hora inicio", _horaInicio, () => _pickTime(true))),
                const SizedBox(width: 10),
                Expanded(child: _horaCampo("Hora cierre", _horaCierre, () => _pickTime(false))),
              ]),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: _guardandoHorario ? null : _guardarHorario,
                icon: _guardandoHorario
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 17),
                label: const Text("Guardar horario"),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
              )),

              const SizedBox(height: 16),
              const Divider(),

              // ── ESTADO ───────────────────────────────
              _seccionTitulo("🔄 Estado"),
              const SizedBox(height: 10),
              if (_cambiandoEstado)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (_estado != 'abierto')
                    _estadoBtn("✅ Abrir venta", const Color(0xFF28A745), () => _cambiarEstado('abierto')),
                  if (_estado == 'abierto')
                    _estadoBtn("🔒 Cerrar venta", const Color(0xFFDC3545), () => _cambiarEstado('cerrado')),
                  if (_estado == 'cerrado')
                    _estadoBtn("✔ Marcar completado", const Color(0xFF0D6EFD), () => _cambiarEstado('completado')),
                ]),

              const SizedBox(height: 16),
              const Divider(),

              // ── PREMIOS ──────────────────────────────
              _seccionTitulo("🏆 Números premiados"),
              const SizedBox(height: 10),
              _campoQ("Q1", _q1Ctrl),
              const SizedBox(height: 8),
              _campoQ("Q2", _q2Ctrl),
              const SizedBox(height: 8),
              _campoQ("Q3", _q3Ctrl),
              const SizedBox(height: 12),

              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: (_premioYaActivado || _activandoPremio) ? null : _activarPremio,
                icon: _activandoPremio
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_premioYaActivado ? Icons.check_circle : Icons.emoji_events, size: 18),
                label: Text(_premioYaActivado ? "✅ Premio ya activado" : "🏆 Activar Premio",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _premioYaActivado ? Colors.grey : const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              )),

              // ── Mensaje
              if (_msg.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _msgColor == Colors.green ? const Color(0xFFD4EDDA)
                        : _msgColor == Colors.red    ? const Color(0xFFF8D7DA)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(_msgColor == Colors.green ? Icons.check_circle
                        : _msgColor == Colors.red  ? Icons.error_outline
                        : Icons.info_outline,
                        color: _msgColor, size: 17),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_msg, style: TextStyle(color: _msgColor, fontWeight: FontWeight.w500, fontSize: 13))),
                  ]),
                ),
              ],
            ]),
          )),

          // ── Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 17),
                label: const Text("Cerrar"),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _seccionTitulo(String t) => Text(t,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF555555)));

  Widget _horaCampo(String label, TimeOfDay? time, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Text(_fmtTime(time), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ]),
    ),
  );

  Widget _estadoBtn(String label, Color color, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)));
}

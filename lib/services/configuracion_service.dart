import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracionService {
  static const String apiBase = 'https://superbett-api-production.up.railway.app/api';

  static Future<String> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  static Map<String, String> _headers(String t) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $t',
  };

  static Future<Map<String, String>> obtenerConfiguracion() async {
    final t = await token();
    final r = await http.get(Uri.parse('$apiBase/admin/configuracion'), headers: _headers(t));
    if (r.statusCode != 200) throw Exception('Error al leer configuración');
    final data = jsonDecode(r.body);
    final Map<String, String> result = {};
    if (data['config'] != null) {
      (data['config'] as Map<String, dynamic>).forEach((k, v) => result[k] = v?.toString() ?? '');
    }
    return result;
  }

  static Future<int> obtenerTiempoAnulacion() async {
    final cfg = await obtenerConfiguracion();
    return int.tryParse(cfg['tiempo_anulacion'] ?? '0') ?? 0;
  }

  static Future<void> guardarConfiguracion(Map<String, dynamic> valores) async {
    final t = await token();
    final r = await http.put(Uri.parse('$apiBase/admin/configuracion'), headers: _headers(t), body: jsonEncode(valores));
    if (r.statusCode != 200) throw Exception('Error al guardar');
  }

  static Future<int> obtenerHoraJornada() async {
    final cfg = await obtenerConfiguracion();
    return int.tryParse(cfg['hora_jornada'] ?? '2') ?? 2;
  }

  static Future<List<Map<String, dynamic>>> obtenerLoterias() async {
    final t = await token();
    final r = await http.get(Uri.parse('$apiBase/admin/loterias'), headers: _headers(t));
    if (r.statusCode != 200) throw Exception('Error al cargar loterías');
    final data = jsonDecode(r.body);
    if (data['loterias'] != null) {
      return (data['loterias'] as List).map((i) => i as Map<String, dynamic>).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> obtenerHorariosLoteria(String loteriaId) async {
    final t = await token();
    final r = await http.get(Uri.parse('$apiBase/admin/loterias/$loteriaId/horarios'), headers: _headers(t));
    final data = jsonDecode(r.body);
    if (data['horarios'] != null) {
      return (data['horarios'] as List).map((i) => i as Map<String, dynamic>).toList();
    }
    return [];
  }

  static Future<void> guardarHorarioLoteria({
    required String loteriaId,
    int? diaSemana,
    required String horaInicio,
    required String horaCierre,
  }) async {
    final t = await token();
    await http.put(
      Uri.parse('$apiBase/admin/loterias/$loteriaId/horarios'),
      headers: _headers(t),
      body: jsonEncode({'dia_semana': diaSemana, 'hora_inicio': horaInicio, 'hora_cierre': horaCierre}),
    );
  }
}

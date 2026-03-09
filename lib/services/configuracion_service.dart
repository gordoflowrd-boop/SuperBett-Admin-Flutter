import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class ConfiguracionService {
  static const String apiBase =
      'https://superbett-api-production.up.railway.app/api';

  static Future<String> token() async {
    return html.window.localStorage['token'] ?? '';
  }

  static Map<String, String> headers(String t) => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $t',
  };

  // ── Obtener toda la configuración ─────────────
  static Future<Map<String, String>> obtenerConfiguracion() async {
    final t = await token();
    final r = await http.get(
      Uri.parse('$apiBase/admin/configuracion'),
      headers: headers(t),
    );
    if (r.statusCode != 200) throw Exception('Error al leer configuración');
    final data = jsonDecode(r.body);
    final Map<String, String> result = {};
    (data['config'] as Map<String, dynamic>).forEach((k, v) {
      result[k] = v?.toString() ?? '';
    });
    return result;
  }

  // ── Tiempo de anulación ───────────────────────
  static Future<int> obtenerTiempoAnulacion() async {
    final cfg = await obtenerConfiguracion();
    return int.tryParse(cfg['tiempo_anulacion'] ?? '0') ?? 0;
  }

  static Future<void> guardarTiempoAnulacion(int minutos) async {
    final t = await token();
    final r = await http.put(
      Uri.parse('$apiBase/admin/configuracion'),
      headers: headers(t),
      body: jsonEncode({'tiempo_anulacion': minutos}),
    );
    if (r.statusCode != 200) {
      final data = jsonDecode(r.body);
      throw Exception(data['error'] ?? 'Error al guardar');
    }
  }

  // ── Hora de jornada ───────────────────────────
  static Future<int> obtenerHoraJornada() async {
    final cfg = await obtenerConfiguracion();
    return int.tryParse(cfg['hora_jornada'] ?? '2') ?? 2;
  }

  static Future<void> guardarHoraJornada(int hora) async {
    final t = await token();
    final r = await http.put(
      Uri.parse('$apiBase/admin/configuracion'),
      headers: headers(t),
      body: jsonEncode({'hora_jornada': hora}),
    );
    if (r.statusCode != 200) {
      final data = jsonDecode(r.body);
      throw Exception(data['error'] ?? 'Error al guardar');
    }
  }

  // ── Horarios de lotería ───────────────────────
  static Future<List<Map<String, dynamic>>> obtenerLoterias() async {
    final t = await token();
    final r = await http.get(
      Uri.parse('$apiBase/admin/loterias'),
      headers: headers(t),
    );
    if (r.statusCode != 200) throw Exception('Error al cargar loterías');
    final data = jsonDecode(r.body);
    return List<Map<String, dynamic>>.from(data['loterias'] ?? []);
  }

}

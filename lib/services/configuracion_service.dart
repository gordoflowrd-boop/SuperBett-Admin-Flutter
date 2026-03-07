import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

class ConfiguracionService {
  static Future<String> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token') ?? '';
  }

  static Map<String, String> _headers(String token) => {
    "Content-Type":  "application/json",
    "Authorization": "Bearer $token",
  };

  // Lee tiempo_anulacion desde /admin/configuracion (no requiere banca)
  static Future<int> obtenerTiempoAnulacion() async {
    final token = await _token();
    final r = await http.get(
      Uri.parse('$_kApi/admin/configuracion'),
      headers: _headers(token),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (!r.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? 'Error ${r.statusCode}');
    }
    final config = data['config'] as Map? ?? {};
    return int.tryParse(config['tiempo_anulacion']?.toString() ?? '0') ?? 0;
  }

  // Guarda tiempo_anulacion en /admin/configuracion
  static Future<void> guardarTiempoAnulacion(int minutos) async {
    final token = await _token();
    final r = await http.put(
      Uri.parse('$_kApi/admin/configuracion'),
      headers: _headers(token),
      body: jsonEncode({'tiempo_anulacion': minutos}),
    );
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (!r.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? 'Error ${r.statusCode}');
    }
  }
}

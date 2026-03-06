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

  static Future<Map<String, dynamic>> _fetch(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();
    final uri   = Uri.parse('$_kApi$path');
    http.Response r;
    if (method == 'PUT') {
      r = await http.put(uri, headers: _headers(token), body: jsonEncode(body ?? {}));
    } else {
      r = await http.get(uri, headers: _headers(token));
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (!r.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? data['mensaje'] ?? 'Error ${r.statusCode}');
    }
    return data;
  }

  // Lee tiempo_anulacion desde /bancas/config
  static Future<int> obtenerTiempoAnulacion() async {
    final data  = await _fetch('/bancas/config');
    final banca = data['banca'] as Map? ?? {};
    return int.tryParse(banca['tiempo_anulacion']?.toString() ?? '0') ?? 0;
  }

  // Guarda tiempo_anulacion (solo admin)
  static Future<void> guardarTiempoAnulacion(int minutos) async {
    await _fetch(
      '/bancas/config/tiempo-anulacion',
      method: 'PUT',
      body: {'tiempo_anulacion': minutos},
    );
  }
}

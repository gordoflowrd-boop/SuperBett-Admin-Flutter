import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/banca.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

class BancasService {
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
    if (method == 'PATCH') {
      r = await http.patch(uri, headers: _headers(token), body: jsonEncode(body ?? {}));
    } else {
      r = await http.get(uri, headers: _headers(token));
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (!r.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? data['mensaje'] ?? 'Error ${r.statusCode}');
    }
    return data;
  }

  static Future<List<Banca>> obtenerBancas() async {
    final data = await _fetch('/admin/bancas');
    return ((data['bancas'] as List?) ?? [])
        .map((b) => Banca.fromMap(b as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Esquema>> obtenerEsquemasPrecios() async {
    final data = await _fetch('/admin/esquemas/precios');
    return ((data['esquemas'] as List?) ?? [])
        .map((e) => Esquema.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Esquema>> obtenerEsquemasPagos() async {
    final data = await _fetch('/admin/esquemas/pagos');
    return ((data['esquemas'] as List?) ?? [])
        .map((e) => Esquema.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> guardarBanca(String id, Map<String, dynamic> cambios) async {
    await _fetch('/admin/bancas/$id', method: 'PATCH', body: cambios);
  }
}

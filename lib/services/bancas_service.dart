import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../models/banca.dart';

class BancasService {
  static const String _kApi =
      'https://superbett-api-production.up.railway.app/api';

  static String _token() => html.window.localStorage['token'] ?? '';

  static Map<String, String> _headers() => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer ${_token()}',
  };

  static Future<Map<String, dynamic>> _fetch(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_kApi$path');
    http.Response r;
    if (method == 'PATCH') {
      r = await http.patch(uri, headers: _headers(), body: jsonEncode(body ?? {}));
    } else if (method == 'PUT') {
      r = await http.put(uri, headers: _headers(), body: jsonEncode(body ?? {}));
    } else {
      r = await http.get(uri, headers: _headers());
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
    final ip = cambios.remove('ip_config');
    await _fetch('/admin/bancas/$id', method: 'PATCH', body: cambios);
    if (ip != null) {
      await _fetch('/admin/bancas/$id/ip', method: 'PUT', body: {'ip_config': ip});
    }
  }
}
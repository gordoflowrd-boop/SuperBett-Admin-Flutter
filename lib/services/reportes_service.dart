import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

class ReportesService {
  // ── Token ──────────────────────────────────────────
  static Future<String> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token') ?? '';
  }

  static Map<String, String> _headers(String token) => {
    "Content-Type":  "application/json",
    "Authorization": "Bearer $token",
  };

  // ── Fetch genérico ─────────────────────────────────
  static Future<dynamic> _fetch(String path) async {
    final token = await _token();
    final uri   = Uri.parse('$_kApi$path');
    final r     = await http.get(uri, headers: _headers(token));
    final data  = jsonDecode(r.body);
    if (!r.statusCode.toString().startsWith('2')) {
      final err = data is Map ? (data['error'] ?? data['mensaje'] ?? 'Error ${r.statusCode}') : 'Error ${r.statusCode}';
      throw Exception(err);
    }
    return data;
  }

  // ── Resumen por banca (admin) ──────────────────────
  // GET /api/reportes/resumen?fecha=YYYY-MM-DD
  static Future<List<dynamic>> obtenerResumen(String fecha) async {
    final data = await _fetch('/reportes/resumen?fecha=$fecha');
    return data is List ? data : [];
  }

  // ── Ganadores del día ──────────────────────────────
  // GET /api/reportes/ganadores?fecha=YYYY-MM-DD
  static Future<List<dynamic>> obtenerGanadores(String fecha) async {
    final data = await _fetch('/reportes/ganadores?fecha=$fecha');
    return data is List ? data : [];
  }
}

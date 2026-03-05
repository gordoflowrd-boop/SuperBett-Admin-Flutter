import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

class ReportesService {
  static Future<String> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token') ?? '';
  }

  static Map<String, String> _headers(String token) => {
    "Content-Type":  "application/json",
    "Authorization": "Bearer $token",
  };

  static Future<dynamic> _fetch(String path) async {
    final token = await _token();
    final uri   = Uri.parse('$_kApi$path');
    final r     = await http.get(uri, headers: _headers(token));
    final data  = jsonDecode(r.body);
    if (!r.statusCode.toString().startsWith('2')) {
      final err = data is Map
          ? (data['error'] ?? data['mensaje'] ?? 'Error ${r.statusCode}')
          : 'Error ${r.statusCode}';
      throw Exception(err);
    }
    return data;
  }

  // ── Resumen por banca (admin) ─────────────────────────
  // GET /api/reportes/resumen?fecha=YYYY-MM-DD
  // La función resumen_admin_dia retorna un array de bancas
  static Future<List<dynamic>> obtenerResumen(String fecha) async {
    final data = await _fetch('/reportes/resumen?fecha=$fecha');
    // Puede venir como List directamente o como un Map/objeto
    if (data is List) return data;
    if (data is Map) {
      // Si tiene claves de banca (e.g. {banca, total_venta}) = objeto único → wrap
      if (data.containsKey('bancas')) return data['bancas'] as List? ?? [];
      if (data.isNotEmpty) return [data];
    }
    return [];
  }

  // ── Ganadores del día ─────────────────────────────────
  // GET /api/reportes/ganadores?fecha=YYYY-MM-DD
  static Future<List<dynamic>> obtenerGanadores(String fecha) async {
    final data = await _fetch('/reportes/ganadores?fecha=$fecha');
    if (data is List) return data;
    if (data is Map && data.containsKey('ganadores')) {
      return data['ganadores'] as List? ?? [];
    }
    return [];
  }
}

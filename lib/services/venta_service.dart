import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

class VentaService {
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

  // ── Loterías ─────────────────────────────────────────
  // GET /api/admin/loterias
  static Future<List<dynamic>> obtenerLoterias() async {
    final data = await _fetch('/admin/loterias');
    return (data['loterias'] as List?) ?? [];
  }

  // ── Venta del día agrupada por modalidad ─────────────
  // GET /api/venta/dia?fecha=YYYY-MM-DD&loteria_id=UUID
  // Retorna: { normales: [], super_pale: [], totales: {} }
  static Future<Map<String, dynamic>> obtenerVentaDia({
    required String fecha,
    String? loteriaId,   // null = todas, "SP_ONLY" = solo Super Palé (filtro cliente)
  }) async {
    final qs = StringBuffer('?fecha=$fecha');
    if (loteriaId != null && loteriaId != 'SP_ONLY') {
      qs.write('&loteria_id=$loteriaId');
    }
    final data = await _fetch('/venta/dia$qs');
    return data is Map<String, dynamic> ? data : {};
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jornada.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

class PremiosService {
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
  static Future<Map<String, dynamic>> _fetch(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();
    final uri   = Uri.parse('$_kApi$path');
    http.Response r;
    if (method == 'POST') {
      r = await http.post(uri, headers: _headers(token), body: jsonEncode(body ?? {}));
    } else if (method == 'PATCH') {
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

  // ── Jornadas del día ───────────────────────────────
  static Future<List<Jornada>> obtenerJornadas(String fecha) async {
    final data = await _fetch('/jornadas?fecha=$fecha');
    final list = data['jornadas'] as List? ?? [];
    return list.map((j) => Jornada.fromMap(j as Map<String, dynamic>)).toList();
  }

  // ── Generar jornadas ──────────────────────────────
  static Future<void> generar(String fecha) async {
    await _fetch('/jornadas/generar', method: 'POST', body: {'fecha': fecha});
  }

  // ── Cambiar estado ────────────────────────────────
  static Future<void> cambiarEstado(String jornadaId, String nuevoEstado) async {
    await _fetch('/jornadas/$jornadaId', method: 'PATCH', body: {'estado': nuevoEstado});
  }

  // ── Guardar horario ───────────────────────────────
  static Future<void> guardarHorario(String jornadaId, String? horaInicio, String? horaCierre) async {
    await _fetch('/jornadas/$jornadaId', method: 'PATCH', body: {
      'hora_inicio': horaInicio,
      'hora_cierre': horaCierre,
    });
  }

  // ── Registrar + activar premio ────────────────────
  static Future<int> activarPremio(String jornadaId, String q1, String q2, String q3) async {
    await _fetch('/premios/registrar', method: 'POST', body: {
      'jornada_id': jornadaId,
      'q1': q1,
      'q2': q2.isEmpty ? '00' : q2,
      'q3': q3.isEmpty ? '00' : q3,
    });
    final resultado = await _fetch('/premios/activar', method: 'POST', body: {'jornada_id': jornadaId});
    return (resultado['total_ganadores'] as num?)?.toInt() ?? 0;
  }
}

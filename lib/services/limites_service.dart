import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// Modelo
// ─────────────────────────────────────────────
class LoteriasModel {
  final String  id;
  final String  nombre;
  final double? limiteQ;
  final double? limiteP;
  final double? limiteT;
  final double? limiteSp;

  LoteriasModel({
    required this.id,
    required this.nombre,
    this.limiteQ,
    this.limiteP,
    this.limiteT,
    this.limiteSp,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory LoteriasModel.fromJson(Map<String, dynamic> j) => LoteriasModel(
        id:       j['id']     as String,
        nombre:   j['nombre'] as String,
        limiteQ:  _toDouble(j['limite_q']),
        limiteP:  _toDouble(j['limite_p']),
        limiteT:  _toDouble(j['limite_t']),
        limiteSp: _toDouble(j['limite_sp']),
      );
}

// ─────────────────────────────────────────────
// Servicio
// ─────────────────────────────────────────────
class LimitesService {
  static const String _base =
      'https://superbett-api-production.up.railway.app/api';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Devuelve todas las loterías con sus límites actuales
  Future<List<LoteriasModel>> getLoterias() async {
    final res = await http.get(
      Uri.parse('$_base/admin/loterias'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Error \${res.statusCode}: \${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final list = json['loterias'] as List<dynamic>;
    return list
        .map((e) => LoteriasModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Guarda los 4 límites de una lotería (null = sin límite)
  Future<void> guardarLimites({
    required String loteriaId,
    double? limiteQ,
    double? limiteP,
    double? limiteT,
    double? limiteSp,
  }) async {
    final res = await http.patch(
      Uri.parse('$_base/admin/loterias/$loteriaId'),
      headers: await _headers(),
      body: jsonEncode({
        'limite_q':  limiteQ,
        'limite_p':  limiteP,
        'limite_t':  limiteT,
        'limite_sp': limiteSp,
      }),
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Error al guardar');
    }
  }
}

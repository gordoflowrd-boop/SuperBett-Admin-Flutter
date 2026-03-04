import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

class UsuariosService {
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
  static Future<dynamic> _fetch(
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
    } else if (method == 'DELETE') {
      r = await http.delete(uri, headers: _headers(token));
    } else {
      r = await http.get(uri, headers: _headers(token));
    }
    final data = jsonDecode(r.body);
    if (!r.statusCode.toString().startsWith('2')) {
      final err = data is Map
          ? (data['error'] ?? data['mensaje'] ?? 'Error ${r.statusCode}')
          : 'Error ${r.statusCode}';
      throw Exception(err);
    }
    return data;
  }

  // ── Listar usuarios ────────────────────────────────
  static Future<List<dynamic>> obtenerUsuarios() async {
    final data = await _fetch('/usuarios');
    if (data is List) return data;
    return (data['usuarios'] as List?) ?? [];
  }

  // ── Crear usuario ──────────────────────────────────
  static Future<void> crearUsuario({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    await _fetch('/usuarios', method: 'POST', body: {
      'nombre':   nombre,
      'email':    email,
      'password': password,
      'rol':      rol,
    });
  }

  // ── Editar usuario ─────────────────────────────────
  static Future<void> editarUsuario(
    String id, {
    String? nombre,
    String? email,
    String? rol,
    bool?   activo,
  }) async {
    await _fetch('/usuarios/$id', method: 'PATCH', body: {
      if (nombre != null) 'nombre': nombre,
      if (email  != null) 'email':  email,
      if (rol    != null) 'rol':    rol,
      if (activo != null) 'activo': activo,
    });
  }

  // ── Eliminar usuario ───────────────────────────────
  static Future<void> eliminarUsuario(String id) async {
    await _fetch('/usuarios/$id', method: 'DELETE');
  }
}

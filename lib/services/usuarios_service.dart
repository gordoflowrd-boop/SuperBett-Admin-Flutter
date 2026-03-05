import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

class UsuariosService {
  static Future<String> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token') ?? '';
  }

  static Map<String, String> _headers(String token) => {
    "Content-Type":  "application/json",
    "Authorization": "Bearer $token",
  };

  static Future<dynamic> _fetch(String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await _token();
    final uri   = Uri.parse('$_kApi$path');
    final heads = _headers(token);

    http.Response r;
    switch (method) {
      case 'POST':
        r = await http.post(uri, headers: heads, body: jsonEncode(body));
        break;
      case 'PATCH':
        r = await http.patch(uri, headers: heads, body: jsonEncode(body));
        break;
      case 'DELETE':
        r = await http.delete(uri, headers: heads);
        break;
      default:
        r = await http.get(uri, headers: heads);
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

  // ── GET /api/admin/usuarios ───────────────────────────
  static Future<List<dynamic>> obtenerUsuarios() async {
    final data = await _fetch('/admin/usuarios');
    // La API devuelve { usuarios: [...] }
    // Cada usuario tiene: id, username, nombre, rol, activo, created_at, bancas
    return (data['usuarios'] as List?) ?? [];
  }

  // ── POST /api/admin/usuarios ──────────────────────────
  // Campos: username (no email), password, nombre, rol
  static Future<void> crearUsuario({
    required String username,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    await _fetch('/admin/usuarios', method: 'POST', body: {
      'username': username,
      'password': password,
      'nombre':   nombre,
      'rol':      rol,
    });
  }

  // ── PATCH /api/admin/usuarios/:id ─────────────────────
  static Future<void> editarUsuario(
    String id, {
    String? nombre,
    String? rol,
    bool?   activo,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (nombre   != null) body['nombre']   = nombre;
    if (rol      != null) body['rol']      = rol;
    if (activo   != null) body['activo']   = activo;
    if (password != null) body['password'] = password;
    await _fetch('/admin/usuarios/$id', method: 'PATCH', body: body);
  }
}

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

  static Future<List<dynamic>> obtenerUsuarios() async {
    final data = await _fetch('/admin/usuarios');
    return (data['usuarios'] as List?) ?? [];
  }

  static Future<Map<String, dynamic>> crearUsuarioConRespuesta({
    required String username,
    required String password,
    required String nombre,
    required String rol,
  }) async {
    final data = await _fetch('/admin/usuarios', method: 'POST', body: {
      'username': username,
      'password': password,
      'nombre':   nombre,
      'rol':      rol,
    });
    return data is Map<String, dynamic> ? data : {};
  }

  static Future<String?> obtenerIdPropio() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('usuario');
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map['id']?.toString();
  }

  static Future<void> asignarBanca({
    required String usuarioId,
    required String bancaId,
  }) async {
    // Ejecutamos las 4 modalidades en paralelo para mayor eficiencia
    final modalidades = ['Q', 'P', 'T', 'SP'];
    await Future.wait(modalidades.map((m) => _fetch('/admin/usuarios/$usuarioId/bancas',
      method: 'POST',
      body: {
        'banca_id':         bancaId,
        'modalidad':        m,
        'porcentaje_bruto': 0,
        'porcentaje_neto':  0,
      })));
  }

  static Future<void> editarUsuario(
    String id, {
    String? nombre,
    String? username,
    String? rol,
    bool?   activo,
    String? password,
    String? passwordActual,
  }) async {
    final body = <String, dynamic>{};
    if (nombre         != null) body['nombre']           = nombre;
    if (username       != null) body['username']         = username;
    if (rol            != null) body['rol']              = rol;
    if (activo         != null) body['activo']           = activo;
    if (password       != null) body['password']         = password;
    if (passwordActual != null) body['password_actual']  = passwordActual;
    await _fetch('/admin/usuarios/$id', method: 'PATCH', body: body);
  }
}

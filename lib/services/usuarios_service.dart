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
  // Igual que crearUsuario pero retorna el objeto { usuario: {...} }
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
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

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
  // Retorna el id del usuario actualmente logueado
  static Future<String?> obtenerIdPropio() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('usuario');
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map['id']?.toString();
  }

  // ── POST /api/admin/usuarios/:id/bancas ──────────────
  // Asigna un vendedor a una banca (modalidades Q/P/T/SP)
  static Future<void> asignarBanca({
    required String usuarioId,
    required String bancaId,
  }) async {
    // Asignar para todas las modalidades sin restricción de comisión
    for (final modalidad in ['Q', 'P', 'T', 'SP']) {
      await _fetch('/admin/usuarios/$usuarioId/bancas',
        method: 'POST',
        body: {
          'banca_id':         bancaId,
          'modalidad':        modalidad,
          'porcentaje_bruto': 0,
          'porcentaje_neto':  0,
        });
    }
  }

  static Future<void> editarUsuario(
    String id, {
    String? nombre,
    String? username,
    String? rol,
    bool?   activo,
    String? password,
    String? passwordActual, // requerido solo si el admin edita su propia cuenta
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

  // Obtener páginas asignadas
  static Future<List<String>> obtenerPaginas(String id) async {
    final data = await _fetch('/admin/usuarios/$id/paginas');
    return List<String>.from(data['paginas'] ?? []);
  }

  // Guardar páginas asignadas (reemplaza todas)
  static Future<void> guardarPaginas(String id, List<String> paginas) async {
    await _fetch('/admin/usuarios/$id/paginas',
        method: 'PUT', body: {'paginas': paginas});
  }
}



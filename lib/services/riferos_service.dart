import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApi = 'https://superbett-api-production.up.railway.app/api';

class RiferosService {
  static Future<String> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token') ?? '';
  }

  static Map<String, String> _h(String t) => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $t',
  };

  static Future<Map<String, dynamic>> _fetch(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final t   = await _token();
    final uri = Uri.parse('$_kApi$path');
    http.Response r;
    switch (method) {
      case 'POST':
        r = await http.post(uri, headers: _h(t), body: jsonEncode(body ?? {}));
        break;
      case 'DELETE':
        r = await http.delete(uri, headers: _h(t));
        break;
      default:
        r = await http.get(uri, headers: _h(t));
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    if (!r.statusCode.toString().startsWith('2')) {
      throw Exception(data['error'] ?? 'Error ${r.statusCode}');
    }
    return data;
  }

  // Lista todos los riferos
  static Future<List<Map<String, dynamic>>> obtenerRiferos() async {
    final data = await _fetch('/admin/riferos');
    return List<Map<String, dynamic>>.from(data['riferos'] ?? []);
  }

  // Lista todos los vendedores
  static Future<List<Map<String, dynamic>>> obtenerVendedores() async {
    final data = await _fetch('/admin/usuarios');
    final todos = List<Map<String, dynamic>>.from(data['usuarios'] ?? []);
    return todos.where((u) => u['rol'] == 'vendedor').toList();
  }

  // Bancas de un rifero
  static Future<List<Map<String, dynamic>>> bancasDeRifero(String riferoId) async {
    final data = await _fetch('/admin/bancas');
    final bancas = List<Map<String, dynamic>>.from(data['bancas'] ?? []);
    return bancas.where((b) => b['rifero_id']?.toString() == riferoId).toList();
  }

  // Vendedores asignados a un rifero ← CORREGIDO
  static Future<List<Map<String, dynamic>>> vendedoresDeRifero(String riferoId) async {
    final data = await _fetch('/admin/riferos/$riferoId/vendedores');
    return List<Map<String, dynamic>>.from(data['vendedores'] ?? []);
  }

  // Asignar vendedor a rifero
  static Future<void> asignarVendedor(String vendedorId, String riferoId) async {
    await _fetch('/admin/usuarios/$vendedorId/riferos',
        method: 'POST', body: {'rifero_id': riferoId});
  }

  // Quitar vendedor de rifero
  static Future<void> quitarVendedor(String vendedorId, String riferoId) async {
    await _fetch('/admin/usuarios/$vendedorId/riferos/$riferoId',
        method: 'DELETE');
  }
}
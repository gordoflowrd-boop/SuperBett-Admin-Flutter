import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kApi = "https://superbett-api-production.up.railway.app/api";

// ─────────────────────────────────────────────
// Modelos
// ─────────────────────────────────────────────
class EsquemaPrecio {
  final String id;
  final String nombre;
  final bool activo;
  final List<DetallesPrecio> detalle;
  EsquemaPrecio({required this.id, required this.nombre,
      required this.activo, required this.detalle});

  factory EsquemaPrecio.fromJson(Map<String, dynamic> j) => EsquemaPrecio(
    id:      j['id'],
    nombre:  j['nombre'],
    activo:  j['activo'] ?? true,
    detalle: ((j['detalle'] as List?) ?? [])
        .where((d) => d != null)
        .map((d) => DetallesPrecio.fromJson(d))
        .toList(),
  );
}

class DetallesPrecio {
  final String modalidad;
  final double precio;
  final String? loteriaId;
  DetallesPrecio({required this.modalidad, required this.precio, this.loteriaId});

  factory DetallesPrecio.fromJson(Map<String, dynamic> j) => DetallesPrecio(
    modalidad: j['modalidad'] ?? '',
    precio:    double.tryParse(j['precio']?.toString() ?? '0') ?? 0,
    loteriaId: j['loteria_id']?.toString(),
  );
}

class EsquemaPago {
  final String id;
  final String nombre;
  final bool activo;
  final List<DetallePago> detalle;
  EsquemaPago({required this.id, required this.nombre,
      required this.activo, required this.detalle});

  factory EsquemaPago.fromJson(Map<String, dynamic> j) => EsquemaPago(
    id:      j['id'],
    nombre:  j['nombre'],
    activo:  j['activo'] ?? true,
    detalle: ((j['detalle'] as List?) ?? [])
        .where((d) => d != null)
        .map((d) => DetallePago.fromJson(d))
        .toList(),
  );
}

class DetallePago {
  final String  modalidad;
  final int     posicion;
  final double  pago;
  final String? loteriaId;
  DetallePago({required this.modalidad, required this.posicion,
      required this.pago, this.loteriaId});

  factory DetallePago.fromJson(Map<String, dynamic> j) => DetallePago(
    modalidad: j['modalidad'] ?? '',
    posicion:  j['posicion']  ?? 0,
    pago:      double.tryParse(j['pago']?.toString() ?? '0') ?? 0,
    loteriaId: j['loteria_id']?.toString(),
  );
}

// ─────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────
class EsquemasService {
  static Future<String> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token') ?? '';
  }

  static Map<String, String> _headers(String t) => {
    'Content-Type':  'application/json',
    'Authorization': 'Bearer $t',
  };

  // ── PRECIOS ───────────────────────────────

  static Future<List<EsquemaPrecio>> getEsquemasPrecios() async {
    final t = await _token();
    final r = await http.get(
      Uri.parse('$_kApi/admin/esquemas/precios'), headers: _headers(t));
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'Error');
    return (data['esquemas'] as List)
        .map((e) => EsquemaPrecio.fromJson(e))
        .toList();
  }

  static Future<String> crearEsquemaPrecio(String nombre) async {
    final t = await _token();
    final r = await http.post(
      Uri.parse('$_kApi/admin/esquemas/precios'),
      headers: _headers(t),
      body: jsonEncode({'nombre': nombre}),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode != 201) throw Exception(data['error'] ?? 'Error');
    return data['esquema']['id'];
  }

  static Future<void> guardarPrecio(String esquemaId, String modalidad, double precio) async {
    final t = await _token();
    final r = await http.put(
      Uri.parse('$_kApi/admin/esquemas/precios/$esquemaId/detalle'),
      headers: _headers(t),
      body: jsonEncode({'modalidad': modalidad, 'precio': precio}),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'Error');
  }

  static Future<void> renombrarEsquemaPrecio(String id, String nombre) async {
    final t = await _token();
    await http.patch(
      Uri.parse('$_kApi/admin/esquemas/precios/$id'),
      headers: _headers(t),
      body: jsonEncode({'nombre': nombre}),
    );
  }

  // ── PAGOS ─────────────────────────────────

  static Future<List<EsquemaPago>> getEsquemasPagos() async {
    final t = await _token();
    final r = await http.get(
      Uri.parse('$_kApi/admin/esquemas/pagos'), headers: _headers(t));
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'Error');
    return (data['esquemas'] as List)
        .map((e) => EsquemaPago.fromJson(e))
        .toList();
  }

  static Future<String> crearEsquemaPago(String nombre) async {
    final t = await _token();
    final r = await http.post(
      Uri.parse('$_kApi/admin/esquemas/pagos'),
      headers: _headers(t),
      body: jsonEncode({'nombre': nombre}),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode != 201) throw Exception(data['error'] ?? 'Error');
    return data['esquema']['id'];
  }

  static Future<void> guardarMultiplicador(
      String esquemaId, String modalidad, int posicion, double pago) async {
    final t = await _token();
    final r = await http.put(
      Uri.parse('$_kApi/admin/esquemas/pagos/$esquemaId/detalle'),
      headers: _headers(t),
      body: jsonEncode({'modalidad': modalidad, 'posicion': posicion, 'pago': pago}),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) throw Exception(data['error'] ?? 'Error');
  }

  static Future<void> renombrarEsquemaPago(String id, String nombre) async {
    final t = await _token();
    await http.patch(
      Uri.parse('$_kApi/admin/esquemas/pagos/$id'),
      headers: _headers(t),
      body: jsonEncode({'nombre': nombre}),
    );
  }
}

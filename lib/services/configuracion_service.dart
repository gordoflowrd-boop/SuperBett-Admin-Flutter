import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class ConfiguracionService {
  static const String apiBase =
      'https://superbett-api-production.up.railway.app/api';

  // Obtener el token desde el almacenamiento local del navegador
  static Future<String> _token() async {
    return html.window.localStorage['token'] ?? '';
  }

  // Generar headers con token de forma centralizada
  static Future<Map<String, String>> _headers() async {
    final t = await _token();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $t',
    };
  }

  // =============================================
  // CONFIGURACIÓN GLOBAL (Key-Value)
  // =============================================

  /// Obtiene todo el mapa de configuración (tiempo_anulacion, hora_jornada, etc.)
  static Future<Map<String, String>> obtenerConfiguracion() async {
    final r = await http.get(
      Uri.parse('$apiBase/admin/configuracion'),
      headers: await _headers(),
    );

    if (r.statusCode != 200) throw Exception('Error al leer configuración');
    
    final data = jsonDecode(r.body);
    final Map<String, String> result = {};
    
    if (data['config'] != null) {
      (data['config'] as Map<String, dynamic>).forEach((k, v) {
        result[k] = v?.toString() ?? '';
      });
    }
    return result;
  }

  /// Guarda uno o varios valores de configuración global
  static Future<void> guardarConfiguracion(Map<String, dynamic> valores) async {
    final r = await http.put(
      Uri.parse('$apiBase/admin/configuracion'),
      headers: await _headers(),
      body: jsonEncode(valores),
    );

    if (r.statusCode != 200) {
      final data = jsonDecode(r.body);
      throw Exception(data['error'] ?? 'Error al guardar configuración');
    }
  }

  // Helpers específicos para facilitar el uso en UI
  static Future<int> obtenerTiempoAnulacion() async {
    final cfg = await obtenerConfiguracion();
    return int.tryParse(cfg['tiempo_anulacion'] ?? '0') ?? 0;
  }

  static Future<int> obtenerHoraJornada() async {
    final cfg = await obtenerConfiguracion();
    return int.tryParse(cfg['hora_jornada'] ?? '2') ?? 2;
  }

  // =============================================
  // GESTIÓN DE LOTERÍAS Y HORARIOS
  // =============================================

  /// Obtiene la lista de loterías con su horario por defecto
  static Future<List<Map<String, dynamic>>> obtenerLoterias() async {
    final r = await http.get(
      Uri.parse('$apiBase/admin/loterias'),
      headers: await _headers(),
    );

    if (r.statusCode != 200) throw Exception('Error al cargar loterías');
    final data = jsonDecode(r.body);
    return List<Map<String, dynamic>>.from(data['loterias'] ?? []);
  }

  /// Obtiene todos los horarios (por día) de una lotería específica
  static Future<List<Map<String, dynamic>>> obtenerHorariosLoteria(String loteriaId) async {
    final r = await http.get(
      Uri.parse('$apiBase/admin/loterias/$loteriaId/horarios'),
      headers: await _headers(),
    );

    if (r.statusCode != 200) throw Exception('Error al obtener horarios');
    final data = jsonDecode(r.body);
    return List<Map<String, dynamic>>.from(data['horarios'] ?? []);
  }

  /// Guarda o actualiza un horario para una lotería (dia_semana null = defecto)
  static Future<void> guardarHorarioLoteria({
    required String loteriaId,
    int? diaSemana, // null para horario por defecto
    required String horaInicio,
    required String horaCierre,
  }) async {
    final r = await http.put(
      Uri.parse('$apiBase/admin/loterias/$loteriaId/horarios'),
      headers: await _headers(),
      body: jsonEncode({
        'dia_semana': diaSemana,
        'hora_inicio': horaInicio,
        'hora_cierre': horaCierre,
      }),
    );

    if (r.statusCode != 200) {
      final data = jsonDecode(r.body);
      throw Exception(data['error'] ?? 'Error al guardar horario');
    }
  }

  // =============================================
  // ACCIONES DE SISTEMA
  // =============================================

  /// Dispara manualmente la función de generación de jornadas en el servidor
  static Future<Map<String, dynamic>> forzarGeneracionJornadas() async {
    final r = await http.post(
      Uri.parse('$apiBase/admin/jornadas/generar'),
      headers: await _headers(),
    );

    final data = jsonDecode(r.body);
    if (r.statusCode != 200) {
      throw Exception(data['error'] ?? 'Error al generar jornadas');
    }
    return data;
  }
}

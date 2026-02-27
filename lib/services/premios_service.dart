import '../models/jornada.dart';
import 'api_service.dart';

class PremiosService {
  static Future<List<Jornada>> obtenerJornadas(String fecha) async {
    final data =
        await ApiService.request("/jornadas?fecha=$fecha", "GET");

    final list = data["jornadas"] as List? ?? [];

    return list.map((e) => Jornada.fromJson(e)).toList();
  }

  static Future<void> generar(String fecha) async {
    await ApiService.request("/jornadas/generar", "POST",
        body: {"fecha": fecha});
  }

  static Future<void> cambiarEstado(
      String id, String estado) async {
    await ApiService.request("/jornadas/$id", "PATCH",
        body: {"estado": estado});
  }

  static Future<void> guardarHorario(
      String id, String hi, String hc) async {
    await ApiService.request("/jornadas/$id", "PATCH",
        body: {
          "hora_inicio": hi,
          "hora_cierre": hc,
        });
  }

  static Future<Map<String, dynamic>> activarPremio(
      String jornadaId,
      String q1,
      String q2,
      String q3) async {
    await ApiService.request("/premios/registrar", "POST",
        body: {
          "jornada_id": jornadaId,
          "q1": q1,
          "q2": q2,
          "q3": q3,
        });

    return await ApiService.request("/premios/activar", "POST",
        body: {"jornada_id": jornadaId});
  }
}
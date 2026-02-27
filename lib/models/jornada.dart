class Jornada {
  final String id;
  final String? loteria;
  final String? horaInicio;
  final String? horaCierre;
  final String? estado;
  final String? q1;
  final String? q2;
  final String? q3;

  Jornada({
    required this.id,
    this.loteria,
    this.horaInicio,
    this.horaCierre,
    this.estado,
    this.q1,
    this.q2,
    this.q3,
  });

  factory Jornada.fromJson(Map<String, dynamic> json) {
    return Jornada(
      id: json["id"].toString(),
      loteria: json["loteria"],
      horaInicio: json["hora_inicio"],
      horaCierre: json["hora_cierre"],
      estado: json["estado"],
      q1: json["q1"]?.toString(),
      q2: json["q2"]?.toString(),
      q3: json["q3"]?.toString(),
    );
  }
}
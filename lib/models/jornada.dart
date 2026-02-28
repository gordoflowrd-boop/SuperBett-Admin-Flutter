class Jornada {
  final String id;
  final String? loteria;
  final String estado;
  final String? horaInicio;
  final String? horaCierre;
  final String? q1;
  final String? q2;
  final String? q3;

  const Jornada({
    required this.id,
    required this.estado,
    this.loteria,
    this.horaInicio,
    this.horaCierre,
    this.q1,
    this.q2,
    this.q3,
  });

  factory Jornada.fromMap(Map<String, dynamic> m) => Jornada(
    id:          m['id']?.toString()          ?? '',
    loteria:     m['loteria']?.toString(),
    estado:      m['estado']?.toString()      ?? 'abierto',
    horaInicio:  m['hora_inicio']?.toString(),
    horaCierre:  m['hora_cierre']?.toString(),
    q1:          m['q1']?.toString(),
    q2:          m['q2']?.toString(),
    q3:          m['q3']?.toString(),
  );

  /// Devuelve una copia con campos actualizados
  Jornada copyWith({
    String? estado,
    String? horaInicio,
    String? horaCierre,
    String? q1, String? q2, String? q3,
  }) => Jornada(
    id: id, loteria: loteria,
    estado:     estado     ?? this.estado,
    horaInicio: horaInicio ?? this.horaInicio,
    horaCierre: horaCierre ?? this.horaCierre,
    q1: q1 ?? this.q1,
    q2: q2 ?? this.q2,
    q3: q3 ?? this.q3,
  );
}

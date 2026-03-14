class Banca {
  final String  id;
  final String  nombre;
  final String? nombreTicket;
  final String? codigo;
  final String? ipConfig;
  final String? riferoId;
  final String? riferoUsername;
  final String? riferoNombre;
  final bool    activa;
  final String? esquemaPrecioId;
  final String? esquemaPagoId;
  final double? limiteQ;
  final double? limiteP;
  final double? limiteT;
  final double? limiteSP;
  final double? comisionQ;
  final double? comisionP;
  final double? comisionT;
  final double? comisionSP;
  final double? topeQ;
  final double? topeP;
  final double? topeT;
  final double? topeSP;

  const Banca({
    required this.id,
    required this.nombre,
    required this.activa,
    this.nombreTicket,
    this.codigo,
    this.ipConfig,
    this.riferoId,
    this.riferoUsername,
    this.riferoNombre,
    this.esquemaPrecioId,
    this.esquemaPagoId,
    this.limiteQ,  this.limiteP,  this.limiteT,  this.limiteSP,
    this.comisionQ, this.comisionP, this.comisionT, this.comisionSP,
    this.topeQ,    this.topeP,    this.topeT,    this.topeSP,
  });

  factory Banca.fromMap(Map<String, dynamic> m) => Banca(
    id:              m['id']?.toString()             ?? '',
    nombre:          m['nombre']?.toString()         ?? '',
    nombreTicket:    m['nombre_ticket']?.toString(),
    codigo:          m['codigo']?.toString(),
    ipConfig:        m['ip_config']?.toString(),
    riferoId:        m['rifero_id']?.toString(),
    riferoUsername:  m['rifero_username']?.toString(),
    riferoNombre:    m['rifero_nombre']?.toString(),
    activa:          m['activa'] == true || m['activa'] == 1,
    esquemaPrecioId: m['esquema_precio_id']?.toString(),
    esquemaPagoId:   m['esquema_pago_id']?.toString(),
    limiteQ:  _n(m['limite_q']),  limiteP:  _n(m['limite_p']),
    limiteT:  _n(m['limite_t']),  limiteSP: _n(m['limite_sp']),
    comisionQ: _n(m['comision_q']), comisionP: _n(m['comision_p']),
    comisionT: _n(m['comision_t']), comisionSP: _n(m['comision_sp']),
    topeQ: _n(m['tope_q']), topeP: _n(m['tope_p']),
    topeT: _n(m['tope_t']), topeSP: _n(m['tope_sp']),
  );

  static double? _n(dynamic v) =>
      v != null ? double.tryParse(v.toString()) : null;
}

class Esquema {
  final String id;
  final String nombre;
  const Esquema({required this.id, required this.nombre});
  factory Esquema.fromMap(Map<String, dynamic> m) =>
      Esquema(id: m['id'].toString(), nombre: m['nombre'].toString());
}

class Rifero {
  final String id;
  final String username;
  final String nombre;
  const Rifero({required this.id, required this.username, required this.nombre});
  factory Rifero.fromMap(Map<String, dynamic> m) => Rifero(
    id:       m['id'].toString(),
    username: m['username'].toString(),
    nombre:   m['nombre']?.toString() ?? m['username'].toString(),
  );
}

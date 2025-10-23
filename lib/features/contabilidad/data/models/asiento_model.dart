class AsientoModel {
  final int? id;
  final String numero;
  final DateTime fecha;
  final String? descripcion;
  final String? origenTipo;
  final int? origenId;
  final String estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AsientoModel({
    this.id,
    required this.numero,
    required this.fecha,
    this.descripcion,
    this.origenTipo,
    this.origenId,
    this.estado = 'registrado',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'numero': numero,
      'fecha': fecha.toIso8601String(),
      'descripcion': descripcion,
      'origen_tipo': origenTipo,
      'origen_id': origenId,
      'estado': estado,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AsientoModel.fromMap(Map<String, dynamic> map) {
    return AsientoModel(
      id: map['id'] as int?,
      numero: map['numero'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      descripcion: map['descripcion'] as String?,
      origenTipo: map['origen_tipo'] as String?,
      origenId: map['origen_id'] as int?,
      estado: map['estado'] as String? ?? 'registrado',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}

class AsientoResumen {
  final AsientoModel asiento;
  final double totalDebe;
  final double totalHaber;
  final int movimientos;

  const AsientoResumen({
    required this.asiento,
    required this.totalDebe,
    required this.totalHaber,
    required this.movimientos,
  });

  factory AsientoResumen.fromMap(Map<String, dynamic> map) {
    return AsientoResumen(
      asiento: AsientoModel.fromMap(map),
      totalDebe: (map['total_debe'] as num?)?.toDouble() ?? 0,
      totalHaber: (map['total_haber'] as num?)?.toDouble() ?? 0,
      movimientos: (map['movimientos'] as int?) ??
          (map['movimientos'] as num?)?.toInt() ??
          0,
    );
  }
}

class AsientoMovimientoModel {
  final int? id;
  final int asientoId;
  final int cuentaId;
  final String? detalle;
  final double debe;
  final double haber;
  final String? cuentaCodigo;
  final String? cuentaNombre;

  const AsientoMovimientoModel({
    this.id,
    required this.asientoId,
    required this.cuentaId,
    this.detalle,
    required this.debe,
    required this.haber,
    this.cuentaCodigo,
    this.cuentaNombre,
  });

  factory AsientoMovimientoModel.fromMap(Map<String, dynamic> map) {
    return AsientoMovimientoModel(
      id: map['id'] as int?,
      asientoId: map['asiento_id'] as int,
      cuentaId: map['cuenta_id'] as int,
      detalle: map['detalle'] as String?,
      debe: (map['debe'] as num?)?.toDouble() ?? 0,
      haber: (map['haber'] as num?)?.toDouble() ?? 0,
      cuentaCodigo: map['cuenta_codigo'] as String?,
      cuentaNombre: map['cuenta_nombre'] as String?,
    );
  }
}

class AsientoMovimientoInput {
  final int cuentaId;
  final double debe;
  final double haber;
  final String? detalle;

  const AsientoMovimientoInput({
    required this.cuentaId,
    this.debe = 0,
    this.haber = 0,
    this.detalle,
  })  : assert(debe >= 0, 'El debe no puede ser negativo'),
        assert(haber >= 0, 'El haber no puede ser negativo');
}

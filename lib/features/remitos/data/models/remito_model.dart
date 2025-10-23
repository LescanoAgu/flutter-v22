/// Modelo base de Remito (cabecera)
class RemitoModel {
  final int? id;
  final String numero;
  final int clienteId;
  final int? obraId;
  final int? ordenInternaId;
  final DateTime fechaEmision;
  final DateTime? fechaEntrega;
  final String estado;
  final String? observaciones;
  final String? chofer;
  final String? transporte;
  final String? patente;
  final String? recibidoPor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RemitoModel({
    this.id,
    required this.numero,
    required this.clienteId,
    this.obraId,
    this.ordenInternaId,
    required this.fechaEmision,
    this.fechaEntrega,
    this.estado = 'emitido',
    this.observaciones,
    this.chofer,
    this.transporte,
    this.patente,
    this.recibidoPor,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'cliente_id': clienteId,
      'obra_id': obraId,
      'orden_interna_id': ordenInternaId,
      'fecha_emision': fechaEmision.toIso8601String(),
      'fecha_entrega': fechaEntrega?.toIso8601String(),
      'estado': estado,
      'observaciones': observaciones,
      'chofer': chofer,
      'transporte': transporte,
      'patente': patente,
      'recibido_por': recibidoPor,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory RemitoModel.fromMap(Map<String, dynamic> map) {
    return RemitoModel(
      id: map['id'] as int?,
      numero: map['numero'] as String,
      clienteId: map['cliente_id'] as int,
      obraId: map['obra_id'] as int?,
      ordenInternaId: map['orden_interna_id'] as int?,
      fechaEmision: DateTime.parse(map['fecha_emision'] as String),
      fechaEntrega: map['fecha_entrega'] != null
          ? DateTime.tryParse(map['fecha_entrega'] as String)
          : null,
      estado: map['estado'] as String? ?? 'emitido',
      observaciones: map['observaciones'] as String?,
      chofer: map['chofer'] as String?,
      transporte: map['transporte'] as String?,
      patente: map['patente'] as String?,
      recibidoPor: map['recibido_por'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}

/// Modelo de datos extendido utilizado para mostrar remitos con información
/// adicional de cliente y obra.
class RemitoResumen {
  final int id;
  final String numero;
  final DateTime fechaEmision;
  final String estado;
  final String clienteNombre;
  final String? obraNombre;
  final int itemsCount;
  final double totalCantidad;
  final String? transporte;
  final String? observaciones;

  RemitoResumen({
    required this.id,
    required this.numero,
    required this.fechaEmision,
    required this.estado,
    required this.clienteNombre,
    this.obraNombre,
    required this.itemsCount,
    required this.totalCantidad,
    this.transporte,
    this.observaciones,
  });

  factory RemitoResumen.fromMap(Map<String, dynamic> map) {
    return RemitoResumen(
      id: map['id'] as int,
      numero: map['numero'] as String,
      fechaEmision: DateTime.parse(map['fecha_emision'] as String),
      estado: map['estado'] as String? ?? 'emitido',
      clienteNombre: map['cliente_nombre'] as String? ?? '',
      obraNombre: map['obra_nombre'] as String?,
      itemsCount: (map['items_count'] as int?) ??
          (map['items_count'] as num?)?.toInt() ??
          0,
      totalCantidad: (map['total_cantidad'] as num?)?.toDouble() ?? 0,
      transporte: map['transporte'] as String?,
      observaciones: map['observaciones'] as String?,
    );
  }
}

/// Item del remito con información del producto
class RemitoItemDetalle {
  final int id;
  final int productoId;
  final String productoCodigo;
  final String productoNombre;
  final double cantidad;
  final String? unidad;
  final String? descripcion;

  RemitoItemDetalle({
    required this.id,
    required this.productoId,
    required this.productoCodigo,
    required this.productoNombre,
    required this.cantidad,
    this.unidad,
    this.descripcion,
  });

  factory RemitoItemDetalle.fromMap(Map<String, dynamic> map) {
    return RemitoItemDetalle(
      id: map['id'] as int,
      productoId: map['producto_id'] as int,
      productoCodigo: map['producto_codigo'] as String? ?? '',
      productoNombre: map['producto_nombre'] as String? ?? '',
      cantidad: (map['cantidad'] as num).toDouble(),
      unidad: map['unidad'] as String?,
      descripcion: map['descripcion'] as String?,
    );
  }
}

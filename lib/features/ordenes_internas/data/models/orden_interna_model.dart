import 'orden_item_model.dart';
/// Modelo de Orden Interna (Pedido)
///
/// Representa un pedido realizado por un cliente/obra.
/// Pasa por varios estados hasta ser despachado y facturado.
class OrdenInterna {
  final int? id;
  final String numero; // OI-0001, OI-0002...
  final int clienteId;
  final int? obraId;

  // Solicitante
  final String solicitanteNombre;
  final String? solicitanteEmail;
  final String? solicitanteTelefono;

  // Fechas
  final DateTime fechaPedido;
  final DateTime? fechaEntregaEstimada;

  // Estado y observaciones
  final String estado; // solicitado, aprobado, rechazado, etc.
  final String? observacionesCliente;
  final String? observacionesInternas;
  final String? motivoRechazo;

  // Total
  final double total;

  // Auditoría
  final int? aprobadoPorUsuarioId;
  final DateTime? aprobadoFecha;
  final int? usuarioCreadorId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrdenInterna({
    this.id,
    required this.numero,
    required this.clienteId,
    this.obraId,
    required this.solicitanteNombre,
    this.solicitanteEmail,
    this.solicitanteTelefono,
    required this.fechaPedido,
    this.fechaEntregaEstimada,
    this.estado = 'solicitado',
    this.observacionesCliente,
    this.observacionesInternas,
    this.motivoRechazo,
    this.total = 0,
    this.aprobadoPorUsuarioId,
    this.aprobadoFecha,
    this.usuarioCreadorId,
    required this.createdAt,
    this.updatedAt,
  });

  // Conversión a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'cliente_id': clienteId,
      'obra_id': obraId,
      'solicitante_nombre': solicitanteNombre,
      'solicitante_email': solicitanteEmail,
      'solicitante_telefono': solicitanteTelefono,
      'fecha_pedido': fechaPedido.toIso8601String(),
      'fecha_entrega_estimada': fechaEntregaEstimada?.toIso8601String(),
      'estado': estado,
      'observaciones_cliente': observacionesCliente,
      'observaciones_internas': observacionesInternas,
      'motivo_rechazo': motivoRechazo,
      'total': total,
      'aprobado_por_usuario_id': aprobadoPorUsuarioId,
      'aprobado_fecha': aprobadoFecha?.toIso8601String(),
      'usuario_creador_id': usuarioCreadorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Crear desde Map de SQLite
  factory OrdenInterna.fromMap(Map<String, dynamic> map) {
    return OrdenInterna(
      id: map['id'] as int?,
      numero: map['numero'] as String,
      clienteId: map['cliente_id'] as int,
      obraId: map['obra_id'] as int?,
      solicitanteNombre: map['solicitante_nombre'] as String,
      solicitanteEmail: map['solicitante_email'] as String?,
      solicitanteTelefono: map['solicitante_telefono'] as String?,
      fechaPedido: DateTime.parse(map['fecha_pedido'] as String),
      fechaEntregaEstimada: map['fecha_entrega_estimada'] != null
          ? DateTime.parse(map['fecha_entrega_estimada'] as String)
          : null,
      estado: map['estado'] as String,
      observacionesCliente: map['observaciones_cliente'] as String?,
      observacionesInternas: map['observaciones_internas'] as String?,
      motivoRechazo: map['motivo_rechazo'] as String?,
      total: (map['total'] as num).toDouble(),
      aprobadoPorUsuarioId: map['aprobado_por_usuario_id'] as int?,
      aprobadoFecha: map['aprobado_fecha'] != null
          ? DateTime.parse(map['aprobado_fecha'] as String)
          : null,
      usuarioCreadorId: map['usuario_creador_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // CopyWith para actualizaciones
  OrdenInterna copyWith({
    int? id,
    String? numero,
    int? clienteId,
    int? obraId,
    String? solicitanteNombre,
    String? solicitanteEmail,
    String? solicitanteTelefono,
    DateTime? fechaPedido,
    DateTime? fechaEntregaEstimada,
    String? estado,
    String? observacionesCliente,
    String? observacionesInternas,
    String? motivoRechazo,
    double? total,
    int? aprobadoPorUsuarioId,
    DateTime? aprobadoFecha,
    int? usuarioCreadorId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrdenInterna(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      obraId: obraId ?? this.obraId,
      solicitanteNombre: solicitanteNombre ?? this.solicitanteNombre,
      solicitanteEmail: solicitanteEmail ?? this.solicitanteEmail,
      solicitanteTelefono: solicitanteTelefono ?? this.solicitanteTelefono,
      fechaPedido: fechaPedido ?? this.fechaPedido,
      fechaEntregaEstimada: fechaEntregaEstimada ?? this.fechaEntregaEstimada,
      estado: estado ?? this.estado,
      observacionesCliente: observacionesCliente ?? this.observacionesCliente,
      observacionesInternas: observacionesInternas ?? this.observacionesInternas,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      total: total ?? this.total,
      aprobadoPorUsuarioId: aprobadoPorUsuarioId ?? this.aprobadoPorUsuarioId,
      aprobadoFecha: aprobadoFecha ?? this.aprobadoFecha,
      usuarioCreadorId: usuarioCreadorId ?? this.usuarioCreadorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ========================================
  // HELPERS
  // ========================================

  /// Indica si la orden puede ser editada
  bool get puedeEditarse => estado == 'solicitado' || estado == 'en_revision';

  /// Indica si la orden puede ser aprobada
  bool get puedeAprobarse => estado == 'solicitado' || estado == 'en_revision';

  /// Indica si la orden puede ser rechazada
  bool get puedeRechazarse => estado == 'solicitado' || estado == 'en_revision';

  /// Indica si la orden puede cancelarse
  bool get puedeCancelarse => estado != 'despachado' && estado != 'facturado';

  /// Indica si está en un estado final
  bool get esFinal => estado == 'despachado' ||
      estado == 'facturado' ||
      estado == 'cancelado' ||
      estado == 'rechazado';
}

/// Modelo completo con datos relacionados (para mostrar en UI)
class OrdenInternaDetalle {
  final OrdenInterna orden;
  final String clienteRazonSocial;
  final String? obraNombre;
  final List<OrdenItemDetalle> items;
  final String? aprobadoPorNombre;

  OrdenInternaDetalle({
    required this.orden,
    required this.clienteRazonSocial,
    this.obraNombre,
    required this.items,
    this.aprobadoPorNombre,
  });

  /// Cantidad total de productos
  int get cantidadProductos => items.length;

  /// Cantidad total de unidades
  double get cantidadTotal => items.fold(
    0,
        (sum, item) => sum + item.cantidadFinal,
  );

  /// Indica si algún item fue modificado
  bool get tieneModificaciones => items.any((item) => item.fueModificada);
}

/// Enum de estados de orden
enum EstadoOrden {
  solicitado('solicitado', 'Solicitado', 'Pedido creado por el cliente'),
  enRevision('en_revision', 'En Revisión', 'Siendo revisado por S&G'),
  aprobado('aprobado', 'Aprobado', 'Aprobado y listo para preparar'),
  rechazado('rechazado', 'Rechazado', 'Pedido rechazado'),
  enPreparacion('en_preparacion', 'En Preparación', 'Armando el pedido'),
  listoEnvio('listo_envio', 'Listo para Envío', 'Preparado para despachar'),
  despachado('despachado', 'Despachado', 'Remito generado y enviado'),
  entregado('entregado', 'Entregado', 'Recibido por el cliente'),
  facturado('facturado', 'Facturado', 'Factura emitida'),
  cancelado('cancelado', 'Cancelado', 'Pedido cancelado');

  final String valor;
  final String label;
  final String descripcion;

  const EstadoOrden(this.valor, this.label, this.descripcion);

  static EstadoOrden fromString(String valor) {
    return EstadoOrden.values.firstWhere(
          (e) => e.valor == valor,
      orElse: () => EstadoOrden.solicitado,
    );
  }
}
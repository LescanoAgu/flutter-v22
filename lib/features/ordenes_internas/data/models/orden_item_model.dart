/// Modelo de Item de Orden (Producto dentro de una orden)
class OrdenItem {
  final int? id;
  final int ordenId;
  final int productoId;
  final double cantidadSolicitada;
  final double? cantidadAprobada;
  final double precioUnitario;
  final double subtotal;
  final String? observaciones;
  final DateTime createdAt;

  OrdenItem({
    this.id,
    required this.ordenId,
    required this.productoId,
    required this.cantidadSolicitada,
    this.cantidadAprobada,
    required this.precioUnitario,
    required this.subtotal,
    this.observaciones,
    required this.createdAt,
  });

  /// Conversión a Map para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orden_id': ordenId,
      'producto_id': productoId,
      'cantidad_solicitada': cantidadSolicitada,
      'cantidad_aprobada': cantidadAprobada,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'observaciones': observaciones,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crear desde Map de SQLite
  factory OrdenItem.fromMap(Map<String, dynamic> map) {
    return OrdenItem(
      id: map['id'] as int?,
      ordenId: map['orden_id'] as int,
      productoId: map['producto_id'] as int,
      cantidadSolicitada: map['cantidad_solicitada'] as double,
      cantidadAprobada: map['cantidad_aprobada'] as double?,
      precioUnitario: map['precio_unitario'] as double,
      subtotal: map['subtotal'] as double,
      observaciones: map['observaciones'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// CopyWith
  OrdenItem copyWith({
    int? id,
    int? ordenId,
    int? productoId,
    double? cantidadSolicitada,
    double? cantidadAprobada,
    double? precioUnitario,
    double? subtotal,
    String? observaciones,
    DateTime? createdAt,
  }) {
    return OrdenItem(
      id: id ?? this.id,
      ordenId: ordenId ?? this.ordenId,
      productoId: productoId ?? this.productoId,
      cantidadSolicitada: cantidadSolicitada ?? this.cantidadSolicitada,
      cantidadAprobada: cantidadAprobada ?? this.cantidadAprobada,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      observaciones: observaciones ?? this.observaciones,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Modelo extendido con datos del producto (para mostrar en UI)
class OrdenItemDetalle {
  final OrdenItem item;
  final String productoNombre;
  final String productoCodigo;
  final String unidadBase;
  final String categoriaNombre;

  OrdenItemDetalle({
    required this.item,
    required this.productoNombre,
    required this.productoCodigo,
    required this.unidadBase,
    required this.categoriaNombre,
  });

  /// Cantidad final (aprobada o solicitada)
  double get cantidadFinal => item.cantidadAprobada ?? item.cantidadSolicitada;

  /// Indica si fue modificada
  bool get fueModificada =>
      item.cantidadAprobada != null &&
          item.cantidadAprobada != item.cantidadSolicitada;
}
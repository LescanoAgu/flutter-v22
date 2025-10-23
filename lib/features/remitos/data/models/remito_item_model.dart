/// Modelo base para un item de remito
class RemitoItemModel {
  final int? id;
  final int remitoId;
  final int productoId;
  final double cantidad;
  final String? unidad;
  final String? descripcion;
  final int? ordenItemId;
  final DateTime? createdAt;

  RemitoItemModel({
    this.id,
    required this.remitoId,
    required this.productoId,
    required this.cantidad,
    this.unidad,
    this.descripcion,
    this.ordenItemId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remito_id': remitoId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'unidad': unidad,
      'descripcion': descripcion,
      'orden_item_id': ordenItemId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory RemitoItemModel.fromMap(Map<String, dynamic> map) {
    return RemitoItemModel(
      id: map['id'] as int?,
      remitoId: map['remito_id'] as int,
      productoId: map['producto_id'] as int,
      cantidad: (map['cantidad'] as num).toDouble(),
      unidad: map['unidad'] as String?,
      descripcion: map['descripcion'] as String?,
      ordenItemId: map['orden_item_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }
}

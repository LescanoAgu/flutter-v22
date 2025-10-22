import 'package:equatable/equatable.dart';

/// Modelo de Acopio
///
/// Representa material guardado para un cliente en una ubicación específica.
/// Clave única: Producto + Cliente + Proveedor
///
/// Ejemplo:
/// - Cliente Pérez tiene 50 bolsas de Pegamento P9 en Proveedor Angler
/// - S&G tiene 100 bolsas de Cemento en Proveedor Corralón X
class AcopioModel extends Equatable {
  final int? id;
  final int productoId;
  final int clienteId;             // Puede ser S&G (SYG-001)
  final int proveedorId;
  final double cantidadDisponible;
  final String estado;             // activo, agotado
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AcopioModel({
    this.id,
    required this.productoId,
    required this.clienteId,
    required this.proveedorId,
    required this.cantidadDisponible,
    this.estado = 'activo',
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory desde Map (BD)
  factory AcopioModel.fromMap(Map<String, dynamic> map) {
    return AcopioModel(
      id: map['id'],
      productoId: map['producto_id'],
      clienteId: map['cliente_id'],
      proveedorId: map['proveedor_id'],
      cantidadDisponible: (map['cantidad_disponible'] as num).toDouble(),
      estado: map['estado'] ?? 'activo',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  /// Convertir a Map (para BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'cliente_id': clienteId,
      'proveedor_id': proveedorId,
      'cantidad_disponible': cantidadDisponible,
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// CopyWith
  AcopioModel copyWith({
    int? id,
    int? productoId,
    int? clienteId,
    int? proveedorId,
    double? cantidadDisponible,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AcopioModel(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      clienteId: clienteId ?? this.clienteId,
      proveedorId: proveedorId ?? this.proveedorId,
      cantidadDisponible: cantidadDisponible ?? this.cantidadDisponible,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productoId,
    clienteId,
    proveedorId,
    cantidadDisponible,
    estado,
    createdAt,
    updatedAt,
  ];

  // Helpers
  bool get sinStock => cantidadDisponible <= 0;
  bool get tieneStock => cantidadDisponible > 0;
  bool get estaActivo => estado == 'activo';
}

/// Modelo extendido con información de producto, cliente y proveedor
/// (Para mostrar en la UI sin hacer múltiples queries)
class AcopioDetalle extends Equatable {
  final AcopioModel acopio;

  // Información del producto
  final String productoCodigo;
  final String productoNombre;
  final String unidadBase;
  final String categoriaCodigo;
  final String categoriaNombre;

  // Información del cliente
  final String clienteCodigo;
  final String clienteRazonSocial;

  // Información del proveedor
  final String proveedorCodigo;
  final String proveedorNombre;
  final String proveedorTipo;

  const AcopioDetalle({
    required this.acopio,
    required this.productoCodigo,
    required this.productoNombre,
    required this.unidadBase,
    required this.categoriaCodigo,
    required this.categoriaNombre,
    required this.clienteCodigo,
    required this.clienteRazonSocial,
    required this.proveedorCodigo,
    required this.proveedorNombre,
    required this.proveedorTipo,
  });

  factory AcopioDetalle.fromMap(Map<String, dynamic> map) {
    return AcopioDetalle(
      acopio: AcopioModel.fromMap(map),
      productoCodigo: map['producto_codigo'] ?? '',
      productoNombre: map['producto_nombre'] ?? '',
      unidadBase: map['unidad_base'] ?? '',
      categoriaCodigo: map['categoria_codigo'] ?? '',
      categoriaNombre: map['categoria_nombre'] ?? '',
      clienteCodigo: map['cliente_codigo'] ?? '',
      clienteRazonSocial: map['cliente_razon_social'] ?? '',
      proveedorCodigo: map['proveedor_codigo'] ?? '',
      proveedorNombre: map['proveedor_nombre'] ?? '',
      proveedorTipo: map['proveedor_tipo'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    acopio,
    productoCodigo,
    productoNombre,
    unidadBase,
    categoriaCodigo,
    categoriaNombre,
    clienteCodigo,
    clienteRazonSocial,
    proveedorCodigo,
    proveedorNombre,
    proveedorTipo,
  ];

  // Helpers
  String get descripcionCompleta => '$productoCodigo - $productoNombre';
  String get ubicacionCompleta => '$proveedorCodigo - $proveedorNombre';
  String get clienteCompleto => '$clienteCodigo - $clienteRazonSocial';

  /// Indica si el acopio está en depósito S&G
  bool get esDepositoSyg => proveedorTipo == 'deposito_syg';

  /// Formatea la cantidad con 2 decimales
  String get cantidadFormateada {
    if (acopio.cantidadDisponible % 1 == 0) {
      return acopio.cantidadDisponible.toInt().toString();
    }
    return acopio.cantidadDisponible.toStringAsFixed(2);
  }

}
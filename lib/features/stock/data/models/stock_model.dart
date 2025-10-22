import 'producto_model.dart';
import 'categoria_model.dart';
/// Modelo de datos para Stock
///
/// Representa el inventario actual de un producto.
/// Corresponde a la tabla 'stock' en la base de datos.
///
/// Relación: 1 Producto → 1 Stock (1:1)
class StockModel {
  final int? id;
  final int productoId; // FK a productos
  final double cantidadDisponible;
  final String? ultimaActualizacion;

  /// Constructor principal
  StockModel({
    this.id,
    required this.productoId,
    required this.cantidadDisponible,
    this.ultimaActualizacion,
  });

  /// Crea un StockModel desde un Map (de la BD)
  factory StockModel.fromMap(Map<String, dynamic> map) {
    return StockModel(
      id: map['id'] as int?,
      productoId: map['producto_id'] as int,
      cantidadDisponible: (map['cantidad_disponible'] as num).toDouble(),
      ultimaActualizacion: map['ultima_actualizacion'] as String?,
    );
  }

  /// Convierte el StockModel a un Map (para guardar en BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'cantidad_disponible': cantidadDisponible,
      'ultima_actualizacion': ultimaActualizacion,
    };
  }

  /// Crea una copia con valores modificados
  StockModel copyWith({
    int? id,
    int? productoId,
    double? cantidadDisponible,
    String? ultimaActualizacion,
  }) {
    return StockModel(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      cantidadDisponible: cantidadDisponible ?? this.cantidadDisponible,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }

  /// Verifica si hay stock disponible
  bool get hayStock => cantidadDisponible > 0;

  /// Verifica si el stock está bajo (menos de 10 unidades)
  bool get stockBajo => cantidadDisponible < 10 && cantidadDisponible > 0;

  /// Verifica si no hay stock
  bool get sinStock => cantidadDisponible <= 0;

  /// Obtiene la cantidad como entero (para productos que no usan decimales)
  int get cantidadEntera => cantidadDisponible.toInt();

  /// Formatea la cantidad para mostrar
  ///
  /// Si es entero: "50"
  /// Si tiene decimales: "50.5"
  String get cantidadFormateada {
    if (cantidadDisponible == cantidadDisponible.toInt()) {
      return cantidadEntera.toString();
    } else {
      return cantidadDisponible.toStringAsFixed(1);
    }
  }

  @override
  String toString() {
    return 'StockModel(id: $id, productoId: $productoId, cantidad: $cantidadDisponible)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modelo extendido: Producto + Stock
///
/// Combina la información del producto con su stock actual.
/// Útil para mostrar en listas.
class ProductoConStock {
  final int productoId;
  final String productoCodigo;
  final String productoNombre;
  final String unidadBase;
  final String? equivalencia;
  final double? precioSinIva;
  final int categoriaId;
  final String categoriaNombre;
  final String categoriaCodigo;
  final double cantidadDisponible;

  ProductoConStock({
    required this.productoId,
    required this.productoCodigo,
    required this.productoNombre,
    required this.unidadBase,
    this.equivalencia,
    this.precioSinIva,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.categoriaCodigo,
    required this.cantidadDisponible,
  });

  /// Crea desde un Map que incluye datos de productos, categorías y stock
  ///
  /// Query con JOIN múltiple:
  /// ```sql
  /// SELECT
  ///   p.id as producto_id,
  ///   p.codigo as producto_codigo,
  ///   p.nombre as producto_nombre,
  ///   p.unidad_base,
  ///   p.equivalencia,
  ///   p.precio_sin_iva,
  ///   c.id as categoria_id,
  ///   c.nombre as categoria_nombre,
  ///   c.codigo as categoria_codigo,
  ///   COALESCE(s.cantidad_disponible, 0) as cantidad_disponible
  /// FROM productos p
  /// JOIN categorias c ON p.categoria_id = c.id
  /// LEFT JOIN stock s ON p.id = s.producto_id
  /// ```
  factory ProductoConStock.fromMap(Map<String, dynamic> map) {
    return ProductoConStock(
      productoId: map['producto_id'] as int,
      productoCodigo: map['producto_codigo'] as String,
      productoNombre: map['producto_nombre'] as String,
      unidadBase: map['unidad_base'] as String,
      equivalencia: map['equivalencia'] as String?,
      precioSinIva: map['precio_sin_iva'] != null
          ? (map['precio_sin_iva'] as num).toDouble()
          : null,
      categoriaId: map['categoria_id'] as int,
      categoriaNombre: map['categoria_nombre'] as String,
      categoriaCodigo: map['categoria_codigo'] as String,
      cantidadDisponible: (map['cantidad_disponible'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Verifica si hay stock
  bool get hayStock => cantidadDisponible > 0;

  /// Verifica si el stock está bajo
  bool get stockBajo => cantidadDisponible < 10 && cantidadDisponible > 0;

  /// Verifica si no hay stock
  bool get sinStock => cantidadDisponible <= 0;

  /// Cantidad como entero
  int get cantidadEntera => cantidadDisponible.toInt();

  /// Cantidad formateada
  String get cantidadFormateada {
    if (cantidadDisponible == cantidadDisponible.toInt()) {
      return cantidadEntera.toString();
    } else {
      return cantidadDisponible.toStringAsFixed(1);
    }
  }

  /// Precio formateado
  String get precioFormateado {
    if (precioSinIva == null) return '-';
    return '\$${precioSinIva!.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    )}';
  }

  /// Descripción de unidad completa
  String get unidadCompleta {
    if (equivalencia != null && equivalencia!.isNotEmpty) {
      return '$unidadBase ($equivalencia)';
    }
    return unidadBase;
  }

  @override
  String toString() {
    return 'ProductoConStock($productoCodigo - $productoNombre: $cantidadDisponible $unidadBase)';
  }
}
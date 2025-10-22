/// Modelo de datos para Productos
///
/// Representa un producto/material en el inventario.
/// Corresponde a la tabla 'productos' en la base de datos.
///
/// Ejemplo:
/// - Código: OG-001
/// - Nombre: Cemento Portland
/// - Categoría: Obra General (id: 6)
/// - Unidad: Bolsa
/// - Precio: 12500.00
class ProductoModel {
  final int? id;
  final String codigo; // OG-001, H-015, P-003
  final int categoriaId; // FK a categorias
  final String nombre;
  final String? descripcion;
  final String unidadBase; // Bolsa, Litro, Caño, m², Unidad
  final String? equivalencia; // 25kg, 50kg, 4m, etc.
  final double? precioSinIva;
  final String estado; // activo/inactivo
  final String? createdAt;
  final String? updatedAt;

  /// Constructor principal
  ProductoModel({
    this.id,
    required this.codigo,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.unidadBase,
    this.equivalencia,
    this.precioSinIva,
    this.estado = 'activo',
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un ProductoModel desde un Map (de la BD)
  ///
  /// Ejemplo:
  /// ```dart
  /// Map<String, dynamic> row = {
  ///   'id': 1,
  ///   'codigo': 'OG-001',
  ///   'categoria_id': 6,
  ///   'nombre': 'Cemento Portland',
  ///   'precio_sin_iva': 12500.00,
  ///   ...
  /// };
  /// ProductoModel producto = ProductoModel.fromMap(row);
  /// ```
  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      categoriaId: map['categoria_id'] as int,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      unidadBase: map['unidad_base'] as String,
      equivalencia: map['equivalencia'] as String?,
      precioSinIva: map['precio_sin_iva'] != null
          ? (map['precio_sin_iva'] as num).toDouble()
          : null,
      estado: map['estado'] as String? ?? 'activo',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Convierte el ProductoModel a un Map (para guardar en BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'categoria_id': categoriaId,
      'nombre': nombre,
      'descripcion': descripcion,
      'unidad_base': unidadBase,
      'equivalencia': equivalencia,
      'precio_sin_iva': precioSinIva,
      'estado': estado,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Crea una copia con valores modificados
  ProductoModel copyWith({
    int? id,
    String? codigo,
    int? categoriaId,
    String? nombre,
    String? descripcion,
    String? unidadBase,
    String? equivalencia,
    double? precioSinIva,
    String? estado,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      categoriaId: categoriaId ?? this.categoriaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      unidadBase: unidadBase ?? this.unidadBase,
      equivalencia: equivalencia ?? this.equivalencia,
      precioSinIva: precioSinIva ?? this.precioSinIva,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica si el producto está activo
  bool get isActivo => estado == 'activo';

  /// Obtiene el precio formateado como string
  ///
  /// Ejemplo: $12,500.00
  String get precioFormateado {
    if (precioSinIva == null) return '-';
    return '\$${precioSinIva!.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    )}';
  }

  /// Obtiene la descripción completa del producto
  ///
  /// Ejemplo: "Cemento Portland - Bolsa (25kg)"
  String get descripcionCompleta {
    String desc = nombre;
    if (equivalencia != null && equivalencia!.isNotEmpty) {
      desc += ' - $unidadBase ($equivalencia)';
    } else {
      desc += ' - $unidadBase';
    }
    return desc;
  }

  @override
  String toString() {
    return 'ProductoModel(id: $id, codigo: $codigo, nombre: $nombre, precio: $precioFormateado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modelo extendido que incluye la categoría completa
///
/// Útil cuando necesitás mostrar productos CON su categoría
/// sin hacer múltiples queries.
class ProductoConCategoria {
  final ProductoModel producto;
  final String categoriaNombre;
  final String categoriaCodigo;

  ProductoConCategoria({
    required this.producto,
    required this.categoriaNombre,
    required this.categoriaCodigo,
  });

  /// Crea desde un Map que incluye datos de productos y categorías
  ///
  /// Ejemplo de query con JOIN:
  /// ```sql
  /// SELECT p.*, c.nombre as categoria_nombre, c.codigo as categoria_codigo
  /// FROM productos p
  /// JOIN categorias c ON p.categoria_id = c.id
  /// ```
  factory ProductoConCategoria.fromMap(Map<String, dynamic> map) {
    return ProductoConCategoria(
      producto: ProductoModel.fromMap(map),
      categoriaNombre: map['categoria_nombre'] as String,
      categoriaCodigo: map['categoria_codigo'] as String,
    );
  }

  @override
  String toString() {
    return 'ProductoConCategoria(${producto.codigo} - ${producto.nombre} [${categoriaCodigo}])';
  }
}
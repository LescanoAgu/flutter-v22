/// Modelo de datos para Categorías
///
/// Representa una categoría de productos (Obra General, Hierros, Pintura, etc.)
/// Este modelo corresponde a la tabla 'categorias' en la base de datos.
class CategoriaModel {
  final int? id; // Puede ser null cuando creamos una nueva categoría
  final String codigo; // A, E, G, H, M, OG, P, S
  final String nombre; // Agua, Eléctrico, Gas, etc.
  final String? descripcion; // Descripción opcional
  final int orden; // Orden de visualización
  final String? createdAt; // Fecha de creación (opcional al crear)

  /// Constructor principal
  CategoriaModel({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.orden,
    this.createdAt,
  });

  /// Crea una CategoriaModel desde un Map (lo que devuelve la BD)
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// Map<String, dynamic> row = await db.query('categorias', where: 'id = ?', whereArgs: [1]);
  /// CategoriaModel categoria = CategoriaModel.fromMap(row);
  /// ```
  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      orden: map['orden'] as int,
      createdAt: map['created_at'] as String?,
    );
  }

  /// Convierte la CategoriaModel a un Map (para guardar en BD)
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// CategoriaModel categoria = CategoriaModel(...);
  /// await db.insert('categorias', categoria.toMap());
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'orden': orden,
      'created_at': createdAt,
    };
  }

  /// Crea una copia de la categoría con valores modificados
  ///
  /// Útil cuando querés cambiar solo algunos campos:
  /// ```dart
  /// CategoriaModel categoriaActualizada = categoria.copyWith(
  ///   nombre: 'Nuevo Nombre',
  /// );
  /// ```
  CategoriaModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    int? orden,
    String? createdAt,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Representación en texto de la categoría (útil para debugging)
  @override
  String toString() {
    return 'CategoriaModel(id: $id, codigo: $codigo, nombre: $nombre)';
  }

  /// Compara dos categorías por su id
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoriaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

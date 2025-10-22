import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/producto_model.dart';

/// Repositorio de Productos
///
/// Maneja todas las operaciones de base de datos relacionadas con productos.
/// Incluye operaciones con JOIN para obtener productos con sus categorías.
class ProductoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'productos';

  // ========================================
  // LECTURA (READ) - Operaciones básicas
  // ========================================

  /// Obtiene TODOS los productos activos ordenados por código
  ///
  /// Ejemplo:
  /// ```dart
  /// List<ProductoModel> productos = await repo.obtenerTodos();
  /// print('Total: ${productos.length}');
  /// ```
  Future<List<ProductoModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: soloActivos ? 'estado = ?' : null,
        whereArgs: soloActivos ? ['activo'] : null,
        orderBy: 'codigo ASC',
      );

      return List.generate(maps.length, (i) {
        return ProductoModel.fromMap(maps[i]);
      });

    } catch (e) {
      print('❌ Error al obtener productos: $e');
      return [];
    }
  }

  /// Obtiene un producto por su ID
  Future<ProductoModel?> obtenerPorId(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ProductoModel.fromMap(maps.first);
      }

      return null;

    } catch (e) {
      print('❌ Error al obtener producto por id $id: $e');
      return null;
    }
  }

  /// Obtiene un producto por su código
  ///
  /// Ejemplo:
  /// ```dart
  /// ProductoModel? producto = await repo.obtenerPorCodigo('OG-001');
  /// ```
  Future<ProductoModel?> obtenerPorCodigo(String codigo) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ProductoModel.fromMap(maps.first);
      }

      return null;

    } catch (e) {
      print('❌ Error al obtener producto por código $codigo: $e');
      return null;
    }
  }

  // ========================================
  // LECTURA CON JOIN (productos + categorías)
  // ========================================

  /// Obtiene todos los productos CON información de su categoría
  ///
  /// Usa un JOIN para traer productos y categorías en una sola query.
  ///
  /// Ejemplo:
  /// ```dart
  /// List<ProductoConCategoria> productos = await repo.obtenerTodosConCategoria();
  /// for (var item in productos) {
  ///   print('${item.producto.nombre} - Categoría: ${item.categoriaNombre}');
  /// }
  /// ```
  Future<List<ProductoConCategoria>> obtenerTodosConCategoria({
    bool soloActivos = true,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      // Query con JOIN
      final String query = '''
        SELECT 
          p.*,
          c.nombre as categoria_nombre,
          c.codigo as categoria_codigo
        FROM $_tableName p
        INNER JOIN categorias c ON p.categoria_id = c.id
        ${soloActivos ? 'WHERE p.estado = ?' : ''}
        ORDER BY p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        query,
        soloActivos ? ['activo'] : null,
      );

      return List.generate(maps.length, (i) {
        return ProductoConCategoria.fromMap(maps[i]);
      });

    } catch (e) {
      print('❌ Error al obtener productos con categoría: $e');
      return [];
    }
  }

  /// Obtiene un producto por ID con su categoría
  Future<ProductoConCategoria?> obtenerPorIdConCategoria(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          p.*,
          c.nombre as categoria_nombre,
          c.codigo as categoria_codigo
        FROM $_tableName p
        INNER JOIN categorias c ON p.categoria_id = c.id
        WHERE p.id = ?
        LIMIT 1
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, [id]);

      if (maps.isNotEmpty) {
        return ProductoConCategoria.fromMap(maps.first);
      }

      return null;

    } catch (e) {
      print('❌ Error al obtener producto por id con categoría: $e');
      return null;
    }
  }

  // ========================================
  // FILTROS Y BÚSQUEDAS
  // ========================================

  /// Obtiene productos de una categoría específica
  ///
  /// Ejemplo:
  /// ```dart
  /// // Obtener todos los productos de Obra General (id: 6)
  /// List<ProductoModel> productos = await repo.obtenerPorCategoria(6);
  /// ```
  Future<List<ProductoModel>> obtenerPorCategoria(
      int categoriaId, {
        bool soloActivos = true,
      }) async {
    try {
      final Database db = await _dbHelper.database;

      String where = 'categoria_id = ?';
      List<dynamic> whereArgs = [categoriaId];

      if (soloActivos) {
        where += ' AND estado = ?';
        whereArgs.add('activo');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'codigo ASC',
      );

      return List.generate(maps.length, (i) {
        return ProductoModel.fromMap(maps[i]);
      });

    } catch (e) {
      print('❌ Error al obtener productos por categoría: $e');
      return [];
    }
  }

  /// Busca productos por nombre o código (búsqueda flexible)
  ///
  /// Ejemplo:
  /// ```dart
  /// // Buscar "cemento" encuentra: "Cemento Portland", "Cemento CPF-40"
  /// List<ProductoModel> resultados = await repo.buscar('cemento');
  /// ```
  Future<List<ProductoModel>> buscar(
      String termino, {
        bool soloActivos = true,
      }) async {
    try {
      final Database db = await _dbHelper.database;

      String where = '(nombre LIKE ? OR codigo LIKE ?)';
      List<dynamic> whereArgs = ['%$termino%', '%$termino%'];

      if (soloActivos) {
        where += ' AND estado = ?';
        whereArgs.add('activo');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'codigo ASC',
      );

      return List.generate(maps.length, (i) {
        return ProductoModel.fromMap(maps[i]);
      });

    } catch (e) {
      print('❌ Error al buscar productos: $e');
      return [];
    }
  }

  /// Busca productos CON categoría (más útil para la UI)
  Future<List<ProductoConCategoria>> buscarConCategoria(
      String termino, {
        bool soloActivos = true,
      }) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          p.*,
          c.nombre as categoria_nombre,
          c.codigo as categoria_codigo
        FROM $_tableName p
        INNER JOIN categorias c ON p.categoria_id = c.id
        WHERE (p.nombre LIKE ? OR p.codigo LIKE ?)
        ${soloActivos ? 'AND p.estado = ?' : ''}
        ORDER BY p.codigo ASC
      ''';

      List<dynamic> args = ['%$termino%', '%$termino%'];
      if (soloActivos) args.add('activo');

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

      return List.generate(maps.length, (i) {
        return ProductoConCategoria.fromMap(maps[i]);
      });

    } catch (e) {
      print('❌ Error al buscar productos con categoría: $e');
      return [];
    }
  }

  /// Filtra productos por rango de precios
  ///
  /// Ejemplo:
  /// ```dart
  /// // Productos entre $10,000 y $20,000
  /// List<ProductoModel> productos = await repo.filtrarPorPrecio(10000, 20000);
  /// ```
  Future<List<ProductoModel>> filtrarPorPrecio(
      double precioMin,
      double precioMax, {
        bool soloActivos = true,
      }) async {
    try {
      final Database db = await _dbHelper.database;

      String where = 'precio_sin_iva BETWEEN ? AND ?';
      List<dynamic> whereArgs = [precioMin, precioMax];

      if (soloActivos) {
        where += ' AND estado = ?';
        whereArgs.add('activo');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'precio_sin_iva ASC',
      );

      return List.generate(maps.length, (i) {
        return ProductoModel.fromMap(maps[i]);
      });

    } catch (e) {
      print('❌ Error al filtrar por precio: $e');
      return [];
    }
  }

  // ========================================
  // ESCRITURA (CREATE / UPDATE / DELETE)
  // ========================================

  /// Crea un nuevo producto
  ///
  /// Ejemplo:
  /// ```dart
  /// ProductoModel nuevo = ProductoModel(
  ///   codigo: 'OG-001',
  ///   categoriaId: 6,
  ///   nombre: 'Cemento Portland',
  ///   unidadBase: 'Bolsa',
  ///   precioSinIva: 12500.0,
  /// );
  ///
  /// int id = await repo.crear(nuevo);
  /// ```
  Future<int> crear(ProductoModel producto) async {
    try {
      final Database db = await _dbHelper.database;

      final int id = await db.insert(
        _tableName,
        producto.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      print('✅ Producto creado con id: $id');
      return id;

    } catch (e) {
      print('❌ Error al crear producto: $e');
      rethrow;
    }
  }

  /// Actualiza un producto existente
  Future<int> actualizar(ProductoModel producto) async {
    try {
      final Database db = await _dbHelper.database;

      // Añadir fecha de actualización
      final productoConFecha = producto.copyWith(
        updatedAt: DateTime.now().toIso8601String(),
      );

      final int count = await db.update(
        _tableName,
        productoConFecha.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );

      print('✅ Producto actualizado. Filas afectadas: $count');
      return count;

    } catch (e) {
      print('❌ Error al actualizar producto: $e');
      rethrow;
    }
  }

  /// Marca un producto como inactivo (soft delete)
  ///
  /// Mejor práctica: no eliminar físicamente, solo marcar como inactivo.
  Future<int> desactivar(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.update(
        _tableName,
        {
          'estado': 'inactivo',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ Producto desactivado. Filas afectadas: $count');
      return count;

    } catch (e) {
      print('❌ Error al desactivar producto: $e');
      rethrow;
    }
  }

  /// Reactiva un producto
  Future<int> activar(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.update(
        _tableName,
        {
          'estado': 'activo',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ Producto activado. Filas afectadas: $count');
      return count;

    } catch (e) {
      print('❌ Error al activar producto: $e');
      rethrow;
    }
  }

  /// Elimina un producto permanentemente (hard delete)
  /// ⚠️ Usar con precaución - solo para testing
  Future<int> eliminar(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ Producto eliminado. Filas afectadas: $count');
      return count;

    } catch (e) {
      print('❌ Error al eliminar producto: $e');
      rethrow;
    }
  }

  // ========================================
  // UTILIDADES Y ESTADÍSTICAS
  // ========================================

  /// Cuenta el total de productos (activos o todos)
  Future<int> contar({bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = soloActivos
          ? 'SELECT COUNT(*) FROM $_tableName WHERE estado = ?'
          : 'SELECT COUNT(*) FROM $_tableName';

      final int? count = Sqflite.firstIntValue(
        await db.rawQuery(query, soloActivos ? ['activo'] : null),
      );

      return count ?? 0;

    } catch (e) {
      print('❌ Error al contar productos: $e');
      return 0;
    }
  }

  /// Cuenta productos por categoría
  ///
  /// Devuelve un Map: {categoriaId: cantidad}
  Future<Map<int, int>> contarPorCategoria() async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT categoria_id, COUNT(*) as total
        FROM $_tableName
        WHERE estado = ?
        GROUP BY categoria_id
      ''';

      final List<Map<String, dynamic>> result =
      await db.rawQuery(query, ['activo']);

      Map<int, int> conteo = {};
      for (var row in result) {
        conteo[row['categoria_id'] as int] = row['total'] as int;
      }

      return conteo;

    } catch (e) {
      print('❌ Error al contar por categoría: $e');
      return {};
    }
  }

  /// Verifica si existe un código
  Future<bool> existeCodigo(String codigo) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      return maps.isNotEmpty;

    } catch (e) {
      print('❌ Error al verificar código: $e');
      return false;
    }
  }

  /// Genera el siguiente código disponible para una categoría
  ///
  /// Ejemplo: Si existe OG-001, OG-002, devuelve "OG-003"
  Future<String> generarSiguienteCodigo(String codigoCategoria) async {
    try {
      final Database db = await _dbHelper.database;

      // Buscar el último código de esa categoría
      final String query = '''
        SELECT codigo
        FROM $_tableName
        WHERE codigo LIKE ?
        ORDER BY codigo DESC
        LIMIT 1
      ''';

      final List<Map<String, dynamic>> result =
      await db.rawQuery(query, ['$codigoCategoria-%']);

      if (result.isEmpty) {
        // Primera vez: OG-001
        return '$codigoCategoria-001';
      }

      // Extraer el número del último código
      String ultimoCodigo = result.first['codigo'] as String;
      String numeroStr = ultimoCodigo.split('-').last;
      int numero = int.parse(numeroStr);

      // Incrementar y formatear con 3 dígitos
      String nuevoCodigo = '$codigoCategoria-${(numero + 1).toString().padLeft(3, '0')}';

      return nuevoCodigo;

    } catch (e) {
      print('❌ Error al generar código: $e');
      return '$codigoCategoria-001'; // Fallback
    }
  }
}
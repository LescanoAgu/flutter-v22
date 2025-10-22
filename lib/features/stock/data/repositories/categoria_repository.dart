import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/categoria_model.dart';

/// Repositorio de Categorías
/// 
/// Esta clase maneja TODAS las operaciones de base de datos
/// relacionadas con categorías.
/// 
/// Responsabilidades:
/// - Obtener categorías (todas, por id, por código)
/// - Crear nuevas categorías
/// - Actualizar categorías existentes
/// - Eliminar categorías (soft delete)
class CategoriaRepository {
  // Instancia del helper de base de datos
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Nombre de la tabla
  static const String _tableName = 'categorias';

  // ========================================
  // OPERACIONES DE LECTURA (READ)
  // ========================================

  /// Obtiene TODAS las categorías ordenadas por 'orden'
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// CategoriaRepository repo = CategoriaRepository();
  /// List<CategoriaModel> categorias = await repo.obtenerTodas();
  /// print('Total: ${categorias.length}'); // Total: 8
  /// ```
  Future<List<CategoriaModel>> obtenerTodas() async {
    try {
      // 1. Obtener la base de datos
      final Database db = await _dbHelper.database;
      
      // 2. Hacer la query (consulta)
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'orden ASC', // Ordenar por el campo 'orden' ascendente
      );
      
      // 3. Convertir cada Map en un CategoriaModel
      return List.generate(maps.length, (i) {
        return CategoriaModel.fromMap(maps[i]);
      });
      
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
      return []; // Si hay error, devolver lista vacía
    }
  }

  /// Obtiene una categoría por su ID
  /// 
  /// Devuelve null si no encuentra la categoría.
  /// 
  /// Ejemplo:
  /// ```dart
  /// CategoriaModel? categoria = await repo.obtenerPorId(1);
  /// if (categoria != null) {
  ///   print('Encontrada: ${categoria.nombre}');
  /// } else {
  ///   print('No existe');
  /// }
  /// ```
  Future<CategoriaModel?> obtenerPorId(int id) async {
    try {
      final Database db = await _dbHelper.database;
      
      // Query con WHERE
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?', // El ? es un placeholder
        whereArgs: [id], // Se reemplaza por el valor de id
        limit: 1, // Solo traer 1 resultado
      );
      
      // Si encontró algo, convertir a modelo
      if (maps.isNotEmpty) {
        return CategoriaModel.fromMap(maps.first);
      }
      
      return null; // No encontró nada
      
    } catch (e) {
      print('❌ Error al obtener categoría por id $id: $e');
      return null;
    }
  }

  /// Obtiene una categoría por su código (A, E, G, H, etc.)
  /// 
  /// Ejemplo:
  /// ```dart
  /// CategoriaModel? categoria = await repo.obtenerPorCodigo('OG');
  /// print(categoria?.nombre); // Obra General
  /// ```
  Future<CategoriaModel?> obtenerPorCodigo(String codigo) async {
    try {
      final Database db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return CategoriaModel.fromMap(maps.first);
      }
      
      return null;
      
    } catch (e) {
      print('❌ Error al obtener categoría por código $codigo: $e');
      return null;
    }
  }

  /// Busca categorías por nombre (búsqueda parcial)
  /// 
  /// Usa LIKE para búsqueda flexible.
  /// 
  /// Ejemplo:
  /// ```dart
  /// List<CategoriaModel> resultados = await repo.buscarPorNombre('obra');
  /// // Encuentra: "Obra General"
  /// ```
  Future<List<CategoriaModel>> buscarPorNombre(String termino) async {
    try {
      final Database db = await _dbHelper.database;
      
      // LIKE '%termino%' busca en cualquier parte del nombre
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'nombre LIKE ?',
        whereArgs: ['%$termino%'], // % significa "cualquier texto"
        orderBy: 'orden ASC',
      );
      
      return List.generate(maps.length, (i) {
        return CategoriaModel.fromMap(maps[i]);
      });
      
    } catch (e) {
      print('❌ Error al buscar categorías por nombre "$termino": $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA (CREATE/UPDATE/DELETE)
  // ========================================

  /// Crea una nueva categoría
  /// 
  /// Devuelve el ID generado por la base de datos.
  /// 
  /// Ejemplo:
  /// ```dart
  /// CategoriaModel nueva = CategoriaModel(
  ///   codigo: 'TEST',
  ///   nombre: 'Categoría de Prueba',
  ///   orden: 99,
  /// );
  /// 
  /// int id = await repo.crear(nueva);
  /// print('Categoría creada con id: $id');
  /// ```
  Future<int> crear(CategoriaModel categoria) async {
    try {
      final Database db = await _dbHelper.database;
      
      // insert devuelve el id generado
      final int id = await db.insert(
        _tableName,
        categoria.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort, // Si hay conflicto (código duplicado), abortar
      );
      
      print('✅ Categoría creada con id: $id');
      return id;
      
    } catch (e) {
      print('❌ Error al crear categoría: $e');
      rethrow; // Re-lanzar el error para que quien llame pueda manejarlo
    }
  }

  /// Actualiza una categoría existente
  /// 
  /// Devuelve el número de filas afectadas (debería ser 1).
  /// 
  /// Ejemplo:
  /// ```dart
  /// CategoriaModel categoria = await repo.obtenerPorId(1);
  /// CategoriaModel actualizada = categoria.copyWith(
  ///   nombre: 'Nuevo Nombre',
  /// );
  /// 
  /// int filasAfectadas = await repo.actualizar(actualizada);
  /// ```
  Future<int> actualizar(CategoriaModel categoria) async {
    try {
      final Database db = await _dbHelper.database;
      
      // update devuelve el número de filas afectadas
      final int count = await db.update(
        _tableName,
        categoria.toMap(),
        where: 'id = ?',
        whereArgs: [categoria.id],
      );
      
      print('✅ Categoría actualizada. Filas afectadas: $count');
      return count;
      
    } catch (e) {
      print('❌ Error al actualizar categoría: $e');
      rethrow;
    }
  }

  /// Elimina una categoría (hard delete - eliminación física)
  /// 
  /// ⚠️ ADVERTENCIA: Esto elimina permanentemente el registro.
  /// En producción, normalmente usarías soft delete (marcar como inactiva).
  /// 
  /// Devuelve el número de filas eliminadas (debería ser 1).
  /// 
  /// Ejemplo:
  /// ```dart
  /// int eliminadas = await repo.eliminar(1);
  /// if (eliminadas > 0) {
  ///   print('Categoría eliminada');
  /// }
  /// ```
  Future<int> eliminar(int id) async {
    try {
      final Database db = await _dbHelper.database;
      
      final int count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('✅ Categoría eliminada. Filas afectadas: $count');
      return count;
      
    } catch (e) {
      print('❌ Error al eliminar categoría: $e');
      rethrow;
    }
  }

  // ========================================
  // OPERACIONES ESPECIALES
  // ========================================

  /// Cuenta el total de categorías
  /// 
  /// Ejemplo:
  /// ```dart
  /// int total = await repo.contarTodas();
  /// print('Total de categorías: $total'); // 8
  /// ```
  Future<int> contarTodas() async {
    try {
      final Database db = await _dbHelper.database;
      
      // Sqflite.firstIntValue() extrae el primer valor entero del resultado
      final int? count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_tableName'),
      );
      
      return count ?? 0; // Si es null, devolver 0
      
    } catch (e) {
      print('❌ Error al contar categorías: $e');
      return 0;
    }
  }

  /// Verifica si existe una categoría con un código dado
  /// 
  /// Útil antes de crear una nueva categoría.
  /// 
  /// Ejemplo:
  /// ```dart
  /// bool existe = await repo.existeCodigo('OG');
  /// if (existe) {
  ///   print('El código OG ya está en uso');
  /// }
  /// ```
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

  /// Obtiene la categoría con el orden más alto (último)
  /// 
  /// Útil para saber qué orden asignar a una nueva categoría.
  /// 
  /// Ejemplo:
  /// ```dart
  /// CategoriaModel? ultima = await repo.obtenerUltima();
  /// int nuevoOrden = (ultima?.orden ?? 0) + 1;
  /// ```
  Future<CategoriaModel?> obtenerUltima() async {
    try {
      final Database db = await _dbHelper.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'orden DESC', // Descendente: del más alto al más bajo
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return CategoriaModel.fromMap(maps.first);
      }
      
      return null;
      
    } catch (e) {
      print('❌ Error al obtener última categoría: $e');
      return null;
    }
  }
}
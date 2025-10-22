import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/proveedor_model.dart';

/// Repositorio de Proveedores/Ubicaciones
///
/// Maneja todas las operaciones de BD relacionadas con proveedores.
class ProveedorRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'proveedores';

  // ========================================
  // OPERACIONES DE LECTURA
  // ========================================

  /// Obtiene TODOS los proveedores
  Future<List<ProveedorModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: soloActivos ? 'estado = ?' : null,
        whereArgs: soloActivos ? ['activo'] : null,
        orderBy: 'nombre ASC',
      );

      return List.generate(maps.length, (i) {
        return ProveedorModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener proveedores: $e');
      return [];
    }
  }

  /// Obtiene un proveedor por ID
  Future<ProveedorModel?> obtenerPorId(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ProveedorModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener proveedor por id $id: $e');
      return null;
    }
  }

  /// Obtiene un proveedor por código
  Future<ProveedorModel?> obtenerPorCodigo(String codigo) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ProveedorModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener proveedor por código $codigo: $e');
      return null;
    }
  }

  /// Obtiene el depósito S&G
  Future<ProveedorModel?> obtenerDepositoSyg() async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'tipo = ?',
        whereArgs: ['deposito_syg'],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ProveedorModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener depósito S&G: $e');
      return null;
    }
  }

  /// Busca proveedores por nombre o código
  Future<List<ProveedorModel>> buscar(String termino, {bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      String whereClause = '(nombre LIKE ? OR codigo LIKE ?)';
      if (soloActivos) {
        whereClause += ' AND estado = ?';
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: soloActivos
            ? ['%$termino%', '%$termino%', 'activo']
            : ['%$termino%', '%$termino%'],
        orderBy: 'nombre ASC',
      );

      return List.generate(maps.length, (i) {
        return ProveedorModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al buscar proveedores: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA
  // ========================================

  /// Crea un nuevo proveedor
  Future<int> crear(ProveedorModel proveedor) async {
    try {
      final Database db = await _dbHelper.database;

      final id = await db.insert(
        _tableName,
        proveedor.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      print('✅ Proveedor creado con id: $id');
      return id;
    } catch (e) {
      print('❌ Error al crear proveedor: $e');
      rethrow;
    }
  }

  /// Actualiza un proveedor existente
  Future<void> actualizar(ProveedorModel proveedor) async {
    try {
      final Database db = await _dbHelper.database;

      await db.update(
        _tableName,
        proveedor.copyWith(updatedAt: DateTime.now()).toMap(),
        where: 'id = ?',
        whereArgs: [proveedor.id],
      );

      print('✅ Proveedor actualizado');
    } catch (e) {
      print('❌ Error al actualizar proveedor: $e');
      rethrow;
    }
  }

  /// Cambia el estado de un proveedor
  Future<void> cambiarEstado(int id, String nuevoEstado) async {
    try {
      final Database db = await _dbHelper.database;

      await db.update(
        _tableName,
        {
          'estado': nuevoEstado,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ Estado de proveedor actualizado a: $nuevoEstado');
    } catch (e) {
      print('❌ Error al cambiar estado: $e');
      rethrow;
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Verifica si existe un código
  Future<bool> existeCodigo(String codigo) async {
    try {
      final Database db = await _dbHelper.database;

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableName WHERE codigo = ?',
          [codigo],
        ),
      );

      return count != null && count > 0;
    } catch (e) {
      print('❌ Error al verificar código: $e');
      return false;
    }
  }

  /// Genera el siguiente código disponible
  Future<String> generarSiguienteCodigo() async {
    try {
      final Database db = await _dbHelper.database;

      final result = await db.rawQuery(
        'SELECT MAX(CAST(SUBSTR(codigo, 6) AS INTEGER)) as max_num FROM $_tableName WHERE codigo LIKE "PROV-%"',
      );

      int nextNum = 1;
      if (result.isNotEmpty && result.first['max_num'] != null) {
        nextNum = (result.first['max_num'] as int) + 1;
      }

      return 'PROV-${nextNum.toString().padLeft(3, '0')}';
    } catch (e) {
      print('❌ Error al generar código: $e');
      return 'PROV-001';
    }
  }
}
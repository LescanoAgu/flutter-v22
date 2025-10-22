import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/cliente_model.dart';

/// Repositorio de Clientes
///
/// Maneja todas las operaciones de base de datos relacionadas con clientes.
class ClienteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'clientes';

  // ========================================
  // OPERACIONES DE LECTURA (READ)
  // ========================================

  /// Obtiene TODOS los clientes
  Future<List<ClienteModel>> obtenerTodos({bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: soloActivos ? 'estado = ?' : null,
        whereArgs: soloActivos ? ['activo'] : null,
        orderBy: 'razon_social ASC',
      );

      return List.generate(maps.length, (i) {
        return ClienteModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener clientes: $e');
      return [];
    }
  }

  /// Obtiene un cliente por su ID
  Future<ClienteModel?> obtenerPorId(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ClienteModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener cliente por id $id: $e');
      return null;
    }
  }

  /// Obtiene un cliente por su código
  Future<ClienteModel?> obtenerPorCodigo(String codigo) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ClienteModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener cliente por código $codigo: $e');
      return null;
    }
  }

  /// Busca clientes por razón social o CUIT
  Future<List<ClienteModel>> buscar(String termino, {bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      String whereClause = '(razon_social LIKE ? OR cuit LIKE ? OR codigo LIKE ?)';
      if (soloActivos) {
        whereClause += ' AND estado = ?';
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: soloActivos
            ? ['%$termino%', '%$termino%', '%$termino%', 'activo']
            : ['%$termino%', '%$termino%', '%$termino%'],
        orderBy: 'razon_social ASC',
      );

      return List.generate(maps.length, (i) {
        return ClienteModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al buscar clientes: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA (CREATE/UPDATE/DELETE)
  // ========================================

  /// Crea un nuevo cliente
  Future<int> crear(ClienteModel cliente) async {
    try {
      final Database db = await _dbHelper.database;

      final int id = await db.insert(
        _tableName,
        cliente.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      print('✅ Cliente creado con id: $id');
      return id;
    } catch (e) {
      print('❌ Error al crear cliente: $e');
      rethrow;
    }
  }

  /// Actualiza un cliente existente
  Future<int> actualizar(ClienteModel cliente) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.update(
        _tableName,
        cliente.toMap(),
        where: 'id = ?',
        whereArgs: [cliente.id],
      );

      print('✅ Cliente actualizado. Filas afectadas: $count');
      return count;
    } catch (e) {
      print('❌ Error al actualizar cliente: $e');
      rethrow;
    }
  }

  /// Elimina un cliente (soft delete - marca como inactivo)
  Future<int> eliminar(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.update(
        _tableName,
        {'estado': 'inactivo', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ Cliente marcado como inactivo. Filas afectadas: $count');
      return count;
    } catch (e) {
      print('❌ Error al eliminar cliente: $e');
      rethrow;
    }
  }

  /// Restaura un cliente inactivo
  Future<int> restaurar(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.update(
        _tableName,
        {'estado': 'activo', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ Cliente restaurado. Filas afectadas: $count');
      return count;
    } catch (e) {
      print('❌ Error al restaurar cliente: $e');
      rethrow;
    }
  }

  // ========================================
  // OPERACIONES ESPECIALES
  // ========================================

  /// Cuenta el total de clientes
  Future<int> contar({bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final int? count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableName${soloActivos ? " WHERE estado = 'activo'" : ""}',
        ),
      );

      return count ?? 0;
    } catch (e) {
      print('❌ Error al contar clientes: $e');
      return 0;
    }
  }

  /// Verifica si existe un cliente con un código dado
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

  /// Verifica si existe un cliente con un CUIT dado
  Future<bool> existeCuit(String cuit) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cuit = ?',
        whereArgs: [cuit],
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      print('❌ Error al verificar CUIT: $e');
      return false;
    }
  }

  /// Genera el siguiente código de cliente (CL-XXX)
  Future<String> generarSiguienteCodigo() async {
    try {
      final Database db = await _dbHelper.database;

      // Obtener el último código
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT codigo FROM $_tableName ORDER BY id DESC LIMIT 1',
      );

      if (maps.isEmpty) {
        return 'CL-001';
      }

      // Extraer el número del último código (CL-001 -> 001)
      String ultimoCodigo = maps.first['codigo'] as String;
      String numeroStr = ultimoCodigo.split('-').last;
      int numero = int.parse(numeroStr);

      // Incrementar y formatear
      numero++;
      return 'CL-${numero.toString().padLeft(3, '0')}';
    } catch (e) {
      print('❌ Error al generar código: $e');
      return 'CL-001';
    }
  }
}
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/obra_model.dart';

/// Repositorio de Obras
///
/// Maneja todas las operaciones de base de datos relacionadas con obras.
class ObraRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'obras';

  // ========================================
  // OPERACIONES DE LECTURA (READ)
  // ========================================

  /// Obtiene TODAS las obras
  Future<List<ObraModel>> obtenerTodas({bool soloActivas = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: soloActivas ? 'estado = ?' : null,
        whereArgs: soloActivas ? ['activa'] : null,
        orderBy: 'nombre ASC',
      );

      return List.generate(maps.length, (i) {
        return ObraModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener obras: $e');
      return [];
    }
  }

  /// Obtiene todas las obras con información del cliente (JOIN)
  Future<List<ObraConCliente>> obtenerTodasConCliente({bool soloActivas = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          o.*,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social
        FROM obras o
        INNER JOIN clientes c ON o.cliente_id = c.id
        ${soloActivas ? "WHERE o.estado = 'activa'" : ''}
        ORDER BY o.nombre ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query);

      return List.generate(maps.length, (i) {
        return ObraConCliente.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener obras con cliente: $e');
      return [];
    }
  }

  /// Obtiene una obra por su ID
  Future<ObraModel?> obtenerPorId(int id) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ObraModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener obra por id $id: $e');
      return null;
    }
  }

  /// Obtiene una obra por su código
  Future<ObraModel?> obtenerPorCodigo(String codigo) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return ObraModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener obra por código $codigo: $e');
      return null;
    }
  }

  /// Obtiene todas las obras de un cliente específico
  Future<List<ObraModel>> obtenerPorCliente(int clienteId, {bool soloActivas = true}) async {
    try {
      final Database db = await _dbHelper.database;

      String whereClause = 'cliente_id = ?';
      List<dynamic> whereArgs = [clienteId];

      if (soloActivas) {
        whereClause += ' AND estado = ?';
        whereArgs.add('activa');
      }

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'nombre ASC',
      );

      return List.generate(maps.length, (i) {
        return ObraModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener obras del cliente $clienteId: $e');
      return [];
    }
  }

  /// Busca obras por nombre o dirección
  Future<List<ObraConCliente>> buscar(String termino, {bool soloActivas = true}) async {
    try {
      final Database db = await _dbHelper.database;

      String query = '''
        SELECT 
          o.*,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social
        FROM obras o
        INNER JOIN clientes c ON o.cliente_id = c.id
        WHERE (o.nombre LIKE ? OR o.direccion LIKE ? OR o.codigo LIKE ? OR c.razon_social LIKE ?)
      ''';

      List<dynamic> args = ['%$termino%', '%$termino%', '%$termino%', '%$termino%'];

      if (soloActivas) {
        query += " AND o.estado = 'activa'";
      }

      query += ' ORDER BY o.nombre ASC';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

      return List.generate(maps.length, (i) {
        return ObraConCliente.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al buscar obras: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA (CREATE/UPDATE/DELETE)
  // ========================================

  /// Crea una nueva obra
  Future<int> crear(ObraModel obra) async {
    try {
      final Database db = await _dbHelper.database;

      final int id = await db.insert(
        _tableName,
        obra.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      print('✅ Obra creada con id: $id');
      return id;
    } catch (e) {
      print('❌ Error al crear obra: $e');
      rethrow;
    }
  }

  /// Actualiza una obra existente
  Future<int> actualizar(ObraModel obra) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.update(
        _tableName,
        obra.toMap(),
        where: 'id = ?',
        whereArgs: [obra.id],
      );

      print('✅ Obra actualizada. Filas afectadas: $count');
      return count;
    } catch (e) {
      print('❌ Error al actualizar obra: $e');
      rethrow;
    }
  }

  /// Cambia el estado de una obra
  Future<int> cambiarEstado(int id, String nuevoEstado) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.update(
        _tableName,
        {
          'estado': nuevoEstado,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      print('✅ Estado de obra actualizado a $nuevoEstado. Filas afectadas: $count');
      return count;
    } catch (e) {
      print('❌ Error al cambiar estado de obra: $e');
      rethrow;
    }
  }

  // ========================================
  // OPERACIONES ESPECIALES
  // ========================================

  /// Cuenta el total de obras
  Future<int> contar({bool soloActivas = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final int? count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableName${soloActivas ? " WHERE estado = 'activa'" : ""}',
        ),
      );

      return count ?? 0;
    } catch (e) {
      print('❌ Error al contar obras: $e');
      return 0;
    }
  }

  /// Cuenta obras por cliente
  Future<int> contarPorCliente(int clienteId, {bool soloActivas = true}) async {
    try {
      final Database db = await _dbHelper.database;

      String whereClause = 'cliente_id = ?';
      List<dynamic> whereArgs = [clienteId];

      if (soloActivas) {
        whereClause += " AND estado = 'activa'";
      }

      final int? count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableName WHERE $whereClause',
          whereArgs,
        ),
      );

      return count ?? 0;
    } catch (e) {
      print('❌ Error al contar obras del cliente: $e');
      return 0;
    }
  }

  /// Verifica si existe una obra con un código dado
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

  /// Genera el siguiente código de obra para un cliente
  /// Formato: OB-XXX-CL-YYY
  Future<String> generarSiguienteCodigoParaCliente(int clienteId, String codigoCliente) async {
    try {
      final Database db = await _dbHelper.database;

      // Obtener la última obra del cliente
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'cliente_id = ?',
        whereArgs: [clienteId],
        orderBy: 'id DESC',
        limit: 1,
      );

      if (maps.isEmpty) {
        return 'OB-001-$codigoCliente';
      }

      // Extraer el número del último código (OB-001-CL-001 -> 001)
      String ultimoCodigo = maps.first['codigo'] as String;
      String numeroStr = ultimoCodigo.split('-')[1];
      int numero = int.parse(numeroStr);

      // Incrementar y formatear
      numero++;
      return 'OB-${numero.toString().padLeft(3, '0')}-$codigoCliente';
    } catch (e) {
      print('❌ Error al generar código: $e');
      return 'OB-001-$codigoCliente';
    }
  }
}
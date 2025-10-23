import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/asiento_model.dart';
import '../models/cuenta_contable_model.dart';

class ContabilidadRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> contarCuentas() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM cuentas_contables');
    return (result.first['total'] as int?) ?? (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> guardarCuenta({
    required String codigo,
    required String nombre,
    required String tipo,
    String? descripcion,
    bool esImputable = true,
  }) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'cuentas_contables',
      where: 'codigo = ?',
      whereArgs: [codigo],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update(
        'cuentas_contables',
        {
          'nombre': nombre,
          'tipo': tipo,
          'descripcion': descripcion,
          'es_imputable': esImputable ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }

    return await db.insert('cuentas_contables', {
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'es_imputable': esImputable ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<CuentaContableModel>> obtenerCuentas({String? search, String? tipo}) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <dynamic>[];

    if (search != null && search.trim().isNotEmpty) {
      where.add('(codigo LIKE ? OR nombre LIKE ?)');
      args.addAll(['%${search.trim()}%', '%${search.trim()}%']);
    }

    if (tipo != null && tipo.isNotEmpty) {
      where.add('tipo = ?');
      args.add(tipo);
    }

    final result = await db.query(
      'cuentas_contables',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'codigo ASC',
    );

    return result.map(CuentaContableModel.fromMap).toList();
  }

  Future<CuentaContableModel?> obtenerCuentaPorId(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cuentas_contables',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return CuentaContableModel.fromMap(result.first);
  }

  Future<CuentaContableModel?> obtenerCuentaPorCodigo(String codigo) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cuentas_contables',
      where: 'codigo = ?',
      whereArgs: [codigo],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return CuentaContableModel.fromMap(result.first);
  }

  Future<int> contarAsientos() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM asientos');
    return (result.first['total'] as int?) ?? (result.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> crearAsiento({
    required DateTime fecha,
    String? descripcion,
    String? origenTipo,
    int? origenId,
    String estado = 'registrado',
    required List<AsientoMovimientoInput> movimientos,
  }) async {
    if (movimientos.length < 2) {
      throw ArgumentError('El asiento debe tener al menos dos movimientos.');
    }

    double totalDebe = 0;
    double totalHaber = 0;
    for (final movimiento in movimientos) {
      totalDebe += movimiento.debe;
      totalHaber += movimiento.haber;
    }

    if ((totalDebe - totalHaber).abs() > 0.01) {
      throw ArgumentError('El asiento no está balanceado: debe $totalDebe vs haber $totalHaber');
    }

    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final numero = await _generarNumeroAsiento(txn);
      final asientoId = await txn.insert('asientos', {
        'numero': numero,
        'fecha': fecha.toIso8601String(),
        'descripcion': descripcion,
        'origen_tipo': origenTipo,
        'origen_id': origenId,
        'estado': estado,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final movimiento in movimientos) {
        await txn.insert('asiento_movimientos', {
          'asiento_id': asientoId,
          'cuenta_id': movimiento.cuentaId,
          'detalle': movimiento.detalle,
          'debe': movimiento.debe,
          'haber': movimiento.haber,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return asientoId;
    });
  }

  Future<String> _generarNumeroAsiento(Transaction txn) async {
    final result = await txn.rawQuery('SELECT COUNT(*) AS total FROM asientos');
    final total = (result.first['total'] as int?) ?? (result.first['total'] as num?)?.toInt() ?? 0;
    final siguiente = total + 1;
    return 'AS-${siguiente.toString().padLeft(4, '0')}';
  }

  Future<bool> existeAsientoPorOrigen({
    required String origenTipo,
    required int origenId,
  }) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'asientos',
      columns: ['id'],
      where: 'origen_tipo = ? AND origen_id = ?',
      whereArgs: [origenTipo, origenId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<List<AsientoResumen>> obtenerAsientos({
    DateTime? desde,
    DateTime? hasta,
    String? search,
  }) async {
    final db = await _dbHelper.database;
    final buffer = StringBuffer();
    final where = <String>[];
    final args = <dynamic>[];

    buffer.writeln('''
      SELECT
        a.id,
        a.numero,
        a.fecha,
        a.descripcion,
        a.origen_tipo,
        a.origen_id,
        a.estado,
        a.created_at,
        a.updated_at,
        COUNT(am.id) AS movimientos,
        SUM(am.debe) AS total_debe,
        SUM(am.haber) AS total_haber
      FROM asientos a
      LEFT JOIN asiento_movimientos am ON am.asiento_id = a.id
    ''');

    if (desde != null) {
      where.add('a.fecha >= ?');
      args.add(desde.toIso8601String());
    }

    if (hasta != null) {
      where.add('a.fecha <= ?');
      args.add(hasta.toIso8601String());
    }

    if (search != null && search.trim().isNotEmpty) {
      where.add(
        '(a.numero LIKE ? OR a.descripcion LIKE ? OR a.origen_tipo LIKE ?)',
      );
      args.addAll(List.filled(3, '%${search.trim()}%'));
    }

    if (where.isNotEmpty) {
      buffer.writeln('WHERE ${where.join(' AND ')}');
    }

    buffer.writeln('GROUP BY a.id');
    buffer.writeln('ORDER BY a.fecha DESC, a.id DESC');

    final result = await db.rawQuery(buffer.toString(), args);
    return result.map(AsientoResumen.fromMap).toList();
  }

  Future<List<AsientoMovimientoModel>> obtenerMovimientos(int asientoId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT
        am.id,
        am.asiento_id,
        am.cuenta_id,
        am.detalle,
        am.debe,
        am.haber,
        c.codigo AS cuenta_codigo,
        c.nombre AS cuenta_nombre
      FROM asiento_movimientos am
      INNER JOIN cuentas_contables c ON c.id = am.cuenta_id
      WHERE am.asiento_id = ?
      ORDER BY am.id ASC
    ''', [asientoId]);

    return result.map(AsientoMovimientoModel.fromMap).toList();
  }
}

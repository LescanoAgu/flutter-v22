import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/factura_model.dart';

/// Repositorio para gestión de facturas, items y pagos
class FacturaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ========================================
  // CREACIÓN DE FACTURAS
  // ========================================

  Future<int> crearFactura({
    required int clienteId,
    int? obraId,
    String tipo = 'B',
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    String? condicionPago,
    String estadoInicial = 'emitida',
    String? observaciones,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('La factura debe contener al menos un item.');
    }

    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final numero = await _generarNumeroFactura(txn);
      final fecha = fechaEmision ?? DateTime.now();

      double subtotal = 0;
      double impuestos = 0;
      double total = 0;

      final itemsPreparados = <Map<String, dynamic>>[];

      for (final item in items) {
        final productoId = item['productoId'] as int?;
        final cantidad = item['cantidad'];
        final precioUnitario = item['precioUnitario'];

        if (productoId == null || cantidad == null || precioUnitario == null) {
          throw ArgumentError(
            'Cada item necesita productoId, cantidad y precioUnitario.',
          );
        }

        final qty = (cantidad as num).toDouble();
        final price = (precioUnitario as num).toDouble();
        final ivaPorcentaje = (item['ivaPorcentaje'] as num?)?.toDouble() ?? 21;

        final itemSubtotal = qty * price;
        final itemIva = itemSubtotal * (ivaPorcentaje / 100);
        final itemTotal = itemSubtotal + itemIva;

        subtotal += itemSubtotal;
        impuestos += itemIva;
        total += itemTotal;

        itemsPreparados.add({
          'producto_id': productoId,
          'descripcion': item['descripcion'] as String?,
          'cantidad': qty,
          'precio_unitario': price,
          'subtotal': itemSubtotal,
          'iva': itemIva,
          'total': itemTotal,
          'remito_item_id': item['remitoItemId'] as int?,
        });
      }

      final factura = FacturaModel(
        numero: numero,
        tipo: tipo,
        clienteId: clienteId,
        obraId: obraId,
        fechaEmision: fecha,
        fechaVencimiento: fechaVencimiento,
        estado: estadoInicial,
        condicionPago: condicionPago,
        subtotal: subtotal,
        impuestos: impuestos,
        total: total,
        observaciones: observaciones,
        createdAt: DateTime.now(),
      );

      final facturaId = await txn.insert('facturas', factura.toMap());

      for (final item in itemsPreparados) {
        await txn.insert('factura_items', {
          ...item,
          'factura_id': facturaId,
        });
      }

      return facturaId;
    });
  }

  Future<String> _generarNumeroFactura(Transaction txn) async {
    final result = await txn.rawQuery('SELECT COUNT(*) as total FROM facturas');
    final totalExistente = (result.first['total'] as int?) ??
        (result.first['total'] as num?)?.toInt() ??
        0;
    final siguiente = totalExistente + 1;
    return 'FC-${siguiente.toString().padLeft(4, '0')}';
  }

  // ========================================
  // CONSULTAS
  // ========================================

  Future<List<FacturaResumen>> obtenerResumen({String? estado}) async {
    final db = await _dbHelper.database;

    final buffer = StringBuffer();
    final where = <String>[];
    final args = <dynamic>[];

    buffer.writeln('''
      SELECT
        f.*,
        c.razon_social AS cliente_nombre,
        o.nombre AS obra_nombre,
        COALESCE(SUM(p.monto), 0) AS total_pagado
      FROM facturas f
      INNER JOIN clientes c ON f.cliente_id = c.id
      LEFT JOIN obras o ON f.obra_id = o.id
      LEFT JOIN pagos p ON p.factura_id = f.id
    ''');

    if (estado != null && estado.isNotEmpty) {
      where.add('f.estado = ?');
      args.add(estado);
    }

    if (where.isNotEmpty) {
      buffer.writeln('WHERE ${where.join(' AND ')}');
    }

    buffer.writeln('GROUP BY f.id');
    buffer.writeln('ORDER BY f.fecha_emision DESC, f.id DESC');

    final result = await db.rawQuery(buffer.toString(), args);
    return result.map(FacturaResumen.fromMap).toList();
  }

  Future<FacturaModel?> obtenerPorId(int facturaId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'facturas',
      where: 'id = ?',
      whereArgs: [facturaId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return FacturaModel.fromMap(result.first);
  }

  Future<List<FacturaItemDetalle>> obtenerItems(int facturaId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT
        fi.id,
        fi.producto_id,
        fi.descripcion,
        fi.cantidad,
        fi.precio_unitario,
        fi.subtotal,
        fi.iva,
        fi.total,
        p.codigo AS producto_codigo,
        p.nombre AS producto_nombre
      FROM factura_items fi
      INNER JOIN productos p ON p.id = fi.producto_id
      WHERE fi.factura_id = ?
      ORDER BY fi.id ASC
    ''', [facturaId]);

    return result.map(FacturaItemDetalle.fromMap).toList();
  }

  Future<List<PagoModel>> obtenerPagos(int facturaId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'pagos',
      where: 'factura_id = ?',
      whereArgs: [facturaId],
      orderBy: 'fecha ASC',
    );

    return result.map(PagoModel.fromMap).toList();
  }

  Future<double> obtenerTotalPagado(int facturaId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS pagado FROM pagos WHERE factura_id = ?',
      [facturaId],
    );

    return (result.first['pagado'] as num?)?.toDouble() ?? 0;
  }

  Future<void> registrarPago({
    required int facturaId,
    required DateTime fecha,
    required double monto,
    String? metodo,
    String? referencia,
    String? observaciones,
  }) async {
    final db = await _dbHelper.database;

    await db.insert('pagos', {
      'factura_id': facturaId,
      'fecha': fecha.toIso8601String(),
      'metodo': metodo,
      'monto': monto,
      'referencia': referencia,
      'observaciones': observaciones,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _recalcularEstado(db, facturaId);
  }

  Future<void> _recalcularEstado(Database db, int facturaId) async {
    final result = await db.query(
      'facturas',
      columns: ['estado', 'total'],
      where: 'id = ?',
      whereArgs: [facturaId],
      limit: 1,
    );

    if (result.isEmpty) return;

    final facturaActual = result.first;
    final estadoActual = facturaActual['estado'] as String? ?? 'emitida';
    final totalFactura = (facturaActual['total'] as num?)?.toDouble() ?? 0;

    final pagos = await db.rawQuery(
      'SELECT COALESCE(SUM(monto), 0) AS pagado FROM pagos WHERE factura_id = ?',
      [facturaId],
    );
    final totalPagado = (pagos.first['pagado'] as num?)?.toDouble() ?? 0;

    String nuevoEstado = estadoActual;
    if (totalPagado <= 0) {
      nuevoEstado = estadoActual;
    } else if (totalPagado + 0.01 >= totalFactura) {
      nuevoEstado = 'pagada';
    } else {
      nuevoEstado = 'parcial';
    }

    if (nuevoEstado == estadoActual) {
      return;
    }

    await db.update(
      'facturas',
      {
        'estado': nuevoEstado,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [facturaId],
    );
  }

  Future<void> actualizarEstado(int facturaId, String estado) async {
    final db = await _dbHelper.database;
    await db.update(
      'facturas',
      {
        'estado': estado,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [facturaId],
    );
  }

  Future<int> contar() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM facturas');
    return (result.first['total'] as int?) ??
        (result.first['total'] as num?)?.toInt() ??
        0;
  }
}

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/remito_item_model.dart';
import '../models/remito_model.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';

/// Repositorio para la gestión de remitos (notas de entrega)
class RemitoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ========================================
  // CREACIÓN DE REMITOS
  // ========================================

  Future<int> crearRemito({
    required int clienteId,
    int? obraId,
    int? ordenInternaId,
    DateTime? fechaEntrega,
    String estado = 'emitido',
    String? observaciones,
    String? chofer,
    String? transporte,
    String? patente,
    String? recibidoPor,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('El remito debe contener al menos un item.');
    }

    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      final numero = await _generarNumeroRemito(txn);

      final remito = RemitoModel(
        numero: numero,
        clienteId: clienteId,
        obraId: obraId,
        ordenInternaId: ordenInternaId,
        fechaEmision: DateTime.now(),
        fechaEntrega: fechaEntrega,
        estado: estado,
        observaciones: observaciones,
        chofer: chofer,
        transporte: transporte,
        patente: patente,
        recibidoPor: recibidoPor,
        createdAt: DateTime.now(),
      );

      final remitoId = await txn.insert('remitos', remito.toMap());

      for (final item in items) {
        final productoId = item['productoId'] as int?;
        final cantidad = item['cantidad'];
        if (productoId == null || cantidad == null) {
          throw ArgumentError('Cada item debe incluir productoId y cantidad.');
        }

        final remitoItem = RemitoItemModel(
          remitoId: remitoId,
          productoId: productoId,
          cantidad: (cantidad as num).toDouble(),
          unidad: item['unidad'] as String?,
          descripcion: item['descripcion'] as String?,
          ordenItemId: item['ordenItemId'] as int?,
          createdAt: DateTime.now(),
        );

        await txn.insert('remito_items', remitoItem.toMap());
      }

      return remitoId;
    });
  }

  Future<String> _generarNumeroRemito(Transaction txn) async {
    final result = await txn.rawQuery('SELECT COUNT(*) as total FROM remitos');
    final total = (result.first['total'] as int?) ??
        (result.first['total'] as num?)?.toInt() ??
        0;
    final siguiente = total + 1;
    return 'RM-${siguiente.toString().padLeft(4, '0')}';
  }

  // ========================================
  // CONSULTAS
  // ========================================

  Future<List<RemitoResumen>> obtenerResumen({
    String? estado,
    String? search,
  }) async {
    final db = await _dbHelper.database;
    final buffer = StringBuffer();
    final where = <String>[];
    final args = <dynamic>[];

    buffer.writeln('''
      SELECT
        r.*, 
        c.razon_social AS cliente_nombre,
        o.nombre AS obra_nombre,
        COUNT(ri.id) AS items_count,
        COALESCE(SUM(ri.cantidad), 0) AS total_cantidad
      FROM remitos r
      INNER JOIN clientes c ON r.cliente_id = c.id
      LEFT JOIN obras o ON r.obra_id = o.id
      LEFT JOIN remito_items ri ON ri.remito_id = r.id
    ''');

    if (estado != null && estado.isNotEmpty) {
      where.add('r.estado = ?');
      args.add(estado);
    }

    if (search != null && search.trim().isNotEmpty) {
      where.add(
        '(r.numero LIKE ? OR c.razon_social LIKE ? OR o.nombre LIKE ?)',
      );
      args.addAll(List.filled(3, '%${search.trim()}%'));
    }

    if (where.isNotEmpty) {
      buffer.writeln('WHERE ${where.join(' AND ')}');
    }

    buffer.writeln('GROUP BY r.id');
    buffer.writeln('ORDER BY r.fecha_emision DESC, r.id DESC');

    final result = await db.rawQuery(buffer.toString(), args);
    return result.map(RemitoResumen.fromMap).toList();
  }

  Future<List<RemitoItemDetalle>> obtenerItems(int remitoId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT
        ri.id,
        ri.producto_id,
        ri.cantidad,
        ri.unidad,
        ri.descripcion,
        p.codigo AS producto_codigo,
        p.nombre AS producto_nombre
      FROM remito_items ri
      INNER JOIN productos p ON p.id = ri.producto_id
      WHERE ri.remito_id = ?
      ORDER BY ri.id ASC
    ''', [remitoId]);

    return result.map(RemitoItemDetalle.fromMap).toList();
  }

  Future<void> marcarComoEntregado({
    required int remitoId,
    DateTime? fechaEntrega,
    String? recibidoPor,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final remitoRows = await txn.query(
        'remitos',
        where: 'id = ?',
        whereArgs: [remitoId],
        limit: 1,
      );

      if (remitoRows.isEmpty) {
        throw Exception('El remito no existe.');
      }

      final remito = remitoRows.first;
      final estadoActual = remito['estado'] as String? ?? 'emitido';
      if (estadoActual == 'entregado') {
        throw Exception('El remito ya fue marcado como entregado.');
      }

      final numeroRemito = remito['numero'] as String? ?? 'REM';
      final detalleItems = await txn.query(
        'remito_items',
        columns: ['producto_id', 'cantidad'],
        where: 'remito_id = ?',
        whereArgs: [remitoId],
      );

      if (detalleItems.isEmpty) {
        throw Exception('El remito no tiene items para impactar en stock.');
      }

      final ahora = DateTime.now();
      final fechaEntregaEfectiva = fechaEntrega ?? ahora;

      for (final item in detalleItems) {
        final productoId = item['producto_id'] as int?;
        final cantidad = (item['cantidad'] as num?)?.toDouble();

        if (productoId == null || cantidad == null) {
          throw Exception('Item inválido en el remito.');
        }

        final stockRows = await txn.query(
          'stock',
          where: 'producto_id = ?',
          whereArgs: [productoId],
          limit: 1,
        );

        if (stockRows.isEmpty) {
          throw Exception(
            'El producto $productoId no tiene stock registrado para descontar.',
          );
        }

        final stockRow = stockRows.first;
        final stockId = stockRow['id'] as int;
        final cantidadActual =
            (stockRow['cantidad_disponible'] as num?)?.toDouble() ?? 0;
        double cantidadPosterior = cantidadActual - cantidad;

        if (cantidadPosterior < -0.0001) {
          throw Exception(
            'Stock insuficiente para el producto $productoId. '
            'Disponible: ${cantidadActual.toStringAsFixed(2)}, '
            'requerido: ${cantidad.toStringAsFixed(2)}.',
          );
        }

        if (cantidadPosterior < 0) {
          cantidadPosterior = 0;
        }

        await txn.update(
          'stock',
          {
            'cantidad_disponible': cantidadPosterior,
            'ultima_actualizacion': ahora.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [stockId],
        );

        await txn.insert('movimientos_stock', {
          'producto_id': productoId,
          'tipo': TipoMovimiento.salida.name,
          'cantidad': cantidad,
          'cantidad_anterior': cantidadActual,
          'cantidad_posterior': cantidadPosterior,
          'motivo': 'Entrega de remito',
          'referencia': 'Remito $numeroRemito',
          'usuario_id': null,
          'created_at': ahora.toIso8601String(),
        });
      }

      final updateData = <String, Object?>{
        'estado': 'entregado',
        'fecha_entrega': fechaEntregaEfectiva.toIso8601String(),
        'updated_at': ahora.toIso8601String(),
      };

      if (recibidoPor != null && recibidoPor.trim().isNotEmpty) {
        updateData['recibido_por'] = recibidoPor.trim();
      }

      await txn.update(
        'remitos',
        updateData,
        where: 'id = ?',
        whereArgs: [remitoId],
      );
    });
  }

  Future<int> contar() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM remitos');
    return (result.first['total'] as int?) ??
        (result.first['total'] as num?)?.toInt() ??
        0;
  }

  Future<bool> actualizarEstado({
    required int remitoId,
    required String nuevoEstado,
    String? recibidoPor,
  }) async {
    final db = await _dbHelper.database;
    final cambios = await db.update(
      'remitos',
      {
        'estado': nuevoEstado,
        'recibido_por': recibidoPor,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [remitoId],
    );
    return cambios > 0;
  }
}

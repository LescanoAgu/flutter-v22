import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/orden_interna_model.dart';
import '../models/orden_item_model.dart';

/// Repositorio de Órdenes Internas
///
/// Maneja toda la lógica de base de datos para:
/// - Crear órdenes (pedidos del cliente)
/// - Aprobar/Rechazar órdenes (admin)
/// - Cambiar estados
/// - Consultar órdenes con filtros
class OrdenInternaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ========================================
  // CREAR ORDEN
  // ========================================

  /// Crea una nueva orden interna con sus items
  ///
  /// Ejemplo:
  /// ```dart
  /// final ordenId = await repo.crearOrden(
  ///   clienteId: 1,
  ///   solicitanteNombre: 'Juan Pérez',
  ///   items: [
  ///     {'productoId': 5, 'cantidad': 100, 'precio': 1500},
  ///     {'productoId': 8, 'cantidad': 50, 'precio': 2300},
  ///   ],
  /// );
  /// ```
  Future<int> crearOrden({
    required int clienteId,
    int? obraId,
    required String solicitanteNombre,
    String? solicitanteEmail,
    String? solicitanteTelefono,
    DateTime? fechaEntregaEstimada,
    String? observacionesCliente,
    required List<Map<String, dynamic>> items, // {productoId, cantidad, precio}
    int? usuarioCreadorId,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      try {
        // 1. Generar número de orden
        final numero = await _generarNumeroOrden(txn);

        // 2. Calcular total
        double total = 0;
        for (var item in items) {
          final cantidad = item['cantidad'] as double;
          final precio = item['precio'] as double;
          total += cantidad * precio;
        }

        // 3. Crear orden
        final orden = OrdenInterna(
          numero: numero,
          clienteId: clienteId,
          obraId: obraId,
          solicitanteNombre: solicitanteNombre,
          solicitanteEmail: solicitanteEmail,
          solicitanteTelefono: solicitanteTelefono,
          fechaPedido: DateTime.now(),
          fechaEntregaEstimada: fechaEntregaEstimada,
          estado: 'solicitado',
          observacionesCliente: observacionesCliente,
          total: total,
          usuarioCreadorId: usuarioCreadorId,
          createdAt: DateTime.now(),
        );

        final ordenId = await txn.insert('ordenes_internas', orden.toMap());

        // 4. Crear items
        for (var itemData in items) {
          final item = OrdenItem(
            ordenId: ordenId,
            productoId: itemData['productoId'] as int,
            cantidadSolicitada: itemData['cantidad'] as double,
            precioUnitario: itemData['precio'] as double,
            subtotal: (itemData['cantidad'] as double) * (itemData['precio'] as double),
            observaciones: itemData['observaciones'] as String?,
            createdAt: DateTime.now(),
          );

          await txn.insert('orden_items', item.toMap());
        }

        print('✅ Orden $numero creada con $ordenId items');
        return ordenId;

      } catch (e) {
        print('❌ Error al crear orden: $e');
        rethrow;
      }
    });
  }

  /// Genera el número correlativo de orden (OI-0001, OI-0002...)
  Future<String> _generarNumeroOrden(Transaction txn) async {
    final result = await txn.rawQuery(
      'SELECT COUNT(*) as total FROM ordenes_internas',
    );

    final total = result.first['total'] as int;
    final numero = total + 1;

    return 'OI-${numero.toString().padLeft(4, '0')}';
  }

  // ========================================
  // APROBAR / RECHAZAR
  // ========================================

  /// Aprueba una orden (con posibles ajustes en cantidades)
  ///
  /// itemsAjustados: Lista opcional con ajustes
  /// Ejemplo: [{'itemId': 1, 'cantidadAprobada': 80}]
  Future<bool> aprobarOrden({
    required int ordenId,
    required int aprobadoPorUsuarioId,
    List<Map<String, dynamic>>? itemsAjustados,
    String? observacionesInternas,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      try {
        // 1. Actualizar orden
        await txn.update(
          'ordenes_internas',
          {
            'estado': 'aprobado',
            'aprobado_por_usuario_id': aprobadoPorUsuarioId,
            'aprobado_fecha': DateTime.now().toIso8601String(),
            'observaciones_internas': observacionesInternas,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [ordenId],
        );

        // 2. Si hay ajustes, aplicarlos
        if (itemsAjustados != null && itemsAjustados.isNotEmpty) {
          for (var ajuste in itemsAjustados) {
            final itemId = ajuste['itemId'] as int;
            final cantidadAprobada = ajuste['cantidadAprobada'] as double;

            await txn.update(
              'orden_items',
              {'cantidad_aprobada': cantidadAprobada},
              where: 'id = ?',
              whereArgs: [itemId],
            );
          }

          // Recalcular total
          await _recalcularTotal(txn, ordenId);
        }

        // 3. Cambiar automáticamente a "en_preparacion"
        await txn.update(
          'ordenes_internas',
          {'estado': 'en_preparacion'},
          where: 'id = ?',
          whereArgs: [ordenId],
        );

        print('✅ Orden $ordenId aprobada y en preparación');
        return true;

      } catch (e) {
        print('❌ Error al aprobar orden: $e');
        return false;
      }
    });
  }

  /// Rechaza una orden
  Future<bool> rechazarOrden({
    required int ordenId,
    required int rechazadoPorUsuarioId,
    required String motivoRechazo,
  }) async {
    final db = await _dbHelper.database;

    try {
      await db.update(
        'ordenes_internas',
        {
          'estado': 'rechazado',
          'motivo_rechazo': motivoRechazo,
          'aprobado_por_usuario_id': rechazadoPorUsuarioId,
          'aprobado_fecha': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [ordenId],
      );

      print('✅ Orden $ordenId rechazada');
      return true;

    } catch (e) {
      print('❌ Error al rechazar orden: $e');
      return false;
    }
  }

  /// Recalcula el total de una orden basado en cantidades aprobadas
  Future<void> _recalcularTotal(Transaction txn, int ordenId) async {
    final items = await txn.query(
      'orden_items',
      where: 'orden_id = ?',
      whereArgs: [ordenId],
    );

    double nuevoTotal = 0;
    for (var itemMap in items) {
      final item = OrdenItem.fromMap(itemMap);
      final cantidadFinal = item.cantidadAprobada ?? item.cantidadSolicitada;
      nuevoTotal += cantidadFinal * item.precioUnitario;
    }

    await txn.update(
      'ordenes_internas',
      {'total': nuevoTotal},
      where: 'id = ?',
      whereArgs: [ordenId],
    );
  }

  // ========================================
  // CAMBIAR ESTADOS
  // ========================================

  /// Cambia el estado de una orden
  Future<bool> cambiarEstado({
    required int ordenId,
    required String nuevoEstado,
    int? usuarioId,
  }) async {
    final db = await _dbHelper.database;

    try {
      await db.update(
        'ordenes_internas',
        {
          'estado': nuevoEstado,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [ordenId],
      );

      print('✅ Orden $ordenId cambió a estado: $nuevoEstado');
      return true;

    } catch (e) {
      print('❌ Error al cambiar estado: $e');
      return false;
    }
  }

  /// Marca como "listo para envío"
  Future<bool> marcarListoEnvio(int ordenId) async {
    return await cambiarEstado(ordenId: ordenId, nuevoEstado: 'listo_envio');
  }

  /// Marca como "despachado"
  Future<bool> marcarDespachado(int ordenId) async {
    return await cambiarEstado(ordenId: ordenId, nuevoEstado: 'despachado');
  }

  /// Cancela una orden
  Future<bool> cancelarOrden({
    required int ordenId,
    int? usuarioId,
  }) async {
    return await cambiarEstado(ordenId: ordenId, nuevoEstado: 'cancelado');
  }

  // ========================================
  // CONSULTAS
  // ========================================

  /// Obtiene todas las órdenes con filtros opcionales
  Future<List<OrdenInternaDetalle>> getOrdenes({
    String? estado,
    int? clienteId,
    DateTime? desde,
    DateTime? hasta,
    int? limit,
  }) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT 
        o.*,
        c.razon_social as cliente_razon_social,
        ob.nombre as obra_nombre,
        u.nombre_completo as aprobado_por_nombre
      FROM ordenes_internas o
      INNER JOIN clientes c ON o.cliente_id = c.id
      LEFT JOIN obras ob ON o.obra_id = ob.id
      LEFT JOIN usuarios u ON o.aprobado_por_usuario_id = u.id
      WHERE 1=1
    ''';

    List<dynamic> args = [];

    if (estado != null) {
      query += ' AND o.estado = ?';
      args.add(estado);
    }

    if (clienteId != null) {
      query += ' AND o.cliente_id = ?';
      args.add(clienteId);
    }

    if (desde != null) {
      query += ' AND o.fecha_pedido >= ?';
      args.add(desde.toIso8601String());
    }

    if (hasta != null) {
      query += ' AND o.fecha_pedido <= ?';
      args.add(hasta.toIso8601String());
    }

    query += ' ORDER BY o.created_at DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    final result = await db.rawQuery(query, args);

    List<OrdenInternaDetalle> ordenes = [];

    for (var row in result) {
      final orden = OrdenInterna.fromMap(row);
      final items = await _getItemsConDetalle(db, orden.id!);

      ordenes.add(OrdenInternaDetalle(
        orden: orden,
        clienteRazonSocial: row['cliente_razon_social'] as String,
        obraNombre: row['obra_nombre'] as String?,
        items: items,
        aprobadoPorNombre: row['aprobado_por_nombre'] as String?,
      ));
    }

    return ordenes;
  }

  /// Obtiene una orden específica por ID
  Future<OrdenInternaDetalle?> getOrdenPorId(int ordenId) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        o.*,
        c.razon_social as cliente_razon_social,
        ob.nombre as obra_nombre,
        u.nombre_completo as aprobado_por_nombre
      FROM ordenes_internas o
      INNER JOIN clientes c ON o.cliente_id = c.id
      LEFT JOIN obras ob ON o.obra_id = ob.id
      LEFT JOIN usuarios u ON o.aprobado_por_usuario_id = u.id
      WHERE o.id = ?
    ''', [ordenId]);

    if (result.isEmpty) return null;

    final row = result.first;
    final orden = OrdenInterna.fromMap(row);
    final items = await _getItemsConDetalle(db, ordenId);

    return OrdenInternaDetalle(
      orden: orden,
      clienteRazonSocial: row['cliente_razon_social'] as String,
      obraNombre: row['obra_nombre'] as String?,
      items: items,
      aprobadoPorNombre: row['aprobado_por_nombre'] as String?,
    );
  }

  /// Obtiene órdenes por cliente
  Future<List<OrdenInternaDetalle>> getOrdenesPorCliente(int clienteId) async {
    return await getOrdenes(clienteId: clienteId);
  }

  /// Obtiene órdenes pendientes de aprobación
  Future<List<OrdenInternaDetalle>> getOrdenesPendientes() async {
    return await getOrdenes(estado: 'solicitado');
  }

  /// Obtiene items de una orden con detalles del producto
  Future<List<OrdenItemDetalle>> _getItemsConDetalle(
      Database db,
      int ordenId,
      ) async {
    final result = await db.rawQuery('''
      SELECT 
        oi.*,
        p.nombre as producto_nombre,
        p.codigo as producto_codigo,
        p.unidad_base,
        c.nombre as categoria_nombre
      FROM orden_items oi
      INNER JOIN productos p ON oi.producto_id = p.id
      INNER JOIN categorias c ON p.categoria_id = c.id
      WHERE oi.orden_id = ?
      ORDER BY oi.id
    ''', [ordenId]);

    return result.map((row) {
      return OrdenItemDetalle(
        item: OrdenItem.fromMap(row),
        productoNombre: row['producto_nombre'] as String,
        productoCodigo: row['producto_codigo'] as String,
        unidadBase: row['unidad_base'] as String,
        categoriaNombre: row['categoria_nombre'] as String,
      );
    }).toList();
  }

  // ========================================
  // ESTADÍSTICAS
  // ========================================

  /// Obtiene conteo de órdenes por estado
  Future<Map<String, int>> getEstadisticasPorEstado() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT estado, COUNT(*) as cantidad
      FROM ordenes_internas
      GROUP BY estado
    ''');

    Map<String, int> stats = {};
    for (var row in result) {
      stats[row['estado'] as String] = row['cantidad'] as int;
    }

    return stats;
  }

  /// Obtiene total de órdenes
  Future<int> getTotalOrdenes() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM ordenes_internas',
    );
    return result.first['total'] as int;
  }
}
// El repositorio es el encargado de interactuar con la base de datos
// Separa la lógica de datos de la lógica de negocio

import 'package:sqflite/sqflite.dart';
import '../models/movimiento_stock_model.dart';
import '../models/stock_model.dart';
import '../../../../core/database/database_helper.dart';

class MovimientoStockRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Registrar un nuevo movimiento (el método más importante)
  Future<MovimientoStock> registrarMovimiento({
    required int productoId,
    required TipoMovimiento tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    int? usuarioId,
  }) async {
    final db = await _databaseHelper.database;

    // Iniciamos una transacción para asegurar consistencia
    // Una transacción garantiza que todo se ejecute o nada (atomicidad)
    return await db.transaction((txn) async {
      // 1. Obtener el stock actual del producto
      final stockActual = await txn.query(
        'stock',
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );

      if (stockActual.isEmpty) {
        throw Exception('No existe stock para el producto $productoId');
      }

      final cantidadAnterior = stockActual.first['cantidad_disponible'] as double;

      // 2. Calcular la nueva cantidad según el tipo de movimiento
      double cantidadPosterior;
      double cantidadMovimiento = cantidad;

      switch (tipo) {
        case TipoMovimiento.entrada:
          cantidadPosterior = cantidadAnterior + cantidad;
          break;
        case TipoMovimiento.salida:
        // Validar que haya suficiente stock
          if (cantidadAnterior < cantidad) {
            throw Exception('Stock insuficiente. Disponible: $cantidadAnterior');
          }
          cantidadPosterior = cantidadAnterior - cantidad;
          cantidadMovimiento = -cantidad;  // Negativo para salidas
          break;
        case TipoMovimiento.ajuste:
        // El ajuste puede ser positivo o negativo
          cantidadPosterior = cantidadAnterior + cantidad;
          break;
      }

      // 3. Actualizar el stock del producto
      await txn.update(
        'stock',
        {
          'cantidad_disponible': cantidadPosterior,
          'ultima_actualizacion': DateTime.now().toIso8601String(),
        },
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );

      // 4. Insertar el movimiento en el historial
      final movimiento = MovimientoStock(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad.abs(),  // Guardamos siempre positivo
        cantidadAnterior: cantidadAnterior,
        cantidadPosterior: cantidadPosterior,
        motivo: motivo,
        referencia: referencia,
        usuarioId: usuarioId,
        createdAt: DateTime.now(),
      );

      final id = await txn.insert(
        'movimientos_stock',
        movimiento.toMap(),
      );

      // 5. Retornar el movimiento con su ID
      return movimiento.copyWith(id: id);
    });
  }

  // Obtener todos los movimientos de un producto
  Future<List<MovimientoStock>> getMovimientosPorProducto(int productoId) async {
    final db = await _databaseHelper.database;

    final maps = await db.query(
      'movimientos_stock',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'created_at DESC',  // Más recientes primero
    );

    return List.generate(
      maps.length,
          (i) => MovimientoStock.fromMap(maps[i]),
    );
  }

  // Obtener movimientos con filtros
  Future<List<MovimientoStock>> getMovimientos({
    DateTime? desde,
    DateTime? hasta,
    TipoMovimiento? tipo,
    int? limit,
  }) async {
    final db = await _databaseHelper.database;

    // Construimos el WHERE dinámicamente
    String where = '1=1';  // Siempre true, para simplificar
    List<dynamic> whereArgs = [];

    if (desde != null) {
      where += ' AND created_at >= ?';
      whereArgs.add(desde.toIso8601String());
    }

    if (hasta != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(hasta.toIso8601String());
    }

    if (tipo != null) {
      where += ' AND tipo = ?';
      whereArgs.add(tipo.name);
    }

    final maps = await db.query(
      'movimientos_stock',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return List.generate(
      maps.length,
          (i) => MovimientoStock.fromMap(maps[i]),
    );
  }

  // Obtener el último movimiento de un producto
  Future<MovimientoStock?> getUltimoMovimiento(int productoId) async {
    final db = await _databaseHelper.database;

    final maps = await db.query(
      'movimientos_stock',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return MovimientoStock.fromMap(maps.first);
  }

  // Cancelar un movimiento (crear un movimiento inverso)
  Future<MovimientoStock> cancelarMovimiento(int movimientoId) async {
    final db = await _databaseHelper.database;

    // 1. Obtener el movimiento original
    final maps = await db.query(
      'movimientos_stock',
      where: 'id = ?',
      whereArgs: [movimientoId],
    );

    if (maps.isEmpty) {
      throw Exception('Movimiento no encontrado');
    }

    final movimientoOriginal = MovimientoStock.fromMap(maps.first);

    // 2. Crear un movimiento inverso
    TipoMovimiento tipoInverso;
    switch (movimientoOriginal.tipo) {
      case TipoMovimiento.entrada:
        tipoInverso = TipoMovimiento.salida;
        break;
      case TipoMovimiento.salida:
        tipoInverso = TipoMovimiento.entrada;
        break;
      case TipoMovimiento.ajuste:
        tipoInverso = TipoMovimiento.ajuste;
        break;
    }

    // 3. Registrar el movimiento inverso
    return await registrarMovimiento(
      productoId: movimientoOriginal.productoId,
      tipo: tipoInverso,
      cantidad: movimientoOriginal.cantidad,
      motivo: 'Cancelación del movimiento #$movimientoId',
      referencia: 'CANC-$movimientoId',
      usuarioId: movimientoOriginal.usuarioId,
    );
  }
  /// Registra múltiples movimientos de stock en una sola transacción
  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items,
    required TipoMovimiento tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    bool valorizado = false,
    int? usuarioId,
  }) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      try {
        int movimientosRegistrados = 0;

        for (var item in items) {
          final productoId = item['productoId'] as int;
          final cantidad = item['cantidad'] as double;
          final montoValorizado = item['montoValorizado'] as double?;

          // 1. Obtener stock actual
          final stockActual = await txn.query(
            'stock',
            where: 'producto_id = ?',
            whereArgs: [productoId],
          );

          if (stockActual.isEmpty) {
            throw Exception('Producto ID $productoId no tiene stock registrado');
          }

          final cantidadActual = stockActual.first['cantidad_disponible'] as double;

          // 2. Calcular nueva cantidad según tipo
          double cantidadPosterior;

          switch (tipo) {
            case TipoMovimiento.entrada:
              cantidadPosterior = cantidadActual + cantidad;
              break;

            case TipoMovimiento.salida:
              if (cantidadActual < cantidad) {
                throw Exception(
                  'Stock insuficiente en producto ID $productoId. '
                      'Disponible: $cantidadActual, Requerido: $cantidad',
                );
              }
              cantidadPosterior = cantidadActual - cantidad;
              break;

            case TipoMovimiento.ajuste:
              cantidadPosterior = cantidad;
              break;
          }

          // 3. Actualizar stock
          await txn.update(
            'stock',
            {
              'cantidad_disponible': cantidadPosterior,
              'ultima_actualizacion': DateTime.now().toIso8601String(),
            },
            where: 'producto_id = ?',
            whereArgs: [productoId],
          );

          // 4. Crear objeto movimiento
          final movimiento = MovimientoStock(
            productoId: productoId,
            tipo: tipo,
            cantidad: cantidad,
            cantidadAnterior: cantidadActual,
            cantidadPosterior: cantidadPosterior,
            motivo: motivo,
            referencia: referencia,
            usuarioId: usuarioId,
            createdAt: DateTime.now(),
          );

          // 5. Registrar movimiento
          await txn.insert('movimientos_stock', movimiento.toMap());
          movimientosRegistrados++;
        }

        print('✅ Movimiento en lote registrado: $movimientosRegistrados productos');
        if (facturaNumero != null) {
          print('   📄 Factura: $facturaNumero');
        }

        return true;

      } catch (e) {
        print('❌ Error en registro en lote: $e');
        rethrow;
      }
    });
  }
}  // ← Cierre de la clase MovimientoStockRepository

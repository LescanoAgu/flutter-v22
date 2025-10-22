import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/stock_model.dart';
import '../models/movimiento_stock_model.dart';

/// Repositorio de Stock
///
/// Maneja todas las operaciones relacionadas con cantidades de stock.
class StockRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'stock';

  // ========================================
  // OPERACIONES BÁSICAS
  // ========================================

  /// Obtiene el stock de un producto específico
  ///
  /// Devuelve null si el producto no tiene registro de stock.
  Future<StockModel?> obtenerPorProductoId(int productoId) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'producto_id = ?',
        whereArgs: [productoId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return StockModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener stock del producto $productoId: $e');
      return null;
    }
  }

  /// Obtiene todos los productos CON su stock
  ///
  /// Hace un JOIN entre productos, categorías y stock.
  /// Los productos sin stock muestran cantidad = 0.
  Future<List<ProductoConStock>> obtenerTodosConStock({
    bool soloActivos = true,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      // Query con JOIN múltiple
      final String query =
          '''
        SELECT 
          p.id as producto_id,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          p.equivalencia,
          p.precio_sin_iva,
          c.id as categoria_id,
          c.nombre as categoria_nombre,
          c.codigo as categoria_codigo,
          COALESCE(s.cantidad_disponible, 0) as cantidad_disponible
        FROM productos p
        INNER JOIN categorias c ON p.categoria_id = c.id
        LEFT JOIN $_tableName s ON p.id = s.producto_id
        ${soloActivos ? 'WHERE p.estado = ?' : ''}
        ORDER BY p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        query,
        soloActivos ? ['activo'] : null,
      );

      return List.generate(maps.length, (i) {
        return ProductoConStock.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener productos con stock: $e');
      return [];
    }
  }

  /// Busca productos con stock por término
  Future<List<ProductoConStock>> buscarConStock(
    String termino, {
    bool soloActivos = true,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      final String query =
          '''
        SELECT 
          p.id as producto_id,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          p.equivalencia,
          p.precio_sin_iva,
          c.id as categoria_id,
          c.nombre as categoria_nombre,
          c.codigo as categoria_codigo,
          COALESCE(s.cantidad_disponible, 0) as cantidad_disponible
        FROM productos p
        INNER JOIN categorias c ON p.categoria_id = c.id
        LEFT JOIN $_tableName s ON p.id = s.producto_id
        WHERE (p.nombre LIKE ? OR p.codigo LIKE ?)
        ${soloActivos ? 'AND p.estado = ?' : ''}
        ORDER BY p.codigo ASC
      ''';

      List<dynamic> args = ['%$termino%', '%$termino%'];
      if (soloActivos) args.add('activo');

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

      return List.generate(maps.length, (i) {
        return ProductoConStock.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al buscar productos con stock: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE ESCRITURA
  // ========================================

  /// Crea un registro de stock inicial para un producto
  ///
  /// Ejemplo:
  /// ```dart
  /// StockModel stock = StockModel(
  ///   productoId: 1,
  ///   cantidadDisponible: 50,
  /// );
  ///
  /// await repo.crear(stock);
  /// ```
  Future<int> crear(StockModel stock) async {
    try {
      final Database db = await _dbHelper.database;

      final int id = await db.insert(
        _tableName,
        stock.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      print('✅ Stock creado con id: $id');
      return id;
    } catch (e) {
      print('❌ Error al crear stock: $e');
      rethrow;
    }
  }

  /// Actualiza la cantidad de stock de un producto
  ///
  /// Ejemplo:
  /// ```dart
  /// await repo.actualizarCantidad(productoId: 1, nuevaCantidad: 75);
  /// ```
  Future<int> actualizarCantidad({
    required int productoId,
    required double nuevaCantidad,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      final int count = await db.update(
        _tableName,
        {
          'cantidad_disponible': nuevaCantidad,
          'ultima_actualizacion': DateTime.now().toIso8601String(),
        },
        where: 'producto_id = ?',
        whereArgs: [productoId],
      );

      print('✅ Stock actualizado para producto $productoId: $nuevaCantidad');
      return count;
    } catch (e) {
      print('❌ Error al actualizar stock: $e');
      rethrow;
    }
  }

  /// Incrementa el stock de un producto (entrada)
  ///
  /// Ejemplo:
  /// ```dart
  /// // Agregar 25 unidades
  /// await repo.incrementar(productoId: 1, cantidad: 25);
  /// ```
  Future<double> incrementar({
    required int productoId,
    required double cantidad,
  }) async {
    try {
      // Obtener stock actual
      StockModel? stockActual = await obtenerPorProductoId(productoId);

      if (stockActual == null) {
        // Si no existe, crear con la cantidad inicial
        await crear(
          StockModel(productoId: productoId, cantidadDisponible: cantidad),
        );
        return cantidad;
      } else {
        // Si existe, incrementar
        double nuevaCantidad = stockActual.cantidadDisponible + cantidad;
        await actualizarCantidad(
          productoId: productoId,
          nuevaCantidad: nuevaCantidad,
        );
        return nuevaCantidad;
      }
    } catch (e) {
      print('❌ Error al incrementar stock: $e');
      rethrow;
    }
  }

  /// Decrementa el stock de un producto (salida)
  ///
  /// NO permite stock negativo. Si la cantidad a decrementar es mayor
  /// al stock disponible, lanza una excepción.
  ///
  /// Ejemplo:
  /// ```dart
  /// try {
  ///   await repo.decrementar(productoId: 1, cantidad: 10);
  /// } catch (e) {
  ///   print('Stock insuficiente');
  /// }
  /// ```
  Future<double> decrementar({
    required int productoId,
    required double cantidad,
  }) async {
    try {
      // Obtener stock actual
      StockModel? stockActual = await obtenerPorProductoId(productoId);

      if (stockActual == null) {
        throw Exception('El producto no tiene stock registrado');
      }

      // Validar que haya suficiente stock
      if (stockActual.cantidadDisponible < cantidad) {
        throw Exception(
          'Stock insuficiente. Disponible: ${stockActual.cantidadDisponible}, Solicitado: $cantidad',
        );
      }

      // Decrementar
      double nuevaCantidad = stockActual.cantidadDisponible - cantidad;
      await actualizarCantidad(
        productoId: productoId,
        nuevaCantidad: nuevaCantidad,
      );

      return nuevaCantidad;
    } catch (e) {
      print('❌ Error al decrementar stock: $e');
      rethrow;
    }
  }

  /// Establece el stock de un producto a una cantidad específica
  ///
  /// Si no existe registro de stock, lo crea.
  ///
  /// Ejemplo:
  /// ```dart
  /// // Ajustar stock a 100 unidades exactas
  /// await repo.establecer(productoId: 1, cantidad: 100);
  /// ```
  Future<void> establecer({
    required int productoId,
    required double cantidad,
  }) async {
    try {
      StockModel? stockActual = await obtenerPorProductoId(productoId);

      if (stockActual == null) {
        // Crear nuevo registro
        await crear(
          StockModel(productoId: productoId, cantidadDisponible: cantidad),
        );
      } else {
        // Actualizar existente
        await actualizarCantidad(
          productoId: productoId,
          nuevaCantidad: cantidad,
        );
      }
    } catch (e) {
      print('❌ Error al establecer stock: $e');
      rethrow;
    }
  }

  // ========================================
  // CONSULTAS Y ESTADÍSTICAS
  // ========================================

  /// Obtiene productos con stock bajo (< 10 unidades)
  Future<List<ProductoConStock>> obtenerStockBajo() async {
    try {
      final Database db = await _dbHelper.database;

      final String query =
          '''
        SELECT 
          p.id as producto_id,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          p.equivalencia,
          p.precio_sin_iva,
          c.id as categoria_id,
          c.nombre as categoria_nombre,
          c.codigo as categoria_codigo,
          s.cantidad_disponible
        FROM productos p
        INNER JOIN categorias c ON p.categoria_id = c.id
        INNER JOIN $_tableName s ON p.id = s.producto_id
        WHERE s.cantidad_disponible < 10 
          AND s.cantidad_disponible > 0
          AND p.estado = 'activo'
        ORDER BY s.cantidad_disponible ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query);

      return List.generate(maps.length, (i) {
        return ProductoConStock.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener stock bajo: $e');
      return [];
    }
  }

  /// Obtiene productos sin stock (cantidad = 0)
  Future<List<ProductoConStock>> obtenerSinStock() async {
    try {
      final Database db = await _dbHelper.database;

      final String query =
          '''
        SELECT 
          p.id as producto_id,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          p.equivalencia,
          p.precio_sin_iva,
          c.id as categoria_id,
          c.nombre as categoria_nombre,
          c.codigo as categoria_codigo,
          COALESCE(s.cantidad_disponible, 0) as cantidad_disponible
        FROM productos p
        INNER JOIN categorias c ON p.categoria_id = c.id
        LEFT JOIN $_tableName s ON p.id = s.producto_id
        WHERE COALESCE(s.cantidad_disponible, 0) = 0
          AND p.estado = 'activo'
        ORDER BY p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query);

      return List.generate(maps.length, (i) {
        return ProductoConStock.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener productos sin stock: $e');
      return [];
    }
  }

  /// Cuenta productos con stock bajo
  Future<int> contarStockBajo() async {
    try {
      final Database db = await _dbHelper.database;

      final int? count = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) 
          FROM $_tableName 
          WHERE cantidad_disponible < 10 AND cantidad_disponible > 0
        '''),
      );

      return count ?? 0;
    } catch (e) {
      print('❌ Error al contar stock bajo: $e');
      return 0;
    }
  }

  // ========================================
// REGISTRO EN LOTE
// ========================================

  /// Registra múltiples movimientos de stock en una sola transacción
  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items, // Lista de {productoId, cantidad, montoValorizado}
    required TipoMovimiento tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    bool valorizado = false,
    int? usuarioId,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      try {
        int movimientosRegistrados = 0;

        for (var item in items) {
          final productoId = item['productoId'] as int;
          final cantidad = item['cantidad'] as double;
          final montoValorizado = item['montoValorizado'] as double?;

          // 1. Obtener stock actual
          final stockActual = await txn.query(
            _tableName,
            where: 'producto_id = ?',
            whereArgs: [productoId],
          );

          if (stockActual.isEmpty) {
            throw Exception('Producto ID $productoId no tiene stock registrado');
          }

          final cantidadActual = stockActual.first['cantidad_disponible'] as double;
          final stockId = stockActual.first['id'] as int;

          // 2. Calcular nueva cantidad
          double cantidadNueva;

          switch (tipo) {
            case TipoMovimiento.entrada:
              cantidadNueva = cantidadActual + cantidad;
              break;

            case TipoMovimiento.salida:
              cantidadNueva = cantidadActual - cantidad;
              if (cantidadNueva < 0) {
                throw Exception(
                  'Saldo insuficiente en producto ID $productoId. '
                      'Disponible: $cantidadActual, Requerido: $cantidad',
                );
              }
              break;

            case TipoMovimiento.ajuste:
              cantidadNueva = cantidad; // En ajuste, la cantidad es el nuevo total
              break;

            default:
              cantidadNueva = cantidadActual;
          }

          // 3. Actualizar stock
          await txn.update(
            _tableName,
            {
              'cantidad_disponible': cantidadNueva,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [stockId],
          );

          // 4. Registrar movimiento
          final movimiento = {
            'producto_id': productoId,
            'tipo': tipo.name,
            'cantidad': cantidad,
            'motivo': motivo,
            'referencia': referencia,
            'remito_numero': remitoNumero,
            'factura_numero': facturaNumero,
            'factura_fecha': facturaFecha?.toIso8601String(),
            'valorizado': valorizado ? 1 : 0,
            'monto_valorizado': montoValorizado,
            'usuario_id': usuarioId,
            'created_at': DateTime.now().toIso8601String(),
          };

          await txn.insert('movimientos_stock', movimiento);
          movimientosRegistrados++;
        }

        print('✅ Movimiento en lote de STOCK registrado: $movimientosRegistrados productos');
        if (facturaNumero != null) {
          print('   📄 Factura: $facturaNumero');
        }

        return true;

      } catch (e) {
        print('❌ Error en registro en lote de stock: $e');
        rethrow;
      }
    });
  }
}

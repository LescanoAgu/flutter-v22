import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/acopio_model.dart';
import '../models/movimiento_acopio_model.dart';

/// Repositorio de Acopios
///
/// Maneja todas las operaciones relacionadas con acopios.
/// IMPORTANTE: Mantiene la integridad de saldos y movimientos.
class AcopioRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'acopios';

  // ========================================
  // OPERACIONES DE LECTURA
  // ========================================

  /// Obtiene TODOS los acopios con detalle
  Future<List<AcopioDetalle>> obtenerTodosConDetalle({bool soloActivos = true}) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          a.*,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social,
          cat.codigo as categoria_codigo,
          cat.nombre as categoria_nombre,
          prov.codigo as proveedor_codigo,
          prov.nombre as proveedor_nombre,
          prov.tipo as proveedor_tipo
        FROM $_tableName a
        INNER JOIN productos p ON a.producto_id = p.id
        INNER JOIN clientes c ON a.cliente_id = c.id
        INNER JOIN categorias cat ON p.categoria_id = cat.id
        INNER JOIN proveedores prov ON a.proveedor_id = prov.id
        ${soloActivos ? "WHERE a.estado = 'activo' AND a.cantidad_disponible > 0" : ''}
        ORDER BY prov.nombre ASC, c.razon_social ASC, p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query);

      return List.generate(maps.length, (i) {
        return AcopioDetalle.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener acopios con detalle: $e');
      return [];
    }
  }

  /// Obtiene acopios de un cliente específico
  Future<List<AcopioDetalle>> obtenerPorCliente(int clienteId) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          a.*,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social,
          cat.codigo as categoria_codigo,
          cat.nombre as categoria_nombre,
          prov.codigo as proveedor_codigo,
          prov.nombre as proveedor_nombre,
          prov.tipo as proveedor_tipo
        FROM $_tableName a
        INNER JOIN productos p ON a.producto_id = p.id
        INNER JOIN clientes c ON a.cliente_id = c.id
        INNER JOIN categorias cat ON p.categoria_id = cat.id
        INNER JOIN proveedores prov ON a.proveedor_id = prov.id
        WHERE a.cliente_id = ? AND a.estado = 'activo' AND a.cantidad_disponible > 0
        ORDER BY prov.nombre ASC, p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, [clienteId]);

      return List.generate(maps.length, (i) {
        return AcopioDetalle.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener acopios del cliente: $e');
      return [];
    }
  }

  /// Obtiene acopios de un proveedor específico
  Future<List<AcopioDetalle>> obtenerPorProveedor(int proveedorId) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          a.*,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social,
          cat.codigo as categoria_codigo,
          cat.nombre as categoria_nombre,
          prov.codigo as proveedor_codigo,
          prov.nombre as proveedor_nombre,
          prov.tipo as proveedor_tipo
        FROM $_tableName a
        INNER JOIN productos p ON a.producto_id = p.id
        INNER JOIN clientes c ON a.cliente_id = c.id
        INNER JOIN categorias cat ON p.categoria_id = cat.id
        INNER JOIN proveedores prov ON a.proveedor_id = prov.id
        WHERE a.proveedor_id = ? AND a.estado = 'activo' AND a.cantidad_disponible > 0
        ORDER BY c.razon_social ASC, p.codigo ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(query, [proveedorId]);

      return List.generate(maps.length, (i) {
        return AcopioDetalle.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener acopios del proveedor: $e');
      return [];
    }
  }

  /// Obtiene un acopio específico
  Future<AcopioModel?> obtenerAcopio({
    required int productoId,
    required int clienteId,
    required int proveedorId,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'producto_id = ? AND cliente_id = ? AND proveedor_id = ?',
        whereArgs: [productoId, clienteId, proveedorId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return AcopioModel.fromMap(maps.first);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener acopio: $e');
      return null;
    }
  }

  /// Busca acopios por producto
  Future<List<AcopioDetalle>> buscarPorProducto(String termino) async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
        SELECT 
          a.*,
          p.codigo as producto_codigo,
          p.nombre as producto_nombre,
          p.unidad_base,
          c.codigo as cliente_codigo,
          c.razon_social as cliente_razon_social,
          cat.codigo as categoria_codigo,
          cat.nombre as categoria_nombre,
          prov.codigo as proveedor_codigo,
          prov.nombre as proveedor_nombre,
          prov.tipo as proveedor_tipo
        FROM $_tableName a
        INNER JOIN productos p ON a.producto_id = p.id
        INNER JOIN clientes c ON a.cliente_id = c.id
        INNER JOIN categorias cat ON p.categoria_id = cat.id
        INNER JOIN proveedores prov ON a.proveedor_id = prov.id
        WHERE (p.nombre LIKE ? OR p.codigo LIKE ?)
          AND a.estado = 'activo' 
          AND a.cantidad_disponible > 0
        ORDER BY prov.nombre ASC, c.razon_social ASC
      ''';

      final List<Map<String, dynamic>> maps = await db.rawQuery(
        query,
        ['%$termino%', '%$termino%'],
      );

      return List.generate(maps.length, (i) {
        return AcopioDetalle.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al buscar acopios por producto: $e');
      return [];
    }
  }

  // ========================================
  // OPERACIONES DE MOVIMIENTOS
  // ========================================

  /// Registra un movimiento de acopio
  /// IMPORTANTE: Actualiza el saldo automáticamente en una transacción
  Future<MovimientoAcopioModel> registrarMovimiento({
    required int productoId,
    required int clienteId,
    required int proveedorId,
    required TipoMovimientoAcopio tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    String? facturaNumero,      // ← NUEVO PARÁMETRO
    DateTime? facturaFecha,     // ← NUEVO PARÁMETRO
    bool valorizado = false,
    double? montoValorizado,
    int? usuarioId,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // 1. Obtener o crear el acopio
      final acopioActual = await txn.query(
        _tableName,
        where: 'producto_id = ? AND cliente_id = ? AND proveedor_id = ?',
        whereArgs: [productoId, clienteId, proveedorId],
      );

      double cantidadAnterior = 0;
      int? acopioId;

      if (acopioActual.isNotEmpty) {
        cantidadAnterior = acopioActual.first['cantidad_disponible'] as double;
        acopioId = acopioActual.first['id'] as int;
      }

      // 2. Calcular nueva cantidad según el tipo de movimiento
      double cantidadNueva;

      switch (tipo) {
        case TipoMovimientoAcopio.entrada:
          cantidadNueva = cantidadAnterior + cantidad;
          break;

        case TipoMovimientoAcopio.salida:
          cantidadNueva = cantidadAnterior - cantidad;
          if (cantidadNueva < 0) {
            throw Exception('Saldo insuficiente. Disponible: $cantidadAnterior, Requerido: $cantidad');
          }
          break;

        default:
        // Para otros tipos (traspaso, reserva, etc.) mantener igual por ahora
          cantidadNueva = cantidadAnterior + cantidad;
      }

      // 3. Actualizar o crear el acopio
      if (acopioId != null) {
        await txn.update(
          _tableName,
          {
            'cantidad_disponible': cantidadNueva,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [acopioId],
        );
      } else {
        // Crear nuevo acopio
        acopioId = await txn.insert(_tableName, {
          'producto_id': productoId,
          'cliente_id': clienteId,
          'proveedor_id': proveedorId,
          'cantidad_disponible': cantidadNueva,
          'estado': 'activo',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. Registrar el movimiento
      final movimiento = MovimientoAcopioModel(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad,
        origenTipo: 'acopio',
        origenId: acopioId,
        destinoTipo: 'acopio',
        destinoId: acopioId,
        motivo: motivo,
        referencia: referencia,
        remitoNumero: remitoNumero,
        facturaNumero: facturaNumero,      // ← NUEVO
        facturaFecha: facturaFecha,        // ← NUEVO
        valorizado: valorizado,
        montoValorizado: montoValorizado,
        usuarioId: usuarioId,
        createdAt: DateTime.now(),
      );

      final movimientoId = await txn.insert('movimientos_acopio', movimiento.toMap());

      print('✅ Movimiento de acopio registrado: ${tipo.name} - $cantidad unidades');
      if (movimiento.tieneFactura) {
        print('   📄 Factura vinculada: ${movimiento.facturaNumero}');
      }

      return movimiento.copyWith(id: movimientoId);
    });
  }

  /// Obtiene movimientos de un acopio
  Future<List<MovimientoAcopioModel>> obtenerMovimientos({
    int? productoId,
    int? clienteId,
    int? proveedorId,
    DateTime? desde,
    DateTime? hasta,
    int? limit,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      String where = '1=1';
      List<dynamic> whereArgs = [];

      if (productoId != null) {
        where += ' AND producto_id = ?';
        whereArgs.add(productoId);
      }

      if (desde != null) {
        where += ' AND created_at >= ?';
        whereArgs.add(desde.toIso8601String());
      }

      if (hasta != null) {
        where += ' AND created_at <= ?';
        whereArgs.add(hasta.toIso8601String());
      }

      final maps = await db.query(
        'movimientos_acopio',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return List.generate(maps.length, (i) {
        return MovimientoAcopioModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener movimientos: $e');
      return [];
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Cuenta total de acopios activos
  Future<int> contarActivos() async {
    try {
      final Database db = await _dbHelper.database;

      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableName WHERE estado = ? AND cantidad_disponible > 0',
          ['activo'],
        ),
      );

      return count ?? 0;
    } catch (e) {
      print('❌ Error al contar acopios: $e');
      return 0;
    }
  }

  // ========================================
// BÚSQUEDA POR FACTURA
// ========================================

  /// Obtiene todos los movimientos de una factura específica
  Future<List<MovimientoAcopioModel>> obtenerMovimientosPorFactura(String facturaNumero) async {
    try {
      final Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'movimientos_acopio',
        where: 'factura_numero = ?',
        whereArgs: [facturaNumero],
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return MovimientoAcopioModel.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error al obtener movimientos por factura: $e');
      return [];
    }
  }

  /// Obtiene todas las facturas únicas registradas
  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async {
    try {
      final Database db = await _dbHelper.database;

      final String query = '''
      SELECT DISTINCT
        factura_numero,
        factura_fecha,
        COUNT(*) as cantidad_items,
        SUM(cantidad) as cantidad_total,
        SUM(CASE WHEN valorizado = 1 THEN monto_valorizado ELSE 0 END) as monto_total
      FROM movimientos_acopio
      WHERE factura_numero IS NOT NULL 
        AND factura_numero != ''
      GROUP BY factura_numero, factura_fecha
      ORDER BY factura_fecha DESC, factura_numero DESC
    ''';

      final List<Map<String, dynamic>> facturas = await db.rawQuery(query);

      print('✅ ${facturas.length} facturas encontradas');
      return facturas;

    } catch (e) {
      print('❌ Error al obtener facturas únicas: $e');
      return [];
    }
  }

  /// Obtiene acopios con sus movimientos de factura
  Future<Map<String, dynamic>> obtenerResumenPorFactura(String facturaNumero) async {
    try {
      final Database db = await _dbHelper.database;

      // Obtener movimientos de la factura con detalle
      final String query = '''
      SELECT 
        m.*,
        p.codigo as producto_codigo,
        p.nombre as producto_nombre,
        p.unidad_base,
        c.razon_social as cliente_razon_social,
        prov.nombre as proveedor_nombre
      FROM movimientos_acopio m
      INNER JOIN productos p ON m.producto_id = p.id
      INNER JOIN acopios a ON m.origen_id = a.id
      INNER JOIN clientes c ON a.cliente_id = c.id
      INNER JOIN proveedores prov ON a.proveedor_id = prov.id
      WHERE m.factura_numero = ?
      ORDER BY m.created_at DESC
    ''';

      final List<Map<String, dynamic>> movimientos = await db.rawQuery(query, [facturaNumero]);

      return {
        'factura_numero': facturaNumero,
        'movimientos': movimientos,
        'cantidad_items': movimientos.length,
      };

    } catch (e) {
      print('❌ Error al obtener resumen de factura: $e');
      return {};
    }
  }

  // ========================================
// TRASPASOS ENTRE ACOPIOS
// ========================================

  /// Registra un traspaso entre dos acopios
  ///
  /// Ejemplo:
  /// - Origen: Cliente A en Proveedor Angler
  /// - Destino: Cliente B en Proveedor Angler
  /// - Cantidad: 20 bolsas
  Future<bool> registrarTraspaso({
    required int productoId,
    // Origen
    required int origenClienteId,
    required int origenProveedorId,
    // Destino
    required int destinoClienteId,
    required int destinoProveedorId,
    // Cantidad
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
    int? usuarioId,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // ========================================
      // 1. VALIDAR ACOPIO ORIGEN
      // ========================================
      final acopioOrigen = await txn.query(
        _tableName,
        where: 'producto_id = ? AND cliente_id = ? AND proveedor_id = ?',
        whereArgs: [productoId, origenClienteId, origenProveedorId],
      );

      if (acopioOrigen.isEmpty) {
        throw Exception('El acopio de origen no existe');
      }

      final cantidadOrigenActual = acopioOrigen.first['cantidad_disponible'] as double;
      final origenId = acopioOrigen.first['id'] as int;

      if (cantidadOrigenActual < cantidad) {
        throw Exception(
          'Saldo insuficiente en origen. Disponible: $cantidadOrigenActual, Requerido: $cantidad',
        );
      }

      // ========================================
      // 2. OBTENER O CREAR ACOPIO DESTINO
      // ========================================
      final acopioDestino = await txn.query(
        _tableName,
        where: 'producto_id = ? AND cliente_id = ? AND proveedor_id = ?',
        whereArgs: [productoId, destinoClienteId, destinoProveedorId],
      );

      int destinoId;
      double cantidadDestinoActual = 0;

      if (acopioDestino.isNotEmpty) {
        destinoId = acopioDestino.first['id'] as int;
        cantidadDestinoActual = acopioDestino.first['cantidad_disponible'] as double;
      } else {
        // Crear nuevo acopio destino
        destinoId = await txn.insert(_tableName, {
          'producto_id': productoId,
          'cliente_id': destinoClienteId,
          'proveedor_id': destinoProveedorId,
          'cantidad_disponible': 0,
          'estado': 'activo',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // ========================================
      // 3. ACTUALIZAR SALDOS
      // ========================================

      // Restar del origen
      final nuevaCantidadOrigen = cantidadOrigenActual - cantidad;
      await txn.update(
        _tableName,
        {
          'cantidad_disponible': nuevaCantidadOrigen,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [origenId],
      );

      // Sumar al destino
      final nuevaCantidadDestino = cantidadDestinoActual + cantidad;
      await txn.update(
        _tableName,
        {
          'cantidad_disponible': nuevaCantidadDestino,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [destinoId],
      );

      // ========================================
      // 4. REGISTRAR MOVIMIENTO DE TRASPASO
      // ========================================
      final movimiento = MovimientoAcopioModel(
        productoId: productoId,
        tipo: TipoMovimientoAcopio.traspaso,
        cantidad: cantidad,
        origenTipo: 'acopio',
        origenId: origenId,
        destinoTipo: 'acopio',
        destinoId: destinoId,
        motivo: motivo ?? 'Traspaso entre acopios',
        referencia: referencia,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        valorizado: false, // Los traspasos no se valorizan
        usuarioId: usuarioId,
        createdAt: DateTime.now(),
      );

      await txn.insert('movimientos_acopio', movimiento.toMap());

      print('✅ Traspaso registrado: $cantidad unidades');
      print('   📤 Origen: Cliente $origenClienteId en Proveedor $origenProveedorId → Saldo: $nuevaCantidadOrigen');
      print('   📥 Destino: Cliente $destinoClienteId en Proveedor $destinoProveedorId → Saldo: $nuevaCantidadDestino');

      return true;
    });
  }

  // ========================================
// HISTORIAL DE MOVIMIENTOS
// ========================================

  /// Obtiene el historial de movimientos de un acopio específico
  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    required int productoId,
    required int clienteId,
    required int proveedorId,
  }) async {
    try {
      final Database db = await _dbHelper.database;

      // Primero obtener el ID del acopio
      final acopioActual = await db.query(
        _tableName,
        where: 'producto_id = ? AND cliente_id = ? AND proveedor_id = ?',
        whereArgs: [productoId, clienteId, proveedorId],
      );

      if (acopioActual.isEmpty) {
        return [];
      }

      final acopioId = acopioActual.first['id'] as int;

      // Obtener todos los movimientos donde este acopio es origen o destino
      final List<Map<String, dynamic>> maps = await db.query(
        'movimientos_acopio',
        where: 'origen_id = ? OR destino_id = ?',
        whereArgs: [acopioId, acopioId],
        orderBy: 'created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return MovimientoAcopioModel.fromMap(maps[i]);
      });

    } catch (e) {
      print('❌ Error al obtener historial de acopio: $e');
      return [];
    }
  }
// ========================================
// REGISTRO EN LOTE
// ========================================

  /// Registra múltiples movimientos de acopio en una sola transacción
  /// Útil para registrar facturas completas con varios productos
  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items, // Lista de {productoId, cantidad}
    required int clienteId,
    required int proveedorId,
    required TipoMovimientoAcopio tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
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

          // 1. Obtener o crear el acopio
          final acopioActual = await txn.query(
            _tableName,
            where: 'producto_id = ? AND cliente_id = ? AND proveedor_id = ?',
            whereArgs: [productoId, clienteId, proveedorId],
          );

          double cantidadAnterior = 0;
          int? acopioId;

          if (acopioActual.isNotEmpty) {
            cantidadAnterior = acopioActual.first['cantidad_disponible'] as double;
            acopioId = acopioActual.first['id'] as int;
          }

          // 2. Calcular nueva cantidad
          double cantidadNueva;

          switch (tipo) {
            case TipoMovimientoAcopio.entrada:
              cantidadNueva = cantidadAnterior + cantidad;
              break;

            case TipoMovimientoAcopio.salida:
              cantidadNueva = cantidadAnterior - cantidad;
              if (cantidadNueva < 0) {
                throw Exception(
                  'Saldo insuficiente en producto ID $productoId. '
                      'Disponible: $cantidadAnterior, Requerido: $cantidad',
                );
              }
              break;

            default:
              cantidadNueva = cantidadAnterior + cantidad;
          }

          // 3. Actualizar o crear el acopio
          if (acopioId != null) {
            await txn.update(
              _tableName,
              {
                'cantidad_disponible': cantidadNueva,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [acopioId],
            );
          } else {
            acopioId = await txn.insert(_tableName, {
              'producto_id': productoId,
              'cliente_id': clienteId,
              'proveedor_id': proveedorId,
              'cantidad_disponible': cantidadNueva,
              'estado': 'activo',
              'created_at': DateTime.now().toIso8601String(),
            });
          }

          // 4. Registrar el movimiento
          final movimiento = MovimientoAcopioModel(
            productoId: productoId,
            tipo: tipo,
            cantidad: cantidad,
            origenTipo: 'acopio',
            origenId: acopioId,
            destinoTipo: 'acopio',
            destinoId: acopioId,
            motivo: motivo,
            referencia: referencia,
            facturaNumero: facturaNumero,
            facturaFecha: facturaFecha,
            valorizado: valorizado,
            montoValorizado: montoValorizado,
            usuarioId: usuarioId,
            createdAt: DateTime.now(),
          );

          await txn.insert('movimientos_acopio', movimiento.toMap());
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

}
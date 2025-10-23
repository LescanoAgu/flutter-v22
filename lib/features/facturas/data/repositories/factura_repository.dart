import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/factura_model.dart';
import '../../../contabilidad/data/models/asiento_model.dart';
import '../../../contabilidad/data/repositories/contabilidad_repository.dart';

/// Repositorio para gestión de facturas, items y pagos
class FacturaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ContabilidadRepository _contabilidadRepository = ContabilidadRepository();

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

    final facturaId = await db.transaction((txn) async {
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

    final facturaGenerada = await obtenerPorId(facturaId);
    if (facturaGenerada != null) {
      await _intentarCrearAsientoFactura(facturaGenerada);
    }

    return facturaId;
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

    final fechaPago = fecha;
    late final int pagoId;

    await db.transaction((txn) async {
      pagoId = await txn.insert('pagos', {
        'factura_id': facturaId,
        'fecha': fechaPago.toIso8601String(),
        'metodo': metodo,
        'monto': monto,
        'referencia': referencia,
        'observaciones': observaciones,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _recalcularEstado(txn, facturaId);
    });

    final factura = await obtenerPorId(facturaId);
    if (factura != null) {
      await _intentarCrearAsientoPago(
        factura: factura,
        pagoId: pagoId,
        fecha: fechaPago,
        monto: monto,
        metodo: metodo,
        referencia: referencia,
      );
    }
  }

  Future<void> _recalcularEstado(DatabaseExecutor db, int facturaId) async {
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

  Future<void> _intentarCrearAsientoFactura(FacturaModel factura) async {
    if (factura.id == null) return;
    if (factura.total <= 0) return;

    try {
      final existe = await _contabilidadRepository.existeAsientoPorOrigen(
        origenTipo: 'factura',
        origenId: factura.id!,
      );
      if (existe) return;

      final cuentaClientes =
          await _contabilidadRepository.obtenerCuentaPorCodigo('1.1.3');
      final cuentaVentas =
          await _contabilidadRepository.obtenerCuentaPorCodigo('4.1.1');
      final cuentaIva =
          await _contabilidadRepository.obtenerCuentaPorCodigo('2.1.1');

      if (cuentaClientes?.id == null || cuentaVentas?.id == null) {
        return;
      }

      final movimientos = <AsientoMovimientoInput>[
        AsientoMovimientoInput(
          cuentaId: cuentaClientes!.id!,
          debe: factura.total,
          detalle: 'Factura ${factura.numero}',
        ),
        AsientoMovimientoInput(
          cuentaId: cuentaVentas!.id!,
          haber: factura.subtotal,
          detalle: 'Ventas ${factura.numero}',
        ),
      ];

      if (factura.impuestos > 0 && cuentaIva?.id != null) {
        movimientos.add(
          AsientoMovimientoInput(
            cuentaId: cuentaIva!.id!,
            haber: factura.impuestos,
            detalle: 'IVA débito ${factura.numero}',
          ),
        );
      }

      await _contabilidadRepository.crearAsiento(
        fecha: factura.fechaEmision,
        descripcion: 'Registro de factura ${factura.numero}',
        origenTipo: 'factura',
        origenId: factura.id!,
        movimientos: movimientos,
      );
    } catch (e) {
      // Si la contabilidad no está configurada todavía se omite el asiento.
      // ignore: avoid_print
      print('⚠️  No se pudo generar asiento para factura ${factura.numero}: $e');
    }
  }

  Future<void> _intentarCrearAsientoPago({
    required FacturaModel factura,
    required int pagoId,
    required DateTime fecha,
    required double monto,
    String? metodo,
    String? referencia,
  }) async {
    if (monto <= 0) return;

    try {
      final existe = await _contabilidadRepository.existeAsientoPorOrigen(
        origenTipo: 'pago',
        origenId: pagoId,
      );
      if (existe) return;

      final cuentaClientes =
          await _contabilidadRepository.obtenerCuentaPorCodigo('1.1.3');
      if (cuentaClientes?.id == null) {
        return;
      }

      final metodoNormalizado = (metodo ?? '').toLowerCase();
      final codigoCobro = metodoNormalizado.contains('transfer') ||
              metodoNormalizado.contains('banco')
          ? '1.1.2'
          : '1.1.1';

      final cuentaCobro =
          await _contabilidadRepository.obtenerCuentaPorCodigo(codigoCobro);
      if (cuentaCobro?.id == null) {
        return;
      }

      await _contabilidadRepository.crearAsiento(
        fecha: fecha,
        descripcion:
            'Cobro ${factura.numero}${referencia != null ? ' · $referencia' : ''}',
        origenTipo: 'pago',
        origenId: pagoId,
        movimientos: [
          AsientoMovimientoInput(
            cuentaId: cuentaCobro!.id!,
            debe: monto,
            detalle: metodo ?? 'Cobro',
          ),
          AsientoMovimientoInput(
            cuentaId: cuentaClientes!.id!,
            haber: monto,
            detalle: 'Aplicado a factura ${factura.numero}',
          ),
        ],
      );
    } catch (e) {
      // ignore: avoid_print
      print('⚠️  No se pudo generar asiento para pago de factura ${factura.numero}: $e');
    }
  }
}

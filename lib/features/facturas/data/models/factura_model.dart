/// Modelo base de Factura (cabecera)
class FacturaModel {
  final int? id;
  final String numero;
  final String tipo;
  final int clienteId;
  final int? obraId;
  final DateTime fechaEmision;
  final DateTime? fechaVencimiento;
  final String estado;
  final String? condicionPago;
  final double subtotal;
  final double impuestos;
  final double total;
  final String? observaciones;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FacturaModel({
    this.id,
    required this.numero,
    this.tipo = 'B',
    required this.clienteId,
    this.obraId,
    required this.fechaEmision,
    this.fechaVencimiento,
    this.estado = 'borrador',
    this.condicionPago,
    this.subtotal = 0,
    this.impuestos = 0,
    this.total = 0,
    this.observaciones,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'tipo': tipo,
      'cliente_id': clienteId,
      'obra_id': obraId,
      'fecha_emision': fechaEmision.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'estado': estado,
      'condicion_pago': condicionPago,
      'subtotal': subtotal,
      'impuestos': impuestos,
      'total': total,
      'observaciones': observaciones,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory FacturaModel.fromMap(Map<String, dynamic> map) {
    return FacturaModel(
      id: map['id'] as int?,
      numero: map['numero'] as String,
      tipo: map['tipo'] as String? ?? 'B',
      clienteId: map['cliente_id'] as int,
      obraId: map['obra_id'] as int?,
      fechaEmision: DateTime.parse(map['fecha_emision'] as String),
      fechaVencimiento: map['fecha_vencimiento'] != null
          ? DateTime.tryParse(map['fecha_vencimiento'] as String)
          : null,
      estado: map['estado'] as String? ?? 'borrador',
      condicionPago: map['condicion_pago'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      impuestos: (map['impuestos'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      observaciones: map['observaciones'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }
}

/// Modelo resumen para listados de facturas
class FacturaResumen {
  final int id;
  final String numero;
  final String tipo;
  final String clienteNombre;
  final String? obraNombre;
  final DateTime fechaEmision;
  final DateTime? fechaVencimiento;
  final String estado;
  final double subtotal;
  final double impuestos;
  final double total;
  final double totalPagado;

  FacturaResumen({
    required this.id,
    required this.numero,
    required this.tipo,
    required this.clienteNombre,
    this.obraNombre,
    required this.fechaEmision,
    this.fechaVencimiento,
    required this.estado,
    required this.subtotal,
    required this.impuestos,
    required this.total,
    required this.totalPagado,
  });

  factory FacturaResumen.fromMap(Map<String, dynamic> map) {
    return FacturaResumen(
      id: map['id'] as int,
      numero: map['numero'] as String,
      tipo: map['tipo'] as String? ?? 'B',
      clienteNombre: map['cliente_nombre'] as String? ?? '',
      obraNombre: map['obra_nombre'] as String?,
      fechaEmision: DateTime.parse(map['fecha_emision'] as String),
      fechaVencimiento: map['fecha_vencimiento'] != null
          ? DateTime.tryParse(map['fecha_vencimiento'] as String)
          : null,
      estado: map['estado'] as String? ?? 'borrador',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      impuestos: (map['impuestos'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      totalPagado: (map['total_pagado'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Detalle de item de factura con información del producto
class FacturaItemDetalle {
  final int id;
  final int productoId;
  final String productoCodigo;
  final String productoNombre;
  final String? descripcion;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;
  final double iva;
  final double total;

  FacturaItemDetalle({
    required this.id,
    required this.productoId,
    required this.productoCodigo,
    required this.productoNombre,
    this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.iva,
    required this.total,
  });

  factory FacturaItemDetalle.fromMap(Map<String, dynamic> map) {
    return FacturaItemDetalle(
      id: map['id'] as int,
      productoId: map['producto_id'] as int,
      productoCodigo: map['producto_codigo'] as String? ?? '',
      productoNombre: map['producto_nombre'] as String? ?? '',
      descripcion: map['descripcion'] as String?,
      cantidad: (map['cantidad'] as num).toDouble(),
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      iva: (map['iva'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}

/// Modelo de pago registrado contra una factura
class PagoModel {
  final int id;
  final int facturaId;
  final DateTime fecha;
  final double monto;
  final String? metodo;
  final String? referencia;
  final String? observaciones;

  PagoModel({
    required this.id,
    required this.facturaId,
    required this.fecha,
    required this.monto,
    this.metodo,
    this.referencia,
    this.observaciones,
  });

  factory PagoModel.fromMap(Map<String, dynamic> map) {
    return PagoModel(
      id: map['id'] as int,
      facturaId: map['factura_id'] as int,
      fecha: DateTime.parse(map['fecha'] as String),
      monto: (map['monto'] as num).toDouble(),
      metodo: map['metodo'] as String?,
      referencia: map['referencia'] as String?,
      observaciones: map['observaciones'] as String?,
    );
  }
}

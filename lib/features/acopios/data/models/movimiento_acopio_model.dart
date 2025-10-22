import 'package:equatable/equatable.dart';

/// Tipos de movimiento de acopio
enum TipoMovimientoAcopio {
  entrada,        // Entrada al acopio (compra directa)
  salida,         // Salida del acopio (uso/consumo)
  reserva,        // Stock S&G → Acopio Cliente (reservar)
  liberacion,     // Acopio → Stock S&G (liberar)
  traspaso,       // Acopio A → Acopio B
  cambio_dueno,   // Cambio de dueño (Cliente X → S&G)
  devolucion,     // Devolución a proveedor
}

/// Modelo de Movimiento de Acopio
///
/// Registra todas las operaciones sobre acopios:
/// - Entradas y salidas
/// - Traspasos entre acopios
/// - Reservas y liberaciones
/// - Cambios de dueño
///
/// NUEVO: Vinculación opcional con facturas
class MovimientoAcopioModel extends Equatable {
  final int? id;
  final int productoId;
  final TipoMovimientoAcopio tipo;
  final double cantidad;

  // Origen y destino flexibles
  final String? origenTipo;        // acopio, stock
  final int? origenId;
  final String? destinoTipo;       // acopio, stock
  final int? destinoId;

  final String? motivo;
  final String? referencia;
  final String? remitoNumero;

  // ========================================
  // NUEVOS CAMPOS: Factura
  // ========================================
  final String? facturaNumero;     // Ej: "0001-00012345"
  final DateTime? facturaFecha;

  // Valorización
  final bool valorizado;
  final double? montoValorizado;

  final int? usuarioId;
  final DateTime createdAt;

  const MovimientoAcopioModel({
    this.id,
    required this.productoId,
    required this.tipo,
    required this.cantidad,
    this.origenTipo,
    this.origenId,
    this.destinoTipo,
    this.destinoId,
    this.motivo,
    this.referencia,
    this.remitoNumero,
    this.facturaNumero,        // ← NUEVO
    this.facturaFecha,         // ← NUEVO
    this.valorizado = false,
    this.montoValorizado,
    this.usuarioId,
    required this.createdAt,
  });

  /// Factory desde Map (BD)
  factory MovimientoAcopioModel.fromMap(Map<String, dynamic> map) {
    return MovimientoAcopioModel(
      id: map['id'],
      productoId: map['producto_id'],
      tipo: TipoMovimientoAcopio.values.firstWhere(
            (t) => t.name == map['tipo'],
      ),
      cantidad: (map['cantidad'] as num).toDouble(),
      origenTipo: map['origen_tipo'],
      origenId: map['origen_id'],
      destinoTipo: map['destino_tipo'],
      destinoId: map['destino_id'],
      motivo: map['motivo'],
      referencia: map['referencia'],
      remitoNumero: map['remito_numero'],

      // ========================================
      // LEER NUEVOS CAMPOS
      // ========================================
      facturaNumero: map['factura_numero'],
      facturaFecha: map['factura_fecha'] != null
          ? DateTime.parse(map['factura_fecha'])
          : null,

      valorizado: map['valorizado'] == 1,
      montoValorizado: map['monto_valorizado'] != null
          ? (map['monto_valorizado'] as num).toDouble()
          : null,
      usuarioId: map['usuario_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// Convertir a Map (para BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'tipo': tipo.name,
      'cantidad': cantidad,
      'origen_tipo': origenTipo,
      'origen_id': origenId,
      'destino_tipo': destinoTipo,
      'destino_id': destinoId,
      'motivo': motivo,
      'referencia': referencia,
      'remito_numero': remitoNumero,

      // ========================================
      // GUARDAR NUEVOS CAMPOS
      // ========================================
      'factura_numero': facturaNumero,
      'factura_fecha': facturaFecha?.toIso8601String(),

      'valorizado': valorizado ? 1 : 0,
      'monto_valorizado': montoValorizado,
      'usuario_id': usuarioId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    productoId,
    tipo,
    cantidad,
    origenTipo,
    origenId,
    destinoTipo,
    destinoId,
    motivo,
    referencia,
    remitoNumero,
    facturaNumero,      // ← NUEVO
    facturaFecha,       // ← NUEVO
    valorizado,
    montoValorizado,
    usuarioId,
    createdAt,
  ];

  // ========================================
  // HELPERS
  // ========================================

  /// Indica si este movimiento tiene factura asociada
  bool get tieneFactura => facturaNumero != null && facturaNumero!.isNotEmpty;

  /// Retorna el número de factura formateado o "Sin factura"
  String get facturaFormateada => tieneFactura ? facturaNumero! : 'Sin factura';

  /// Indica si la factura es reciente (últimos 30 días)
  bool get facturaReciente {
    if (facturaFecha == null) return false;
    final diasDesdeFactura = DateTime.now().difference(facturaFecha!).inDays;
    return diasDesdeFactura <= 30;
  }

  /// CopyWith para crear copias modificadas
  MovimientoAcopioModel copyWith({
    int? id,
    int? productoId,
    TipoMovimientoAcopio? tipo,
    double? cantidad,
    String? origenTipo,
    int? origenId,
    String? destinoTipo,
    int? destinoId,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    String? facturaNumero,
    DateTime? facturaFecha,
    bool? valorizado,
    double? montoValorizado,
    int? usuarioId,
    DateTime? createdAt,
  }) {
    return MovimientoAcopioModel(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      origenTipo: origenTipo ?? this.origenTipo,
      origenId: origenId ?? this.origenId,
      destinoTipo: destinoTipo ?? this.destinoTipo,
      destinoId: destinoId ?? this.destinoId,
      motivo: motivo ?? this.motivo,
      referencia: referencia ?? this.referencia,
      remitoNumero: remitoNumero ?? this.remitoNumero,
      facturaNumero: facturaNumero ?? this.facturaNumero,
      facturaFecha: facturaFecha ?? this.facturaFecha,
      valorizado: valorizado ?? this.valorizado,
      montoValorizado: montoValorizado ?? this.montoValorizado,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

}
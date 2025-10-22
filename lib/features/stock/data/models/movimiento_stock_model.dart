// Este archivo define el MODELO de datos para los movimientos de stock
// Un modelo es como un "molde" que define cómo se estructura la información

import 'package:equatable/equatable.dart';  // Para comparar objetos fácilmente

// Enum para los tipos de movimiento (es más seguro que usar strings)
// Un enum es una lista de valores constantes predefinidos
enum TipoMovimiento {
  entrada,  // Cuando entra mercadería al depósito
  salida,   // Cuando sale mercadería del depósito
  ajuste    // Cuando corriges manualmente el stock
}

// Extendemos de Equatable para poder comparar movimientos fácilmente
class MovimientoStock extends Equatable {
  final int? id;                    // ? significa que puede ser null (para nuevos registros)
  final int productoId;              // ID del producto que se está moviendo
  final TipoMovimiento tipo;         // Tipo de movimiento
  final double cantidad;             // Cantidad del movimiento
  final double cantidadAnterior;    // Stock ANTES del movimiento
  final double cantidadPosterior;   // Stock DESPUÉS del movimiento
  final String? motivo;              // Razón del movimiento (opcional)
  final String? referencia;          // Documento relacionado (ej: "Remito 001-0001234")
  final int? usuarioId;              // Quién hizo el movimiento
  final DateTime createdAt;          // Cuándo se hizo el movimiento

  // Constructor - define cómo crear un objeto MovimientoStock
  const MovimientoStock({
    this.id,
    required this.productoId,      // required = obligatorio
    required this.tipo,
    required this.cantidad,
    required this.cantidadAnterior,
    required this.cantidadPosterior,
    this.motivo,
    this.referencia,
    this.usuarioId,
    required this.createdAt,
  });

  // Factory constructor para crear desde un Map (datos de SQLite)
  // Factory = método especial que construye objetos de manera personalizada
  factory MovimientoStock.fromMap(Map<String, dynamic> map) {
    return MovimientoStock(
      id: map['id'],
      productoId: map['producto_id'],
      // Convertimos el string a enum
      tipo: TipoMovimiento.values.firstWhere(
            (t) => t.name == map['tipo'],
      ),
      cantidad: map['cantidad'].toDouble(),
      cantidadAnterior: map['cantidad_anterior'].toDouble(),
      cantidadPosterior: map['cantidad_posterior'].toDouble(),
      motivo: map['motivo'],
      referencia: map['referencia'],
      usuarioId: map['usuario_id'],
      // Convertimos el string a DateTime
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Método para convertir a Map (para guardar en SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'tipo': tipo.name,  // Convertimos enum a string
      'cantidad': cantidad,
      'cantidad_anterior': cantidadAnterior,
      'cantidad_posterior': cantidadPosterior,
      'motivo': motivo,
      'referencia': referencia,
      'usuario_id': usuarioId,
      'created_at': createdAt.toIso8601String(),  // Formato estándar de fecha
    };
  }

  // copyWith - permite crear una copia modificando algunos valores
  // Útil para actualizar el estado sin mutar el objeto original
  MovimientoStock copyWith({
    int? id,
    int? productoId,
    TipoMovimiento? tipo,
    double? cantidad,
    double? cantidadAnterior,
    double? cantidadPosterior,
    String? motivo,
    String? referencia,
    int? usuarioId,
    DateTime? createdAt,
  }) {
    return MovimientoStock(
      id: id ?? this.id,  // Si no se pasa valor, usa el actual
      productoId: productoId ?? this.productoId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      cantidadAnterior: cantidadAnterior ?? this.cantidadAnterior,
      cantidadPosterior: cantidadPosterior ?? this.cantidadPosterior,
      motivo: motivo ?? this.motivo,
      referencia: referencia ?? this.referencia,
      usuarioId: usuarioId ?? this.usuarioId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Define qué propiedades usar para comparar objetos
  @override
  List<Object?> get props => [
    id,
    productoId,
    tipo,
    cantidad,
    cantidadAnterior,
    cantidadPosterior,
    motivo,
    referencia,
    usuarioId,
    createdAt
  ];

  // Método helper para verificar si es una entrada
  bool get esEntrada => tipo == TipoMovimiento.entrada;

  // Método helper para verificar si es una salida
  bool get esSalida => tipo == TipoMovimiento.salida;

  // Método helper para obtener el signo del movimiento
  String get signo => esEntrada ? '+' : '-';

  // Método helper para obtener el color según el tipo
  // (lo usaremos en la UI más tarde)
  String get colorTipo {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return 'green';
      case TipoMovimiento.salida:
        return 'red';
      case TipoMovimiento.ajuste:
        return 'orange';
    }
  }
}
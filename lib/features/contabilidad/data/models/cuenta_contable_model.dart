import 'package:flutter/foundation.dart';

class CuentaContableModel {
  final int? id;
  final String codigo;
  final String nombre;
  final String tipo;
  final String? descripcion;
  final bool esImputable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CuentaContableModel({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.esImputable = true,
    this.createdAt,
    this.updatedAt,
  });

  CuentaContableModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? tipo,
    String? descripcion,
    bool? esImputable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CuentaContableModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      esImputable: esImputable ?? this.esImputable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'es_imputable': esImputable ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CuentaContableModel.fromMap(Map<String, dynamic> map) {
    return CuentaContableModel(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      nombre: map['nombre'] as String,
      tipo: map['tipo'] as String,
      descripcion: map['descripcion'] as String?,
      esImputable: (map['es_imputable'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return describeIdentity(this);
  }
}

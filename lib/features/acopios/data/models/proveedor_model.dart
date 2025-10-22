import 'package:equatable/equatable.dart';

/// Tipos de proveedor
enum TipoProveedor {
  deposito_syg,  // Depósito propio de S&G
  proveedor,     // Proveedor externo
}

/// Modelo de Proveedor/Ubicación de Acopio
///
/// Representa lugares donde se pueden guardar acopios:
/// - Depósito S&G
/// - Proveedores externos (Angler, etc.)
class ProveedorModel extends Equatable {
  final int? id;
  final String codigo;              // DEP-001, PROV-001
  final String nombre;              // Depósito Central, Proveedor Angler
  final TipoProveedor tipo;
  final String? direccion;
  final String? telefono;
  final String? contacto;
  final String? email;
  final String estado;              // activo, inactivo
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProveedorModel({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    this.direccion,
    this.telefono,
    this.contacto,
    this.email,
    this.estado = 'activo',
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory desde Map (BD)
  factory ProveedorModel.fromMap(Map<String, dynamic> map) {
    return ProveedorModel(
      id: map['id'],
      codigo: map['codigo'],
      nombre: map['nombre'],
      tipo: TipoProveedor.values.firstWhere(
        (t) => t.name == map['tipo'],
      ),
      direccion: map['direccion'],
      telefono: map['telefono'],
      contacto: map['contacto'],
      email: map['email'],
      estado: map['estado'] ?? 'activo',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  /// Convertir a Map (para BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'tipo': tipo.name,
      'direccion': direccion,
      'telefono': telefono,
      'contacto': contacto,
      'email': email,
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// CopyWith
  ProveedorModel copyWith({
    int? id,
    String? codigo,
    String? nombre,
    TipoProveedor? tipo,
    String? direccion,
    String? telefono,
    String? contacto,
    String? email,
    String? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProveedorModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      contacto: contacto ?? this.contacto,
      email: email ?? this.email,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    codigo,
    nombre,
    tipo,
    direccion,
    telefono,
    contacto,
    email,
    estado,
    createdAt,
    updatedAt,
  ];

  // ========================================
// HELPERS
// ========================================

  /// Indica si es el depósito de S&G
  bool get esDepositoSyg => tipo == TipoProveedor.deposito_syg;

  /// Indica si es un proveedor externo
  bool get esProveedorExterno => tipo == TipoProveedor.proveedor;

  /// Indica si está activo
  bool get estaActivo => estado == 'activo';
}
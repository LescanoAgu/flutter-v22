/// Modelo de datos para Cliente
///
/// Representa un cliente de la empresa.
/// Corresponde a la tabla 'clientes' en la base de datos.
class ClienteModel {
  final int? id;
  final String codigo; // CL-001, CL-002, etc.
  final String razonSocial;
  final String? cuit;
  final String? condicionIva; // Responsable Inscripto, Monotributista, etc.
  final String? condicionPago; // Contado, 30 días, 60 días, etc.
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? localidad;
  final String? provincia;
  final String? codigoPostal;
  final String? observaciones;
  final String estado; // activo, inactivo
  final String? createdAt;
  final String? updatedAt;

  ClienteModel({
    this.id,
    required this.codigo,
    required this.razonSocial,
    this.cuit,
    this.condicionIva,
    this.condicionPago,
    this.telefono,
    this.email,
    this.direccion,
    this.localidad,
    this.provincia,
    this.codigoPostal,
    this.observaciones,
    this.estado = 'activo',
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un ClienteModel desde un Map (de la BD)
  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      razonSocial: map['razon_social'] as String,
      cuit: map['cuit'] as String?,
      condicionIva: map['condicion_iva'] as String?,
      condicionPago: map['condicion_pago'] as String?,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
      direccion: map['direccion'] as String?,
      localidad: map['localidad'] as String?,
      provincia: map['provincia'] as String?,
      codigoPostal: map['codigo_postal'] as String?,
      observaciones: map['observaciones'] as String?,
      estado: map['estado'] as String? ?? 'activo',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Convierte el ClienteModel a un Map (para guardar en BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'razon_social': razonSocial,
      'cuit': cuit,
      'condicion_iva': condicionIva,
      'condicion_pago': condicionPago,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'localidad': localidad,
      'provincia': provincia,
      'codigo_postal': codigoPostal,
      'observaciones': observaciones,
      'estado': estado,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Crea una copia con valores modificados
  ClienteModel copyWith({
    int? id,
    String? codigo,
    String? razonSocial,
    String? cuit,
    String? condicionIva,
    String? condicionPago,
    String? telefono,
    String? email,
    String? direccion,
    String? localidad,
    String? provincia,
    String? codigoPostal,
    String? observaciones,
    String? estado,
    String? createdAt,
    String? updatedAt,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      razonSocial: razonSocial ?? this.razonSocial,
      cuit: cuit ?? this.cuit,
      condicionIva: condicionIva ?? this.condicionIva,
      condicionPago: condicionPago ?? this.condicionPago,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      localidad: localidad ?? this.localidad,
      provincia: provincia ?? this.provincia,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      observaciones: observaciones ?? this.observaciones,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica si el cliente está activo
  bool get isActivo => estado == 'activo';

  /// Obtiene el nombre para mostrar
  String get displayName => razonSocial;

  /// Formatea el CUIT
  String get cuitFormateado {
    if (cuit == null || cuit!.length != 11) return cuit ?? '-';
    // Formato: 20-12345678-9
    return '${cuit!.substring(0, 2)}-${cuit!.substring(2, 10)}-${cuit!.substring(10)}';
  }

  /// Dirección completa
  String get direccionCompleta {
    List<String> partes = [];
    if (direccion != null && direccion!.isNotEmpty) partes.add(direccion!);
    if (localidad != null && localidad!.isNotEmpty) partes.add(localidad!);
    if (provincia != null && provincia!.isNotEmpty) partes.add(provincia!);
    if (codigoPostal != null && codigoPostal!.isNotEmpty) partes.add('(CP: $codigoPostal)');

    return partes.isEmpty ? '-' : partes.join(', ');
  }

  @override
  String toString() {
    return 'ClienteModel(id: $id, codigo: $codigo, razonSocial: $razonSocial)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClienteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
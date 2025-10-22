/// Modelo de datos para Obra
///
/// Representa una obra/proyecto de un cliente.
/// Corresponde a la tabla 'obras' en la base de datos.
class ObraModel {
  final int? id;
  final String codigo; // OB-001-CL-001, OB-002-CL-001, etc.
  final int clienteId; // FK a clientes
  final String nombre;
  final String direccion;
  final String? horariosDescarga;
  final String? contactoObra;
  final String? telefonoObra;
  final String? maestroObraNombre;
  final String? maestroObraTelefono;
  final int? responsableInternoId; // FK a usuarios (opcional)
  final String estado; // activa, pausada, finalizada, cancelada
  final String? createdAt;
  final String? updatedAt;

  ObraModel({
    this.id,
    required this.codigo,
    required this.clienteId,
    required this.nombre,
    required this.direccion,
    this.horariosDescarga,
    this.contactoObra,
    this.telefonoObra,
    this.maestroObraNombre,
    this.maestroObraTelefono,
    this.responsableInternoId,
    this.estado = 'activa',
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un ObraModel desde un Map (de la BD)
  factory ObraModel.fromMap(Map<String, dynamic> map) {
    return ObraModel(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      clienteId: map['cliente_id'] as int,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String,
      horariosDescarga: map['horarios_descarga'] as String?,
      contactoObra: map['contacto_obra'] as String?,
      telefonoObra: map['telefono_obra'] as String?,
      maestroObraNombre: map['maestro_obra_nombre'] as String?,
      maestroObraTelefono: map['maestro_obra_telefono'] as String?,
      responsableInternoId: map['responsable_interno_id'] as int?,
      estado: map['estado'] as String? ?? 'activa',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Convierte el ObraModel a un Map (para guardar en BD)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'cliente_id': clienteId,
      'nombre': nombre,
      'direccion': direccion,
      'horarios_descarga': horariosDescarga,
      'contacto_obra': contactoObra,
      'telefono_obra': telefonoObra,
      'maestro_obra_nombre': maestroObraNombre,
      'maestro_obra_telefono': maestroObraTelefono,
      'responsable_interno_id': responsableInternoId,
      'estado': estado,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Crea una copia con valores modificados
  ObraModel copyWith({
    int? id,
    String? codigo,
    int? clienteId,
    String? nombre,
    String? direccion,
    String? horariosDescarga,
    String? contactoObra,
    String? telefonoObra,
    String? maestroObraNombre,
    String? maestroObraTelefono,
    int? responsableInternoId,
    String? estado,
    String? createdAt,
    String? updatedAt,
  }) {
    return ObraModel(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      clienteId: clienteId ?? this.clienteId,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      horariosDescarga: horariosDescarga ?? this.horariosDescarga,
      contactoObra: contactoObra ?? this.contactoObra,
      telefonoObra: telefonoObra ?? this.telefonoObra,
      maestroObraNombre: maestroObraNombre ?? this.maestroObraNombre,
      maestroObraTelefono: maestroObraTelefono ?? this.maestroObraTelefono,
      responsableInternoId: responsableInternoId ?? this.responsableInternoId,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica si la obra está activa
  bool get isActiva => estado == 'activa';

  /// Verifica si la obra está pausada
  bool get isPausada => estado == 'pausada';

  /// Verifica si la obra está finalizada
  bool get isFinalizada => estado == 'finalizada';

  /// Obtiene el nombre para mostrar
  String get displayName => nombre;

  /// Color según el estado
  String get estadoColor {
    switch (estado) {
      case 'activa':
        return 'success';
      case 'pausada':
        return 'warning';
      case 'finalizada':
        return 'info';
      case 'cancelada':
        return 'error';
      default:
        return 'textMedium';
    }
  }

  @override
  String toString() {
    return 'ObraModel(id: $id, codigo: $codigo, nombre: $nombre, clienteId: $clienteId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ObraModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modelo extendido: Obra con información del Cliente
///
/// Combina la información de la obra con los datos del cliente.
class ObraConCliente {
  final ObraModel obra;
  final String clienteCodigo;
  final String clienteRazonSocial;

  ObraConCliente({
    required this.obra,
    required this.clienteCodigo,
    required this.clienteRazonSocial,
  });

  /// Crea desde un Map con JOIN
  factory ObraConCliente.fromMap(Map<String, dynamic> map) {
    return ObraConCliente(
      obra: ObraModel.fromMap(map),
      clienteCodigo: map['cliente_codigo'] as String,
      clienteRazonSocial: map['cliente_razon_social'] as String,
    );
  }

  String get nombreCompleto => '${obra.nombre} - $clienteRazonSocial';

  @override
  String toString() {
    return 'ObraConCliente(${obra.codigo} - ${obra.nombre} - $clienteRazonSocial)';
  }
}
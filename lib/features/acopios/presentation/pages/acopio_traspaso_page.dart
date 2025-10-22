import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/acopio_model.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../stock/data/models/stock_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../../data/models/proveedor_model.dart';
import '../providers/acopio_provider.dart';

/// Pantalla para registrar traspasos entre acopios
///
/// Permite mover materiales de un acopio a otro:
/// - Cambiar de cliente
/// - Cambiar de proveedor
/// - O ambos
class AcopioTraspasoPage extends StatefulWidget {
  const AcopioTraspasoPage({super.key});

  @override
  State<AcopioTraspasoPage> createState() => _AcopioTraspasoPageState();
}

class _AcopioTraspasoPageState extends State<AcopioTraspasoPage> {
  // ========================================
  // ESTADO
  // ========================================

  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _facturaNumeroController = TextEditingController();

  // Origen
  ProductoConStock? _productoSeleccionado;
  ClienteModel? _origenClienteSeleccionado;
  ProveedorModel? _origenProveedorSeleccionado;
  AcopioDetalle? _acopioOrigenSeleccionado;

  // Destino
  ClienteModel? _destinoClienteSeleccionado;
  ProveedorModel? _destinoProveedorSeleccionado;

  DateTime? _facturaFecha;

  @override
  void initState() {
    super.initState();

    // Cargar datos necesarios
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarTodo();
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _referenciaController.dispose();
    _facturaNumeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Traspaso entre Acopios'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
              _buildInfoCard(),
              const SizedBox(height: 24),

              // ========================================
              // ACOPIO ORIGEN
              // ========================================
              _buildSeccionTitulo('📤 ORIGEN'),
              _buildSelectorAcopioOrigen(),

              if (_acopioOrigenSeleccionado != null) ...[
                const SizedBox(height: 12),
                _buildResumenOrigen(),
              ],

              const SizedBox(height: 24),

              // ========================================
              // ACOPIO DESTINO
              // ========================================
              _buildSeccionTitulo('📥 DESTINO'),
              _buildSelectorClienteDestino(),
              const SizedBox(height: 12),
              _buildSelectorProveedorDestino(),

              const SizedBox(height: 24),

              // ========================================
              // CANTIDAD
              // ========================================
              _buildSeccionTitulo('Cantidad a Traspasar'),
              _buildCampoCantidad(),

              const SizedBox(height: 24),

              // ========================================
              // MOTIVO
              // ========================================
              _buildSeccionTitulo('Motivo (Opcional)'),
              _buildCampoMotivo(),

              const SizedBox(height: 24),

              // ========================================
              // REFERENCIA
              // ========================================
              _buildSeccionTitulo('Referencia (Opcional)'),
              _buildCampoReferencia(),

              const SizedBox(height: 32),

              // ========================================
              // BOTÓN REGISTRAR
              // ========================================
              _buildBotonRegistrar(),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // WIDGETS
  // ========================================

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seleccioná el acopio origen y el destino para mover materiales entre ellos',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildSelectorAcopioOrigen() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (_acopioOrigenSeleccionado != null) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.inventory_2, color: AppColors.primary),
              ),
              title: Text(_acopioOrigenSeleccionado!.productoNombre),
              subtitle: Text(
                '${_acopioOrigenSeleccionado!.clienteRazonSocial} en ${_acopioOrigenSeleccionado!.proveedorNombre}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _acopioOrigenSeleccionado = null;
                    _productoSeleccionado = null;
                    _origenClienteSeleccionado = null;
                    _origenProveedorSeleccionado = null;
                  });
                },
              ),
            ),
          );
        }

        return Card(
          child: InkWell(
            onTap: () => _mostrarDialogoSeleccionAcopioOrigen(provider.acopios),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Text('Seleccionar acopio origen', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoSeleccionAcopioOrigen(List<AcopioDetalle> acopios) {
    showDialog(
      context: context,
      builder: (context) {
        String busqueda = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final acopiosFiltrados = busqueda.isEmpty
                ? acopios
                : acopios.where((a) {
              final texto = busqueda.toLowerCase();
              return a.productoNombre.toLowerCase().contains(texto) ||
                  a.clienteRazonSocial.toLowerCase().contains(texto) ||
                  a.proveedorNombre.toLowerCase().contains(texto);
            }).toList();

            return AlertDialog(
              title: const Text('Seleccionar Acopio Origen'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          busqueda = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: acopiosFiltrados.length,
                        itemBuilder: (context, index) {
                          final acopio = acopiosFiltrados[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                            ),
                            title: Text(acopio.productoNombre),
                            subtitle: Text(
                              '${acopio.clienteRazonSocial} → ${acopio.proveedorNombre}\n'
                                  'Disponible: ${acopio.cantidadFormateada} ${acopio.unidadBase}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                            onTap: () async {
                              // Obtener el producto completo
                              final productos = context.read<ProductoProvider>().productos;
                              final producto = productos.firstWhere(
                                    (p) => p.productoId == acopio.acopio.productoId,
                              );

                              // Obtener cliente y proveedor
                              final clientes = context.read<ClienteProvider>().clientes;
                              final cliente = clientes.firstWhere(
                                    (c) => c.id == acopio.acopio.clienteId,
                              );

                              final proveedores = context.read<AcopioProvider>().proveedores;
                              final proveedor = proveedores.firstWhere(
                                    (p) => p.id == acopio.acopio.proveedorId,
                              );

                              setState(() {
                                _acopioOrigenSeleccionado = acopio;
                                _productoSeleccionado = producto;
                                _origenClienteSeleccionado = cliente;
                                _origenProveedorSeleccionado = proveedor;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResumenOrigen() {
    if (_acopioOrigenSeleccionado == null) return const SizedBox.shrink();

    return Card(
      color: AppColors.success.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Disponible: ${_acopioOrigenSeleccionado!.cantidadFormateada} ${_acopioOrigenSeleccionado!.unidadBase}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorClienteDestino() {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
        if (_destinoClienteSeleccionado != null) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              title: Text(_destinoClienteSeleccionado!.razonSocial),
              subtitle: Text(_destinoClienteSeleccionado!.codigo),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _destinoClienteSeleccionado = null;
                  });
                },
              ),
            ),
          );
        }

        return Card(
          child: InkWell(
            onTap: () => _mostrarDialogoSeleccionClienteDestino(provider.clientes),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Text('Seleccionar cliente destino', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoSeleccionClienteDestino(List<ClienteModel> clientes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Cliente Destino'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                title: Text(cliente.razonSocial),
                subtitle: Text(cliente.codigo),
                onTap: () {
                  setState(() {
                    _destinoClienteSeleccionado = cliente;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorProveedorDestino() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, child) {
        if (_destinoProveedorSeleccionado != null) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.successLight,
                child: Icon(
                  _destinoProveedorSeleccionado!.esDepositoSyg ? Icons.warehouse : Icons.store,
                  color: AppColors.success,
                ),
              ),
              title: Text(_destinoProveedorSeleccionado!.nombre),
              subtitle: Text(_destinoProveedorSeleccionado!.codigo),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _destinoProveedorSeleccionado = null;
                  });
                },
              ),
            ),
          );
        }

        return Card(
          child: InkWell(
            onTap: () => _mostrarDialogoSeleccionProveedorDestino(provider.proveedores),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.store, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Text('Seleccionar proveedor destino', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoSeleccionProveedorDestino(List<ProveedorModel> proveedores) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Proveedor/Ubicación Destino'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: proveedores.length,
            itemBuilder: (context, index) {
              final proveedor = proveedores[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.successLight,
                  child: Icon(
                    proveedor.esDepositoSyg ? Icons.warehouse : Icons.store,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                title: Text(proveedor.nombre),
                subtitle: Text(proveedor.codigo),
                onTap: () {
                  setState(() {
                    _destinoProveedorSeleccionado = proveedor;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoCantidad() {
    return TextFormField(
      controller: _cantidadController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: 'Ej: 100',
        suffixText: _acopioOrigenSeleccionado?.unidadBase ?? '',
        prefixIcon: const Icon(Icons.format_list_numbered),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa la cantidad';
        }
        final cantidad = double.tryParse(value);
        if (cantidad == null || cantidad <= 0) {
          return 'La cantidad debe ser mayor a 0';
        }
        if (_acopioOrigenSeleccionado != null &&
            cantidad > _acopioOrigenSeleccionado!.acopio.cantidadDisponible) {
          return 'No hay suficiente stock (disponible: ${_acopioOrigenSeleccionado!.cantidadFormateada})';
        }
        return null;
      },
    );
  }

  Widget _buildCampoMotivo() {
    return TextFormField(
      controller: _motivoController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Ej: Reasignación de materiales entre clientes',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCampoReferencia() {
    return TextFormField(
      controller: _referenciaController,
      decoration: InputDecoration(
        hintText: 'Ej: TRAS-001',
        prefixIcon: const Icon(Icons.tag),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBotonRegistrar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _registrarTraspaso,
        icon: const Icon(Icons.swap_horiz),
        label: const Text(
          'REGISTRAR TRASPASO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ========================================
  // LÓGICA DE REGISTRO
  // ========================================

  Future<void> _registrarTraspaso() async {
    // Validar selecciones
    if (_acopioOrigenSeleccionado == null) {
      _mostrarError('Debes seleccionar un acopio origen');
      return;
    }

    if (_destinoClienteSeleccionado == null) {
      _mostrarError('Debes seleccionar un cliente destino');
      return;
    }

    if (_destinoProveedorSeleccionado == null) {
      _mostrarError('Debes seleccionar un proveedor destino');
      return;
    }

    // Validar que origen y destino sean diferentes
    if (_origenClienteSeleccionado!.id == _destinoClienteSeleccionado!.id &&
        _origenProveedorSeleccionado!.id == _destinoProveedorSeleccionado!.id) {
      _mostrarError('El origen y destino deben ser diferentes');
      return;
    }

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cantidad = double.parse(_cantidadController.text);

    // Obtener datos de factura (opcionales)
    final facturaNumero = _facturaNumeroController.text.trim().isEmpty
        ? null
        : _facturaNumeroController.text.trim();

    // Registrar traspaso
    final exito = await context.read<AcopioProvider>().registrarTraspaso(
      productoId: _productoSeleccionado!.productoId,
      origenClienteId: _origenClienteSeleccionado!.id!,
      origenProveedorId: _origenProveedorSeleccionado!.id!,
      destinoClienteId: _destinoClienteSeleccionado!.id!,
      destinoProveedorId: _destinoProveedorSeleccionado!.id!,
      cantidad: cantidad,
      motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
      referencia: _referenciaController.text.isEmpty ? null : _referenciaController.text,
      facturaNumero: facturaNumero,
      facturaFecha: _facturaFecha,
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Traspaso registrado exitosamente\n'
                '📤 Origen: ${_origenClienteSeleccionado!.razonSocial} en ${_origenProveedorSeleccionado!.nombre}\n'
                '📥 Destino: ${_destinoClienteSeleccionado!.razonSocial} en ${_destinoProveedorSeleccionado!.nombre}\n'
                '📦 Cantidad: $cantidad ${_acopioOrigenSeleccionado!.unidadBase}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true);
    } else if (mounted) {
      _mostrarError('Error al registrar el traspaso');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
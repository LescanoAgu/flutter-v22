import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../stock/data/models/stock_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../providers/acopio_provider.dart';

/// Pantalla para registrar movimientos de acopios
///
/// Permite:
/// - Entrada a acopio (compra directa)
/// - Salida de acopio (uso/consumo)
/// - Valorización opcional
class AcopioMovimientoPage extends StatefulWidget {
  final AcopioDetalle? acopioInicial;

  const AcopioMovimientoPage({
    super.key,
    this.acopioInicial,
  });

  @override
  State<AcopioMovimientoPage> createState() => _AcopioMovimientoPageState();
}

class _AcopioMovimientoPageState extends State<AcopioMovimientoPage> {
  // ========================================
  // ESTADO
  // ========================================

  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _facturaNumeroController = TextEditingController();


  TipoMovimientoAcopio _tipoMovimiento = TipoMovimientoAcopio.entrada;
  ProductoConStock? _productoSeleccionado;
  ClienteModel? _clienteSeleccionado;
  ProveedorModel? _proveedorSeleccionado;
  bool _valorizar = false;
  DateTime? _facturaFecha;

  @override
  void initState() {
    super.initState();

    // Si viene un acopio inicial, pre-cargar datos
    if (widget.acopioInicial != null) {
      _tipoMovimiento = TipoMovimientoAcopio.salida;
      // TODO: Cargar producto, cliente y proveedor del acopio inicial
    }

    // Cargar datos necesarios
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarProveedores();
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
      // ========================================
      // APP BAR
      // ========================================
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
        title: const Text('Registrar Movimiento de Acopio'),
      ),

      // ========================================
      // BODY
      // ========================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // TIPO DE MOVIMIENTO
              // ========================================
              _buildSeccionTitulo('Tipo de Movimiento'),
              _buildSelectorTipo(),

              const SizedBox(height: 24),

              // ========================================
              // PRODUCTO
              // ========================================
              _buildSeccionTitulo('Producto'),
              _buildSelectorProducto(),

              const SizedBox(height: 24),

              // ========================================
              // CLIENTE (DUEÑO)
              // ========================================
              _buildSeccionTitulo('Cliente (Dueño del Acopio)'),
              _buildSelectorCliente(),

              const SizedBox(height: 24),

              // ========================================
              // PROVEEDOR (UBICACIÓN)
              // ========================================
              _buildSeccionTitulo('Proveedor/Ubicación'),
              _buildSelectorProveedor(),

              const SizedBox(height: 24),

              // ========================================
              // CANTIDAD
              // ========================================
              _buildSeccionTitulo('Cantidad'),
              _buildCampoCantidad(),

              const SizedBox(height: 24),

              // ========================================
              // VALORIZACIÓN
              // ========================================
              _buildCheckboxValorizar(),

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

              const SizedBox(height: 24),

              // ========================================
              // DATOS DE FACTURA (OPCIONAL)
              // ========================================
              _buildSeccionTitulo('📄 Datos de Factura (Opcional)'),
              _buildInfoFactura(),
              _buildCampoFacturaNumero(),

              const SizedBox(height: 16),

              _buildCampoFacturaFecha(),

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

  // ========================================
  // SELECTOR DE TIPO
  // ========================================

  Widget _buildSelectorTipo() {
    return Row(
      children: [
        Expanded(
          child: _buildChipTipo(
            tipo: TipoMovimientoAcopio.entrada,
            label: 'ENTRADA',
            icono: Icons.arrow_downward,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildChipTipo(
            tipo: TipoMovimientoAcopio.salida,
            label: 'SALIDA',
            icono: Icons.arrow_upward,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildChipTipo({
    required TipoMovimientoAcopio tipo,
    required String label,
    required IconData icono,
    required Color color,
  }) {
    final seleccionado = _tipoMovimiento == tipo;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoMovimiento = tipo;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.1) : Colors.grey[100],
          border: Border.all(
            color: seleccionado ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: seleccionado ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: seleccionado ? color : Colors.grey[600],
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // SELECTOR DE PRODUCTO
  // ========================================

  Widget _buildSelectorProducto() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (_productoSeleccionado != null) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  _productoSeleccionado!.categoriaCodigo,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(_productoSeleccionado!.productoNombre),
              subtitle: Text(_productoSeleccionado!.productoCodigo),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _productoSeleccionado = null;
                  });
                },
              ),
            ),
          );
        }

        return Card(
          child: InkWell(
            onTap: () => _mostrarDialogoSeleccionProducto(provider.productos),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Text('Seleccionar producto', style: TextStyle(fontSize: 16)),
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

  void _mostrarDialogoSeleccionProducto(List<ProductoConStock> productos) {
    showDialog(
      context: context,
      builder: (context) {
        String busqueda = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final productosFiltrados = busqueda.isEmpty
                ? productos
                : productos.where((p) {
              final texto = busqueda.toLowerCase();
              return p.productoNombre.toLowerCase().contains(texto) ||
                  p.productoCodigo.toLowerCase().contains(texto);
            }).toList();

            return AlertDialog(
              title: const Text('Seleccionar Producto'),
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
                        itemCount: productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final producto = productosFiltrados[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                producto.categoriaCodigo,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(producto.productoNombre),
                            subtitle: Text(producto.productoCodigo),
                            onTap: () {
                              setState(() {
                                _productoSeleccionado = producto;
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

  // ========================================
  // SELECTOR DE CLIENTE
  // ========================================

  Widget _buildSelectorCliente() {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (_clienteSeleccionado != null) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
              title: Text(_clienteSeleccionado!.razonSocial),
              subtitle: Text(_clienteSeleccionado!.codigo),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _clienteSeleccionado = null;
                  });
                },
              ),
            ),
          );
        }

        return Card(
          child: InkWell(
            onTap: () => _mostrarDialogoSeleccionCliente(provider.clientes),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Text('Seleccionar cliente', style: TextStyle(fontSize: 16)),
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

  void _mostrarDialogoSeleccionCliente(List<ClienteModel> clientes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Cliente'),
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
                    _clienteSeleccionado = cliente;
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

  // ========================================
  // SELECTOR DE PROVEEDOR
  // ========================================

  Widget _buildSelectorProveedor() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, child) {
        if (_proveedorSeleccionado != null) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.successLight,
                child: Icon(
                  _proveedorSeleccionado!.esDepositoSyg ? Icons.warehouse : Icons.store,
                  color: AppColors.success,
                ),
              ),
              title: Text(_proveedorSeleccionado!.nombre),
              subtitle: Text(_proveedorSeleccionado!.codigo),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _proveedorSeleccionado = null;
                  });
                },
              ),
            ),
          );
        }

        return Card(
          child: InkWell(
            onTap: () => _mostrarDialogoSeleccionProveedor(provider.proveedores),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.store, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Text('Seleccionar proveedor', style: TextStyle(fontSize: 16)),
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

  void _mostrarDialogoSeleccionProveedor(List<ProveedorModel> proveedores) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Proveedor/Ubicación'),
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
                    _proveedorSeleccionado = proveedor;
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

  // ========================================
  // CAMPOS DE FORMULARIO
  // ========================================

  Widget _buildCampoCantidad() {
    return TextFormField(
      controller: _cantidadController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: 'Ej: 100',
        suffixText: _productoSeleccionado?.unidadBase ?? '',
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
        return null;
      },
    );
  }

  Widget _buildCampoMotivo() {
    return TextFormField(
      controller: _motivoController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Ej: Compra a proveedor, Material sobrante de obra, etc.',
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
        hintText: 'Ej: OC-001, FACT-1234, etc.',
        prefixIcon: const Icon(Icons.tag),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCheckboxValorizar() {
    return Card(
      color: _valorizar ? AppColors.warning.withOpacity(0.05) : null,
      child: CheckboxListTile(
        value: _valorizar,
        onChanged: (value) {
          setState(() {
            _valorizar = value ?? false;
          });
        },
        title: const Text('Valorizar movimiento'),
        subtitle: Text(
          _valorizar
              ? 'Se generará un cargo pendiente en cuenta corriente'
              : 'Solo registrar movimiento físico',
          style: TextStyle(
            fontSize: 12,
            color: _valorizar ? AppColors.warning : AppColors.textLight,
          ),
        ),
        secondary: Icon(
          _valorizar ? Icons.attach_money : Icons.money_off,
          color: _valorizar ? AppColors.warning : AppColors.textMedium,
        ),
      ),
    );
  }

  Widget _buildBotonRegistrar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _registrarMovimiento,
        icon: const Icon(Icons.check_circle),
        label: Text(
          'REGISTRAR ${_tipoMovimiento.name.toUpperCase()}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ========================================
// WIDGETS DE FACTURA
// ========================================

  Widget _buildInfoFactura() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vinculá este movimiento a una factura para facilitar la búsqueda y organización',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoFacturaNumero() {
    return TextFormField(
      controller: _facturaNumeroController,
      decoration: InputDecoration(
        labelText: 'Número de Factura',
        hintText: 'Ej: 0001-00012345',
        prefixIcon: const Icon(Icons.receipt_long),
        suffixIcon: _facturaNumeroController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _facturaNumeroController.clear();
            });
          },
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildCampoFacturaFecha() {
    return InkWell(
      onTap: () async {
        final fecha = await showDatePicker(
          context: context,
          initialDate: _facturaFecha ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es', 'AR'),
        );

        if (fecha != null) {
          setState(() {
            _facturaFecha = fecha;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de Factura',
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: _facturaFecha != null
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _facturaFecha = null;
              });
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _facturaFecha != null
              ? '${_facturaFecha!.day}/${_facturaFecha!.month}/${_facturaFecha!.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: _facturaFecha != null ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ),
    );
  }




  // ========================================
  // LÓGICA DE REGISTRO
  // ========================================

  Future<void> _registrarMovimiento() async {
    // Validar selecciones
    if (_productoSeleccionado == null) {
      _mostrarError('Debes seleccionar un producto');
      return;
    }

    if (_clienteSeleccionado == null) {
      _mostrarError('Debes seleccionar un cliente');
      return;
    }

    if (_proveedorSeleccionado == null) {
      _mostrarError('Debes seleccionar un proveedor');
      return;
    }

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cantidad = double.parse(_cantidadController.text);

    // Calcular monto si se valoriza
    double? montoValorizado;
    if (_valorizar && _productoSeleccionado!.precioSinIva != null) {
      montoValorizado = cantidad * _productoSeleccionado!.precioSinIva!;
    }

    // Obtener datos de factura (opcionales)
    final facturaNumero = _facturaNumeroController.text.trim().isEmpty
        ? null
        : _facturaNumeroController.text.trim();

    // Registrar según el tipo
    bool exito = false;

    if (_tipoMovimiento == TipoMovimientoAcopio.entrada) {
      exito = await context.read<AcopioProvider>().registrarEntrada(
        productoId: _productoSeleccionado!.productoId,
        clienteId: _clienteSeleccionado!.id!,
        proveedorId: _proveedorSeleccionado!.id!,
        cantidad: cantidad,
        motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
        referencia: _referenciaController.text.isEmpty ? null : _referenciaController.text,
        facturaNumero: facturaNumero,      // ← NUEVO
        facturaFecha: _facturaFecha,       // ← NUEVO
        valorizado: _valorizar,
        montoValorizado: montoValorizado,
      );
    } else {
      exito = await context.read<AcopioProvider>().registrarSalida(
        productoId: _productoSeleccionado!.productoId,
        clienteId: _clienteSeleccionado!.id!,
        proveedorId: _proveedorSeleccionado!.id!,
        cantidad: cantidad,
        motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
        referencia: _referenciaController.text.isEmpty ? null : _referenciaController.text,
        facturaNumero: facturaNumero,      // ← NUEVO
        facturaFecha: _facturaFecha,       // ← NUEVO
        valorizado: _valorizar,
        montoValorizado: montoValorizado,
      );
    }

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Movimiento registrado: ${_tipoMovimiento.name.toUpperCase()} de $cantidad ${_productoSeleccionado!.unidadBase}'
                '${facturaNumero != null ? "\n📄 Factura: $facturaNumero" : ""}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true);
    } else if (mounted) {
      _mostrarError('Error al registrar el movimiento');
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
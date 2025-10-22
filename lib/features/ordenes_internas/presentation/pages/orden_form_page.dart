import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../obras/presentation/providers/obra_provider.dart';
import '../../../stock/data/models/stock_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../providers/orden_interna_provider.dart';

/// Pantalla de Formulario de Orden Interna
class OrdenFormPage extends StatefulWidget {
  const OrdenFormPage({super.key});

  @override
  State<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends State<OrdenFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _solicitanteNombreController = TextEditingController();
  final _solicitanteEmailController = TextEditingController();
  final _solicitanteTelefonoController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Selecciones
  ClienteModel? _clienteSeleccionado;
  ObraModel? _obraSeleccionada;
  DateTime? _fechaEntregaEstimada;

  // Lista de productos agregados
  List<Map<String, dynamic>> _productosAgregados = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
      context.read<ProductoProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _solicitanteNombreController.dispose();
    _solicitanteEmailController.dispose();
    _solicitanteTelefonoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nueva Orden Interna'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSeccionHeader('👤 Datos del Solicitante'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _solicitanteNombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _solicitanteEmailController,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _solicitanteTelefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _buildSeccionHeader('🏢 Destino del Pedido'),
            const SizedBox(height: 12),
            Consumer<ClienteProvider>(
              builder: (context, provider, child) {
                return DropdownButtonFormField<ClienteModel>(
                  value: _clienteSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Cliente *',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  items: provider.clientes.map((cliente) {
                    return DropdownMenuItem(
                      value: cliente,
                      child: Text(cliente.razonSocial),
                    );
                  }).toList(),
                  onChanged: (cliente) {
                    setState(() {
                      _clienteSeleccionado = cliente;
                      _obraSeleccionada = null;
                    });
                    if (cliente != null) {
                      context.read<ObraProvider>().cargarObrasPorCliente(cliente.id!, soloActivas: true);
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Seleccioná un cliente';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            if (_clienteSeleccionado != null)
              Consumer<ObraProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<ObraModel>(
                    value: _obraSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Obra (opcional)',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    items: provider.obras.map((obraConCliente) {
                      return DropdownMenuItem(
                        value: obraConCliente.obra,
                        child: Text(obraConCliente.obra.nombre),
                      );
                    }).toList(),
                    onChanged: (obra) {
                      setState(() {
                        _obraSeleccionada = obra;
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: Text(
                _fechaEntregaEstimada != null
                    ? 'Entrega estimada: ${ArgFormats.fecha(_fechaEntregaEstimada!)}'
                    : 'Fecha de entrega estimada (opcional)',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _seleccionarFechaEntrega,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 24),
            _buildSeccionHeader('📦 Productos'),
            const SizedBox(height: 12),
            if (_productosAgregados.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 48, color: AppColors.textLight),
                    const SizedBox(height: 8),
                    const Text('No hay productos agregados'),
                    const SizedBox(height: 8),
                    Text(
                      'Presioná el botón + para agregar productos',
                      style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._productosAgregados.asMap().entries.map((entry) {
                final index = entry.key;
                final producto = entry.value;
                return _buildProductoItem(producto, index);
              }).toList(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Producto'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            _buildSeccionHeader('📝 Observaciones'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones adicionales (opcional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            if (_productosAgregados.isNotEmpty) ...[
              _buildResumen(),
              const SizedBox(height: 24),
            ],
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _crearOrden,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Creando...' : 'Crear Orden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildProductoItem(Map<String, dynamic> producto, int index) {
    final productoData = producto['producto'] as ProductoConStock;
    final cantidad = producto['cantidad'] as double;
    final precio = producto['precio'] as double;
    final subtotal = cantidad * precio;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productoData.productoNombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ArgFormats.decimal(cantidad)} ${productoData.unidadBase} × ${ArgFormats.moneda(precio)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${ArgFormats.moneda(subtotal)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editarProducto(index),
                  color: AppColors.info,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _eliminarProducto(index),
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen() {
    final total = _productosAgregados.fold<double>(
      0,
          (sum, item) => sum + ((item['cantidad'] as double) * (item['precio'] as double)),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total de productos:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                _productosAgregados.length.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total estimado:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ArgFormats.moneda(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarFechaEntrega() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha != null) {
      setState(() {
        _fechaEntregaEstimada = fecha;
      });
    }
  }

  Future<void> _agregarProducto() async {
    final productoProvider = context.read<ProductoProvider>();

    if (productoProvider.productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles')),
      );
      return;
    }

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ProductoSelectorDialog(
        productos: productoProvider.productos,
      ),
    );

    if (resultado != null) {
      setState(() {
        _productosAgregados.add(resultado);
      });
    }
  }

  void _editarProducto(int index) async {
    final productoActual = _productosAgregados[index];

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ProductoSelectorDialog(
        productos: context.read<ProductoProvider>().productos,
        productoInicial: productoActual['producto'] as ProductoConStock,
        cantidadInicial: productoActual['cantidad'] as double,
        precioInicial: productoActual['precio'] as double,
      ),
    );

    if (resultado != null) {
      setState(() {
        _productosAgregados[index] = resultado;
      });
    }
  }

  void _eliminarProducto(int index) {
    setState(() {
      _productosAgregados.removeAt(index);
    });
  }

  Future<void> _crearOrden() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_productosAgregados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agregá al menos un producto')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final items = _productosAgregados.map((p) {
      final producto = p['producto'] as ProductoConStock;
      return {
        'productoId': producto.productoId,
        'cantidad': p['cantidad'],
        'precio': p['precio'],
      };
    }).toList();

    final exito = await context.read<OrdenInternaProvider>().crearOrden(
      clienteId: _clienteSeleccionado!.id!,
      obraId: _obraSeleccionada?.id,
      solicitanteNombre: _solicitanteNombreController.text.trim(),
      solicitanteEmail: _solicitanteEmailController.text.trim().isEmpty
          ? null
          : _solicitanteEmailController.text.trim(),
      solicitanteTelefono: _solicitanteTelefonoController.text.trim().isEmpty
          ? null
          : _solicitanteTelefonoController.text.trim(),
      fechaEntregaEstimada: _fechaEntregaEstimada,
      observacionesCliente: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      items: items,
    );

    setState(() => _isLoading = false);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Orden creada exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al crear la orden'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// Dialog Selector de Producto
class _ProductoSelectorDialog extends StatefulWidget {
  final List<ProductoConStock> productos;
  final ProductoConStock? productoInicial;
  final double? cantidadInicial;
  final double? precioInicial;

  const _ProductoSelectorDialog({
    required this.productos,
    this.productoInicial,
    this.cantidadInicial,
    this.precioInicial,
  });

  @override
  State<_ProductoSelectorDialog> createState() => _ProductoSelectorDialogState();
}

class _ProductoSelectorDialogState extends State<_ProductoSelectorDialog> {
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  ProductoConStock? _productoSeleccionado;

  @override
  void initState() {
    super.initState();
    _productoSeleccionado = widget.productoInicial;
    _cantidadController.text = widget.cantidadInicial?.toString() ?? '';
    _precioController.text = widget.precioInicial?.toStringAsFixed(2) ?? '';
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.productoInicial != null ? 'Editar Producto' : 'Agregar Producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProductoConStock>(
              value: _productoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
              items: widget.productos.map((producto) {
                return DropdownMenuItem(
                  value: producto,
                  child: Text(producto.productoNombre),
                );
              }).toList(),
              onChanged: (producto) {
                setState(() {
                  _productoSeleccionado = producto;
                  if (producto?.precioSinIva != null) {
                    _precioController.text = producto!.precioSinIva!.toStringAsFixed(2);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController,
              decoration: InputDecoration(
                labelText: 'Cantidad',
                suffix: Text(_productoSeleccionado?.unidadBase ?? ''),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio unitario',
                prefix: Text('\$ '),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_productoSeleccionado == null ||
                _cantidadController.text.isEmpty ||
                _precioController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Completá todos los campos')),
              );
              return;
            }

            Navigator.pop(context, {
              'producto': _productoSeleccionado,
              'cantidad': double.parse(_cantidadController.text),
              'precio': double.parse(_precioController.text),
            });
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
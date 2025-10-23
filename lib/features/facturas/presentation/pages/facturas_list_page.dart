
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../data/models/factura_model.dart';
import '../providers/factura_provider.dart';

class FacturasListPage extends StatefulWidget {
  const FacturasListPage({super.key});

  @override
  State<FacturasListPage> createState() => _FacturasListPageState();
}

class _FacturasListPageState extends State<FacturasListPage> {
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FacturaProvider>().cargarFacturas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Facturación y cobros'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (value) {
              setState(() {
                _filtroEstado = value;
              });
              context.read<FacturaProvider>().cargarFacturas(estado: value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: null, child: Text('Todos')),
              PopupMenuItem(value: 'borrador', child: Text('Borradores')),
              PopupMenuItem(value: 'emitida', child: Text('Emitidas')),
              PopupMenuItem(value: 'parcial', child: Text('Cobro parcial')),
              PopupMenuItem(value: 'pagada', child: Text('Pagadas')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarSheetNuevaFactura(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva factura'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Consumer<FacturaProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (provider.errorMessage != null) {
              return _ErrorState(message: provider.errorMessage!);
            }

            if (!provider.hayFacturas) {
              return const _EmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => provider.cargarFacturas(estado: _filtroEstado),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.facturas.length,
                itemBuilder: (context, index) {
                  final factura = provider.facturas[index];
                  return _FacturaCard(
                    factura: factura,
                    onTap: () => _mostrarDetalleFactura(context, factura.id),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _mostrarDetalleFactura(
    BuildContext context,
    int facturaId,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DetalleFacturaSheet(facturaId: facturaId),
    );
  }

  Future<void> _mostrarSheetNuevaFactura(BuildContext context) async {
    final provider = context.read<FacturaProvider>();
    final clientes = await provider.obtenerClientesActivos();
    final productos = await provider.obtenerProductosActivos();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _NuevaFacturaSheet(
        clientes: clientes,
        productos: productos,
        provider: provider,
      ),
    );
  }
}

class _FacturaCard extends StatelessWidget {
  final FacturaResumen factura;
  final VoidCallback onTap;

  const _FacturaCard({
    required this.factura,
    required this.onTap,
  });

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'borrador':
        return Colors.orange.shade600;
      case 'pagada':
        return Colors.green.shade600;
      case 'parcial':
        return Colors.amber.shade700;
      default:
        return AppColors.primary;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: r'$');
    final saldo = factura.total - factura.totalPagado;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${factura.numero} · Tipo ${factura.tipo}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Chip(
              backgroundColor: _estadoColor(factura.estado),
              label: Text(
                factura.estado.toUpperCase(),
                style: const TextStyle(color: AppColors.textWhite),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(factura.clienteNombre),
              if (factura.obraNombre != null)
                Text(
                  factura.obraNombre!,
                  style: const TextStyle(color: AppColors.textMedium),
                ),
              const SizedBox(height: 4),
              Text('Emitida: ${_formatearFecha(factura.fechaEmision)}'),
              if (factura.fechaVencimiento != null)
                Text(
                  'Vence: ${_formatearFecha(factura.fechaVencimiento!)}',
                  style: const TextStyle(color: AppColors.textMedium),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Subtotal: ${formatter.format(factura.subtotal)}'),
                        Text('Impuestos: ${formatter.format(factura.impuestos)}'),
                        Text('Total: ${formatter.format(factura.total)}'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Pagado: ${formatter.format(factura.totalPagado)}'),
                        Text(
                          'Saldo: ${formatter.format(saldo > 0 ? saldo : 0)}',
                          style: TextStyle(
                            color: saldo <= 0
                                ? Colors.green.shade700
                                : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.receipt_long, size: 48, color: AppColors.textLight),
            SizedBox(height: 16),
            Text('Todavía no hay facturas registradas'),
            SizedBox(height: 8),
            Text(
              'Generá la primera factura desde el botón "+"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleFacturaSheet extends StatefulWidget {
  final int facturaId;

  const _DetalleFacturaSheet({required this.facturaId});

  @override
  State<_DetalleFacturaSheet> createState() => _DetalleFacturaSheetState();
}

class _DetalleFacturaSheetState extends State<_DetalleFacturaSheet> {
  late Future<List<FacturaItemDetalle>> _itemsFuture;
  late Future<List<PagoModel>> _pagosFuture;
  FacturaResumen? _facturaResumen;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FacturaProvider>();
    _itemsFuture = provider.obtenerItems(widget.facturaId);
    _pagosFuture = provider.obtenerPagos(widget.facturaId);
    _facturaResumen = provider.facturas
        .firstWhere((element) => element.id == widget.facturaId);
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: r'$');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _facturaResumen != null
                          ? _facturaResumen!.numero
                          : 'Factura',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_facturaResumen != null) ...[
                  Text('Cliente: ${_facturaResumen!.clienteNombre}'),
                  if (_facturaResumen!.obraNombre != null)
                    Text('Obra: ${_facturaResumen!.obraNombre!}'),
                  const SizedBox(height: 8),
                  Text('Estado: ${_facturaResumen!.estado.toUpperCase()}'),
                  Text(
                    'Total: ${formatter.format(_facturaResumen!.total)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Pagado: ${formatter.format(_facturaResumen!.totalPagado)}',
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<FacturaItemDetalle>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Sin items cargados'),
                      );
                    }

                    return Column(
                      children: items
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.productoNombre),
                              subtitle: Text(
                                '${item.cantidad.toStringAsFixed(2)} x '
                                '${formatter.format(item.precioUnitario)}',
                              ),
                              trailing: Text(
                                formatter.format(item.total),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pagos registrados',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () => _mostrarDialogoPago(context),
                      icon: const Icon(Icons.attach_money),
                      label: const Text('Registrar pago'),
                    ),
                  ],
                ),
                FutureBuilder<List<PagoModel>>(
                  future: _pagosFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final pagos = snapshot.data ?? [];
                    if (pagos.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Todavía no se registraron pagos'),
                      );
                    }

                    return Column(
                      children: pagos
                          .map(
                            (pago) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.check_circle,
                                  color: AppColors.primary),
                              title: Text(
                                formatter.format(pago.monto),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${DateFormat('dd/MM/yyyy').format(pago.fecha)} · '
                                '${pago.metodo ?? 'Sin método'}'
                                '${pago.referencia != null ? ' · Ref: ${pago.referencia}' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _mostrarDialogoPago(BuildContext context) async {
    final provider = context.read<FacturaProvider>();
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController();
    final referenciaController = TextEditingController();
    String? metodoSeleccionado;
    DateTime fecha = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Registrar pago'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: montoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto'),
                      validator: (value) {
                        final monto = double.tryParse(value ?? '');
                        if (monto == null || monto <= 0) {
                          return 'Ingrese un monto válido';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Método'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Transferencia',
                          child: Text('Transferencia'),
                        ),
                        DropdownMenuItem(
                          value: 'Efectivo',
                          child: Text('Efectivo'),
                        ),
                        DropdownMenuItem(
                          value: 'Cheque',
                          child: Text('Cheque'),
                        ),
                      ],
                      onChanged: (value) => metodoSeleccionado = value,
                    ),
                    TextFormField(
                      controller: referenciaController,
                      decoration:
                          const InputDecoration(labelText: 'Referencia'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final nuevaFecha = await showDatePicker(
                              context: context,
                              initialDate: fecha,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (nuevaFecha != null) {
                              setStateDialog(() {
                                fecha = nuevaFecha;
                              });
                            }
                          },
                          icon: const Icon(Icons.event),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final monto = double.parse(
                      montoController.text.replaceAll(',', '.'),
                    );
                    final ok = await provider.registrarPago(
                      facturaId: widget.facturaId,
                      monto: monto,
                      fecha: fecha,
                      metodo: metodoSeleccionado,
                      referencia: referenciaController.text.isNotEmpty
                          ? referenciaController.text
                          : null,
                    );

                    if (!mounted) return;

                    if (ok) {
                      setState(() {
                        _pagosFuture = provider.obtenerPagos(widget.facturaId);
                        _facturaResumen = provider.facturas
                            .firstWhere((element) => element.id == widget.facturaId);
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _NuevaFacturaSheet extends StatefulWidget {
  final List<ClienteModel> clientes;
  final List<ProductoModel> productos;
  final FacturaProvider provider;

  const _NuevaFacturaSheet({
    required this.clientes,
    required this.productos,
    required this.provider,
  });

  @override
  State<_NuevaFacturaSheet> createState() => _NuevaFacturaSheetState();
}

class _ItemFacturaForm {
  final ProductoModel producto;
  double cantidad;
  double precioUnitario;
  double ivaPorcentaje;
  String? descripcion;

  _ItemFacturaForm({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.ivaPorcentaje,
    this.descripcion,
  });
}

class _NuevaFacturaSheetState extends State<_NuevaFacturaSheet> {
  final _formKey = GlobalKey<FormState>();
  ClienteModel? _clienteSeleccionado;
  ObraModel? _obraSeleccionada;
  List<ObraModel> _obrasDisponibles = [];
  String _tipoSeleccionado = 'B';
  final TextEditingController _condicionPagoController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  DateTime? _fechaVencimiento;

  ProductoModel? _productoSeleccionado;
  final TextEditingController _cantidadController =
      TextEditingController(text: '1');
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _ivaController =
      TextEditingController(text: '21');
  final TextEditingController _descripcionItemController =
      TextEditingController();

  final List<_ItemFacturaForm> _items = [];
  bool _enviando = false;

  @override
  void dispose() {
    _condicionPagoController.dispose();
    _observacionesController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _ivaController.dispose();
    _descripcionItemController.dispose();
    super.dispose();
  }

  Future<void> _cargarObras(int clienteId) async {
    final obras = await widget.provider.obtenerObrasPorCliente(clienteId);
    if (!mounted) return;
    setState(() {
      _obrasDisponibles = obras;
      _obraSeleccionada = null;
    });
  }

  Future<void> _agregarItem() async {
    if (_productoSeleccionado == null) {
      _mostrarSnack('Seleccione un producto');
      return;
    }

    final cantidad = double.tryParse(_cantidadController.text.replaceAll(',', '.'));
    final precio = double.tryParse(_precioController.text.replaceAll(',', '.'));
    final iva = double.tryParse(_ivaController.text.replaceAll(',', '.'));

    if (cantidad == null || cantidad <= 0) {
      _mostrarSnack('Ingrese una cantidad válida');
      return;
    }
    if (precio == null || precio <= 0) {
      _mostrarSnack('Ingrese un precio unitario válido');
      return;
    }
    if (iva == null || iva < 0) {
      _mostrarSnack('Ingrese un IVA válido');
      return;
    }

    setState(() {
      _items.add(
        _ItemFacturaForm(
          producto: _productoSeleccionado!,
          cantidad: cantidad,
          precioUnitario: precio,
          ivaPorcentaje: iva,
          descripcion: _descripcionItemController.text.isNotEmpty
              ? _descripcionItemController.text
              : null,
        ),
      );
      _productoSeleccionado = null;
      _cantidadController.text = '1';
      _precioController.clear();
      _ivaController.text = '21';
      _descripcionItemController.clear();
    });
  }

  void _eliminarItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _guardarFactura() async {
    if (_clienteSeleccionado == null) {
      _mostrarSnack('Selecciona un cliente');
      return;
    }
    if (_items.isEmpty) {
      _mostrarSnack('Agrega al menos un item a la factura');
      return;
    }

    if (_enviando) return;

    setState(() {
      _enviando = true;
    });

    final itemsPayload = _items
        .map(
          (item) => {
            'productoId': item.producto.id,
            'descripcion': item.descripcion ?? item.producto.descripcion,
            'cantidad': item.cantidad,
            'precioUnitario': item.precioUnitario,
            'ivaPorcentaje': item.ivaPorcentaje,
          },
        )
        .toList();

    final ok = await widget.provider.crearFacturaRapida(
      clienteId: _clienteSeleccionado!.id!,
      obraId: _obraSeleccionada?.id,
      tipo: _tipoSeleccionado,
      fechaVencimiento: _fechaVencimiento,
      condicionPago: _condicionPagoController.text.isNotEmpty
          ? _condicionPagoController.text
          : null,
      observaciones: _observacionesController.text.isNotEmpty
          ? _observacionesController.text
          : null,
      items: itemsPayload,
    );

    if (!mounted) return;

    setState(() {
      _enviando = false;
    });

    if (ok) {
      Navigator.of(context).pop();
    }
  }

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom + 24;

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nueva factura',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ClienteModel>(
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  value: _clienteSeleccionado,
                  items: widget.clientes
                      .map(
                        (cliente) => DropdownMenuItem(
                          value: cliente,
                          child: Text(cliente.razonSocial),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _clienteSeleccionado = value;
                    });
                    if (value?.id != null) {
                      _cargarObras(value!.id!);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ObraModel>(
                  decoration: const InputDecoration(labelText: 'Obra'),
                  value: _obraSeleccionada,
                  items: _obrasDisponibles
                      .map(
                        (obra) => DropdownMenuItem(
                          value: obra,
                          child: Text(obra.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _obraSeleccionada = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Tipo de factura'),
                  value: _tipoSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('Factura A')),
                    DropdownMenuItem(value: 'B', child: Text('Factura B')),
                    DropdownMenuItem(value: 'C', child: Text('Factura C')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoSeleccionado = value ?? 'B';
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _condicionPagoController,
                  decoration: const InputDecoration(labelText: 'Condición de pago'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fechaVencimiento == null
                            ? 'Sin fecha de vencimiento'
                            : 'Vence: ${DateFormat('dd/MM/yyyy').format(_fechaVencimiento!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final seleccionada = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime(2100),
                        );
                        if (seleccionada != null) {
                          setState(() {
                            _fechaVencimiento = seleccionada;
                          });
                        }
                      },
                      child: const Text('Elegir fecha'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  maxLines: 3,
                ),
                const Divider(height: 32),
                Text(
                  'Items de la factura',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductoModel>(
                  decoration: const InputDecoration(labelText: 'Producto'),
                  value: _productoSeleccionado,
                  items: widget.productos
                      .map(
                        (producto) => DropdownMenuItem(
                          value: producto,
                          child: Text(producto.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _productoSeleccionado = value;
                      if (value?.precioSinIva != null) {
                        _precioController.text =
                            value!.precioSinIva!.toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cantidadController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _precioController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio unit.'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _ivaController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'IVA %'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionItemController,
                  decoration:
                      const InputDecoration(labelText: 'Descripción adicional'),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _agregarItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar item'),
                  ),
                ),
                const SizedBox(height: 8),
                if (_items.isEmpty)
                  const Text(
                    'Todavía no agregaste items.',
                    style: TextStyle(color: AppColors.textMedium),
                  ),
                ..._items.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(item.producto.nombre),
                        subtitle: Text(
                          '${item.cantidad} x ${item.precioUnitario.toStringAsFixed(2)} '
                          '(IVA ${item.ivaPorcentaje.toStringAsFixed(2)}%)',
                        ),
                        trailing: IconButton(
                          onPressed: () => _eliminarItem(index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _guardarFactura,
                    icon: const Icon(Icons.save_alt),
                    label: Text(_enviando ? 'Guardando...' : 'Guardar factura'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

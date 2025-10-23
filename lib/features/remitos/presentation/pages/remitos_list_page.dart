import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../data/models/remito_model.dart';
import '../providers/remito_provider.dart';

class RemitosListPage extends StatefulWidget {
  const RemitosListPage({super.key});

  @override
  State<RemitosListPage> createState() => _RemitosListPageState();
}

class _RemitosListPageState extends State<RemitosListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemitoProvider>().cargarRemitos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Remitos de entrega'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarSheetNuevoRemito(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo remito'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Consumer<RemitoProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (provider.errorMessage != null) {
              return _ErrorState(message: provider.errorMessage!);
            }

            if (!provider.hayRemitos) {
              return const _EmptyState();
            }

            return RefreshIndicator(
              onRefresh: provider.refrescarRemitos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.remitos.length,
                itemBuilder: (context, index) {
                  final remito = provider.remitos[index];
                  return _RemitoCard(
                    remito: remito,
                    onTap: () => _mostrarDetalleRemito(context, remito),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _mostrarDetalleRemito(
    BuildContext context,
    RemitoResumen remito,
  ) async {
    final provider = context.read<RemitoProvider>();
    final items = await provider.obtenerItems(remito.id);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _RemitoDetalleSheet(
          remito: remito,
          items: items,
          onConfirmarEntrega: remito.estado.toLowerCase() == 'entregado'
              ? null
              : () async {
                  final confirmar = await showDialog<bool>(
                    context: sheetContext,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirmar entrega'),
                        content: Text(
                          '¿Registrar como entregado el remito ${remito.numero}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmar != true) return;

                  Navigator.of(sheetContext).pop();
                  await _confirmarEntregaRemito(context, remito);
                },
        );
      },
    );
  }

  Future<void> _mostrarSheetNuevoRemito(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _NuevoRemitoSheet(),
    );
  }

  Future<void> _confirmarEntregaRemito(
    BuildContext context,
    RemitoResumen remito,
  ) async {
    final provider = context.read<RemitoProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      await provider.confirmarEntrega(remitoId: remito.id);
      if (!mounted) {
        if (navigator.canPop()) {
          navigator.pop();
        }
        return;
      }

      if (navigator.canPop()) {
        navigator.pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Remito ${remito.numero} marcado como entregado.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (!mounted) return;

      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo confirmar la entrega: $mensaje'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _RemitoCard extends StatelessWidget {
  final RemitoResumen remito;
  final VoidCallback onTap;

  const _RemitoCard({
    required this.remito,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fechaReferencia = remito.fechaEntrega ?? remito.fechaEmision;
    final fechaTexto = _formatearFecha(fechaReferencia);
    final estadoColor = _estadoColor(remito.estado);
    final estadoLabel = _estadoEtiqueta(remito.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        title: Text(remito.numero),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(remito.clienteNombre),
            if (remito.obraNombre != null)
              Text(
                remito.obraNombre!,
                style: const TextStyle(color: AppColors.textMedium),
              ),
            const SizedBox(height: 4),
            Text('Items: ${remito.itemsCount} · Cantidad total: ${remito.totalCantidad.toStringAsFixed(remito.totalCantidad.truncateToDouble() == remito.totalCantidad ? 0 : 2)}'),
            if (remito.transporte != null && remito.transporte!.isNotEmpty)
              Text('Transporte: ${remito.transporte!}'),
            if (remito.observaciones != null && remito.observaciones!.isNotEmpty)
              Text('Obs.: ${remito.observaciones!}'),
            if (remito.recibidoPor != null && remito.recibidoPor!.isNotEmpty)
              Text('Recibido por: ${remito.recibidoPor!}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Chip(
              label: Text(
                estadoLabel,
                style: const TextStyle(color: AppColors.textWhite),
              ),
              backgroundColor: estadoColor,
            ),
            const SizedBox(height: 8),
            Text(
              remito.fechaEntrega != null
                  ? 'Entregado: $fechaTexto'
                  : 'Emitido: $fechaTexto',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemitoDetalleSheet extends StatelessWidget {
  final RemitoResumen remito;
  final List<RemitoItemDetalle> items;
  final Future<void> Function()? onConfirmarEntrega;

  const _RemitoDetalleSheet({
    required this.remito,
    required this.items,
    this.onConfirmarEntrega,
  });

  @override
  Widget build(BuildContext context) {
    final fechaEmision = _formatearFecha(remito.fechaEmision);
    final fechaEntrega =
        remito.fechaEntrega != null ? _formatearFecha(remito.fechaEntrega!) : null;
    final estadoColor = _estadoColor(remito.estado);
    final estadoLabel = _estadoEtiqueta(remito.estado);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    estadoLabel,
                    style: const TextStyle(color: AppColors.textWhite),
                  ),
                  backgroundColor: estadoColor,
                ),
                const SizedBox(width: 12),
                Text(
                  fechaEntrega != null
                      ? 'Entregado el $fechaEntrega'
                      : 'Emitido el $fechaEmision',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Remito ${remito.numero}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Cliente: ${remito.clienteNombre}'),
            if (remito.obraNombre != null && remito.obraNombre!.isNotEmpty)
              Text('Obra: ${remito.obraNombre!}'),
            if (remito.transporte != null && remito.transporte!.isNotEmpty)
              Text('Transporte: ${remito.transporte!}'),
            if (remito.recibidoPor != null && remito.recibidoPor!.isNotEmpty)
              Text('Recibido por: ${remito.recibidoPor!}'),
            if (remito.observaciones != null && remito.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Observaciones: ${remito.observaciones!}'),
            ],
            const SizedBox(height: 24),
            const Text(
              'Detalle de items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                final cantidadTexto =
                    item.cantidad.truncateToDouble() == item.cantidad
                        ? item.cantidad.toStringAsFixed(0)
                        : item.cantidad.toStringAsFixed(2);

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item.productoCodigo} · ${item.productoNombre}'),
                  subtitle: item.descripcion != null && item.descripcion!.isNotEmpty
                      ? Text(item.descripcion!)
                      : null,
                  trailing: Text(
                    '$cantidadTexto ${item.unidad ?? ''}'.trim(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            if (onConfirmarEntrega != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onConfirmarEntrega,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar como entregado'),
              ),
            ],
          ],
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
            Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textLight),
            SizedBox(height: 16),
            Text('Todavía no hay remitos registrados'),
            SizedBox(height: 8),
            Text(
              'Crea tu primer remito desde el botón "+"',
              style: TextStyle(color: AppColors.textMedium),
              textAlign: TextAlign.center,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<RemitoProvider>().cargarRemitos(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NuevoRemitoSheet extends StatefulWidget {
  const _NuevoRemitoSheet();

  @override
  State<_NuevoRemitoSheet> createState() => _NuevoRemitoSheetState();
}

class _NuevoRemitoSheetState extends State<_NuevoRemitoSheet> {
  final _observacionesController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _transporteController = TextEditingController();
  final _choferController = TextEditingController();
  final _patenteController = TextEditingController();

  bool _loadingCombos = true;
  List<ClienteModel> _clientes = [];
  List<ObraModel> _obras = [];
  List<ProductoModel> _productos = [];

  ClienteModel? _clienteSeleccionado;
  ObraModel? _obraSeleccionada;
  ProductoModel? _productoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarCombos();
  }

  Future<void> _cargarCombos() async {
    final provider = context.read<RemitoProvider>();
    final clientes = await provider.obtenerClientesActivos();
    final productos = await provider.obtenerProductosActivos();

    setState(() {
      _clientes = clientes;
      _productos = productos;
      _clienteSeleccionado = clientes.isNotEmpty ? clientes.first : null;
      _productoSeleccionado = productos.isNotEmpty ? productos.first : null;
      _loadingCombos = false;
    });

    if (_clienteSeleccionado != null) {
      await _cargarObrasCliente(_clienteSeleccionado!.id!);
    }
  }

  Future<void> _cargarObrasCliente(int clienteId) async {
    final provider = context.read<RemitoProvider>();
    final obras = await provider.obtenerObrasPorCliente(clienteId);
    setState(() {
      _obras = obras;
      _obraSeleccionada = obras.isNotEmpty ? obras.first : null;
    });
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _cantidadController.dispose();
    _transporteController.dispose();
    _choferController.dispose();
    _patenteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: _loadingCombos
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nuevo remito rápido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ClienteModel>(
                    value: _clienteSeleccionado,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    items: _clientes
                        .map(
                          (cliente) => DropdownMenuItem(
                            value: cliente,
                            child: Text(cliente.razonSocial),
                          ),
                        )
                        .toList(),
                    onChanged: (nuevo) async {
                      if (nuevo == null) return;
                      setState(() {
                        _clienteSeleccionado = nuevo;
                      });
                      await _cargarObrasCliente(nuevo.id!);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ObraModel>(
                    value: _obraSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Obra (opcional)',
                    ),
                    items: _obras
                        .map(
                          (obra) => DropdownMenuItem(
                            value: obra,
                            child: Text(obra.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (obra) {
                      setState(() {
                        _obraSeleccionada = obra;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductoModel>(
                    value: _productoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Producto'),
                    items: _productos
                        .map(
                          (producto) => DropdownMenuItem(
                            value: producto,
                            child: Text('${producto.codigo} · ${producto.nombre}'),
                          ),
                        )
                        .toList(),
                    onChanged: (producto) {
                      setState(() {
                        _productoSeleccionado = producto;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cantidadController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _transporteController,
                    decoration: const InputDecoration(labelText: 'Transporte'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _choferController,
                    decoration: const InputDecoration(labelText: 'Chofer'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _patenteController,
                    decoration: const InputDecoration(labelText: 'Patente'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _observacionesController,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Consumer<RemitoProvider>(
                    builder: (context, provider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: provider.isCreating ? null : () => _guardar(provider),
                          icon: provider.isCreating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(provider.isCreating ? 'Creando...' : 'Guardar remito'),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _guardar(RemitoProvider provider) async {
    final cliente = _clienteSeleccionado;
    final producto = _productoSeleccionado;
    if (cliente == null || producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona cliente y producto')),
      );
      return;
    }

    final cantidad = double.tryParse(_cantidadController.text.replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida')),
      );
      return;
    }

    final exito = await provider.crearRemitoRapido(
      clienteId: cliente.id!,
      obraId: _obraSeleccionada?.id,
      observaciones: _observacionesController.text.isEmpty
          ? null
          : _observacionesController.text,
      transporte: _transporteController.text.isEmpty
          ? null
          : _transporteController.text,
      chofer: _choferController.text.isEmpty ? null : _choferController.text,
      patente: _patenteController.text.isEmpty ? null : _patenteController.text,
      items: [
        {
          'productoId': producto.id!,
          'cantidad': cantidad,
          'unidad': producto.unidadBase,
          'descripcion': producto.nombre,
        }
      ],
    );

    if (!mounted) return;

    if (exito) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remito creado correctamente')),
      );
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
    }
  }
}

String _formatearFecha(DateTime fecha) {
  return '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';
}

Color _estadoColor(String estado) {
  switch (estado.toLowerCase()) {
    case 'entregado':
      return AppColors.success;
    case 'emitido':
      return AppColors.warning;
    case 'rechazado':
    case 'anulado':
      return AppColors.error;
    default:
      return AppColors.info;
  }
}

String _estadoEtiqueta(String estado) {
  final normalizado = estado.toLowerCase();
  switch (normalizado) {
    case 'entregado':
      return 'Entregado';
    case 'emitido':
      return 'Emitido';
    case 'rechazado':
      return 'Rechazado';
    case 'anulado':
      return 'Anulado';
    default:
      final limpio = normalizado.replaceAll('_', ' ').trim();
      if (limpio.isEmpty) return '-';
      return limpio
          .split(' ')
          .map(
            (palabra) => palabra.isEmpty
                ? ''
                : '${palabra[0].toUpperCase()}${palabra.substring(1)}',
          )
          .join(' ');
  }
}

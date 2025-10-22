import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/models/movimiento_lote_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/presentation/providers/cliente_provider.dart';
import '../../../stock/data/models/stock_model.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../stock/presentation/providers/producto_provider.dart';
import '../../../stock/presentation/providers/movimiento_stock_provider.dart';
import '../providers/acopio_provider.dart';

/// Pantalla UNIFICADA para registrar movimientos en LOTE
///
/// Soporta dos modos:
/// - Stock S&G (depósito propio)
/// - Acopio (cliente en proveedor)
class MovimientoLotePage extends StatefulWidget {
  const MovimientoLotePage({super.key});

  @override
  State<MovimientoLotePage> createState() => _MovimientoLotePageState();
}

class _MovimientoLotePageState extends State<MovimientoLotePage> {
  // ========================================
  // ESTADO
  // ========================================

  final _formKey = GlobalKey<FormState>();
  final _facturaNumeroController = TextEditingController();
  final _motivoController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _remitoController = TextEditingController();

  // Tipo de destino
  TipoDestinoLote _tipoDestino = TipoDestinoLote.stock;

  // Tipo de movimiento
  bool _esEntrada = true; // true = entrada, false = salida

  // Para Acopios
  ClienteModel? _clienteSeleccionado;
  ProveedorModel? _proveedorSeleccionado;

  // Común
  DateTime? _facturaFecha;
  bool _valorizar = false;

  // Lista de productos agregados
  List<MovimientoLoteItem> _items = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<ClienteProvider>().cargarClientes();
      context.read<AcopioProvider>().cargarProveedores();
    });
  }

  @override
  void dispose() {
    _facturaNumeroController.dispose();
    _motivoController.dispose();
    _referenciaController.dispose();
    _remitoController.dispose();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Movimiento en Lote'),
            Text(
              '${_items.length} productos agregados',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ========================================
          // FORMULARIO PRINCIPAL
          // ========================================
          Expanded(
            child: SingleChildScrollView(
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
                    // TOGGLE: STOCK vs ACOPIO
                    // ========================================
                    _buildSeccionTitulo('Destino del Movimiento'),
                    _buildToggleDestino(),
                    const SizedBox(height: 24),

                    // ========================================
                    // TIPO: ENTRADA vs SALIDA
                    // ========================================
                    _buildSeccionTitulo('Tipo de Movimiento'),
                    _buildToggleTipo(),
                    const SizedBox(height: 24),

                    // ========================================
                    // SELECTORES (solo si es ACOPIO)
                    // ========================================
                    if (_tipoDestino == TipoDestinoLote.acopio) ...[
                      _buildSeccionTitulo('Cliente (Dueño)'),
                      _buildSelectorCliente(),
                      const SizedBox(height: 24),

                      _buildSeccionTitulo('Proveedor/Ubicación'),
                      _buildSelectorProveedor(),
                      const SizedBox(height: 24),
                    ],

                    // ========================================
                    // DATOS COMUNES
                    // ========================================
                    _buildSeccionTitulo('📄 Datos de Documento (Opcional)'),
                    _buildCampoFacturaNumero(),
                    const SizedBox(height: 12),
                    _buildCampoFacturaFecha(),

                    if (!_esEntrada) ...[
                      const SizedBox(height: 12),
                      _buildCampoRemito(),
                    ],

                    const SizedBox(height: 24),

                    // Valorizar
                    _buildCheckboxValorizar(),
                    const SizedBox(height: 24),

                    // Productos agregados
                    _buildSeccionTitulo('📦 Productos (${_items.length})'),
                    _buildListaProductos(),
                  ],
                ),
              ),
            ),
          ),

          // ========================================
          // BOTONES INFERIORES
          // ========================================
          _buildBotonesInferiores(),
        ],
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
              'Registra múltiples productos de una factura/remito en un solo paso',
              style: TextStyle(fontSize: 13, color: AppColors.textDark),
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

  // ========================================
  // TOGGLE DESTINO: STOCK vs ACOPIO
  // ========================================

  Widget _buildToggleDestino() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOpcionDestino(
              tipo: TipoDestinoLote.stock,
              label: 'STOCK S&G',
              icono: Icons.warehouse,
              descripcion: 'Depósito propio',
            ),
          ),
          Expanded(
            child: _buildOpcionDestino(
              tipo: TipoDestinoLote.acopio,
              label: 'ACOPIO',
              icono: Icons.store,
              descripcion: 'Cliente/Proveedor',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpcionDestino({
    required TipoDestinoLote tipo,
    required String label,
    required IconData icono,
    required String descripcion,
  }) {
    final seleccionado = _tipoDestino == tipo;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoDestino = tipo;
          // Limpiar selecciones si cambia
          if (tipo == TipoDestinoLote.stock) {
            _clienteSeleccionado = null;
            _proveedorSeleccionado = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: seleccionado
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: seleccionado
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: seleccionado ? AppColors.primary : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: seleccionado ? AppColors.primary : Colors.grey[700],
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              descripcion,
              style: TextStyle(
                color: seleccionado ? AppColors.primary.withOpacity(0.7) : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // TOGGLE TIPO: ENTRADA vs SALIDA
  // ========================================

  Widget _buildToggleTipo() {
    return Row(
      children: [
        Expanded(
          child: _buildChipTipo(
            esEntrada: true,
            label: 'ENTRADA',
            icono: Icons.arrow_downward,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildChipTipo(
            esEntrada: false,
            label: 'SALIDA',
            icono: Icons.arrow_upward,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildChipTipo({
    required bool esEntrada,
    required String label,
    required IconData icono,
    required Color color,
  }) {
    final seleccionado = _esEntrada == esEntrada;

    return InkWell(
      onTap: () {
        setState(() {
          _esEntrada = esEntrada;
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
            Icon(icono, color: seleccionado ? color : Colors.grey, size: 32),
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

  Widget _buildSelectorCliente() {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
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

  Widget _buildCampoFacturaNumero() {
    return TextFormField(
      controller: _facturaNumeroController,
      decoration: InputDecoration(
        labelText: _esEntrada ? 'Número de Factura' : 'Número de Remito',
        hintText: 'Ej: 0001-00012345',
        prefixIcon: Icon(_esEntrada ? Icons.receipt_long : Icons.description),
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
          labelText: _esEntrada ? 'Fecha de Factura' : 'Fecha de Remito',
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

  Widget _buildCampoRemito() {
    return TextFormField(
      controller: _remitoController,
      decoration: InputDecoration(
        labelText: 'Número de Remito Adicional',
        hintText: 'Ej: REM-001',
        prefixIcon: const Icon(Icons.local_shipping),
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

  Widget _buildListaProductos() {
    if (_items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay productos agregados',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Tocá el botón "+" para agregar productos',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    double totalGeneral = 0;
    if (_valorizar) {
      totalGeneral = _items.fold(0, (sum, item) => sum + item.montoTotal);
    }

    return Column(
        children: [
        ..._items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return _buildItemCard(item, index);
    }),

    // Total
    if (_valorizar && totalGeneral > 0)
    Card(
    color: AppColors.primary.withOpacity(0.1),
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    const Text(
    'TOTAL GENERAL',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    ),
    ),
    Text(
    ArgFormats.moneda(totalGeneral),
    style: const TextStyle(fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.primary,
    ),
    ),
    ],
    ),
    ),
    ),
        ],
    );
  }

  Widget _buildItemCard(MovimientoLoteItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            item.producto.categoriaCodigo,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(item.producto.productoNombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.cantidad} ${item.producto.unidadBase}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_valorizar && item.producto.precioSinIva != null)
              Text(
                ArgFormats.moneda(item.montoTotal),
                style: const TextStyle(color: AppColors.success),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editarItem(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
              onPressed: () {
                setState(() {
                  _items.removeAt(index);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesInferiores() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón agregar producto
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _agregarProducto,
              icon: const Icon(Icons.add),
              label: const Text('AGREGAR PRODUCTO'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botón registrar
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _items.isEmpty ? null : _registrarLote,
              icon: const Icon(Icons.check_circle),
              label: const Text('REGISTRAR TODO'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // LÓGICA
  // ========================================

  void _agregarProducto() {
    showDialog(
      context: context,
      builder: (context) => _DialogoAgregarProducto(
        onAgregar: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  void _editarItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _DialogoEditarCantidad(
        item: _items[index],
        onGuardar: (nuevaCantidad) {
          setState(() {
            _items[index] = _items[index].copyWith(cantidad: nuevaCantidad);
          });
        },
      ),
    );
  }

  Future<void> _registrarLote() async {
    // Validar según el tipo de destino
    if (_tipoDestino == TipoDestinoLote.acopio) {
      if (_clienteSeleccionado == null) {
        _mostrarError('Debes seleccionar un cliente');
        return;
      }
      if (_proveedorSeleccionado == null) {
        _mostrarError('Debes seleccionar un proveedor');
        return;
      }
    }

    if (_items.isEmpty) {
      _mostrarError('Debes agregar al menos un producto');
      return;
    }

    // Preparar items
    final items = _items.map((item) {
      double? montoValorizado;
      if (_valorizar && item.producto.precioSinIva != null) {
        montoValorizado = item.cantidad * item.producto.precioSinIva!;
      }

      return {
        'productoId': item.producto.productoId,
        'cantidad': item.cantidad,
        'montoValorizado': montoValorizado,
      };
    }).toList();

    final facturaNumero = _facturaNumeroController.text.trim().isEmpty
        ? null
        : _facturaNumeroController.text.trim();

    final remitoNumero = _remitoController.text.trim().isEmpty
        ? null
        : _remitoController.text.trim();

    bool exito = false;

    // Registrar según el tipo de destino
    if (_tipoDestino == TipoDestinoLote.stock) {
      // ========================================
      // REGISTRO EN STOCK
      // ========================================
      final tipo = _esEntrada
          ? TipoMovimiento.entrada
          : TipoMovimiento.salida;

      exito = await context.read<MovimientoStockProvider>().registrarMovimientoEnLote(
        items: items,
        tipo: tipo,
        facturaNumero: facturaNumero,
        facturaFecha: _facturaFecha,
        motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
        referencia: _facturaNumeroController.text.isEmpty ? null : _facturaNumeroController.text,
        remitoNumero: remitoNumero,
        valorizado: _valorizar,
      );
    } else {
      // ========================================
      // REGISTRO EN ACOPIO
      // ========================================
      final tipo = _esEntrada
          ? TipoMovimientoAcopio.entrada
          : TipoMovimientoAcopio.salida;

      exito = await context.read<AcopioProvider>().registrarMovimientoEnLote(
        items: items,
        clienteId: _clienteSeleccionado!.id!,
        proveedorId: _proveedorSeleccionado!.id!,
        tipo: tipo,
        facturaNumero: facturaNumero,
        facturaFecha: _facturaFecha,
        motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
        referencia: _facturaNumeroController.text.isEmpty ? null : _facturaNumeroController.text,
        valorizado: _valorizar,
      );
    }

    if (exito && mounted) {
      final destino = _tipoDestino == TipoDestinoLote.stock
          ? 'Stock S&G'
          : '${_clienteSeleccionado!.razonSocial} en ${_proveedorSeleccionado!.nombre}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Movimiento registrado exitosamente\n'
                '📦 ${_items.length} productos\n'
                '📍 Destino: $destino'
                '${facturaNumero != null ? "\n📄 Doc: $facturaNumero" : ""}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true);
    } else if (mounted) {
      _mostrarError('Error al registrar el movimiento en lote');
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

// ========================================
// DIÁLOGO AGREGAR PRODUCTO
// ========================================

class _DialogoAgregarProducto extends StatefulWidget {
  final Function(MovimientoLoteItem) onAgregar;

  const _DialogoAgregarProducto({required this.onAgregar});

  @override
  State<_DialogoAgregarProducto> createState() => _DialogoAgregarProductoState();
}

class _DialogoAgregarProductoState extends State<_DialogoAgregarProducto> {
  ProductoConStock? _productoSeleccionado;
  final _cantidadController = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // Buscador
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _busqueda = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Lista de productos
            Expanded(
              child: Consumer<ProductoProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final productosFiltrados = _busqueda.isEmpty
                      ? provider.productos
                      : provider.productos.where((p) {
                    final texto = _busqueda.toLowerCase();
                    return p.productoNombre.toLowerCase().contains(texto) ||
                        p.productoCodigo.toLowerCase().contains(texto);
                  }).toList();

                  return ListView.builder(
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
                        },
                        selected: _productoSeleccionado == producto,
                        selectedTileColor: AppColors.primary.withOpacity(0.1),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Campo cantidad
            if (_productoSeleccionado != null)
              TextFormField(
                controller: _cantidadController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej: 100',
                  suffixText: _productoSeleccionado!.unidadBase,
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
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
          onPressed: _productoSeleccionado != null && _cantidadController.text.isNotEmpty
              ? () {
            final cantidad = double.tryParse(_cantidadController.text);
            if (cantidad != null && cantidad > 0) {
              widget.onAgregar(
                MovimientoLoteItem(
                  producto: _productoSeleccionado!,
                  cantidad: cantidad,
                ),
              );
              Navigator.pop(context);
            }
          }
              : null,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// ========================================
// DIÁLOGO EDITAR CANTIDAD
// ========================================

class _DialogoEditarCantidad extends StatefulWidget {
  final MovimientoLoteItem item;
  final Function(double) onGuardar;

  const _DialogoEditarCantidad({
    required this.item,
    required this.onGuardar,
  });

  @override
  State<_DialogoEditarCantidad> createState() => _DialogoEditarCantidadState();
}

class _DialogoEditarCantidadState extends State<_DialogoEditarCantidad> {
  late TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _cantidadController = TextEditingController(
      text: widget.item.cantidad.toString(),
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Cantidad'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.item.producto.productoNombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cantidadController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Nueva Cantidad',
              suffixText: widget.item.producto.unidadBase,
              prefixIcon: const Icon(Icons.format_list_numbered),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final cantidad = double.tryParse(_cantidadController.text);
            if (cantidad != null && cantidad > 0) {
              widget.onGuardar(cantidad);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
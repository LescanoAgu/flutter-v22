import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/models/stock_model.dart';
import '../providers/producto_provider.dart';
import '../providers/movimiento_stock_provider.dart';

/// Pantalla para REGISTRAR movimientos de stock
///
/// Permite:
/// - Seleccionar un producto
/// - Elegir tipo de movimiento (entrada/salida/ajuste)
/// - Ingresar cantidad
/// - Agregar motivo y referencia
class MovimientoRegistroPage extends StatefulWidget {
  /// Si se pasa un producto, viene pre-seleccionado
  final ProductoConStock? productoInicial;

  const MovimientoRegistroPage({
    super.key,
    this.productoInicial,
  });

  @override
  State<MovimientoRegistroPage> createState() => _MovimientoRegistroPageState();
}

class _MovimientoRegistroPageState extends State<MovimientoRegistroPage> {
  // ========================================
  // CONTROLADORES Y ESTADO
  // ========================================

  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _referenciaController = TextEditingController();

  ProductoConStock? _productoSeleccionado;
  TipoMovimiento _tipoSeleccionado = TipoMovimiento.entrada;

  @override
  void initState() {
    super.initState();

    // Si viene un producto inicial, pre-seleccionarlo
    _productoSeleccionado = widget.productoInicial;

    // Cargar productos si no hay ninguno seleccionado
    if (_productoSeleccionado == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductoProvider>().cargarProductos();
      });
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  // ========================================
  // BUILD
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================
      // APP BAR
      // ========================================
      appBar: AppBar(
        title: const Text('Registrar Movimiento'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      // ========================================
      // BODY
      // ========================================
      body: Consumer<MovimientoStockProvider>(
        builder: (context, movProvider, child) {
          // Si está registrando, mostrar loading
          if (movProvider.isRegistering) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Registrando movimiento...'),
                ],
              ),
            );
          }

          // Formulario normal
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================
                  // SELECCIÓN DE PRODUCTO
                  // ========================================
                  _buildSeccionTitulo('Producto'),
                  _buildSelectorProducto(),

                  const SizedBox(height: 24),

                  // ========================================
                  // TIPO DE MOVIMIENTO
                  // ========================================
                  _buildSeccionTitulo('Tipo de Movimiento'),
                  _buildSelectorTipo(),

                  const SizedBox(height: 24),

                  // ========================================
                  // CANTIDAD
                  // ========================================
                  _buildSeccionTitulo('Cantidad'),
                  _buildCampoCantidad(),

                  const SizedBox(height: 24),

                  // ========================================
                  // MOTIVO (OPCIONAL)
                  // ========================================
                  _buildSeccionTitulo('Motivo (Opcional)'),
                  _buildCampoMotivo(),

                  const SizedBox(height: 24),

                  // ========================================
                  // REFERENCIA (OPCIONAL)
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
          );
        },
      ),
    );
  }

  // ========================================
  // WIDGETS DE SECCIONES
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
  // SELECTOR DE PRODUCTO
  // ========================================

  Widget _buildSelectorProducto() {
    return Consumer<ProductoProvider>(
      builder: (context, prodProvider, child) {
        // Si está cargando productos
        if (prodProvider.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Si ya hay un producto seleccionado (caso inicial)
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
              subtitle: Text(
                '${_productoSeleccionado!.productoCodigo} • Stock: ${_productoSeleccionado!.cantidadFormateada}',
              ),
              trailing: widget.productoInicial == null
                  ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _productoSeleccionado = null;
                  });
                },
              )
                  : null,
            ),
          );
        }

        // Botón para seleccionar producto
        return Card(
          child: InkWell(
            onTap: () => _mostrarDialogoSeleccionProducto(prodProvider.productos),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, color: AppColors.primary),
                  const SizedBox(width: 16),
                  const Text(
                    'Seleccionar producto',
                    style: TextStyle(fontSize: 16),
                  ),
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

  // ========================================
  // DIÁLOGO PARA SELECCIONAR PRODUCTO
  // ========================================

  void _mostrarDialogoSeleccionProducto(List<ProductoConStock> productos) {
    showDialog(
      context: context,
      builder: (context) {
        String busqueda = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filtrar productos según búsqueda
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
                        setDialogState(() {
                          busqueda = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lista de productos
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
                            subtitle: Text(
                              '${producto.productoCodigo} • Stock: ${producto.cantidadFormateada}',
                            ),
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
  // SELECTOR DE TIPO
  // ========================================

  Widget _buildSelectorTipo() {
    return Row(
      children: [
        Expanded(
          child: _buildChipTipo(
            tipo: TipoMovimiento.entrada,
            icono: Icons.arrow_downward,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildChipTipo(
            tipo: TipoMovimiento.salida,
            icono: Icons.arrow_upward,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildChipTipo(
            tipo: TipoMovimiento.ajuste,
            icono: Icons.settings,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildChipTipo({
    required TipoMovimiento tipo,
    required IconData icono,
    required Color color,
  }) {
    final seleccionado = _tipoSeleccionado == tipo;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoSeleccionado = tipo;
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
              tipo.name.toUpperCase(),
              style: TextStyle(
                color: seleccionado ? color : Colors.grey[600],
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
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

        // Validar stock suficiente para salidas
        if (_tipoSeleccionado == TipoMovimiento.salida && _productoSeleccionado != null) {
          if (cantidad > _productoSeleccionado!.cantidadDisponible) {
            return 'Stock insuficiente (disponible: ${_productoSeleccionado!.cantidadFormateada})';
          }
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
        hintText: 'Ej: Compra a proveedor, Devolución cliente, etc.',
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
        hintText: 'Ej: OC-001, REM-1234, etc.',
        prefixIcon: const Icon(Icons.tag),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ========================================
  // BOTÓN REGISTRAR
  // ========================================

  Widget _buildBotonRegistrar() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _registrarMovimiento,
        icon: const Icon(Icons.check_circle),
        label: const Text(
          'REGISTRAR MOVIMIENTO',
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

  Future<void> _registrarMovimiento() async {
    // Validar que haya un producto seleccionado
    if (_productoSeleccionado == null) {
      _mostrarError('Debes seleccionar un producto');
      return;
    }

    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Obtener la cantidad
    final cantidad = double.parse(_cantidadController.text);

    // Registrar el movimiento
    final exito = await context.read<MovimientoStockProvider>().registrarMovimiento(
      productoId: _productoSeleccionado!.productoId,
      tipo: _tipoSeleccionado,
      cantidad: cantidad,
      motivo: _motivoController.text.isEmpty ? null : _motivoController.text,
      referencia: _referenciaController.text.isEmpty ? null : _referenciaController.text,
      // TODO: Agregar usuarioId cuando tengamos login
      usuarioId: null,
    );

    if (exito && mounted) {
      // Recargar productos para actualizar el stock
      await context.read<ProductoProvider>().cargarProductos();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Movimiento registrado: ${_tipoSeleccionado.name.toUpperCase()} de $cantidad ${_productoSeleccionado!.unidadBase}',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );

      // Volver atrás
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/stock_model.dart';
import '../../data/repositories/stock_repository.dart';
import '../providers/producto_provider.dart';
import 'movimiento_historial_page.dart';
import 'producto_form_page.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../providers/movimiento_stock_provider.dart';
/// Pantalla de Detalle del Producto
///
/// Muestra toda la información del producto y permite:
/// - Ver detalles completos
/// - Ajustar stock manualmente
/// - Editar producto (próximamente)
/// - Ver historial de movimientos (próximamente)
class ProductoDetallePage extends StatefulWidget {
  final ProductoConStock producto;

  const ProductoDetallePage({
    super.key,
    required this.producto,
  });

  @override
  State<ProductoDetallePage> createState() => _ProductoDetallePageState();
}

class _ProductoDetallePageState extends State<ProductoDetallePage> {
  final StockRepository _stockRepo = StockRepository();
  final TextEditingController _cantidadController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cantidadController.dispose();
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
        title: const Text('Detalle del Producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navegar a editar producto
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar próximamente')),
              );
            },
          ),
        ],
      ),

      // ========================================
      // BODY
      // ========================================
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // CARD PRINCIPAL
              // ========================================
              _buildMainCard(),

              const SizedBox(height: 16),

              // ========================================
              // CARD DE STOCK
              // ========================================
              _buildStockCard(),

              const SizedBox(height: 16),

              // ========================================
              // CARD DE INFORMACIÓN
              // ========================================
              _buildInfoCard(),

              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // CARD PRINCIPAL (Código + Nombre + Categoría)
  // ========================================
  Widget _buildMainCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Código y Badge de Stock
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.producto.productoCodigo,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Spacer(),
                _buildStockBadge(),
              ],
            ),

            const SizedBox(height: 16),

            // Nombre del producto
            Text(
              widget.producto.productoNombre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 12),

            // Categoría
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.category,
                    size: 18,
                    color: AppColors.textMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '[${widget.producto.categoriaCodigo}] ${widget.producto.categoriaNombre}',
                    style: const TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // CARD DE STOCK
  // ========================================
  // ========================================
// CARD DE STOCK
// ========================================
  Widget _buildStockCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.inventory_2,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Stock Disponible',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Cantidad grande
            Center(
              child: Column(
                children: [
                  Text(
                    widget.producto.cantidadFormateada,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getStockColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.producto.unidadCompleta,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botones de acciones
            Row(
              children: [
                // Botón Ver Historial
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovimientoHistorialPage(
                            productoId: widget.producto.productoId,
                            productoNombre: widget.producto.productoNombre,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('VER HISTORIAL'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      side: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Botón Ajustar Stock
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _mostrarDialogoAjustarStock,
                    icon: const Icon(Icons.edit),
                    label: const Text('AJUSTAR'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ========================================
  // CARD DE INFORMACIÓN
  // ========================================
  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Producto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 20),

            // Precio
            if (widget.producto.precioSinIva != null)
              _buildInfoRow(
                icon: Icons.attach_money,
                label: 'Precio sin IVA',
                value: widget.producto.precioFormateado,
                valueColor: AppColors.success,
              ),

            const SizedBox(height: 16),

            // Unidad base
            _buildInfoRow(
              icon: Icons.straighten,
              label: 'Unidad de medida',
              value: widget.producto.unidadBase,
            ),

            if (widget.producto.equivalencia != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.info_outline,
                label: 'Equivalencia',
                value: widget.producto.equivalencia!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================
  // FILA DE INFORMACIÓN
  // ========================================
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMedium, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ========================================
  // BADGE DE STOCK
  // ========================================
  Widget _buildStockBadge() {
    if (widget.producto.sinStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning, size: 16, color: AppColors.error),
            SizedBox(width: 6),
            Text(
              'SIN STOCK',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.producto.stockBajo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
            SizedBox(width: 6),
            Text(
              'STOCK BAJO',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle, size: 16, color: AppColors.success),
          SizedBox(width: 6),
          Text(
            'STOCK OK',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

// ========================================
// DIÁLOGO AJUSTAR STOCK
// ========================================
  void _mostrarDialogoAjustarStock() {
    _cantidadController.text = widget.producto.cantidadDisponible.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajustar Stock Manualmente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AVISO
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este ajuste se registrará en el historial de movimientos (Kardex).',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stock actual
            Text(
              'Stock actual: ${widget.producto.cantidadFormateada} ${widget.producto.unidadBase}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Campo de entrada
            TextField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Nueva cantidad total',
                hintText: '0.00',
                suffixText: widget.producto.unidadBase,
                prefixIcon: const Icon(Icons.edit),
                helperText: 'Ingresa el nuevo total de stock',
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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _ajustarStock();
            },
            icon: const Icon(Icons.check),
            label: const Text('Ajustar Stock'),
          ),
        ],
      ),
    );
  }// =====================================
// AJUSTAR STOCK
// ========================================
  Future<void> _ajustarStock() async {
    final String textoNuevaCantidad = _cantidadController.text.trim();

    if (textoNuevaCantidad.isEmpty) {
      _mostrarError('Ingresá una cantidad válida');
      return;
    }

    final double? nuevaCantidad = double.tryParse(textoNuevaCantidad);

    if (nuevaCantidad == null || nuevaCantidad < 0) {
      _mostrarError('La cantidad debe ser un número positivo');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cantidadActual = widget.producto.cantidadDisponible;
      final diferencia = nuevaCantidad - cantidadActual;

      // Registrar el ajuste como movimiento en el Kardex
      final movimientoProvider = context.read<MovimientoStockProvider>();

      await movimientoProvider.registrarMovimiento(
        productoId: widget.producto.productoId,
        tipo: TipoMovimiento.ajuste,
        cantidad: diferencia.abs(), // Siempre positivo en el modelo
        motivo: diferencia > 0
            ? 'Ajuste manual desde catálogo (+${diferencia.abs()})'
            : 'Ajuste manual desde catálogo (-${diferencia.abs()})',
        referencia: 'AJUSTE-CATALOGO',
        usuarioId: null, // TODO: Agregar cuando tengamos login
      );

      // Recargar productos en el provider
      if (mounted) {
        await context.read<ProductoProvider>().cargarProductos();

        // Actualizar el producto actual
        final productoActualizado = context
            .read<ProductoProvider>()
            .productos
            .firstWhere((p) => p.productoId == widget.producto.productoId);

        // Volver a la lista con el producto actualizado
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              diferencia > 0
                  ? 'Stock ajustado: +${diferencia.abs()} ${productoActualizado.unidadBase} (${productoActualizado.cantidadFormateada} total)'
                  : 'Stock ajustado: -${diferencia.abs()} ${productoActualizado.unidadBase} (${productoActualizado.cantidadFormateada} total)',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al ajustar stock: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  Color _getStockColor() {
    if (widget.producto.sinStock) return AppColors.error;
    if (widget.producto.stockBajo) return AppColors.warning;
    return AppColors.success;
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../providers/acopio_provider.dart';
import 'acopio_movimiento_page.dart';

/// Pantalla de Detalle Completo de un Acopio
///
/// Muestra:
/// - Información general del acopio
/// - Historial de movimientos
/// - Estadísticas (totales entrada/salida)
/// - Acciones rápidas
class AcopioDetallePage extends StatefulWidget {
  final AcopioDetalle acopio;

  const AcopioDetallePage({
    super.key,
    required this.acopio,
  });

  @override
  State<AcopioDetallePage> createState() => _AcopioDetallePageState();
}

class _AcopioDetallePageState extends State<AcopioDetallePage>
    with SingleTickerProviderStateMixin {

  // TabController maneja las pestañas
  late TabController _tabController;

  // Lista de movimientos del acopio
  List<MovimientoAcopioModel> _movimientos = [];

  // Estado de carga
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Inicializar el TabController con 2 tabs
    _tabController = TabController(length: 2, vsync: this);

    // Cargar los movimientos
    _cargarMovimientos();
  }

  @override
  void dispose() {
    // IMPORTANTE: Liberar recursos cuando se cierra la pantalla
    _tabController.dispose();
    super.dispose();
  }

  /// Carga los movimientos del acopio desde el repositorio
  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);

    final provider = Provider.of<AcopioProvider>(context, listen: false);

    // Obtenemos el historial usando los datos del acopio
    final movimientos = await provider.obtenerHistorialAcopio(
      productoId: widget.acopio.acopio.productoId,
      clienteId: widget.acopio.acopio.clienteId,
      proveedorId: widget.acopio.acopio.proveedorId,
    );

    setState(() {
      _movimientos = movimientos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // AppBar con degradado
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.acopio.productoNombre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.acopio.clienteRazonSocial,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          // Botón de refrescar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMovimientos,
            tooltip: 'Actualizar',
          ),
        ],

        // TabBar en el AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textWhite,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'Información',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Movimientos',
            ),
          ],
        ),
      ),

      // Cuerpo con TabBarView
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInformacionTab(),
          _buildMovimientosTab(),
        ],
      ),

      // Botón flotante para registrar movimiento
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registrarMovimiento(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar Movimiento'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ========================================
  // TAB DE INFORMACIÓN
  // ========================================

  /// Tab de Información General
  Widget _buildInformacionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de estadísticas
          _buildEstadisticasCard(),

          const SizedBox(height: 16),

          // Información del producto
          _buildInfoCard(
            title: 'Producto',
            items: [
              _buildInfoRow('Código', widget.acopio.productoCodigo),
              _buildInfoRow('Nombre', widget.acopio.productoNombre),
              _buildInfoRow('Categoría', widget.acopio.categoriaNombre),
              _buildInfoRow('Unidad', widget.acopio.unidadBase),
            ],
          ),

          const SizedBox(height: 16),

          // Información del cliente
          _buildInfoCard(
            title: 'Cliente',
            items: [
              _buildInfoRow('Código', widget.acopio.clienteCodigo),
              _buildInfoRow('Razón Social', widget.acopio.clienteRazonSocial),
            ],
          ),

          const SizedBox(height: 16),

          // Información del proveedor/ubicación
          _buildInfoCard(
            title: 'Ubicación',
            items: [
              _buildInfoRow('Proveedor', widget.acopio.proveedorNombre),
              _buildInfoRow('Código', widget.acopio.proveedorCodigo),
              _buildInfoRow('Tipo', _formatearTipoProveedor(widget.acopio.proveedorTipo)),
            ],
          ),
        ],
      ),
    );
  }

  /// Card con estadísticas del acopio
  Widget _buildEstadisticasCard() {
    // Calcular totales
    double totalEntradas = 0;
    double totalSalidas = 0;

    for (var mov in _movimientos) {
      if (mov.tipo == TipoMovimientoAcopio.entrada) {
        totalEntradas += mov.cantidad;
      } else if (mov.tipo == TipoMovimientoAcopio.salida) {
        totalSalidas += mov.cantidad;
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Título
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Estadísticas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Fila con 3 estadísticas
            Row(
              children: [
                // Stock Disponible
                Expanded(
                  child: _buildEstadistica(
                    label: 'Disponible',
                    valor: widget.acopio.acopio.cantidadDisponible,
                    unidad: widget.acopio.unidadBase,
                    color: AppColors.primary,
                    icon: Icons.inventory_2,
                  ),
                ),

                // Total Entradas
                Expanded(
                  child: _buildEstadistica(
                    label: 'Entradas',
                    valor: totalEntradas,
                    unidad: widget.acopio.unidadBase,
                    color: AppColors.success,
                    icon: Icons.arrow_downward,
                  ),
                ),

                // Total Salidas
                Expanded(
                  child: _buildEstadistica(
                    label: 'Salidas',
                    valor: totalSalidas,
                    unidad: widget.acopio.unidadBase,
                    color: AppColors.error,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget individual de estadística
  Widget _buildEstadistica({
    required String label,
    required double valor,
    required String unidad,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          ArgFormats.decimal(valor),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unidad,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  // ========================================
  // WIDGETS HELPER
  // ========================================

  /// Card genérica de información
  Widget _buildInfoCard({
    required String title,
    required List<Widget> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  /// Fila de información (label: valor)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formatea el tipo de proveedor para mostrar
  String _formatearTipoProveedor(String tipo) {
    switch (tipo) {
      case 'deposito_syg':
        return 'Depósito S&G';
      case 'proveedor_externo':
        return 'Proveedor Externo';
      default:
        return tipo;
    }
  }

  // ========================================
  // TAB DE MOVIMIENTOS
  // ========================================

  /// Tab de Movimientos (historial)
  Widget _buildMovimientosTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_movimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin movimientos registrados',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registrá el primer movimiento con el botón + ',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _movimientos.length,
      itemBuilder: (context, index) {
        return _buildMovimientoItem(_movimientos[index]);
      },
    );
  }

  /// Card de movimiento individual
  Widget _buildMovimientoItem(MovimientoAcopioModel movimiento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getColorMovimiento(movimiento.tipo),
          child: Icon(
            _getIconoMovimiento(movimiento.tipo),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Text(
              _formatearTipoMovimiento(movimiento.tipo),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Text(
              ArgFormats.decimal(movimiento.cantidad),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getColorMovimiento(movimiento.tipo),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.acopio.unidadBase,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              ArgFormats.fechaHora(movimiento.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
            if (movimiento.motivo != null && movimiento.motivo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  movimiento.motivo!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            if (movimiento.tieneFactura)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.receipt, size: 12, color: AppColors.info),
                    const SizedBox(width: 4),
                    Text(
                      'Factura: ${movimiento.facturaNumero}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.info,
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

  /// Retorna el color según tipo de movimiento
  Color _getColorMovimiento(TipoMovimientoAcopio tipo) {
    switch (tipo) {
      case TipoMovimientoAcopio.entrada:
        return AppColors.success;
      case TipoMovimientoAcopio.salida:
        return AppColors.error;
      case TipoMovimientoAcopio.traspaso:
        return AppColors.info;
      case TipoMovimientoAcopio.reserva:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  /// Retorna el icono según tipo de movimiento
  IconData _getIconoMovimiento(TipoMovimientoAcopio tipo) {
    switch (tipo) {
      case TipoMovimientoAcopio.entrada:
        return Icons.arrow_downward;
      case TipoMovimientoAcopio.salida:
        return Icons.arrow_upward;
      case TipoMovimientoAcopio.traspaso:
        return Icons.swap_horiz;
      case TipoMovimientoAcopio.reserva:
        return Icons.bookmark;
      default:
        return Icons.edit;
    }
  }

  /// Formatea el tipo de movimiento para mostrar
  String _formatearTipoMovimiento(TipoMovimientoAcopio tipo) {
    switch (tipo) {
      case TipoMovimientoAcopio.entrada:
        return 'Entrada';
      case TipoMovimientoAcopio.salida:
        return 'Salida';
      case TipoMovimientoAcopio.traspaso:
        return 'Traspaso';
      case TipoMovimientoAcopio.reserva:
        return 'Reserva';
      case TipoMovimientoAcopio.liberacion:
        return 'Liberación';
      case TipoMovimientoAcopio.cambio_dueno:
        return 'Cambio de Dueño';
      case TipoMovimientoAcopio.devolucion:
        return 'Devolución';
      default:
        return tipo.name;
    }
  }

  // ========================================
  // ACCIONES
  // ========================================

  /// Navega a la pantalla de registro de movimiento
  void _registrarMovimiento(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AcopioMovimientoPage(
          acopioInicial: widget.acopio,
        ),
      ),
    ).then((_) {
      // Recargar movimientos al volver
      _cargarMovimientos();
    });
  }
}
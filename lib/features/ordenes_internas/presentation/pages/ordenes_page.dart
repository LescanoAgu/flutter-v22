import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/orden_interna_model.dart';
import '../providers/orden_interna_provider.dart';
import 'orden_form_page.dart';
import 'orden_detalle_page.dart';

/// Pantalla de Lista de Órdenes Internas
///
/// Muestra todas las órdenes con:
/// - Filtros por estado
/// - Búsqueda
/// - Navegación a detalle
class OrdenesPage extends StatefulWidget {
  const OrdenesPage({super.key});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
  String? _estadoSeleccionado;

  @override
  void initState() {
    super.initState();
    // Cargar órdenes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdenInternaProvider>().cargarOrdenes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('📋 Órdenes Internas'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          // Botón de filtro
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),

      // Botón flotante para crear nueva orden
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _irACrearOrden(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Orden'),
        backgroundColor: AppColors.primary,
      ),

      body: Consumer<OrdenInternaProvider>(
        builder: (context, provider, child) {
          // Estado de carga
          if (provider.isLoading && !provider.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Estado de error
          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'Error desconocido',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refrescar(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Estado vacío
          if (!provider.hasData) {
            return _buildEmptyState();
          }

          // Lista de órdenes
          return Column(
            children: [
              // Estadísticas
              _buildEstadisticas(provider),

              // Chips de filtro por estado
              _buildFiltrosEstado(provider),

              // Lista
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.refrescar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.ordenes.length,
                    itemBuilder: (context, index) {
                      final orden = provider.ordenes[index];
                      return _buildOrdenCard(orden);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // WIDGETS
  // ========================================

  Widget _buildEstadisticas(OrdenInternaProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Solicitadas',
            provider.ordenesSolicitadas.toString(),
            AppColors.warning,
            Icons.pending_actions,
          ),
          _buildStatItem(
            'En Preparación',
            provider.ordenesEnPreparacion.toString(),
            AppColors.info,
            Icons.hourglass_empty,
          ),
          _buildStatItem(
            'Despachadas',
            provider.ordenesDespachadas.toString(),
            AppColors.success,
            Icons.local_shipping,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String valor, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFiltrosEstado(OrdenInternaProvider provider) {
    final estados = [
      {'valor': null, 'label': 'Todas'},
      {'valor': 'solicitado', 'label': 'Solicitadas'},
      {'valor': 'aprobado', 'label': 'Aprobadas'},
      {'valor': 'en_preparacion', 'label': 'En Preparación'},
      {'valor': 'listo_envio', 'label': 'Listas'},
      {'valor': 'despachado', 'label': 'Despachadas'},
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: estados.length,
        itemBuilder: (context, index) {
          final estado = estados[index];
          final isSelected = _estadoSeleccionado == estado['valor'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(estado['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _estadoSeleccionado = selected ? estado['valor'] as String? : null;
                });
                provider.filtrarPorEstado(_estadoSeleccionado);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdenCard(OrdenInternaDetalle ordenDetalle) {
    final orden = ordenDetalle.orden;
    final estadoColor = _getEstadoColor(orden.estado);
    final estadoIcon = _getEstadoIcon(orden.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _irADetalle(ordenDetalle),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
// Header: Número y Estado
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
// Número de orden
          Row(
          children: [
          Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            orden.numero,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(estadoIcon, size: 18, color: estadoColor),
        ],
      ),
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: estadoColor, width: 1),
                ),
                child: Text(
                  _getEstadoLabel(orden.estado),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: estadoColor,
                  ),
                ),
              ),
            ],
            ),

              const SizedBox(height: 12),

              // Cliente
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: AppColors.textMedium),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ordenDetalle.clienteRazonSocial,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),

              // Obra (si existe)
              if (ordenDetalle.obraNombre != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.textMedium),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ordenDetalle.obraNombre!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Footer: Fecha, Productos, Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fecha
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        ArgFormats.fecha(orden.fechaPedido),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),

                  // Cantidad de productos
                  Row(
                    children: [
                      Icon(Icons.inventory_2, size: 14, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        '${ordenDetalle.cantidadProductos} productos',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),

                  // Total
                  Text(
                    ArgFormats.moneda(orden.total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text(
            'No hay órdenes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Creá tu primera orden con el botón +',
            style: TextStyle(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
// ========================================
// HELPERS
// ========================================
  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'solicitado':
        return AppColors.warning;
      case 'en_revision':
        return AppColors.info;
      case 'aprobado':
        return AppColors.success;
      case 'rechazado':
        return AppColors.error;
      case 'en_preparacion':
        return Colors.blue;
      case 'listo_envio':
        return Colors.purple;
      case 'despachado':
        return AppColors.success;
      case 'cancelado':
        return Colors.grey;
      default:
        return AppColors.textMedium;
    }
  }
  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'solicitado':
        return Icons.pending_actions;
      case 'en_revision':
        return Icons.search;
      case 'aprobado':
        return Icons.check_circle;
      case 'rechazado':
        return Icons.cancel;
      case 'en_preparacion':
        return Icons.hourglass_empty;
      case 'listo_envio':
        return Icons.done_all;
      case 'despachado':
        return Icons.local_shipping;
      case 'cancelado':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }
  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'solicitado':
        return 'SOLICITADO';
      case 'en_revision':
        return 'EN REVISIÓN';
      case 'aprobado':
        return 'APROBADO';
      case 'rechazado':
        return 'RECHAZADO';
      case 'en_preparacion':
        return 'EN PREPARACIÓN';
      case 'listo_envio':
        return 'LISTO ENVÍO';
      case 'despachado':
        return 'DESPACHADO';
      case 'cancelado':
        return 'CANCELADO';
      default:
        return estado.toUpperCase();
    }
  }
// ========================================
// NAVEGACIÓN
// ========================================
  void _irACrearOrden() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrdenFormPage(),
      ),
    );
  }
  void _irADetalle(OrdenInternaDetalle orden) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdenDetallePage(ordenDetalle: orden),
      ),
    );
  }
  void _mostrarFiltros() {
// TODO: Implementar sheet de filtros avanzados
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filtros avanzados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Próximamente...'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../providers/movimiento_stock_provider.dart';
import '../providers/producto_provider.dart';

/// Pantalla de HISTORIAL de movimientos (Sistema Kardex)
///
/// Muestra todos los movimientos de stock en formato de lista cronológica.
/// Permite filtrar por:
/// - Fechas
/// - Tipo de movimiento
/// - Producto
class MovimientoHistorialPage extends StatefulWidget {
  /// Si se pasa un productoId, muestra solo los movimientos de ese producto
  final int? productoId;
  final String? productoNombre;

  const MovimientoHistorialPage({
    super.key,
    this.productoId,
    this.productoNombre,
  });

  @override
  State<MovimientoHistorialPage> createState() => _MovimientoHistorialPageState();
}

class _MovimientoHistorialPageState extends State<MovimientoHistorialPage> {
  // ========================================
  // ESTADO
  // ========================================

  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  TipoMovimiento? _tipoFiltro;

  @override
  void initState() {
    super.initState();

    // Cargar movimientos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productoId != null) {
        // Si viene un productoId específico, cargar sus movimientos
        context.read<MovimientoStockProvider>().cargarMovimientosDeProducto(widget.productoId!);
      } else {
        // Sino, cargar todos los movimientos (últimos 100)
        context.read<MovimientoStockProvider>().cargarMovimientos(limit: 100);
      }
    });
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
        leading: IconButton(  // ← AGREGAR ESTO
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productoNombre ?? 'Historial de Movimientos'),
            Consumer<MovimientoStockProvider>(
              builder: (context, provider, child) {
                return Text(
                  '${provider.totalMovimientos} registros',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textWhite,
                  ),
                );
              },
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Botón de filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarDialogoFiltros,
          ),
        ],
      ),

      // ========================================
      // BODY
      // ========================================
      body: Column(
        children: [
          // Chips de filtros activos
          _buildChipsFiltrosActivos(),

          // Lista de movimientos
          Expanded(
            child: Consumer<MovimientoStockProvider>(
              builder: (context, provider, child) {
                // Estado de carga
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                // Error
                if (provider.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.errorMessage ?? 'Error desconocido',
                          style: const TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
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

                // Sin movimientos
                if (!provider.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin movimientos',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aún no hay movimientos de stock registrados',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  );
                }

                // Lista de movimientos
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => provider.refrescar(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.movimientos.length,
                    itemBuilder: (context, index) {
                      final movimiento = provider.movimientos[index];
                      return _MovimientoCard(
                        movimiento: movimiento,
                        mostrarProducto: widget.productoId == null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ========================================
      // ESTADÍSTICAS (Bottom Sheet opcional)
      // ========================================
      bottomNavigationBar: _buildBarraEstadisticas(),
    );
  }

  // ========================================
  // FILTROS ACTIVOS (CHIPS)
  // ========================================

  Widget _buildChipsFiltrosActivos() {
    return Consumer<MovimientoStockProvider>(
      builder: (context, provider, child) {
        final hayFiltros = provider.fechaDesde != null ||
            provider.fechaHasta != null ||
            provider.tipoFiltro != null;

        if (!hayFiltros) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.backgroundGray,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Filtro de fecha desde
              if (provider.fechaDesde != null)
                Chip(
                  label: Text(
                    'Desde: ${DateFormat('dd/MM/yy').format(provider.fechaDesde!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() => _fechaDesde = null);
                    provider.filtrarPorFechas(null, provider.fechaHasta);
                  },
                ),

              // Filtro de fecha hasta
              if (provider.fechaHasta != null)
                Chip(
                  label: Text(
                    'Hasta: ${DateFormat('dd/MM/yy').format(provider.fechaHasta!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() => _fechaHasta = null);
                    provider.filtrarPorFechas(provider.fechaDesde, null);
                  },
                ),

              // Filtro de tipo
              if (provider.tipoFiltro != null)
                Chip(
                  label: Text(
                    provider.tipoFiltro!.name.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getColorTipo(provider.tipoFiltro!).withOpacity(0.2),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() => _tipoFiltro = null);
                    provider.filtrarPorTipo(null);
                  },
                ),

              // Botón limpiar todo
              if (hayFiltros)
                ActionChip(
                  label: const Text(
                    'Limpiar filtros',
                    style: TextStyle(fontSize: 12),
                  ),
                  avatar: const Icon(Icons.clear_all, size: 16),
                  onPressed: () {
                    setState(() {
                      _fechaDesde = null;
                      _fechaHasta = null;
                      _tipoFiltro = null;
                    });
                    provider.limpiarFiltros();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // DIÁLOGO DE FILTROS
  // ========================================

  void _mostrarDialogoFiltros() {
    showDialog(
      context: context,
      builder: (context) {
        DateTime? tempFechaDesde = _fechaDesde;
        DateTime? tempFechaHasta = _fechaHasta;
        TipoMovimiento? tempTipoFiltro = _tipoFiltro;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FILTRO POR TIPO
                    const Text(
                      'Tipo de movimiento',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Todos'),
                          selected: tempTipoFiltro == null,
                          onSelected: (selected) {
                            setDialogState(() {
                              tempTipoFiltro = null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Entradas'),
                          selected: tempTipoFiltro == TipoMovimiento.entrada,
                          onSelected: (selected) {
                            setDialogState(() {
                              tempTipoFiltro = selected ? TipoMovimiento.entrada : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Salidas'),
                          selected: tempTipoFiltro == TipoMovimiento.salida,
                          onSelected: (selected) {
                            setDialogState(() {
                              tempTipoFiltro = selected ? TipoMovimiento.salida : null;
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Ajustes'),
                          selected: tempTipoFiltro == TipoMovimiento.ajuste,
                          onSelected: (selected) {
                            setDialogState(() {
                              tempTipoFiltro = selected ? TipoMovimiento.ajuste : null;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // FILTRO POR FECHA
                    const Text(
                      'Rango de fechas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Fecha desde
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        tempFechaDesde == null
                            ? 'Desde...'
                            : DateFormat('dd/MM/yyyy').format(tempFechaDesde!),
                      ),
                      trailing: tempFechaDesde != null
                          ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setDialogState(() {
                            tempFechaDesde = null;
                          });
                        },
                      )
                          : null,
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: tempFechaDesde ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setDialogState(() {
                            tempFechaDesde = fecha;
                          });
                        }
                      },
                    ),

                    // Fecha hasta
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        tempFechaHasta == null
                            ? 'Hasta...'
                            : DateFormat('dd/MM/yyyy').format(tempFechaHasta!),
                      ),
                      trailing: tempFechaHasta != null
                          ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setDialogState(() {
                            tempFechaHasta = null;
                          });
                        },
                      )
                          : null,
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: tempFechaHasta ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setDialogState(() {
                            tempFechaHasta = fecha;
                          });
                        }
                      },
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
                    setState(() {
                      _fechaDesde = tempFechaDesde;
                      _fechaHasta = tempFechaHasta;
                      _tipoFiltro = tempTipoFiltro;
                    });

                    // Aplicar filtros
                    context.read<MovimientoStockProvider>().cargarMovimientos(
                      desde: _fechaDesde,
                      hasta: _fechaHasta,
                      tipo: _tipoFiltro,
                      limit: 100,
                    );

                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ========================================
  // BARRA DE ESTADÍSTICAS
  // ========================================

  Widget _buildBarraEstadisticas() {
    return Consumer<MovimientoStockProvider>(
      builder: (context, provider, child) {
        if (!provider.hasData) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEstadisticaItem(
                'Entradas',
                provider.totalEntradas.toString(),
                AppColors.success,
                Icons.arrow_downward,
              ),
              _buildEstadisticaItem(
                'Salidas',
                provider.totalSalidas.toString(),
                AppColors.error,
                Icons.arrow_upward,
              ),
              _buildEstadisticaItem(
                'Ajustes',
                provider.totalAjustes.toString(),
                AppColors.warning,
                Icons.settings,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadisticaItem(String label, String valor, Color color, IconData icono) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  // ========================================
  // UTILIDADES
  // ========================================

  Color _getColorTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return AppColors.success;
      case TipoMovimiento.salida:
        return AppColors.error;
      case TipoMovimiento.ajuste:
        return AppColors.warning;
    }
  }
}

// ========================================
// CARD DE MOVIMIENTO
// ========================================

class _MovimientoCard extends StatelessWidget {
  final MovimientoStock movimiento;
  final bool mostrarProducto;

  const _MovimientoCard({
    required this.movimiento,
    this.mostrarProducto = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icono = _getIcono();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono del tipo de movimiento
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 28),
            ),

            const SizedBox(width: 16),

            // Información del movimiento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo y fecha
                  Row(
                    children: [
                      Text(
                        movimiento.tipo.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(movimiento.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Producto (si corresponde)
                  if (mostrarProducto)
                    Consumer<ProductoProvider>(
                      builder: (context, provider, child) {
                        final producto = provider.productos
                            .where((p) => p.productoId == movimiento.productoId)
                            .firstOrNull;

                        return Text(
                          producto?.productoNombre ?? 'Producto #${movimiento.productoId}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                          ),
                        );
                      },
                    ),

                  // Cantidad y saldos
                  Row(
                    children: [
                      Text(
                        'Cantidad: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      Text(
                        '${movimiento.signo}${ArgFormats.decimal(movimiento.cantidad)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),

                  // Saldos anterior y posterior
                  Text(
                    '${ArgFormats.decimal(movimiento.cantidadAnterior)} → ${ArgFormats.decimal(movimiento.cantidadPosterior)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),

                  // Motivo (si existe)
                  if (movimiento.motivo != null && movimiento.motivo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        movimiento.motivo!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),

                  // Referencia (si existe)
                  if (movimiento.referencia != null && movimiento.referencia!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.tag, size: 12, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            movimiento.referencia!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
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

  Color _getColor() {
    switch (movimiento.tipo) {
      case TipoMovimiento.entrada:
        return AppColors.success;
      case TipoMovimiento.salida:
        return AppColors.error;
      case TipoMovimiento.ajuste:
        return AppColors.warning;
    }
  }

  IconData _getIcono() {
    switch (movimiento.tipo) {
      case TipoMovimiento.entrada:
        return Icons.arrow_downward;
      case TipoMovimiento.salida:
        return Icons.arrow_upward;
      case TipoMovimiento.ajuste:
        return Icons.settings;
    }
  }
}
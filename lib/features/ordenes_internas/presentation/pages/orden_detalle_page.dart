import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/orden_interna_model.dart';
import '../../data/models/orden_item_model.dart';
import '../providers/orden_interna_provider.dart';

/// Pantalla de Detalle de Orden Interna
class OrdenDetallePage extends StatefulWidget {
  final OrdenInternaDetalle ordenDetalle;

  const OrdenDetallePage({
    super.key,
    required this.ordenDetalle,
  });

  @override
  State<OrdenDetallePage> createState() => _OrdenDetallePageState();
}

class _OrdenDetallePageState extends State<OrdenDetallePage> {
  bool _isLoading = false;

  OrdenInterna get orden => widget.ordenDetalle.orden;

  @override
  Widget build(BuildContext context) {
    final estadoColor = _getEstadoColor(orden.estado);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Orden ${orden.numero}'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(estadoColor),
            const SizedBox(height: 20),
            _buildSeccion(
              titulo: '👤 Cliente',
              children: [
                _buildInfoRow('Razón Social', widget.ordenDetalle.clienteRazonSocial),
                if (widget.ordenDetalle.obraNombre != null)
                  _buildInfoRow('Obra', widget.ordenDetalle.obraNombre!),
                _buildInfoRow('Solicitante', orden.solicitanteNombre),
                if (orden.solicitanteEmail != null)
                  _buildInfoRow('Email', orden.solicitanteEmail!),
                if (orden.solicitanteTelefono != null)
                  _buildInfoRow('Teléfono', orden.solicitanteTelefono!),
              ],
            ),
            const SizedBox(height: 16),
            _buildSeccion(
              titulo: '📅 Fechas',
              children: [
                _buildInfoRow('Pedido', ArgFormats.fechaHora(orden.fechaPedido)),
                if (orden.fechaEntregaEstimada != null)
                  _buildInfoRow('Entrega estimada', ArgFormats.fecha(orden.fechaEntregaEstimada!)),
                if (orden.aprobadoFecha != null)
                  _buildInfoRow('Aprobación', ArgFormats.fechaHora(orden.aprobadoFecha!)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSeccion(
              titulo: '📦 Productos',
              children: [
                ...widget.ordenDetalle.items.map((item) => _buildProductoCard(item)),
              ],
            ),
            const SizedBox(height: 16),
            if (orden.observacionesCliente != null || orden.observacionesInternas != null)
              _buildSeccion(
                titulo: '📝 Observaciones',
                children: [
                  if (orden.observacionesCliente != null)
                    _buildObservacion('Cliente', orden.observacionesCliente!),
                  if (orden.observacionesInternas != null)
                    _buildObservacion('Internas', orden.observacionesInternas!, isInternal: true),
                ],
              ),
            if (orden.estado == 'rechazado' && orden.motivoRechazo != null) ...[
              const SizedBox(height: 16),
              _buildSeccion(
                titulo: '❌ Motivo de Rechazo',
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      orden.motivoRechazo!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildTotal(),
            const SizedBox(height: 24),
            _buildBotonesAccion(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color estadoColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [estadoColor.withOpacity(0.1), estadoColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: estadoColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: estadoColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEstadoIcon(orden.estado),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orden.numero,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getEstadoLabel(orden.estado),
                  style: TextStyle(
                    fontSize: 16,
                    color: estadoColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({required String titulo, required List<Widget> children}) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(OrdenItemDetalle item) {
    final fueModificada = item.fueModificada;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fueModificada ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productoNombre,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.productoCodigo} • ${item.categoriaNombre}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cantidad',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ArgFormats.decimal(item.cantidadFinal)} ${item.unidadBase}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Precio unitario',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ArgFormats.moneda(item.item.precioUnitario),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                ArgFormats.moneda(item.cantidadFinal * item.item.precioUnitario),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (fueModificada) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Cantidad ajustada de ${ArgFormats.decimal(item.item.cantidadSolicitada)} a ${ArgFormats.decimal(item.item.cantidadAprobada!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObservacion(String titulo, String texto, {bool isInternal = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInternal ? AppColors.info.withOpacity(0.1) : AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInternal ? AppColors.info : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isInternal)
                Icon(Icons.lock_outline, size: 16, color: AppColors.info),
              if (isInternal) const SizedBox(width: 4),
              Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isInternal ? AppColors.info : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            texto,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.ordenDetalle.cantidadProductos} productos • ${ArgFormats.decimal(widget.ordenDetalle.cantidadTotal)} unidades',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            ArgFormats.moneda(orden.total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    if (orden.esFinal && orden.estado != 'rechazado') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (orden.estado == 'solicitado') ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarDialogAprobar(),
              icon: const Icon(Icons.check_circle),
              label: const Text('Aprobar Orden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _mostrarDialogRechazar(),
              icon: const Icon(Icons.cancel),
              label: const Text('Rechazar Orden'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
        if (orden.estado == 'aprobado' || orden.estado == 'en_preparacion') ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _cambiarEstado('listo_envio'),
              icon: const Icon(Icons.done_all),
              label: const Text('Marcar Listo para Envío'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
            ),
          ),
        ],
        if (orden.estado == 'listo_envio') ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _cambiarEstado('despachado'),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Marcar como Despachado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        ],
        if (!orden.esFinal) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _mostrarDialogCancelar(),
              icon: const Icon(Icons.block),
              label: const Text('Cancelar Orden'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _isLoading = true);

    final exito = await context.read<OrdenInternaProvider>().cambiarEstado(
      ordenId: orden.id!,
      nuevoEstado: nuevoEstado,
    );

    setState(() => _isLoading = false);

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Estado actualizado a ${_getEstadoLabel(nuevoEstado)}'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al cambiar el estado'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _mostrarDialogAprobar() {
    final obsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Orden'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Confirmar la aprobación de la orden ${orden.numero}?'),
            const SizedBox(height: 16),
            TextField(
              controller: obsController,
              decoration: const InputDecoration(
                labelText: 'Observaciones internas (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final exito = await context.read<OrdenInternaProvider>().aprobarOrden(
                ordenId: orden.id!,
                aprobadoPorUsuarioId: 1,
                observacionesInternas: obsController.text.trim().isEmpty
                    ? null
                    : obsController.text.trim(),
              );

              setState(() => _isLoading = false);

              if (exito && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Orden aprobada exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error al aprobar la orden'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogRechazar() {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Orden'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Confirmar el rechazo de la orden ${orden.numero}?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El motivo es obligatorio')),
                );
                return;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);

              final exito = await context.read<OrdenInternaProvider>().rechazarOrden(
                ordenId: orden.id!,
                rechazadoPorUsuarioId: 1,
                motivoRechazo: motivoController.text.trim(),
              );

              setState(() => _isLoading = false);

              if (exito && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Orden rechazada'),
                    backgroundColor: AppColors.error,
                  ),
                );
                Navigator.pop(context);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error al rechazar la orden'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogCancelar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Orden'),
        content: Text('¿Estás seguro de cancelar la orden ${orden.numero}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final exito = await context.read<OrdenInternaProvider>().cancelarOrden(orden.id!);

              setState(() => _isLoading = false);

              if (exito && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Orden cancelada'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.pop(context);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error al cancelar la orden'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'solicitado': return AppColors.warning;
      case 'en_revision': return AppColors.info;
      case 'aprobado': return AppColors.success;
      case 'rechazado': return AppColors.error;
      case 'en_preparacion': return Colors.blue;
      case 'listo_envio': return Colors.purple;
      case 'despachado': return AppColors.success;
      case 'cancelado': return Colors.grey;
      default: return AppColors.textMedium;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'solicitado': return Icons.pending_actions;
      case 'en_revision': return Icons.search;
      case 'aprobado': return Icons.check_circle;
      case 'rechazado': return Icons.cancel;
      case 'en_preparacion': return Icons.hourglass_empty;
      case 'listo_envio': return Icons.done_all;
      case 'despachado': return Icons.local_shipping;
      case 'cancelado': return Icons.block;
      default: return Icons.help_outline;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'solicitado': return 'SOLICITADO';
      case 'en_revision': return 'EN REVISIÓN';
      case 'aprobado': return 'APROBADO';
      case 'rechazado': return 'RECHAZADO';
      case 'en_preparacion': return 'EN PREPARACIÓN';
      case 'listo_envio': return 'LISTO PARA ENVÍO';
      case 'despachado': return 'DESPACHADO';
      case 'cancelado': return 'CANCELADO';
      default: return estado.toUpperCase();
    }
  }
}
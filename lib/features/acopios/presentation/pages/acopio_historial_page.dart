import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/repositories/acopio_repository.dart';

/// Pantalla de Historial de Movimientos de un Acopio
///
/// Muestra todos los movimientos (entradas, salidas, traspasos)
/// de un acopio específico, estilo Kardex.
class AcopioHistorialPage extends StatefulWidget {
  final AcopioDetalle acopioDetalle;

  const AcopioHistorialPage({
    super.key,
    required this.acopioDetalle,
  });

  @override
  State<AcopioHistorialPage> createState() => _AcopioHistorialPageState();
}

class _AcopioHistorialPageState extends State<AcopioHistorialPage> {
  final AcopioRepository _acopioRepo = AcopioRepository();
  List<MovimientoAcopioModel> _movimientos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);

    final movimientos = await _acopioRepo.obtenerHistorialAcopio(
      productoId: widget.acopioDetalle.acopio.productoId,
      clienteId: widget.acopioDetalle.acopio.clienteId,
      proveedorId: widget.acopioDetalle.acopio.proveedorId,
    );

    setState(() {
      _movimientos = movimientos;
      _isLoading = false;
    });
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
        title: const Text('Historial de Acopio'),
      ),

      body: Column(
        children: [
          // ========================================
          // HEADER DEL ACOPIO
          // ========================================
          _buildHeaderAcopio(),

          // ========================================
          // HISTORIAL DE MOVIMIENTOS
          // ========================================
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _movimientos.isEmpty
                ? _buildEstadoVacio()
                : _buildHistorial(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAcopio() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.1), AppColors.primaryLight.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Producto
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.acopioDetalle.productoCodigo,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.acopioDetalle.productoNombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.acopioDetalle.categoriaNombre,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Info del acopio
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.person,
                  'Cliente',
                  widget.acopioDetalle.clienteRazonSocial,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.store,
                  'Ubicación',
                  widget.acopioDetalle.proveedorNombre,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Saldo actual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2, color: AppColors.success, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Saldo Actual: ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${widget.acopioDetalle.cantidadFormateada} ${widget.acopioDetalle.unidadBase}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icono, String label, String valor) {
    return Column(
      children: [
        Icon(icono, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Sin movimientos registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'El historial aparecerá aquí cuando se registren movimientos',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorial() {
    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _movimientos.length,
        itemBuilder: (context, index) {
          final movimiento = _movimientos[index];
          return _buildMovimientoCard(movimiento);
        },
      ),
    );
  }

  Widget _buildMovimientoCard(MovimientoAcopioModel movimiento) {
    // Determinar el color según el tipo
    Color color;
    IconData icono;
    String tipoTexto;

    switch (movimiento.tipo) {
      case TipoMovimientoAcopio.entrada:
        color = AppColors.success;
        icono = Icons.arrow_downward;
        tipoTexto = 'ENTRADA';
        break;
      case TipoMovimientoAcopio.salida:
        color = AppColors.error;
        icono = Icons.arrow_upward;
        tipoTexto = 'SALIDA';
        break;
      case TipoMovimientoAcopio.traspaso:
        color = AppColors.warning;
        icono = Icons.swap_horiz;
        tipoTexto = 'TRASPASO';
        break;
      default:
        color = AppColors.info;
        icono = Icons.info;
        tipoTexto = movimiento.tipo.name.toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tipoTexto,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${movimiento.cantidad.toStringAsFixed(2)} ${widget.acopioDetalle.unidadBase}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatearFecha(movimiento.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Detalles
            if (movimiento.motivo != null || movimiento.referencia != null || movimiento.tieneFactura) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              if (movimiento.motivo != null)
                _buildDetalle(Icons.description, 'Motivo', movimiento.motivo!),

              if (movimiento.referencia != null)
                _buildDetalle(Icons.tag, 'Referencia', movimiento.referencia!),

              if (movimiento.tieneFactura) ...[
                _buildDetalle(
                  Icons.receipt_long,
                  'Factura',
                  movimiento.facturaNumero!,
                ),
                if (movimiento.facturaFecha != null)
                  _buildDetalle(
                    Icons.calendar_today,
                    'Fecha Factura',
                    _formatearFecha(movimiento.facturaFecha!),
                  ),
              ],

              if (movimiento.valorizado && movimiento.montoValorizado != null)
                _buildDetalle(
                  Icons.attach_money,
                  'Monto',
                  ArgFormats.moneda(movimiento.montoValorizado!),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetalle(IconData icono, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/acopio_provider.dart';

/// Pantalla de Facturas
///
/// Muestra todas las facturas registradas con sus estadísticas
class FacturasListPage extends StatefulWidget {
  const FacturasListPage({super.key});

  @override
  State<FacturasListPage> createState() => _FacturasListPageState();
}

class _FacturasListPageState extends State<FacturasListPage> {
  List<Map<String, dynamic>> _facturas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarFacturas();
  }

  Future<void> _cargarFacturas() async {
    setState(() => _isLoading = true);

    final facturas = await context.read<AcopioProvider>().obtenerFacturasUnicas();

    setState(() {
      _facturas = facturas;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Facturas de Acopios'),
            Text(
              '${_facturas.length} facturas registradas',
              style: const TextStyle(fontSize: 12, color: AppColors.textWhite),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarFacturas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _facturas.isEmpty
          ? _buildEstadoVacio()
          : _buildListaFacturas(),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay facturas registradas',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra movimientos con factura para verlas aquí',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildListaFacturas() {
    return RefreshIndicator(
      onRefresh: _cargarFacturas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _facturas.length,
        itemBuilder: (context, index) {
          final factura = _facturas[index];
          return _buildFacturaCard(factura);
        },
      ),
    );
  }

  Widget _buildFacturaCard(Map<String, dynamic> factura) {
    final facturaNumero = factura['factura_numero'] as String;
    final facturaFecha = factura['factura_fecha'] != null
        ? DateTime.parse(factura['factura_fecha'])
        : null;
    final cantidadItems = factura['cantidad_items'] as int;
    final cantidadTotal = (factura['cantidad_total'] as num?)?.toDouble() ?? 0.0;
    final montoTotal = (factura['monto_total'] as num?)?.toDouble() ?? 0.0;

    // Determinar si es reciente (últimos 30 días)
    final esReciente = facturaFecha != null &&
        DateTime.now().difference(facturaFecha).inDays <= 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esReciente ? AppColors.success : AppColors.border,
          width: esReciente ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verDetalleFactura(facturaNumero),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          facturaNumero,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (facturaFecha != null)
                          Text(
                            '${facturaFecha.day}/${facturaFecha.month}/${facturaFecha.year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (esReciente)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'RECIENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Estadísticas
              Row(
                children: [
                  Expanded(
                    child: _buildEstadisticaItem(
                      'Items',
                      cantidadItems.toString(),
                      Icons.inventory_2,
                      AppColors.primary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildEstadisticaItem(
                      'Unidades',
                      ArgFormats.decimal(cantidadTotal),
                      Icons.numbers,
                      AppColors.secondary,
                    ),
                  ),
                  if (montoTotal > 0) ...[
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildEstadisticaItem(
                        'Total',
                        ArgFormats.moneda(montoTotal),
                        Icons.attach_money,
                        AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticaItem(
      String label,
      String valor,
      IconData icono,
      Color color,
      ) {
    return Column(
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _verDetalleFactura(String facturaNumero) async {
    // Filtrar acopios por esta factura
    await context.read<AcopioProvider>().filtrarPorFactura(facturaNumero);

    if (mounted) {
      // Volver a la pantalla de acopios con el filtro aplicado
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mostrando acopios de factura: $facturaNumero'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
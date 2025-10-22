import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../acopios/data/models/acopio_model.dart';
import '../../../acopios/data/repositories/acopio_repository.dart';
import '../../data/services/excel_service.dart';

/// Pantalla de Reporte de Acopios por Cliente
class ReporteAcopiosPage extends StatefulWidget {
  const ReporteAcopiosPage({super.key});

  @override
  State<ReporteAcopiosPage> createState() => _ReporteAcopiosPageState();
}

class _ReporteAcopiosPageState extends State<ReporteAcopiosPage> {
  final AcopioRepository _repo = AcopioRepository();
  final ExcelService _excelService = ExcelService();

  List<AcopioDetalle> _acopios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAcopios();
  }

  Future<void> _cargarAcopios() async {
    setState(() => _isLoading = true);

    final acopios = await _repo.obtenerTodosConDetalle();

    setState(() {
      _acopios = acopios;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Reporte de Acopios'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _acopios.isEmpty ? null : _exportarExcel,
            tooltip: 'Exportar Excel',
          ),
        ],
      ),

      body: Column(
        children: [
          // Estadísticas
          _buildEstadisticas(),

          // Lista de acopios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _acopios.isEmpty
                ? _buildEmptyState()
                : _buildLista(),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    final totalClientes = _acopios.map((a) => a.acopio.clienteId).toSet().length;
    final totalProveedores = _acopios.map((a) => a.acopio.proveedorId).toSet().length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          _buildEst('Acopios', _acopios.length.toString(), AppColors.primary),
          _buildEst('Clientes', totalClientes.toString(), AppColors.secondary),
          _buildEst('Proveedores', totalProveedores.toString(), AppColors.info),
        ],
      ),
    );
  }

  Widget _buildEst(String label, String valor, Color color) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildLista() {
    // Agrupar por cliente
    final Map<String, List<AcopioDetalle>> agrupadosPorCliente = {};

    for (var acopio in _acopios) {
      final cliente = acopio.clienteRazonSocial;
      if (!agrupadosPorCliente.containsKey(cliente)) {
        agrupadosPorCliente[cliente] = [];
      }
      agrupadosPorCliente[cliente]!.add(acopio);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: agrupadosPorCliente.length,
      itemBuilder: (context, index) {
        final cliente = agrupadosPorCliente.keys.elementAt(index);
        final acopiosCliente = agrupadosPorCliente[cliente]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              cliente,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${acopiosCliente.length} acopio(s)'),
            children: acopiosCliente.map((acopio) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.inventory_2, size: 20),
                title: Text(acopio.productoNombre),
                subtitle: Text(acopio.proveedorNombre),
                trailing: Text(
                  '${acopio.acopio.cantidadDisponible.toStringAsFixed(0)} ${acopio.unidadBase}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: AppColors.textLight),
          const SizedBox(height: 16),
          const Text('No hay acopios registrados'),
        ],
      ),
    );
  }

  Future<void> _exportarExcel() async {
    try {
      await _excelService.generarReporteAcopios(acopios: _acopios);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Excel generado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al generar Excel: $e')),
        );
      }
    }
  }
}
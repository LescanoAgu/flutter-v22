import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../stock/data/repositories/movimiento_stock_repository.dart';
import '../../data/services/pdf_service.dart';
import '../../data/services/excel_service.dart';

/// Pantalla de Reporte de Movimientos de Stock
///
/// Permite:
/// - Ver lista de movimientos
/// - Filtrar por fecha y tipo
/// - Exportar a PDF
class ReporteStockPage extends StatefulWidget {
  const ReporteStockPage({super.key});

  @override
  State<ReporteStockPage> createState() => _ReporteStockPageState();
}

class _ReporteStockPageState extends State<ReporteStockPage> {
  final MovimientoStockRepository _repo = MovimientoStockRepository();
  final PdfService _pdfService = PdfService();

  List<MovimientoStock> _movimientos = [];
  bool _isLoading = true;

  // Filtros
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  TipoMovimiento? _tipoFiltro;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  Future<void> _cargarMovimientos() async {
    setState(() => _isLoading = true);

    final movimientos = await _repo.getMovimientos(
      desde: _fechaDesde,
      hasta: _fechaHasta,
      tipo: _tipoFiltro,
      limit: 100, // Últimos 100 movimientos
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

      appBar: AppBar(
        title: const Text('Reporte de Stock'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          // Botón de exportar PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _movimientos.isEmpty ? null : _exportarPDF,
            tooltip: 'Exportar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _movimientos.isEmpty ? null : _exportarExcel,
            tooltip: 'Exportar Excel',
          ),
        ],
      ),


      body: Column(
        children: [
          // Filtros
          _buildFiltros(),

          // Estadísticas
          _buildEstadisticas(),

          // Lista de movimientos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _movimientos.isEmpty
                ? _buildEmptyState()
                : _buildLista(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Fila de filtros de fecha
          Row(
            children: [
              Expanded(
                child: _buildFechaButton(
                  label: 'Desde',
                  fecha: _fechaDesde,
                  onTap: () => _seleccionarFecha(esDesde: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFechaButton(
                  label: 'Hasta',
                  fecha: _fechaHasta,
                  onTap: () => _seleccionarFecha(esDesde: false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Filtro por tipo
          DropdownButtonFormField<TipoMovimiento?>(
            value: _tipoFiltro,
            decoration: InputDecoration(
              labelText: 'Tipo de movimiento',
              prefixIcon: const Icon(Icons.filter_list),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              const DropdownMenuItem(
                value: TipoMovimiento.entrada,
                child: Text('Entradas'),
              ),
              const DropdownMenuItem(
                value: TipoMovimiento.salida,
                child: Text('Salidas'),
              ),
              const DropdownMenuItem(
                value: TipoMovimiento.ajuste,
                child: Text('Ajustes'),
              ),
            ],
            onChanged: (valor) {
              setState(() => _tipoFiltro = valor);
              _cargarMovimientos();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFechaButton({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        fecha != null ? ArgFormats.fecha(fecha) : label,
        style: const TextStyle(fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    final totalEntradas = _movimientos
        .where((m) => m.tipo == TipoMovimiento.entrada)
        .length;
    final totalSalidas = _movimientos
        .where((m) => m.tipo == TipoMovimiento.salida)
        .length;

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
          _buildEst('Total', _movimientos.length.toString(), AppColors.primary),
          _buildEst('Entradas', totalEntradas.toString(), AppColors.success),
          _buildEst('Salidas', totalSalidas.toString(), AppColors.error),
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _movimientos.length,
      itemBuilder: (context, index) {
        final mov = _movimientos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColor(mov.tipo),
              child: Icon(_getIcon(mov.tipo), color: Colors.white, size: 20),
            ),
            title: Text(
              _formatTipo(mov.tipo),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${ArgFormats.fechaHora(mov.createdAt)}\n${mov.motivo ?? "Sin motivo"}',
            ),
            trailing: Text(
              ArgFormats.decimal(mov.cantidad),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getColor(mov.tipo),
              ),
            ),
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
          const Text('No hay movimientos en este período'),
        ],
      ),
    );
  }

  // Helpers
  Color _getColor(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return AppColors.success;
      case TipoMovimiento.salida:
        return AppColors.error;
      case TipoMovimiento.ajuste:
        return AppColors.warning;
    }
  }

  IconData _getIcon(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return Icons.arrow_downward;
      case TipoMovimiento.salida:
        return Icons.arrow_upward;
      case TipoMovimiento.ajuste:
        return Icons.settings;
    }
  }

  String _formatTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return 'Entrada';
      case TipoMovimiento.salida:
        return 'Salida';
      case TipoMovimiento.ajuste:
        return 'Ajuste';
    }
  }

  // Acciones
  Future<void> _seleccionarFecha({required bool esDesde}) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        if (esDesde) {
          _fechaDesde = fecha;
        } else {
          _fechaHasta = fecha;
        }
      });
      _cargarMovimientos();
    }
  }

  Future<void> _exportarPDF() async {
    try {
      await _pdfService.generarReporteMovimientosStock(
        movimientos: _movimientos,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ PDF generado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al generar PDF: $e')),
        );
      }
    }
  }
  Future<void> _exportarExcel() async {
    try {
      final excelService = ExcelService();
      await excelService.generarReporteMovimientosStock(
        movimientos: _movimientos,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );

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
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';

/// Servicio para generar PDFs de reportes
///
/// Usa el paquete 'pdf' para crear documentos
/// y 'printing' para previsualizar/compartir.
class PdfService {

  /// Genera PDF de Movimientos de Stock
  ///
  /// Parámetros:
  /// - movimientos: Lista de movimientos a incluir
  /// - fechaDesde: Fecha inicial del reporte (opcional)
  /// - fechaHasta: Fecha final del reporte (opcional)
  Future<void> generarReporteMovimientosStock({
    required List<MovimientoStock> movimientos,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    // Crear el documento PDF
    final pdf = pw.Document();

    // Calcular totales
    int totalEntradas = movimientos
        .where((m) => m.tipo == TipoMovimiento.entrada)
        .length;
    int totalSalidas = movimientos
        .where((m) => m.tipo == TipoMovimiento.salida)
        .length;
    int totalAjustes = movimientos
        .where((m) => m.tipo == TipoMovimiento.ajuste)
        .length;

    // Agregar página al PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ========================================
            // HEADER - Logo y Título
            // ========================================
            _buildHeader(),

            pw.SizedBox(height: 20),

            // ========================================
            // INFORMACIÓN DEL REPORTE
            // ========================================
            _buildReporteInfo(fechaDesde, fechaHasta),

            pw.SizedBox(height: 20),

            // ========================================
            // RESUMEN DE TOTALES
            // ========================================
            _buildResumenTotales(
              totalMovimientos: movimientos.length,
              totalEntradas: totalEntradas,
              totalSalidas: totalSalidas,
              totalAjustes: totalAjustes,
            ),

            pw.SizedBox(height: 20),

            // ========================================
            // TABLA DE MOVIMIENTOS
            // ========================================
            _buildTablaMovimientos(movimientos),

            pw.SizedBox(height: 20),

            // ========================================
            // FOOTER
            // ========================================
            _buildFooter(),
          ];
        },
      ),
    );

    // Previsualizar y compartir el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'reporte_movimientos_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // ========================================
  // COMPONENTES DEL PDF
  // ========================================

  /// Header con logo y título
  pw.Widget _buildHeader() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.teal,
            width: 3,
          ),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Logo (texto por ahora, después agregamos imagen)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.teal,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'S&G',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),

          // Título
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'REPORTE DE MOVIMIENTOS',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'S&G Ingeniería y Desarrollo',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Información del reporte (fecha de generación, rango)
  pw.Widget _buildReporteInfo(DateTime? fechaDesde, DateTime? fechaHasta) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Fecha de generación:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                ArgFormats.fechaHora(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          if (fechaDesde != null || fechaHasta != null) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Período:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${fechaDesde != null ? ArgFormats.fecha(fechaDesde) : "Inicio"} - ${fechaHasta != null ? ArgFormats.fecha(fechaHasta) : "Hoy"}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Resumen de totales
  pw.Widget _buildResumenTotales({
    required int totalMovimientos,
    required int totalEntradas,
    required int totalSalidas,
    required int totalAjustes,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildTotalCard('Total', totalMovimientos.toString(), PdfColors.teal),
        _buildTotalCard('Entradas', totalEntradas.toString(), PdfColors.green),
        _buildTotalCard('Salidas', totalSalidas.toString(), PdfColors.red),
        _buildTotalCard('Ajustes', totalAjustes.toString(), PdfColors.orange),
      ],
    );
  }

  /// Card individual de total
  pw.Widget _buildTotalCard(String label, String valor, PdfColor color) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.9),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  /// Tabla de movimientos
  pw.Widget _buildTablaMovimientos(List<MovimientoStock> movimientos) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Fecha
        1: const pw.FlexColumnWidth(2), // Tipo
        2: const pw.FlexColumnWidth(2), // Cantidad
        3: const pw.FlexColumnWidth(3), // Motivo
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.teal,
          ),
          children: [
            _buildCeldaHeader('Fecha'),
            _buildCeldaHeader('Tipo'),
            _buildCeldaHeader('Cantidad'),
            _buildCeldaHeader('Motivo'),
          ],
        ),

        // Filas de datos
        ...movimientos.map((mov) {
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: movimientos.indexOf(mov) % 2 == 0
                  ? PdfColors.white
                  : PdfColors.grey100,
            ),
            children: [
              _buildCelda(ArgFormats.fecha(mov.createdAt)),
              _buildCelda(_formatearTipo(mov.tipo)),
              _buildCelda(
                ArgFormats.decimal(mov.cantidad),
                color: _getColorTipo(mov.tipo),
              ),
              _buildCelda(mov.motivo ?? '-'),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// Celda de header de tabla
  pw.Widget _buildCeldaHeader(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Celda de datos de tabla
  pw.Widget _buildCelda(String texto, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 9,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  /// Footer del PDF
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey400,
            width: 1,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado con SyG Materiales',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Página 1',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // HELPERS
  // ========================================

  String _formatearTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return 'ENTRADA';
      case TipoMovimiento.salida:
        return 'SALIDA';
      case TipoMovimiento.ajuste:
        return 'AJUSTE';
    }
  }

  PdfColor _getColorTipo(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return PdfColors.green700;
      case TipoMovimiento.salida:
        return PdfColors.red700;
      case TipoMovimiento.ajuste:
        return PdfColors.orange700;
    }
  }
}
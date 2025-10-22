import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/formatters.dart';
import '../../../stock/data/models/movimiento_stock_model.dart';
import '../../../acopios/data/models/acopio_model.dart';

/// Servicio para generar archivos Excel
///
/// Usa el paquete 'excel' para crear .xlsx
class ExcelService {

  /// Genera Excel de Movimientos de Stock
  Future<void> generarReporteMovimientosStock({
    required List<MovimientoStock> movimientos,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      // Crear libro de Excel
      final excel = Excel.createExcel();

      // Obtener la hoja por defecto y renombrarla
      final sheet = excel['Sheet1'];
      excel.rename('Sheet1', 'Movimientos');

      // ========================================
      // HEADER - Título y fecha
      // ========================================
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('F1'),
      );

      final titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('REPORTE DE MOVIMIENTOS DE STOCK');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.teal,
        fontColorHex: ExcelColor.white,
      );

      // Fecha de generación
      final fechaCell = sheet.cell(CellIndex.indexByString('A2'));
      fechaCell.value = TextCellValue(
        'Generado: ${ArgFormats.fechaHora(DateTime.now())}',
      );
      fechaCell.cellStyle = CellStyle(
        fontSize: 10,
        italic: true,
      );

      // Período
      if (fechaDesde != null || fechaHasta != null) {
        final periodoCell = sheet.cell(CellIndex.indexByString('A3'));
        periodoCell.value = TextCellValue(
          'Período: ${fechaDesde != null ? ArgFormats.fecha(fechaDesde) : "Inicio"} - ${fechaHasta != null ? ArgFormats.fecha(fechaHasta) : "Hoy"}',
        );
        periodoCell.cellStyle = CellStyle(
          fontSize: 10,
          italic: true,
        );
      }

      // ========================================
      // RESUMEN DE TOTALES
      // ========================================
      final rowResumen = fechaDesde != null || fechaHasta != null ? 5 : 4;

      final totalEntradas = movimientos
          .where((m) => m.tipo == TipoMovimiento.entrada)
          .length;
      final totalSalidas = movimientos
          .where((m) => m.tipo == TipoMovimiento.salida)
          .length;
      final totalAjustes = movimientos
          .where((m) => m.tipo == TipoMovimiento.ajuste)
          .length;

      _agregarResumen(sheet, rowResumen, [
        ['Total Movimientos:', movimientos.length.toString()],
        ['Entradas:', totalEntradas.toString()],
        ['Salidas:', totalSalidas.toString()],
        ['Ajustes:', totalAjustes.toString()],
      ]);

      // ========================================
      // HEADERS DE TABLA
      // ========================================
      final rowHeader = rowResumen + 2;
      final headers = ['#', 'Fecha', 'Hora', 'Tipo', 'Cantidad', 'Motivo', 'Referencia'];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowHeader));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.teal,
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // ========================================
      // DATOS DE MOVIMIENTOS
      // ========================================
      for (int i = 0; i < movimientos.length; i++) {
        final mov = movimientos[i];
        final rowIndex = rowHeader + 1 + i;

        // Número
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = IntCellValue(i + 1);

        // Fecha
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(ArgFormats.fecha(mov.createdAt));

        // Hora
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(ArgFormats.hora(mov.createdAt));

        // Tipo
        final tipoCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        tipoCell.value = TextCellValue(_formatearTipo(mov.tipo));
        tipoCell.cellStyle = CellStyle(
          bold: true,
          fontColorHex: _getColorHex(mov.tipo),
        );

        // Cantidad
        final cantidadCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
        cantidadCell.value = DoubleCellValue(mov.cantidad);
        cantidadCell.cellStyle = CellStyle(
          numberFormat: NumFormat.standard_2,
        );

        // Motivo
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue(mov.motivo ?? '-');

        // Referencia
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(mov.referencia ?? '-');
      }

      // Ajustar ancho de columnas
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }
      sheet.setColumnWidth(5, 30); // Motivo más ancho
      sheet.setColumnWidth(6, 20); // Referencia más ancho

      // ========================================
      // GUARDAR Y COMPARTIR
      // ========================================
      await _guardarYCompartir(
        excel,
        'reporte_movimientos_${DateTime.now().millisecondsSinceEpoch}',
      );

    } catch (e) {
      print('❌ Error al generar Excel: $e');
      rethrow;
    }
  }

  /// Genera Excel de Acopios por Cliente
  Future<void> generarReporteAcopios({
    required List<AcopioDetalle> acopios,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      excel.rename('Sheet1', 'Acopios');

      // HEADER
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('G1'),
      );

      final titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('REPORTE DE ACOPIOS POR CLIENTE');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.teal,
        fontColorHex: ExcelColor.white,
      );

      final fechaCell = sheet.cell(CellIndex.indexByString('A2'));
      fechaCell.value = TextCellValue(
        'Generado: ${ArgFormats.fechaHora(DateTime.now())}',
      );

      // RESUMEN
      final totalAcopios = acopios.length;
      final totalClientes = acopios.map((a) => a.acopio.clienteId).toSet().length;
      final totalProveedores = acopios.map((a) => a.acopio.proveedorId).toSet().length;

      _agregarResumen(sheet, 4, [
        ['Total Acopios:', totalAcopios.toString()],
        ['Clientes:', totalClientes.toString()],
        ['Proveedores:', totalProveedores.toString()],
      ]);

      // HEADERS
      const rowHeader = 6;
      final headers = [
        'Cliente',
        'Proveedor',
        'Producto',
        'Categoría',
        'Cantidad',
        'Unidad',
        'Estado',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowHeader));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.teal,
          fontColorHex: ExcelColor.white,
        );
      }

      // DATOS
      for (int i = 0; i < acopios.length; i++) {
        final acopio = acopios[i];
        final rowIndex = rowHeader + 1 + i;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(acopio.clienteRazonSocial);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(acopio.proveedorNombre);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(acopio.productoNombre);

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(acopio.categoriaNombre);

        final cantidadCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
        cantidadCell.value = DoubleCellValue(acopio.acopio.cantidadDisponible);
        cantidadCell.cellStyle = CellStyle(
          numberFormat: NumFormat.standard_2,
        );

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue(acopio.unidadBase);

        final estadoCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex));
        estadoCell.value = TextCellValue(acopio.acopio.estado);
        estadoCell.cellStyle = CellStyle(
          bold: true,
          fontColorHex: acopio.acopio.estado == 'activo'
              ? ExcelColor.green
              : ExcelColor.red,
        );
      }

      // Ajustar anchos
      sheet.setColumnWidth(0, 30); // Cliente
      sheet.setColumnWidth(1, 25); // Proveedor
      sheet.setColumnWidth(2, 30); // Producto
      sheet.setColumnWidth(3, 20); // Categoría
      sheet.setColumnWidth(4, 12); // Cantidad
      sheet.setColumnWidth(5, 10); // Unidad
      sheet.setColumnWidth(6, 12); // Estado

      await _guardarYCompartir(
        excel,
        'reporte_acopios_${DateTime.now().millisecondsSinceEpoch}',
      );

    } catch (e) {
      print('❌ Error al generar Excel de acopios: $e');
      rethrow;
    }
  }

  // ========================================
  // HELPERS
  // ========================================

  void _agregarResumen(Sheet sheet, int startRow, List<List<String>> datos) {
    for (int i = 0; i < datos.length; i++) {
      final labelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: startRow + i),
      );
      labelCell.value = TextCellValue(datos[i][0]);
      labelCell.cellStyle = CellStyle(bold: true);

      final valueCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRow + i),
      );
      valueCell.value = TextCellValue(datos[i][1]);
    }
  }

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

  ExcelColor _getColorHex(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entrada:
        return ExcelColor.green;
      case TipoMovimiento.salida:
        return ExcelColor.red;
      case TipoMovimiento.ajuste:
        return ExcelColor.orange;
    }
  }

  Future<void> _guardarYCompartir(Excel excel, String nombreArchivo) async {
    // Obtener directorio temporal
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$nombreArchivo.xlsx';

    // Guardar archivo
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Compartir usando share_plus
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Reporte generado por SyG Materiales',
      );
    }
  }
}
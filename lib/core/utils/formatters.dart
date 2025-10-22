import 'package:intl/intl.dart';

/// Formateadores para Argentina (es-AR)
///
/// Esta clase provee métodos estáticos para formatear:
/// - Moneda (Pesos argentinos)
/// - Fechas (formato argentino)
/// - Números (separadores argentinos)
/// - Porcentajes
///
/// Uso:
/// ```dart
/// String precio = ArgFormats.moneda(12500.50); // "$12.500,50"
/// String fecha = ArgFormats.fecha(DateTime.now()); // "15/10/2025"
/// ```
class ArgFormats {
  // Constructor privado para prevenir instanciación
  ArgFormats._();

  // ========================================
  // CONFIGURACIÓN DE LOCALE ARGENTINA
  // ========================================

  /// Locale de Argentina (es-AR)
  static const String locale = 'es_AR';

  // ========================================
  // FORMATEO DE MONEDA
  // ========================================

  /// Formatea un número como moneda argentina
  ///
  /// Formato: $12.500,50
  /// - Usa punto como separador de miles
  /// - Usa coma como separador decimal
  /// - Siempre muestra 2 decimales
  ///
  /// Ejemplos:
  /// ```dart
  /// ArgFormats.moneda(1500);      // "$1.500,00"
  /// ArgFormats.moneda(12500.5);   // "$12.500,50"
  /// ArgFormats.moneda(0);         // "$0,00"
  /// ArgFormats.moneda(null);      // "-"
  /// ```
  static String moneda(double? valor) {
    if (valor == null) return '-';

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '\$',           // Símbolo del peso argentino
      decimalDigits: 2,       // Siempre 2 decimales
    );

    return formatter.format(valor);
  }

  /// Formatea un número como moneda SIN el símbolo $
  ///
  /// Útil para inputs de texto donde el símbolo ya está visible.
  ///
  /// Ejemplos:
  /// ```dart
  /// ArgFormats.monedaSinSimbolo(1500);    // "1.500,00"
  /// ArgFormats.monedaSinSimbolo(12500.5); // "12.500,50"
  /// ```
  static String monedaSinSimbolo(double? valor) {
    if (valor == null) return '-';

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '',             // Sin símbolo
      decimalDigits: 2,
    );

    return formatter.format(valor).trim();
  }

  // ========================================
  // FORMATEO DE NÚMEROS
  // ========================================

  /// Formatea un número con separadores de miles
  ///
  /// Formato: 12.500
  /// - Usa punto como separador de miles
  /// - Sin decimales
  ///
  /// Ejemplos:
  /// ```dart
  /// ArgFormats.numero(1500);      // "1.500"
  /// ArgFormats.numero(1000000);   // "1.000.000"
  /// ```
  static String numero(int? valor) {
    if (valor == null) return '-';

    final formatter = NumberFormat('#,###', locale);
    return formatter.format(valor);
  }

  /// Formatea un número decimal
  ///
  /// Formato: 12.500,50
  /// - Usa punto como separador de miles
  /// - Usa coma como separador decimal
  /// - Cantidad de decimales configurable (default: 2)
  ///
  /// Ejemplos:
  /// ```dart
  /// ArgFormats.decimal(1500.5);         // "1.500,50"
  /// ArgFormats.decimal(1500.567, 3);    // "1.500,567"
  /// ```
  static String decimal(double? valor, [int decimales = 2]) {
    if (valor == null) return '-';

    final formatter = NumberFormat('#,##0.${'0' * decimales}', locale);
    return formatter.format(valor);
  }

  // ========================================
  // FORMATEO DE FECHAS
  // ========================================

  /// Formatea una fecha en formato corto argentino
  ///
  /// Formato: dd/MM/yyyy
  /// Ejemplo: 15/10/2025
  ///
  /// ```dart
  /// ArgFormats.fecha(DateTime.now());  // "15/10/2025"
  /// ArgFormats.fecha(null);            // "-"
  /// ```
  static String fecha(DateTime? fecha) {
    if (fecha == null) return '-';
    return DateFormat('dd/MM/yyyy', locale).format(fecha);
  }

  /// Formatea una fecha con hora
  ///
  /// Formato: dd/MM/yyyy HH:mm
  /// Ejemplo: 15/10/2025 14:30
  ///
  /// ```dart
  /// ArgFormats.fechaHora(DateTime.now());  // "15/10/2025 14:30"
  /// ```
  static String fechaHora(DateTime? fecha) {
    if (fecha == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(fecha);
  }

  /// Formatea una fecha en formato largo argentino
  ///
  /// Formato: Lunes 15 de octubre de 2025
  ///
  /// ```dart
  /// ArgFormats.fechaLarga(DateTime.now());
  /// // "miércoles 15 de octubre de 2025"
  /// ```
  static String fechaLarga(DateTime? fecha) {
    if (fecha == null) return '-';
    return DateFormat('EEEE d \'de\' MMMM \'de\' yyyy', locale).format(fecha);
  }

  /// Formatea solo el mes y año
  ///
  /// Formato: Octubre 2025
  ///
  /// ```dart
  /// ArgFormats.mesAnio(DateTime.now());  // "Octubre 2025"
  /// ```
  static String mesAnio(DateTime? fecha) {
    if (fecha == null) return '-';
    return DateFormat('MMMM yyyy', locale).format(fecha);
  }

  /// Formatea solo la hora
  ///
  /// Formato: 14:30
  ///
  /// ```dart
  /// ArgFormats.hora(DateTime.now());  // "14:30"
  /// ```
  static String hora(DateTime? fecha) {
    if (fecha == null) return '-';
    return DateFormat('HH:mm', locale).format(fecha);
  }

  // ========================================
  // FORMATEO DE PORCENTAJES
  // ========================================

  /// Formatea un número como porcentaje
  ///
  /// Formato: 21,00%
  ///
  /// Ejemplos:
  /// ```dart
  /// ArgFormats.porcentaje(21);      // "21,00%"
  /// ArgFormats.porcentaje(10.5);    // "10,50%"
  /// ArgFormats.porcentaje(0.105);   // "0,11%" (redondea)
  /// ```
  static String porcentaje(double? valor, [int decimales = 2]) {
    if (valor == null) return '-';

    final formatter = NumberFormat('#,##0.${'0' * decimales}%', locale);
    return formatter.format(valor);
  }

  // ========================================
  // UTILIDADES DE PARSING
  // ========================================

  /// Convierte un string con formato argentino a double
  ///
  /// Acepta:
  /// - "1.500,50" → 1500.50
  /// - "1500,50"  → 1500.50
  /// - "1500.50"  → 1500.50 (formato US también)
  /// - "$1.500,50" → 1500.50 (ignora el símbolo)
  ///
  /// Ejemplos:
  /// ```dart
  /// double? valor = ArgFormats.parseMoneda("$1.500,50");  // 1500.50
  /// double? valor = ArgFormats.parseMoneda("1500");       // 1500.0
  /// double? valor = ArgFormats.parseMoneda("abc");        // null
  /// ```
  static double? parseMoneda(String? texto) {
    if (texto == null || texto.isEmpty) return null;

    try {
      // Eliminar el símbolo $ y espacios
      String limpio = texto.replaceAll('\$', '').trim();

      // Reemplazar punto por nada (separador de miles)
      limpio = limpio.replaceAll('.', '');

      // Reemplazar coma por punto (separador decimal)
      limpio = limpio.replaceAll(',', '.');

      return double.parse(limpio);
    } catch (e) {
      return null;
    }
  }

  /// Convierte un string de fecha argentina a DateTime
  ///
  /// Acepta formato: dd/MM/yyyy
  ///
  /// Ejemplos:
  /// ```dart
  /// DateTime? fecha = ArgFormats.parseFecha("15/10/2025");
  /// // DateTime(2025, 10, 15)
  ///
  /// DateTime? fecha = ArgFormats.parseFecha("fecha inválida");
  /// // null
  /// ```
  static DateTime? parseFecha(String? texto) {
    if (texto == null || texto.isEmpty) return null;

    try {
      return DateFormat('dd/MM/yyyy', locale).parse(texto);
    } catch (e) {
      return null;
    }
  }
}
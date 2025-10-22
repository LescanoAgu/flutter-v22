import 'package:flutter/material.dart';

/// Paleta de colores de S&G Ingeniería y Desarrollo
///
/// Esta clase define todos los colores usados en la aplicación
/// basados en la identidad visual de la empresa.
///
/// Uso: AppColors.primary, AppColors.textDark, etc.
class AppColors {
  // Constructor privado para prevenir instanciación
  // Esta clase solo contiene constantes estáticas
  AppColors._();

  // ========================================
  // COLORES PRIMARIOS (del logo S&G)
  // ========================================

  /// Color principal - Teal (verde azulado)
  /// Se usa en: Header, botones principales, elementos destacados
  static const Color primary = Color(0xFF14b8a6);

  /// Variante oscura del color principal
  /// Se usa en: Hover de botones, degradados
  static const Color primaryDark = Color(0xFF0d9488);

  /// Variante clara del color principal
  /// Se usa en: Fondos suaves, estados disabled
  static const Color primaryLight = Color(0xFF5eead4);

  // ========================================
  // COLORES SECUNDARIOS
  // ========================================

  /// Azul oscuro institucional
  /// Se usa en: Títulos importantes, texto del logo
  static const Color secondary = Color(0xFF1e3a8a);

  /// Verde para estados positivos
  /// Se usa en: Badges de éxito, iconos de confirmación
  static const Color accent = Color(0xFF10b981);

  // ========================================
  // COLORES DE ESTADO
  // ========================================

  /// Rojo para errores y alertas
  static const Color error = Color(0xFFef4444);

  /// Naranja para advertencias
  static const Color warning = Color(0xFFf59e0b);

  /// Verde para éxito
  static const Color success = Color(0xFF10b981);

  static const Color successLight = Color(0xFFE8F5E9); // ejemplo "light"


  /// Azul para información
  static const Color info = Color(0xFF3b82f6);

  // ========================================
  // COLORES DE TEXTO
  // ========================================

  /// Texto principal oscuro
  static const Color textDark = Color(0xFF1f2937);

  /// Texto secundario gris
  static const Color textMedium = Color(0xFF6b7280);

  /// Texto deshabilitado o muy suave
  static const Color textLight = Color(0xFF9ca3af);

  /// Texto sobre fondos oscuros
  static const Color textWhite = Color(0xFFffffff);

  // ========================================
  // COLORES DE FONDO
  // ========================================

  /// Fondo principal de la app
  static const Color background = Color(0xFFf9fafb);

  /// Fondo de tarjetas y elementos elevados
  static const Color surface = Color(0xFFffffff);

  /// Fondo gris suave
  static const Color backgroundGray = Color(0xFFf3f4f6);

  // ========================================
  // COLORES DE BORDE Y DIVISORES
  // ========================================

  /// Bordes suaves
  static const Color border = Color(0xFFe5e7eb);

  /// Divisores entre elementos
  static const Color divider = Color(0xFFd1d5db);



  // ========================================
  // DEGRADADOS (Gradients)
  // ========================================

  /// Degradado principal (Header, botones destacados)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF14b8a6), Color(0xFF0d9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Degradado de fondo suave
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFf8fafc), Color(0xFFf1f5f9), Color(0xFFccfbf1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
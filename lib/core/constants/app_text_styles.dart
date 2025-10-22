import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos de texto de S&G Materiales
///
/// Define todos los estilos tipográficos usados en la aplicación.
/// Usa la fuente Roboto (Material Design) con escalas definidas.
///
/// Uso:
/// ```dart
/// Text('Título', style: AppTextStyles.h1)
/// Text('Párrafo', style: AppTextStyles.body1)
/// ```
class AppTextStyles {
  AppTextStyles._();

  // ========================================
  // FUENTE BASE
  // ========================================

  /// Fuente principal: Roboto
  static TextStyle get _baseStyle => GoogleFonts.roboto();

  // ========================================
  // HEADINGS (TÍTULOS)
  // ========================================

  /// H1 - Título principal de pantalla
  ///
  /// Tamaño: 32px, Peso: Bold
  /// Uso: Títulos de páginas principales
  ///
  /// Ejemplo: "Gestión de Stock"
  static TextStyle get h1 => _baseStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  /// H2 - Subtítulo importante
  ///
  /// Tamaño: 24px, Peso: Bold
  /// Uso: Secciones importantes dentro de una página
  ///
  /// Ejemplo: "Productos Destacados"
  static TextStyle get h2 => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  /// H3 - Subtítulo de sección
  ///
  /// Tamaño: 20px, Peso: SemiBold
  /// Uso: Títulos de cards, diálogos
  ///
  /// Ejemplo: "Detalles del Producto"
  static TextStyle get h3 => _baseStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: -0.2,
  );

  /// H4 - Título pequeño
  ///
  /// Tamaño: 18px, Peso: SemiBold
  /// Uso: Subtítulos menores, encabezados de listas
  ///
  /// Ejemplo: "Categoría: Obra General"
  static TextStyle get h4 => _baseStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // ========================================
  // BODY TEXT (TEXTO DE CUERPO)
  // ========================================

  /// Body 1 - Texto principal
  ///
  /// Tamaño: 16px, Peso: Normal
  /// Uso: Contenido principal, descripciones
  ///
  /// Ejemplo: "Cemento Portland de alta resistencia..."
  static TextStyle get body1 => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
    height: 1.5, // Interlineado
  );

  /// Body 2 - Texto secundario
  ///
  /// Tamaño: 14px, Peso: Normal
  /// Uso: Información adicional, metadatos
  ///
  /// Ejemplo: "Última actualización: 15/10/2025"
  static TextStyle get body2 => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textMedium,
    height: 1.4,
  );

  /// Caption - Texto pequeño
  ///
  /// Tamaño: 12px, Peso: Normal
  /// Uso: Notas al pie, etiquetas pequeñas
  ///
  /// Ejemplo: "* Campo obligatorio"
  static TextStyle get caption => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textMedium,
  );

  // ========================================
  // ESTILOS ESPECIALES
  // ========================================

  /// Precio - Estilo para mostrar precios
  ///
  /// Tamaño: 20px, Peso: Bold, Color: Success
  ///
  /// Ejemplo: "$12.500,50"
  static TextStyle get precio => _baseStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.success,
  );

  /// Precio grande - Estilo para precios destacados
  ///
  /// Tamaño: 28px, Peso: Bold, Color: Success
  ///
  /// Ejemplo: En detalles de producto
  static TextStyle get precioGrande => _baseStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.success,
    letterSpacing: -0.5,
  );

  /// Código - Estilo monoespaciado para códigos
  ///
  /// Fuente: Roboto Mono, Tamaño: 14px
  ///
  /// Ejemplo: "OG-001", "CL-042"
  static TextStyle get codigo => GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );

  /// Label - Etiquetas de formularios
  ///
  /// Tamaño: 14px, Peso: Medium
  ///
  /// Ejemplo: "Nombre del producto"
  static TextStyle get label => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  /// Button - Texto de botones
  ///
  /// Tamaño: 16px, Peso: SemiBold
  ///
  /// Ejemplo: "GUARDAR", "CANCELAR"
  static TextStyle get button => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ========================================
  // ESTILOS DE ESTADO
  // ========================================

  /// Error - Texto de error
  ///
  /// Tamaño: 14px, Color: Error
  ///
  /// Ejemplo: "Este campo es obligatorio"
  static TextStyle get error => _baseStyle.copyWith(
    fontSize: 14,
    color: AppColors.error,
  );

  /// Success - Texto de éxito
  ///
  /// Tamaño: 14px, Color: Success
  ///
  /// Ejemplo: "Producto guardado correctamente"
  static TextStyle get success => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );

  /// Warning - Texto de advertencia
  ///
  /// Tamaño: 14px, Color: Warning
  ///
  /// Ejemplo: "Stock bajo"
  static TextStyle get warning => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.warning,
  );

  // ========================================
  // BADGES Y CHIPS
  // ========================================

  /// Badge - Texto para badges/insignias
  ///
  /// Tamaño: 12px, Peso: Bold
  ///
  /// Ejemplo: "NUEVO", "OFERTA"
  static TextStyle get badge => _baseStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );

  /// Chip - Texto para chips/etiquetas
  ///
  /// Tamaño: 13px, Peso: Medium
  ///
  /// Ejemplo: Categorías, tags
  static TextStyle get chip => _baseStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}

///## ✅ **¿Qué hace este archivo?**

///Define TODOS los estilos de texto que vas a usar:

///### **Headings (Títulos):**
///- `h1` → Títulos principales (32px, Bold)
///- `h2` → Subtítulos importantes (24px, Bold)
///- `h3` → Títulos de secciones (20px, SemiBold)
///- `h4` → Títulos pequeños (18px, SemiBold)

///### **Body (Texto de cuerpo):**
///- `body1` → Texto principal (16px)
///- `body2` → Texto secundario (14px)
///- `caption` → Texto pequeño (12px)

///### **Estilos Especiales:**
///- `precio` → Para mostrar precios ($12.500,50)
///- `codigo` → Para códigos de producto (OG-001)
///- `button` → Texto de botones
///- `error/success/warning` → Estados///

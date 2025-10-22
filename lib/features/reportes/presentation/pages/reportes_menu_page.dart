import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'reporte_stock_page.dart';
import 'reporte_acopios_page.dart';

/// Pantalla de Menú de Reportes
///
/// Muestra las opciones de reportes disponibles:
/// - Movimientos de Stock
/// - Acopios por Cliente
/// - Dashboard General
class ReportesMenuPage extends StatelessWidget {
  const ReportesMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('📊 Reportes'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Título de sección
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Seleccioná el tipo de reporte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),

          // Card 1: Movimientos de Stock
          _buildReporteCard(
            context,
            icono: Icons.inventory_2,
            color: AppColors.primary,
            titulo: 'Movimientos de Stock',
            descripcion: 'Entradas, salidas y ajustes de inventario',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReporteStockPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Card 2: Acopios por Cliente
          _buildReporteCard(
            context,
            icono: Icons.business,
            color: AppColors.secondary,
            titulo: 'Acopios por Cliente',
            descripcion: 'Estado de materiales por cliente y proveedor',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReporteAcopiosPage(),
                  ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Card 3: Dashboard General
          _buildReporteCard(
            context,
            icono: Icons.dashboard,
            color: AppColors.info,
            titulo: 'Dashboard General',
            descripcion: 'Estadísticas y gráficos del sistema',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Próximamente: Dashboard')),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Widget reutilizable para cada card de reporte
  Widget _buildReporteCard(
      BuildContext context, {
        required IconData icono,
        required Color color,
        required String titulo,
        required String descripcion,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icono circular
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  size: 32,
                  color: color,
                ),
              ),

              const SizedBox(width: 16),

              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../../features/stock/presentation/pages/catalogo_page.dart';
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/clientes/presentation/pages/clientes_list_page.dart';
import '../../features/obras/presentation/pages/obras_list_page.dart';
import '../../features/stock/presentation/pages/movimiento_historial_page.dart';
import '../../features/acopios/presentation/pages/acopios_list_page.dart';
import '../../features/stock/presentation/pages/consultar_disponibilidad_page.dart';
import '../../features/reportes/presentation/pages/reportes_menu_page.dart';
import '../../features/ordenes_internas/presentation/pages/ordenes_page.dart';



/// Drawer (menú lateral) de la aplicación S&G
///
/// Muestra las opciones de navegación principales:
/// - Stock
/// - Clientes
/// - Obras
/// - Pedidos
/// - Configuración
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ========================================
          // HEADER DEL DRAWER
          // ========================================
          _buildHeader(),

          // ========================================
          // OPCIONES DE NAVEGACIÓN
          // ========================================
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.book,
                  title: 'Catálogo',
                  subtitle: 'Productos disponibles',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CatalogoPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Stock',
                  subtitle: 'Inventario actual',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StockPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.warehouse,
                  title: 'Acopios',
                  subtitle: 'Materiales en proveedores',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AcopiosListPage(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.search,
                  title: 'Consultar Disponibilidad',
                  subtitle: '¿Dónde está este material?',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConsultarDisponibilidadPage(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.people,
                  title: 'Clientes',
                  subtitle: 'Gestión de clientes',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientesListPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.business,
                  title: 'Obras',
                  subtitle: 'Gestión de obras',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ObrasListPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.assessment,
                  title: 'Reportes',
                  subtitle: 'Informes y estadísticas',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportesMenuPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Órdenes Internas',
                  subtitle: 'Pedidos y despachos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrdenesPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(  // ← NUEVO
                  context,
                  icon: Icons.swap_horiz,
                  title: 'Movimientos de Stock',
                  subtitle: 'Historial y Kardex',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MovimientoHistorialPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ========================================
          // FOOTER DEL DRAWER
          // ========================================
          _buildFooter(),
        ],
      ),
    );
  }

  // ========================================
  // HEADER CON DEGRADADO
  // ========================================
  Widget _buildHeader() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Logo/Icono circular
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business_center,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),

              const SizedBox(height: 12),

              // Nombre de la empresa
              Text(
                'S&G Materiales',
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              // Subtítulo
              Text(
                'Sistema de Gestión',
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ITEM DEL MENÚ
  // ========================================
  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 28),
      title: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption,
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textLight,
      ),
      onTap: onTap,
    );
  }

  // ========================================
  // FOOTER CON VERSIÓN
  // ========================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textMedium,
          ),
          const SizedBox(width: 8),
          Text(
            'Versión 1.0.0',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
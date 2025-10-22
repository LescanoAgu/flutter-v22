import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/obra_model.dart';
import '../providers/obra_provider.dart';

/// Pantalla de Lista de Obras
class ObrasListPage extends StatefulWidget {
  const ObrasListPage({super.key});

  @override
  State<ObrasListPage> createState() => _ObrasListPageState();
}

class _ObrasListPageState extends State<ObrasListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroEstado = 'Activas';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObraProvider>().cargarObras();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text('Obras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ObraProvider>().cargarObras();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFiltroEstado(),
            _buildEstadisticas(),
            Expanded(
              child: Consumer<ObraProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.obras.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildObrasList(provider.obras);
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioObra(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Obra'),
      ),
    );
  }

  // ========================================
  // BARRA DE BÚSQUEDA
  // ========================================
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, dirección o cliente...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<ObraProvider>().cargarObras();
            },
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          context.read<ObraProvider>().buscarObras(value);
        },
      ),
    );
  }

  // ========================================
  // FILTRO POR ESTADO
  // ========================================
  Widget _buildFiltroEstado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildEstadoChip('Activas'),
          _buildEstadoChip('Pausadas'),
          _buildEstadoChip('Finalizadas'),
          _buildEstadoChip('Todas'),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    final isSelected = _filtroEstado == estado;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(estado),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroEstado = estado;
          });
          // TODO: Aplicar filtro
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ========================================
  // ESTADÍSTICAS
  // ========================================
  Widget _buildEstadisticas() {
    return Consumer<ObraProvider>(
      builder: (context, provider, child) {
        final total = provider.totalObras;

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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business, color: AppColors.primary, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.toString(),
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    'Obras activas',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // LISTA DE OBRAS
  // ========================================
  Widget _buildObrasList(List<ObraConCliente> obras) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: obras.length,
      itemBuilder: (context, index) {
        final obraConCliente = obras[index];
        return _buildObraCard(obraConCliente);
      },
    );
  }

  Widget _buildObraCard(ObraConCliente obraConCliente) {
    final obra = obraConCliente.obra;

    Color estadoColor;
    IconData estadoIcon;

    switch (obra.estado) {
      case 'activa':
        estadoColor = AppColors.success;
        estadoIcon = Icons.check_circle;
        break;
      case 'pausada':
        estadoColor = AppColors.warning;
        estadoIcon = Icons.pause_circle;
        break;
      case 'finalizada':
        estadoColor = AppColors.info;
        estadoIcon = Icons.check_circle_outline;
        break;
      case 'cancelada':
        estadoColor = AppColors.error;
        estadoIcon = Icons.cancel;
        break;
      default:
        estadoColor = AppColors.textMedium;
        estadoIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verDetalleObra(context, obra),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con código y estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      obra.codigo,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(estadoIcon, color: estadoColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    obra.estado.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Nombre de la obra
              Text(
                obra.nombre,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Cliente
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textMedium),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      obraConCliente.clienteRazonSocial,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Dirección
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.textMedium),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      obra.direccion,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // ESTADO VACÍO
  // ========================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay obras',
            style: AppTextStyles.h3.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera obra',
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  // ========================================
  // NAVEGACIÓN
  // ========================================
  void _verDetalleObra(BuildContext context, ObraModel obra) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver detalle de: ${obra.nombre}')),
    );
    // TODO: Navegar a pantalla de detalle
  }

  void _mostrarFormularioObra(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente: Formulario de obra')),
    );
    // TODO: Navegar a pantalla de formulario
  }
}
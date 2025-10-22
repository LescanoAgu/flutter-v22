import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/cliente_model.dart';
import '../providers/cliente_provider.dart';

/// Pantalla de Lista de Clientes
class ClientesListPage extends StatefulWidget {
  const ClientesListPage({super.key});

  @override
  State<ClientesListPage> createState() => _ClientesListPageState();
}

class _ClientesListPageState extends State<ClientesListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar clientes al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClienteProvider>().cargarClientes();
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
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ClienteProvider>().cargarClientes();
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
            // Barra de búsqueda
            _buildSearchBar(),

            // Estadísticas
            _buildEstadisticas(),

            // Lista de clientes
            Expanded(
              child: Consumer<ClienteProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.clientes.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildClientesList(provider.clientes);
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioCliente(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cliente'),
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
          hintText: 'Buscar por razón social, CUIT o código...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<ClienteProvider>().cargarClientes();
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
          context.read<ClienteProvider>().buscarClientes(value);
        },
      ),
    );
  }

  // ========================================
  // ESTADÍSTICAS
  // ========================================
  Widget _buildEstadisticas() {
    return Consumer<ClienteProvider>(
      builder: (context, provider, child) {
        final total = provider.totalClientes;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
              const Icon(Icons.people, color: AppColors.primary, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.toString(),
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    'Clientes activos',
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
  // LISTA DE CLIENTES
  // ========================================
  Widget _buildClientesList(List<ClienteModel> clientes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(cliente);
      },
    );
  }

  Widget _buildClienteCard(ClienteModel cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withOpacity(0.2),
          child: Text(
            cliente.razonSocial[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        title: Text(
          cliente.razonSocial,
          style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cliente.codigo,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (cliente.cuit != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'CUIT: ${cliente.cuitFormateado}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            if (cliente.condicionIva != null)
              Text(
                cliente.condicionIva!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
          ],
        ),

        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),

        onTap: () => _verDetalleCliente(context, cliente),
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
            Icons.people_outline,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay clientes',
            style: AppTextStyles.h3.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer cliente',
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  // ========================================
  // NAVEGACIÓN
  // ========================================
  void _verDetalleCliente(BuildContext context, ClienteModel cliente) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ver detalle de: ${cliente.razonSocial}')),
    );
    // TODO: Navegar a pantalla de detalle
  }

  void _mostrarFormularioCliente(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente: Formulario de cliente')),
    );
    // TODO: Navegar a pantalla de formulario
  }
}
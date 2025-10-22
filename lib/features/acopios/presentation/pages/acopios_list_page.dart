import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../data/models/acopio_model.dart';
import '../providers/acopio_provider.dart';
import 'acopio_movimiento_page.dart';
import 'facturas_list_page.dart';
import 'acopio_traspaso_page.dart';
import 'acopio_historial_page.dart';
import 'movimiento_lote_page.dart';


/// Pantalla principal de Acopios
///
/// Muestra lista de acopios con múltiples vistas:
/// - Por Cliente
/// - Por Proveedor
/// - Reservas en Depósito S&G
/// - Todos los Acopios
class AcopiosListPage extends StatefulWidget {
  const AcopiosListPage({super.key});
  @override
  State<AcopiosListPage> createState() => _AcopiosListPageState();
}

class _AcopiosListPageState extends State<AcopiosListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Cargar datos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcopioProvider>().cargarTodo();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),

      // ========================================
      // APP BAR
      // ========================================
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Acopios'),
            Consumer<AcopioProvider>(
              builder: (context, provider, child) {
                return Text(
                  '${provider.totalAcopios} registros',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textWhite,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FacturasListPage(),
                ),
              );
            },
            tooltip: 'Ver Facturas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AcopioProvider>().refrescar();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.textWhite,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Por Cliente'),
            Tab(text: 'Por Proveedor'),
            Tab(text: 'Reservas S&G'),
          ],
        ),
      ),

      // ========================================
      // BODY
      // ========================================
      body: Column(
        children: [
          // Barra de búsqueda
          _buildSearchBar(),

          // Estadísticas
          _buildEstadisticas(),

          // Contenido según tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVistaGeneral(),
                _buildVistaPorCliente(),
                _buildVistaPorProveedor(),
                _buildVistaReservas(),
              ],
            ),
          ),
        ],
      ),

      // ========================================
      // FAB
      // ========================================
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón de traspaso
          FloatingActionButton(
            heroTag: 'traspaso',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AcopioTraspasoPage(),
                ),
              ).then((resultado) {
                if (resultado == true) {
                  context.read<AcopioProvider>().cargarTodo();
                }
              });
            },
            backgroundColor: AppColors.warning,
            child: const Icon(Icons.swap_horiz),
          ),
          const SizedBox(height: 12),
          // Botón movimiento en lote
          FloatingActionButton(
            heroTag: 'lote',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MovimientoLotePage(),
                ),
              ).then((resultado) {
                if (resultado == true) {
                  context.read<AcopioProvider>().cargarTodo();
                }
              });
            },
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.playlist_add),
          ),
          const SizedBox(height: 12),
          // Botón nuevo movimiento individual
          FloatingActionButton.extended(
            heroTag: 'movimiento',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AcopioMovimientoPage(),
                ),
              ).then((resultado) {
                if (resultado == true) {
                  context.read<AcopioProvider>().cargarTodo();
                }
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('MOVIMIENTO'),
            backgroundColor: AppColors.primary,
          ),
        ],
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
          hintText: 'Buscar por producto...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<AcopioProvider>().limpiarFiltros();
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
          context.read<AcopioProvider>().buscarPorProducto(value);
          setState(() {});
        },
      ),
    );
  }

  // ========================================
  // ESTADÍSTICAS
  // ========================================

  Widget _buildEstadisticas() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEstadisticaItem(
                'Total',
                provider.totalAcopios.toString(),
                Icons.inventory_2,
                AppColors.primary,
              ),
              _buildEstadisticaItem(
                'Clientes',
                provider.totalClientes.toString(),
                Icons.people,
                AppColors.secondary,
              ),
              _buildEstadisticaItem(
                'Proveedores',
                provider.totalProveedores.toString(),
                Icons.store,
                AppColors.success,
              ),
              _buildEstadisticaItem(
                'Reservas',
                provider.totalReservas.toString(),
                Icons.bookmark,
                AppColors.warning,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadisticaItem(String label, String valor, IconData icono, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  // ========================================
  // VISTA GENERAL (TODOS)
  // ========================================

  Widget _buildVistaGeneral() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (provider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(provider.errorMessage ?? 'Error desconocido'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.cargarTodo(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (!provider.hasData) {
          return _buildEstadoVacio();
        }

        return RefreshIndicator(
          onRefresh: () => provider.refrescar(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.acopios.length,
            itemBuilder: (context, index) {
              final acopio = provider.acopios[index];
              return _AcopioCard(acopioDetalle: acopio);
            },
          ),
        );
      },
    );
  }

  // ========================================
  // VISTA POR CLIENTE
  // ========================================

  Widget _buildVistaPorCliente() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!provider.hasData) {
          return _buildEstadoVacio();
        }

        final agrupados = provider.obtenerAgrupadosPorCliente();

        return RefreshIndicator(
          onRefresh: () => provider.refrescar(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agrupados.length,
            itemBuilder: (context, index) {
              final cliente = agrupados.keys.elementAt(index);
              final acopiosCliente = agrupados[cliente]!;

              return _ClienteAcopiosCard(
                cliente: cliente,
                acopios: acopiosCliente,
              );
            },
          ),
        );
      },
    );
  }

  // ========================================
  // VISTA POR PROVEEDOR
  // ========================================

  Widget _buildVistaPorProveedor() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!provider.hasData) {
          return _buildEstadoVacio();
        }

        final agrupados = provider.obtenerAgrupadosPorProveedor();

        return RefreshIndicator(
          onRefresh: () => provider.refrescar(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agrupados.length,
            itemBuilder: (context, index) {
              final proveedor = agrupados.keys.elementAt(index);
              final acopiosProveedor = agrupados[proveedor]!;

              return _ProveedorAcopiosCard(
                proveedor: proveedor,
                acopios: acopiosProveedor,
              );
            },
          ),
        );
      },
    );
  }

  // ========================================
  // VISTA RESERVAS
  // ========================================

  Widget _buildVistaReservas() {
    return Consumer<AcopioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final reservas = provider.acopiosEnDepositoSyg;

        if (reservas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bookmark_border, size: 64, color: AppColors.textLight),
                SizedBox(height: 16),
                Text('Sin reservas en Depósito S&G'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refrescar(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final acopio = reservas[index];
              return _AcopioCard(
                acopioDetalle: acopio,
                esReserva: true,
              );
            },
          ),
        );
      },
    );
  }

  // ========================================
  // ESTADO VACÍO
  // ========================================

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.textLight),
          SizedBox(height: 16),
          Text(
            'Sin acopios registrados',
            style: TextStyle(fontSize: 18, color: AppColors.textMedium),
          ),
          SizedBox(height: 8),
          Text(
            'Los acopios aparecerán aquí',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ========================================
// CARD DE ACOPIO INDIVIDUAL
// ========================================

class _AcopioCard extends StatelessWidget {
  final AcopioDetalle acopioDetalle;
  final bool esReserva;

  const _AcopioCard({
    required this.acopioDetalle,
    this.esReserva = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: esReserva ? AppColors.warning : AppColors.border,
          width: esReserva ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AcopioHistorialPage(
                acopioDetalle: acopioDetalle,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Código de producto
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      acopioDetalle.productoCodigo,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Cantidad
                  Text(
                    acopioDetalle.cantidadFormateada,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    acopioDetalle.unidadBase,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Nombre producto
              Text(
                acopioDetalle.productoNombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // Info adicional
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppColors.textMedium),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      acopioDetalle.clienteRazonSocial,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    esReserva ? Icons.bookmark : Icons.store,
                    size: 16,
                    color: esReserva ? AppColors.warning : AppColors.textMedium,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      acopioDetalle.proveedorNombre,
                      style: TextStyle(
                        fontSize: 13,
                        color: esReserva ? AppColors.warning : AppColors.textMedium,
                        fontWeight: esReserva ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),

              if (esReserva)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⚠️ RESERVADO EN DEPÓSITO S&G',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// CARD AGRUPADO POR CLIENTE
// ========================================

class _ClienteAcopiosCard extends StatelessWidget {
  final String cliente;
  final List<AcopioDetalle> acopios;

  const _ClienteAcopiosCard({
    required this.cliente,
    required this.acopios,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(
          cliente,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${acopios.length} acopios'),
        children: acopios.map((acopio) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                acopio.productoCodigo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(acopio.productoNombre),
            subtitle: Text(
              acopio.proveedorNombre,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  acopio.cantidadFormateada,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  acopio.unidadBase,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ========================================
// CARD AGRUPADO POR PROVEEDOR
// ========================================

class _ProveedorAcopiosCard extends StatelessWidget {
  final String proveedor;
  final List<AcopioDetalle> acopios;

  const _ProveedorAcopiosCard({
    required this.proveedor,
    required this.acopios,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.successLight,
          child: Icon(Icons.store, color: AppColors.success),
        ),
        title: Text(
          proveedor,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${acopios.length} acopios'),
        children: acopios.map((acopio) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                acopio.productoCodigo,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(acopio.productoNombre),
            subtitle: Text(
              acopio.clienteRazonSocial,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  acopio.cantidadFormateada,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  acopio.unidadBase,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/repositories/stock_repository.dart';
import '../providers/producto_provider.dart';
import 'movimiento_registro_page.dart';
import '../../../acopios/presentation/pages/movimiento_lote_page.dart';

/// Pantalla de STOCK (Inventario)
///
/// Muestra los productos que tienen stock asignado.
/// Permite ajustar cantidades (entradas/salidas).
/// Los operarios NO pueden crear productos nuevos aquí.
class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final StockRepository _stockRepo = StockRepository();
  final TextEditingController _searchController = TextEditingController();

  List<ProductoConStock> _todosLosProductos = [];
  List<ProductoConStock> _productosFiltrados = [];
  bool _isLoading = true;
  String _filtroCategoria = 'Todos';
  String _filtroEstado = 'Todos';
  String _ordenamiento = 'Código';
  static const int _itemsPorPagina = 20;
  int _paginaActual = 0;
  bool _cargandoMas = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _searchController.addListener(_filtrarProductos);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Detectar cuando llega al final del scroll
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      _cargarMasProductos();
    }
  }

  Future<void> _cargarMasProductos() async {
    if (_cargandoMas) return;

    final totalProductos = _productosFiltrados.length;
    final productosMostrados = (_paginaActual + 1) * _itemsPorPagina;

    // Si ya mostramos todos, no cargar más
    if (productosMostrados >= totalProductos) return;

    setState(() {
      _cargandoMas = true;
    });

    // Simular delay de red (opcional, solo para efecto visual)
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _paginaActual++;
      _cargandoMas = false;
    });
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _paginaActual = 0;
    });

    try {
      final productos = await _stockRepo.obtenerTodosConStock(soloActivos: true);

      setState(() {
        _todosLosProductos = productos;
        _productosFiltrados = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar stock: $e')),
        );
      }
    }
  }

  void _filtrarProductos() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _productosFiltrados = _todosLosProductos.where((producto) {
        // Filtro por búsqueda
        final matchQuery = query.isEmpty ||
            producto.productoNombre.toLowerCase().contains(query) ||
            producto.productoCodigo.toLowerCase().contains(query);

        // Filtro por categoría
        final matchCategoria = _filtroCategoria == 'Todos' ||
            producto.categoriaNombre == _filtroCategoria;

        // Filtro por estado de stock
        bool matchEstado = true;
        switch (_filtroEstado) {
          case 'Con Stock':
            matchEstado = producto.cantidadDisponible > 0;
            break;
          case 'Stock Bajo':
            matchEstado = producto.cantidadDisponible < 10 && producto.cantidadDisponible > 0;
            break;
          case 'Sin Stock':
            matchEstado = producto.cantidadDisponible == 0;
            break;
          default:
            matchEstado = true;
        }

        return matchQuery && matchCategoria && matchEstado;
      }).toList();

      // Ordenamiento
      switch (_ordenamiento) {
        case 'Código':
          _productosFiltrados.sort((a, b) => a.productoCodigo.compareTo(b.productoCodigo));
          break;
        case 'Nombre':
          _productosFiltrados.sort((a, b) => a.productoNombre.compareTo(b.productoNombre));
          break;
        case 'Stock Menor':
          _productosFiltrados.sort((a, b) => a.cantidadDisponible.compareTo(b.cantidadDisponible));
          break;
        case 'Stock Mayor':
          _productosFiltrados.sort((a, b) => b.cantidadDisponible.compareTo(a.cantidadDisponible));
          break;
        case 'Categoría':
          _productosFiltrados.sort((a, b) => a.categoriaNombre.compareTo(b.categoriaNombre));
          break;
      }
      _paginaActual = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text('Stock de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProductos,
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
            // ========================================
            // BARRA DE BÚSQUEDA Y FILTROS
            // ========================================
            _buildSearchBar(),

            // ========================================
            // ESTADÍSTICAS
            // ========================================
            _buildEstadisticas(),

            // ========================================
            // LISTA DE PRODUCTOS
            // ========================================
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _productosFiltrados.isEmpty
                  ? _buildEmptyState()
                  : _buildProductList(),
            ),
          ],
        ),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
                  _cargarProductos();
                }
              });
            },
            backgroundColor: AppColors.secondary,
            child: const Icon(Icons.playlist_add),
          ),
          const SizedBox(height: 16),
          // Botón movimiento individual
          FloatingActionButton.extended(
            heroTag: 'individual',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MovimientoRegistroPage(),
                ),
              ).then((_) {
                _cargarProductos();
              });
            },            icon: const Icon(Icons.add),
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
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por código o nombre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
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
          ),

          const SizedBox(height: 12),

          // Fila de ordenamiento y filtros
          Row(
            children: [
              // Botón de ordenamiento
              Expanded(
                child: PopupMenuButton<String>(
                  initialValue: _ordenamiento,
                  onSelected: (value) {
                    setState(() {
                      _ordenamiento = value;
                      _filtrarProductos();
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Código',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha, size: 20),
                          SizedBox(width: 8),
                          Text('Por Código'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Nombre',
                      child: Row(
                        children: [
                          Icon(Icons.text_fields, size: 20),
                          SizedBox(width: 8),
                          Text('Por Nombre'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Stock Menor',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 20),
                          SizedBox(width: 8),
                          Text('Stock Menor'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Stock Mayor',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 20),
                          SizedBox(width: 8),
                          Text('Stock Mayor'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Categoría',
                      child: Row(
                        children: [
                          Icon(Icons.category, size: 20),
                          SizedBox(width: 8),
                          Text('Por Categoría'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ordenamiento,
                            style: AppTextStyles.body2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Botón de filtro por estado
              Expanded(
                child: PopupMenuButton<String>(
                  initialValue: _filtroEstado,
                  onSelected: (value) {
                    setState(() {
                      _filtroEstado = value;
                      _filtrarProductos();
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Todos',
                      child: Row(
                        children: [
                          Icon(Icons.all_inclusive, size: 20),
                          SizedBox(width: 8),
                          Text('Todos'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Con Stock',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20, color: AppColors.success),
                          SizedBox(width: 8),
                          Text('Con Stock'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Stock Bajo',
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, size: 20, color: AppColors.warning),
                          SizedBox(width: 8),
                          Text('Stock Bajo'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Sin Stock',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 20, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Sin Stock'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _filtroEstado,
                            style: AppTextStyles.body2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Filtro por categoría (chips horizontales)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoriaChip('Todos'),
                _buildCategoriaChip('Obra General'),
                _buildCategoriaChip('Hierros'),
                _buildCategoriaChip('Pintura'),
                _buildCategoriaChip('Sanitario'),
                _buildCategoriaChip('Eléctrico'),
                _buildCategoriaChip('Maderas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaChip(String categoria) {
    final isSelected = _filtroCategoria == categoria;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(categoria),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filtroCategoria = categoria;
            _filtrarProductos();
          });
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
    final totalProductos = _productosFiltrados.length;
    final stockBajo = _productosFiltrados
        .where((p) => p.cantidadDisponible < 10)
        .length;
    final sinStock = _productosFiltrados
        .where((p) => p.cantidadDisponible == 0)
        .length;

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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEstadistica(
            'Total',
            totalProductos.toString(),
            Icons.inventory_2,
            AppColors.primary,
          ),
          _buildEstadistica(
            'Stock Bajo',
            stockBajo.toString(),
            Icons.warning_amber,
            AppColors.warning,
          ),
          _buildEstadistica(
            'Sin Stock',
            sinStock.toString(),
            Icons.error_outline,
            AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadistica(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  // ========================================
  // LISTA DE PRODUCTOS
  // ========================================
  Widget _buildProductList() {
    // Calcular cuántos productos mostrar
    final totalProductos = _productosFiltrados.length;
    final productosMostrados = (_paginaActual + 1) * _itemsPorPagina;
    final productosAMostrar = productosMostrados > totalProductos
        ? totalProductos
        : productosMostrados;

    final productosVisibles = _productosFiltrados.take(productosAMostrar).toList();

    return Column(
      children: [
        // Lista de productos
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: productosVisibles.length + (_cargandoMas ? 1 : 0),
            itemBuilder: (context, index) {
              // Mostrar indicador de carga al final
              if (index == productosVisibles.length) {
                return _buildLoadingIndicator();
              }

              final productoStock = productosVisibles[index];
              return _buildProductoCard(productoStock);
            },
          ),
        ),

        // Contador de productos mostrados
        if (productosAMostrar < totalProductos)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Mostrando $productosAMostrar de $totalProductos productos',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Cargando más productos...',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(ProductoConStock productoStock) {
    final cantidad = productoStock.cantidadDisponible;

    // Determinar color según stock
    Color stockColor;

    if (cantidad == 0) {
      stockColor = AppColors.error;
    } else if (cantidad < 10) {
      stockColor = AppColors.warning;
    } else {
      stockColor = AppColors.success;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _ajustarStock(productoStock),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Indicador de stock (barra de color)
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: stockColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(width: 12),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Código
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            productoStock.productoCodigo,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nombre
                        Expanded(
                          child: Text(
                            productoStock.productoNombre,
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Categoría
                    Text(
                      productoStock.categoriaNombre,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Stock (compacto)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cantidad.toStringAsFixed(0),
                    style: AppTextStyles.h3.copyWith(color: stockColor),
                  ),
                  Text(
                    productoStock.unidadBase,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),

              // Icono de acción
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
                size: 20,
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
            Icons.inventory_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos en stock',
            style: AppTextStyles.h3.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos del catálogo al inventario',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ========================================
  // ACCIONES
  // ========================================
  void _ajustarStock(ProductoConStock productoStock) {
    // TODO: Navegar a pantalla de ajuste de stock
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ajustar stock de: ${productoStock.productoNombre}'),
      ),
    );
  }

  void _mostrarAgregarAlStock() {
    // TODO: Mostrar diálogo para seleccionar producto del catálogo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente: Agregar productos del catálogo a stock'),
      ),
    );
  }
}
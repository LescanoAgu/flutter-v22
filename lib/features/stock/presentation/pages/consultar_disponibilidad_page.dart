import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/stock_model.dart';
import '../providers/producto_provider.dart';
import '../../../acopios/presentation/providers/acopio_provider.dart';
import '../../../acopios/data/models/acopio_model.dart';

/// Pantalla de Consultar Disponibilidad
///
/// Permite buscar un material y ver:
/// - Stock disponible en depósito S&G
/// - Acopios en proveedores
/// - Total general
class ConsultarDisponibilidadPage extends StatefulWidget {
  const ConsultarDisponibilidadPage({super.key});

  @override
  State<ConsultarDisponibilidadPage> createState() => _ConsultarDisponibilidadPageState();
}

class _ConsultarDisponibilidadPageState extends State<ConsultarDisponibilidadPage> {
  final TextEditingController _searchController = TextEditingController();
  ProductoConStock? _productoSeleccionado;
  List<AcopioDetalle> _acopiosProducto = [];

  @override
  void initState() {
    super.initState();

    // Cargar datos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductoProvider>().cargarProductos();
      context.read<AcopioProvider>().cargarTodo();
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
        title: const Text('Consultar Disponibilidad'),
      ),

      // ========================================
      // BODY
      // ========================================
      body: Column(
        children: [
          // ========================================
          // BUSCADOR
          // ========================================
          _buildBuscador(),

          // ========================================
          // CONTENIDO
          // ========================================
          Expanded(
            child: _productoSeleccionado == null
                ? _buildEstadoInicial()
                : _buildResultados(),
          ),
        ],
      ),
    );
  }

  // ========================================
  // BUSCADOR
  // ========================================

  Widget _buildBuscador() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Campo de búsqueda
          Consumer<ProductoProvider>(
            builder: (context, provider, child) {
              return TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar material por código o nombre...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _productoSeleccionado = null;
                        _acopiosProducto = [];
                      });
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.length >= 3) {
                    _buscarProducto(value, provider.productos);
                  } else {
                    setState(() {
                      _productoSeleccionado = null;
                      _acopiosProducto = [];
                    });
                  }
                },
              );
            },
          ),

          if (_searchController.text.length > 0 && _searchController.text.length < 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Escribe al menos 3 caracteres para buscar',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _buscarProducto(String termino, List<ProductoConStock> productos) {
    final productoEncontrado = productos.where((p) {
      final texto = termino.toLowerCase();
      return p.productoNombre.toLowerCase().contains(texto) ||
          p.productoCodigo.toLowerCase().contains(texto);
    }).toList();

    if (productoEncontrado.isNotEmpty) {
      setState(() {
        _productoSeleccionado = productoEncontrado.first;
      });

      // Buscar acopios de este producto
      _buscarAcopiosProducto();
    } else {
      setState(() {
        _productoSeleccionado = null;
        _acopiosProducto = [];
      });
    }
  }

  Future<void> _buscarAcopiosProducto() async {
    if (_productoSeleccionado == null) return;

    final acopioProvider = context.read<AcopioProvider>();
    final todosAcopios = acopioProvider.acopios;

    setState(() {
      _acopiosProducto = todosAcopios
          .where((a) => a.acopio.productoId == _productoSeleccionado!.productoId)
          .toList();
    });
  }

  // ========================================
  // ESTADO INICIAL
  // ========================================

  Widget _buildEstadoInicial() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Busca un material',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verás el stock y acopios disponibles',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // RESULTADOS
  // ========================================

  Widget _buildResultados() {
    if (_productoSeleccionado == null) return const SizedBox.shrink();

    final totalGeneral = _productoSeleccionado!.cantidadDisponible +
        _acopiosProducto.fold(0.0, (sum, acopio) => sum + acopio.acopio.cantidadDisponible);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================
          // HEADER DEL PRODUCTO
          // ========================================
          _buildHeaderProducto(),

          const SizedBox(height: 24),

          // ========================================
          // STOCK S&G
          // ========================================
          _buildSeccionTitulo('📦 STOCK S&G'),
          const SizedBox(height: 8),
          _buildStockCard(),

          const SizedBox(height: 24),

          // ========================================
          // ACOPIOS
          // ========================================
          _buildSeccionTitulo('🏪 ACOPIOS'),
          const SizedBox(height: 8),
          _acopiosProducto.isEmpty
              ? _buildSinAcopios()
              : _buildAcopiosList(),

          const SizedBox(height: 24),

          // ========================================
          // TOTAL GENERAL
          // ========================================
          _buildTotalGeneral(totalGeneral),
        ],
      ),
    );
  }

  Widget _buildHeaderProducto() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                _productoSeleccionado!.categoriaCodigo,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _productoSeleccionado!.productoCodigo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _productoSeleccionado!.productoNombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _productoSeleccionado!.categoriaNombre,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warehouse,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Depósito Central',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _productoSeleccionado!.cantidadFormateada,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _productoSeleccionado!.unidadBase,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  if (_productoSeleccionado!.stockBajo)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '⚠️ STOCK BAJO',
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
          ],
        ),
      ),
    );
  }

  Widget _buildAcopiosList() {
    // Agrupar por proveedor
    final acopiosPorProveedor = <String, List<AcopioDetalle>>{};

    for (var acopio in _acopiosProducto) {
      final key = acopio.proveedorNombre;
      if (!acopiosPorProveedor.containsKey(key)) {
        acopiosPorProveedor[key] = [];
      }
      acopiosPorProveedor[key]!.add(acopio);
    }

    return Column(
      children: acopiosPorProveedor.entries.map((entry) {
        final proveedor = entry.key;
        final acopios = entry.value;
        final totalProveedor = acopios.fold(
          0.0,
              (sum, a) => sum + a.acopio.cantidadDisponible,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                acopios.first.esDepositoSyg ? Icons.bookmark : Icons.store,
                color: AppColors.success,
                size: 24,
              ),
            ),
            title: Text(
              proveedor,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${ArgFormats.decimal(totalProveedor)} ${_productoSeleccionado!.unidadBase} en ${acopios.length} acopio(s)',
              style: const TextStyle(fontSize: 12),
            ),
            children: acopios.map((acopio) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary, size: 18),
                ),
                title: Text(acopio.clienteRazonSocial),
                subtitle: Text(
                  acopio.clienteCodigo,
                  style: const TextStyle(fontSize: 11),
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
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      _productoSeleccionado!.unidadBase,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSinAcopios() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 8),
              Text(
                'Sin acopios de este material',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalGeneral(double total) {
    return Card(
      elevation: 6,
      color: AppColors.primaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📊 TOTAL GENERAL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
            Row(
              children: [
                Text(
                  ArgFormats.decimal(total),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _productoSeleccionado!.unidadBase,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }
}
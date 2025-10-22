import 'package:flutter/foundation.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/stock_repository.dart';

/// Provider de Productos con Stock
///
/// Maneja el estado de los productos en la aplicación.
/// Usa ChangeNotifier para notificar a la UI cuando hay cambios.
class ProductoProvider extends ChangeNotifier {
  // ========================================
  // REPOSITORIOS
  // ========================================

  final ProductoRepository _repository = ProductoRepository();
  final StockRepository _stockRepository = StockRepository();

  // ========================================
  // ESTADO
  // ========================================

  /// Lista de productos CON stock
  List<ProductoConStock> _productos = [];

  /// Producto seleccionado actualmente
  ProductoConStock? _productoSeleccionado;

  /// Estado de carga
  bool _isLoading = false;

  /// Mensaje de error (si hay)
  String? _errorMessage;

  /// Término de búsqueda actual
  String _searchTerm = '';

  /// Filtro de categoría actual (null = todas)
  int? _categoriaFiltro;

  // ========================================
  // GETTERS (lectura del estado)
  // ========================================

  /// Obtiene la lista de productos
  List<ProductoConStock> get productos => _productos;

  /// Obtiene el producto seleccionado
  ProductoConStock? get productoSeleccionado => _productoSeleccionado;

  /// Indica si está cargando
  bool get isLoading => _isLoading;

  /// Obtiene el mensaje de error
  String? get errorMessage => _errorMessage;

  /// Obtiene el término de búsqueda
  String get searchTerm => _searchTerm;

  /// Obtiene el filtro de categoría
  int? get categoriaFiltro => _categoriaFiltro;

  /// Indica si hay productos
  bool get hayProductos => _productos.isNotEmpty;

  /// Cuenta total de productos
  int get totalProductos => _productos.length;

  /// Cuenta productos con stock bajo
  int get productosStockBajo => _productos.where((p) => p.stockBajo).length;

  /// Cuenta productos sin stock
  int get productosSinStock => _productos.where((p) => p.sinStock).length;

  // ========================================
  // OPERACIONES DE CARGA
  // ========================================

  /// Carga todos los productos con su stock
  Future<void> cargarProductos() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _productos = await _stockRepository.obtenerTodosConStock();

      _isLoading = false;
      notifyListeners();

      print('✅ ${_productos.length} productos cargados en el provider');

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar productos: $e';
      notifyListeners();

      print('❌ Error al cargar productos: $e');
    }
  }

  /// Recarga los productos (útil para pull-to-refresh)
  Future<void> recargarProductos() async {
    await cargarProductos();
  }

  /// Selecciona un producto
  void seleccionarProducto(ProductoConStock? producto) {
    _productoSeleccionado = producto;
    notifyListeners();
  }

  // ========================================
  // BÚSQUEDA Y FILTROS
  // ========================================

  /// Busca productos por término
  Future<void> buscarProductos(String termino) async {
    try {
      _isLoading = true;
      _searchTerm = termino;
      _errorMessage = null;
      notifyListeners();

      if (termino.trim().isEmpty) {
        await cargarProductos();
      } else {
        _productos = await _stockRepository.buscarConStock(termino);
      }

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al buscar: $e';
      notifyListeners();

      print('❌ Error al buscar productos: $e');
    }
  }

  /// Limpia la búsqueda y recarga todos los productos
  Future<void> limpiarBusqueda() async {
    _searchTerm = '';
    await cargarProductos();
  }

  /// Filtra productos por categoría
  Future<void> filtrarPorCategoria(int? categoriaId) async {
    try {
      _isLoading = true;
      _categoriaFiltro = categoriaId;
      _errorMessage = null;
      notifyListeners();

      if (categoriaId == null) {
        await cargarProductos();
      } else {
        await cargarProductos();
        _productos = _productos
            .where((p) => p.categoriaId == categoriaId)
            .toList();
      }

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al filtrar: $e';
      notifyListeners();

      print('❌ Error al filtrar por categoría: $e');
    }
  }

  /// Limpia todos los filtros
  Future<void> limpiarFiltros() async {
    _categoriaFiltro = null;
    _searchTerm = '';
    await cargarProductos();
  }

  // ========================================
  // OPERACIONES CRUD
  // ========================================

  /// Crea un nuevo producto
  Future<bool> crearProducto(ProductoModel producto) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      int id = await _repository.crear(producto);

      await cargarProductos();

      _isLoading = false;
      notifyListeners();

      print('✅ Producto creado con id: $id');
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al crear producto: $e';
      notifyListeners();

      print('❌ Error al crear producto: $e');
      return false;
    }
  }

  /// Actualiza un producto existente
  Future<bool> actualizarProducto(ProductoModel producto) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.actualizar(producto);

      await cargarProductos();

      _isLoading = false;
      notifyListeners();

      print('✅ Producto actualizado');
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al actualizar: $e';
      notifyListeners();

      print('❌ Error al actualizar producto: $e');
      return false;
    }
  }

  /// Desactiva un producto (soft delete)
  Future<bool> desactivarProducto(int id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.desactivar(id);

      await cargarProductos();

      _isLoading = false;
      notifyListeners();

      print('✅ Producto desactivado');
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al desactivar: $e';
      notifyListeners();

      print('❌ Error al desactivar producto: $e');
      return false;
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Limpia el mensaje de error
  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reinicia el provider a su estado inicial
  void reset() {
    _productos = [];
    _productoSeleccionado = null;
    _isLoading = false;
    _errorMessage = null;
    _searchTerm = '';
    _categoriaFiltro = null;
    notifyListeners();
  }
}
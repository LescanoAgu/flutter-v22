import 'package:flutter/foundation.dart';
import '../../data/models/acopio_model.dart';
import '../../data/models/proveedor_model.dart';
import '../../data/models/movimiento_acopio_model.dart';
import '../../data/repositories/acopio_repository.dart';
import '../../data/repositories/proveedor_repository.dart';

/// Estados del provider
enum AcopioState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider de Acopios
///
/// Gestiona el estado de los acopios en la aplicación.
class AcopioProvider extends ChangeNotifier {
  // ========================================
  // REPOSITORIOS
  // ========================================

  final AcopioRepository _acopioRepo = AcopioRepository();
  final ProveedorRepository _proveedorRepo = ProveedorRepository();

  // ========================================
  // ESTADO
  // ========================================

  AcopioState _state = AcopioState.initial;
  List<AcopioDetalle> _acopios = [];
  List<ProveedorModel> _proveedores = [];
  String? _errorMessage;

  // Filtros
  int? _clienteFiltro;
  int? _proveedorFiltro;
  String _searchTerm = '';
  String? _facturaFiltro;

  // ========================================
  // GETTERS
  // ========================================

  AcopioState get state => _state;
  List<AcopioDetalle> get acopios => _acopios;
  List<ProveedorModel> get proveedores => _proveedores;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == AcopioState.loading;
  bool get hasError => _state == AcopioState.error;
  bool get hasData => _acopios.isNotEmpty;

  int? get clienteFiltro => _clienteFiltro;
  int? get proveedorFiltro => _proveedorFiltro;
  String get searchTerm => _searchTerm;
  String? get facturaFiltro => _facturaFiltro;

  // Estadísticas
  int get totalAcopios => _acopios.length;

  int get totalProveedores =>
      _acopios.map((a) => a.acopio.proveedorId).toSet().length;

  int get totalClientes =>
      _acopios.map((a) => a.acopio.clienteId).toSet().length;

  // Acopios en depósito S&G (reservas)
  List<AcopioDetalle> get acopiosEnDepositoSyg =>
      _acopios.where((a) => a.esDepositoSyg).toList();

  int get totalReservas => acopiosEnDepositoSyg.length;

  // ========================================
  // CARGAR DATOS
  // ========================================

  /// Carga todos los acopios
  Future<void> cargarAcopios() async {
    try {
      _state = AcopioState.loading;
      _errorMessage = null;
      notifyListeners();

      _acopios = await _acopioRepo.obtenerTodosConDetalle();

      _state = AcopioState.loaded;
      notifyListeners();

      print('✅ ${_acopios.length} acopios cargados');

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al cargar acopios: $e';
      notifyListeners();

      print('❌ $_errorMessage');
    }
  }

  /// Carga proveedores
  Future<void> cargarProveedores() async {
    try {
      _proveedores = await _proveedorRepo.obtenerTodos();
      notifyListeners();

      print('✅ ${_proveedores.length} proveedores cargados');

    } catch (e) {
      print('❌ Error al cargar proveedores: $e');
    }
  }

  /// Carga todo (acopios + proveedores)
  Future<void> cargarTodo() async {
    await Future.wait([
      cargarAcopios(),
      cargarProveedores(),
    ]);
  }

  /// Refresca los datos
  Future<void> refrescar() async {
    await cargarTodo();
  }

  // ========================================
  // FILTROS
  // ========================================

  /// Filtra acopios por cliente
  Future<void> filtrarPorCliente(int? clienteId) async {
    try {
      _state = AcopioState.loading;
      _clienteFiltro = clienteId;
      _proveedorFiltro = null;
      notifyListeners();

      if (clienteId == null) {
        await cargarAcopios();
      } else {
        _acopios = await _acopioRepo.obtenerPorCliente(clienteId);
        _state = AcopioState.loaded;
        notifyListeners();
      }

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al filtrar: $e';
      notifyListeners();
    }
  }

  /// Filtra acopios por proveedor
  Future<void> filtrarPorProveedor(int? proveedorId) async {
    try {
      _state = AcopioState.loading;
      _proveedorFiltro = proveedorId;
      _clienteFiltro = null;
      notifyListeners();

      if (proveedorId == null) {
        await cargarAcopios();
      } else {
        _acopios = await _acopioRepo.obtenerPorProveedor(proveedorId);
        _state = AcopioState.loaded;
        notifyListeners();
      }

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al filtrar: $e';
      notifyListeners();
    }
  }

  /// Busca acopios por producto
  Future<void> buscarPorProducto(String termino) async {
    try {
      _state = AcopioState.loading;
      _searchTerm = termino;
      notifyListeners();

      if (termino.trim().isEmpty) {
        await cargarAcopios();
      } else {
        _acopios = await _acopioRepo.buscarPorProducto(termino);
        _state = AcopioState.loaded;
        notifyListeners();
      }

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al buscar: $e';
      notifyListeners();
    }
  }

  /// Limpia todos los filtros
  Future<void> limpiarFiltros() async {
    _clienteFiltro = null;
    _proveedorFiltro = null;
    _searchTerm = '';
    _facturaFiltro = null;
    await cargarAcopios();
  }

  // ========================================
  // OPERACIONES DE MOVIMIENTOS
  // ========================================

  /// Registra entrada a acopio
  Future<bool> registrarEntrada({
    required int productoId,
    required int clienteId,
    required int proveedorId,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
    bool valorizado = false,
    double? montoValorizado,
  }) async {
    try {
      _state = AcopioState.loading;
      notifyListeners();

      await _acopioRepo.registrarMovimiento(
        productoId: productoId,
        clienteId: clienteId,
        proveedorId: proveedorId,
        tipo: TipoMovimientoAcopio.entrada,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        valorizado: valorizado,
        montoValorizado: montoValorizado,
      );

      // Recargar acopios
      await cargarAcopios();

      print('✅ Entrada registrada');
      return true;

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al registrar entrada: $e';
      notifyListeners();

      print('❌ $_errorMessage');
      return false;
    }
  }

  /// Registra salida de acopio
  Future<bool> registrarSalida({
    required int productoId,
    required int clienteId,
    required int proveedorId,
    required double cantidad,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    String? facturaNumero,
    DateTime? facturaFecha,
    bool valorizado = false,
    double? montoValorizado,
  }) async {
    try {
      _state = AcopioState.loading;
      notifyListeners();

      await _acopioRepo.registrarMovimiento(
        productoId: productoId,
        clienteId: clienteId,
        proveedorId: proveedorId,
        tipo: TipoMovimientoAcopio.salida,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        remitoNumero: remitoNumero,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        valorizado: valorizado,
        montoValorizado: montoValorizado,
      );

      // Recargar acopios
      await cargarAcopios();

      print('✅ Salida registrada');
      return true;

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = e.toString();
      notifyListeners();

      print('❌ Error: $e');
      return false;
    }
  }

  /// Registra traspaso entre acopios
  Future<bool> registrarTraspaso({
    required int productoId,
    // Origen
    required int origenClienteId,
    required int origenProveedorId,
    // Destino
    required int destinoClienteId,
    required int destinoProveedorId,
    // Cantidad
    required double cantidad,
    String? motivo,
    String? referencia,
    String? facturaNumero,
    DateTime? facturaFecha,
  }) async {
    try {
      _state = AcopioState.loading;
      notifyListeners();

      final exito = await _acopioRepo.registrarTraspaso(
        productoId: productoId,
        origenClienteId: origenClienteId,
        origenProveedorId: origenProveedorId,
        destinoClienteId: destinoClienteId,
        destinoProveedorId: destinoProveedorId,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
      );

      // Recargar acopios
      await cargarAcopios();

      print('✅ Traspaso registrado');
      return exito;

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = e.toString();
      notifyListeners();

      print('❌ Error al registrar traspaso: $e');
      return false;
    }
  }

  /// Registra movimiento en lote (múltiples productos)
  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items,
    required int clienteId,
    required int proveedorId,
    required TipoMovimientoAcopio tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
    bool valorizado = false,
  }) async {
    try {
      _state = AcopioState.loading;
      notifyListeners();

      final exito = await _acopioRepo.registrarMovimientoEnLote(
        items: items,
        clienteId: clienteId,
        proveedorId: proveedorId,
        tipo: tipo,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        motivo: motivo,
        referencia: referencia,
        valorizado: valorizado,
      );

      // Recargar acopios
      await cargarAcopios();

      print('✅ Movimiento en lote registrado');
      return exito;

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = e.toString();
      notifyListeners();

      print('❌ Error al registrar lote: $e');
      return false;
    }
  }

  // ========================================
  // FILTRO POR FACTURA
  // ========================================

  /// Obtiene facturas únicas con sus estadísticas
  Future<List<Map<String, dynamic>>> obtenerFacturasUnicas() async {
    try {
      return await _acopioRepo.obtenerFacturasUnicas();
    } catch (e) {
      print('❌ Error al obtener facturas: $e');
      return [];
    }
  }

  /// Filtra acopios por número de factura
  Future<void> filtrarPorFactura(String? facturaNumero) async {
    try {
      _state = AcopioState.loading;
      _facturaFiltro = facturaNumero;
      _clienteFiltro = null;
      _proveedorFiltro = null;
      notifyListeners();

      if (facturaNumero == null || facturaNumero.isEmpty) {
        await cargarAcopios();
      } else {
        // Obtener movimientos de esta factura
        final movimientos = await _acopioRepo.obtenerMovimientosPorFactura(facturaNumero);

        // Obtener los acopios relacionados
        final acopiosIds = movimientos
            .where((m) => m.origenId != null)
            .map((m) => m.origenId!)
            .toSet()
            .toList();

        // Cargar los detalles de esos acopios
        _acopios = await _acopioRepo.obtenerTodosConDetalle(soloActivos: false);
        _acopios = _acopios.where((a) => acopiosIds.contains(a.acopio.id)).toList();

        _state = AcopioState.loaded;
        notifyListeners();
      }

    } catch (e) {
      _state = AcopioState.error;
      _errorMessage = 'Error al filtrar por factura: $e';
      notifyListeners();
    }
  }

  /// Obtiene resumen completo de una factura
  Future<Map<String, dynamic>> obtenerResumenFactura(String facturaNumero) async {
    try {
      return await _acopioRepo.obtenerResumenPorFactura(facturaNumero);
    } catch (e) {
      print('❌ Error al obtener resumen de factura: $e');
      return {};
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Obtiene acopios agrupados por proveedor
  Map<String, List<AcopioDetalle>> obtenerAgrupadosPorProveedor() {
    final Map<String, List<AcopioDetalle>> agrupados = {};

    for (var acopio in _acopios) {
      final key = acopio.proveedorNombre;
      if (!agrupados.containsKey(key)) {
        agrupados[key] = [];
      }
      agrupados[key]!.add(acopio);
    }

    return agrupados;
  }

  /// Obtiene acopios agrupados por cliente
  Map<String, List<AcopioDetalle>> obtenerAgrupadosPorCliente() {
    final Map<String, List<AcopioDetalle>> agrupados = {};

    for (var acopio in _acopios) {
      final key = acopio.clienteRazonSocial;
      if (!agrupados.containsKey(key)) {
        agrupados[key] = [];
      }
      agrupados[key]!.add(acopio);
    }

    return agrupados;
  }

  /// Limpia el estado
  void limpiar() {
    _state = AcopioState.initial;
    _acopios = [];
    _proveedores = [];
    _errorMessage = null;
    _clienteFiltro = null;
    _proveedorFiltro = null;
    _searchTerm = '';
    _facturaFiltro = null;
    notifyListeners();
  }

  /// Obtiene el historial de movimientos de un acopio específico
  Future<List<MovimientoAcopioModel>> obtenerHistorialAcopio({
    required int productoId,
    required int clienteId,
    required int proveedorId,
  }) async {
    try {
      return await _acopioRepo.obtenerHistorialAcopio(
        productoId: productoId,
        clienteId: clienteId,
        proveedorId: proveedorId,
      );
    } catch (e) {
      print('❌ Error en provider al obtener historial: $e');
      return [];
    }
  }

}
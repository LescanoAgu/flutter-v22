// Provider para gestionar movimientos de stock (Sistema Kardex)
// Maneja entradas, salidas, ajustes y consulta de historial

import 'package:flutter/foundation.dart';
import '../../data/models/movimiento_stock_model.dart';
import '../../data/repositories/movimiento_stock_repository.dart';

/// Estados posibles del provider
enum MovimientoStockState {
  initial,
  loading,
  loaded,
  error,
  registering,  // Cuando está registrando un movimiento
}

class MovimientoStockProvider extends ChangeNotifier {
  // ========================================
  // REPOSITORIO
  // ========================================

  final MovimientoStockRepository _repository = MovimientoStockRepository();

  // ========================================
  // ESTADO
  // ========================================

  MovimientoStockState _state = MovimientoStockState.initial;
  List<MovimientoStock> _movimientos = [];
  String? _errorMessage;

  // Filtros actuales
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  TipoMovimiento? _tipoFiltro;
  int? _productoFiltro;

  // ========================================
  // GETTERS
  // ========================================

  MovimientoStockState get state => _state;

  List<MovimientoStock> get movimientos => _movimientos;

  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == MovimientoStockState.loading;

  bool get isRegistering => _state == MovimientoStockState.registering;

  bool get hasError => _state == MovimientoStockState.error;

  bool get hasData => _movimientos.isNotEmpty;

  DateTime? get fechaDesde => _fechaDesde;

  DateTime? get fechaHasta => _fechaHasta;

  TipoMovimiento? get tipoFiltro => _tipoFiltro;

  int? get productoFiltro => _productoFiltro;

  // Estadísticas
  int get totalMovimientos => _movimientos.length;

  int get totalEntradas =>
      _movimientos
          .where((m) => m.tipo == TipoMovimiento.entrada)
          .length;

  int get totalSalidas =>
      _movimientos
          .where((m) => m.tipo == TipoMovimiento.salida)
          .length;

  int get totalAjustes =>
      _movimientos
          .where((m) => m.tipo == TipoMovimiento.ajuste)
          .length;

  // ========================================
  // OPERACIONES PRINCIPALES
  // ========================================

  /// Registra un nuevo movimiento de stock
  ///
  /// Esta es la operación MÁS IMPORTANTE del sistema Kardex.
  /// Actualiza el stock Y registra el movimiento en el historial.
  ///
  /// Ejemplo:
  /// ```dart
  /// bool exito = await provider.registrarMovimiento(
  ///   productoId: 1,
  ///   tipo: TipoMovimiento.entrada,
  ///   cantidad: 100,
  ///   motivo: 'Compra a proveedor',
  ///   referencia: 'OC-001',
  /// );
  /// ```
  Future<bool> registrarMovimiento({
    required int productoId,
    required TipoMovimiento tipo,
    required double cantidad,
    String? motivo,
    String? referencia,
    int? usuarioId,
  }) async {
    try {
      // Cambiar estado a "registrando"
      _state = MovimientoStockState.registering;
      _errorMessage = null;
      notifyListeners();

      // Llamar al repositorio para hacer el movimiento
      final movimiento = await _repository.registrarMovimiento(
        productoId: productoId,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        referencia: referencia,
        usuarioId: usuarioId,
      );

      // Agregar el nuevo movimiento al inicio de la lista
      _movimientos.insert(0, movimiento);

      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ Movimiento registrado: ${tipo.name} de $cantidad unidades');
      return true;
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = e.toString();
      notifyListeners();

      print('❌ Error al registrar movimiento: $e');
      return false;
    }
  }

  /// Carga los movimientos de un producto específico
  ///
  /// Ejemplo:
  /// ```dart
  /// await provider.cargarMovimientosDeProducto(productoId: 5);
  /// ```
  Future<void> cargarMovimientosDeProducto(int productoId) async {
    try {
      _state = MovimientoStockState.loading;
      _errorMessage = null;
      _productoFiltro = productoId;
      notifyListeners();

      _movimientos = await _repository.getMovimientosPorProducto(productoId);

      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ ${_movimientos
          .length} movimientos cargados del producto $productoId');
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = 'Error al cargar movimientos: $e';
      notifyListeners();

      print('❌ $_errorMessage');
    }
  }

  /// Carga movimientos con filtros opcionales
  ///
  /// Permite filtrar por:
  /// - Rango de fechas
  /// - Tipo de movimiento
  /// - Límite de resultados
  ///
  /// Ejemplo:
  /// ```dart
  /// await provider.cargarMovimientos(
  ///   desde: DateTime(2025, 1, 1),
  ///   hasta: DateTime.now(),
  ///   tipo: TipoMovimiento.salida,
  ///   limit: 50,
  /// );
  /// ```
  Future<void> cargarMovimientos({
    DateTime? desde,
    DateTime? hasta,
    TipoMovimiento? tipo,
    int? limit,
  }) async {
    try {
      _state = MovimientoStockState.loading;
      _errorMessage = null;
      _fechaDesde = desde;
      _fechaHasta = hasta;
      _tipoFiltro = tipo;
      notifyListeners();

      _movimientos = await _repository.getMovimientos(
        desde: desde,
        hasta: hasta,
        tipo: tipo,
        limit: limit,
      );

      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ ${_movimientos.length} movimientos cargados con filtros');
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = 'Error al cargar movimientos: $e';
      notifyListeners();

      print('❌ $_errorMessage');
    }
  }

  /// Obtiene el último movimiento de un producto
  Future<MovimientoStock?> obtenerUltimoMovimiento(int productoId) async {
    try {
      return await _repository.getUltimoMovimiento(productoId);
    } catch (e) {
      print('❌ Error al obtener último movimiento: $e');
      return null;
    }
  }

  /// Cancela un movimiento (crea un movimiento inverso)
  ///
  /// Ejemplo: Si registraste una salida por error, esto crea
  /// una entrada automática que "cancela" ese movimiento.
  ///
  /// IMPORTANTE: No borra el movimiento original, crea uno nuevo inverso.
  Future<bool> cancelarMovimiento(int movimientoId) async {
    try {
      _state = MovimientoStockState.registering;
      _errorMessage = null;
      notifyListeners();

      final movimientoCancelacion = await _repository.cancelarMovimiento(
          movimientoId);

      // Agregar el movimiento de cancelación a la lista
      _movimientos.insert(0, movimientoCancelacion);

      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ Movimiento cancelado');
      return true;
    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = 'Error al cancelar movimiento: $e';
      notifyListeners();

      print('❌ $_errorMessage');
      return false;
    }
  }

  // ========================================
  // FILTROS
  // ========================================

  /// Aplica un filtro por rango de fechas
  void filtrarPorFechas(DateTime? desde, DateTime? hasta) {
    cargarMovimientos(
      desde: desde,
      hasta: hasta,
      tipo: _tipoFiltro,
    );
  }

  /// Aplica un filtro por tipo de movimiento
  void filtrarPorTipo(TipoMovimiento? tipo) {
    cargarMovimientos(
      desde: _fechaDesde,
      hasta: _fechaHasta,
      tipo: tipo,
    );
  }

  /// Limpia todos los filtros
  Future<void> limpiarFiltros() async {
    _fechaDesde = null;
    _fechaHasta = null;
    _tipoFiltro = null;
    _productoFiltro = null;
    await cargarMovimientos();
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Limpia el estado del provider
  void limpiar() {
    _state = MovimientoStockState.initial;
    _movimientos = [];
    _errorMessage = null;
    _fechaDesde = null;
    _fechaHasta = null;
    _tipoFiltro = null;
    _productoFiltro = null;
    notifyListeners();
  }
  Future<void> refrescar() async {
    if (_productoFiltro != null) {
      await cargarMovimientosDeProducto(_productoFiltro!);
    } else {
      await cargarMovimientos(
        desde: _fechaDesde,
        hasta: _fechaHasta,
        tipo: _tipoFiltro,
      );
    }
  }
  /// Registra movimiento en lote (múltiples productos)
  Future<bool> registrarMovimientoEnLote({
    required List<Map<String, dynamic>> items,
    required TipoMovimiento tipo,
    String? facturaNumero,
    DateTime? facturaFecha,
    String? motivo,
    String? referencia,
    String? remitoNumero,
    bool valorizado = false,
    int? usuarioId,
  }) async {
    try {
      _state = MovimientoStockState.registering;
      _errorMessage = null;
      notifyListeners();

      // Llamar al repositorio
      final exito = await _repository.registrarMovimientoEnLote(
        items: items,
        tipo: tipo,
        facturaNumero: facturaNumero,
        facturaFecha: facturaFecha,
        motivo: motivo,
        referencia: referencia,
        remitoNumero: remitoNumero,
        valorizado: valorizado,
        usuarioId: usuarioId,
      );

      _state = MovimientoStockState.loaded;
      notifyListeners();

      print('✅ Movimiento en lote registrado');
      return exito;

    } catch (e) {
      _state = MovimientoStockState.error;
      _errorMessage = 'Error al registrar lote: $e';
      notifyListeners();

      print('❌ Error: $e');
      return false;
    }
  }
}
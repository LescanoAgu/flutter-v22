import 'package:flutter/foundation.dart';
import '../../data/models/orden_interna_model.dart';
import '../../data/repositories/orden_interna_repository.dart';

/// Estados posibles del provider
enum OrdenInternaState {
  initial,
  loading,
  loaded,
  error,
  creating,
  updating,
}

/// Provider de Órdenes Internas
///
/// Maneja el estado de las órdenes en la UI:
/// - Lista de órdenes
/// - Filtros
/// - Crear nuevas órdenes
/// - Aprobar/Rechazar
class OrdenInternaProvider extends ChangeNotifier {
  final OrdenInternaRepository _repository = OrdenInternaRepository();

  // ========================================
  // ESTADO
  // ========================================

  OrdenInternaState _state = OrdenInternaState.initial;
  List<OrdenInternaDetalle> _ordenes = [];
  OrdenInternaDetalle? _ordenSeleccionada;
  String? _errorMessage;

  // Filtros
  String? _estadoFiltro;
  int? _clienteFiltro;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  // Estadísticas
  Map<String, int> _estadisticasPorEstado = {};

  // ========================================
  // GETTERS
  // ========================================

  OrdenInternaState get state => _state;
  List<OrdenInternaDetalle> get ordenes => _ordenes;
  OrdenInternaDetalle? get ordenSeleccionada => _ordenSeleccionada;
  String? get errorMessage => _errorMessage;
  String? get estadoFiltro => _estadoFiltro;
  int? get clienteFiltro => _clienteFiltro;
  DateTime? get fechaDesde => _fechaDesde;
  DateTime? get fechaHasta => _fechaHasta;
  Map<String, int> get estadisticasPorEstado => _estadisticasPorEstado;

  bool get isLoading => _state == OrdenInternaState.loading;
  bool get isCreating => _state == OrdenInternaState.creating;
  bool get isUpdating => _state == OrdenInternaState.updating;
  bool get hasError => _state == OrdenInternaState.error;
  bool get hasData => _ordenes.isNotEmpty;

  // Contadores por estado
  int get totalOrdenes => _ordenes.length;
  int get ordenesSolicitadas => _estadisticasPorEstado['solicitado'] ?? 0;
  int get ordenesEnPreparacion => _estadisticasPorEstado['en_preparacion'] ?? 0;
  int get ordenesListasEnvio => _estadisticasPorEstado['listo_envio'] ?? 0;
  int get ordenesDespachadas => _estadisticasPorEstado['despachado'] ?? 0;

  // ========================================
  // CREAR ORDEN
  // ========================================

  /// Crea una nueva orden interna
  ///
  /// Ejemplo:
  /// ```dart
  /// final exito = await provider.crearOrden(
  ///   clienteId: 1,
  ///   solicitanteNombre: 'Juan Pérez',
  ///   items: [
  ///     {'productoId': 5, 'cantidad': 100.0, 'precio': 1500.0},
  ///   ],
  /// );
  /// ```
  Future<bool> crearOrden({
    required int clienteId,
    int? obraId,
    required String solicitanteNombre,
    String? solicitanteEmail,
    String? solicitanteTelefono,
    DateTime? fechaEntregaEstimada,
    String? observacionesCliente,
    required List<Map<String, dynamic>> items,
    int? usuarioCreadorId,
  }) async {
    try {
      _state = OrdenInternaState.creating;
      _errorMessage = null;
      notifyListeners();

      final ordenId = await _repository.crearOrden(
        clienteId: clienteId,
        obraId: obraId,
        solicitanteNombre: solicitanteNombre,
        solicitanteEmail: solicitanteEmail,
        solicitanteTelefono: solicitanteTelefono,
        fechaEntregaEstimada: fechaEntregaEstimada,
        observacionesCliente: observacionesCliente,
        items: items,
        usuarioCreadorId: usuarioCreadorId,
      );

      // Recargar lista
      await cargarOrdenes();

      print('✅ Orden creada con ID: $ordenId');
      return true;

    } catch (e) {
      _state = OrdenInternaState.error;
      _errorMessage = 'Error al crear orden: $e';
      notifyListeners();

      print('❌ $_errorMessage');
      return false;
    }
  }

  // ========================================
  // CARGAR ÓRDENES
  // ========================================

  /// Carga órdenes con los filtros actuales
  Future<void> cargarOrdenes({
    String? estado,
    int? clienteId,
    DateTime? desde,
    DateTime? hasta,
    int? limit,
  }) async {
    try {
      _state = OrdenInternaState.loading;
      _errorMessage = null;
      notifyListeners();

      // Actualizar filtros si se proporcionan
      if (estado != null) _estadoFiltro = estado;
      if (clienteId != null) _clienteFiltro = clienteId;
      if (desde != null) _fechaDesde = desde;
      if (hasta != null) _fechaHasta = hasta;

      _ordenes = await _repository.getOrdenes(
        estado: _estadoFiltro,
        clienteId: _clienteFiltro,
        desde: _fechaDesde,
        hasta: _fechaHasta,
        limit: limit,
      );

      // Cargar estadísticas
      await _cargarEstadisticas();

      _state = OrdenInternaState.loaded;
      notifyListeners();

      print('✅ ${_ordenes.length} órdenes cargadas');

    } catch (e) {
      _state = OrdenInternaState.error;
      _errorMessage = 'Error al cargar órdenes: $e';
      notifyListeners();

      print('❌ $_errorMessage');
    }
  }

  /// Carga órdenes pendientes de aprobación
  Future<void> cargarOrdenesPendientes() async {
    await cargarOrdenes(estado: 'solicitado');
  }

  /// Carga órdenes de un cliente específico
  Future<void> cargarOrdenesPorCliente(int clienteId) async {
    await cargarOrdenes(clienteId: clienteId);
  }

  /// Carga una orden específica por ID
  Future<void> cargarOrdenPorId(int ordenId) async {
    try {
      _state = OrdenInternaState.loading;
      _errorMessage = null;
      notifyListeners();

      _ordenSeleccionada = await _repository.getOrdenPorId(ordenId);

      _state = OrdenInternaState.loaded;
      notifyListeners();

      if (_ordenSeleccionada != null) {
        print('✅ Orden ${_ordenSeleccionada!.orden.numero} cargada');
      }

    } catch (e) {
      _state = OrdenInternaState.error;
      _errorMessage = 'Error al cargar orden: $e';
      notifyListeners();

      print('❌ $_errorMessage');
    }
  }

  // ========================================
  // APROBAR / RECHAZAR
  // ========================================

  /// Aprueba una orden
  Future<bool> aprobarOrden({
    required int ordenId,
    required int aprobadoPorUsuarioId,
    List<Map<String, dynamic>>? itemsAjustados,
    String? observacionesInternas,
  }) async {
    try {
      _state = OrdenInternaState.updating;
      _errorMessage = null;
      notifyListeners();

      final exito = await _repository.aprobarOrden(
        ordenId: ordenId,
        aprobadoPorUsuarioId: aprobadoPorUsuarioId,
        itemsAjustados: itemsAjustados,
        observacionesInternas: observacionesInternas,
      );

      if (exito) {
        await cargarOrdenes();
        print('✅ Orden aprobada exitosamente');
      }

      return exito;

    } catch (e) {
      _state = OrdenInternaState.error;
      _errorMessage = 'Error al aprobar orden: $e';
      notifyListeners();

      print('❌ $_errorMessage');
      return false;
    }
  }

  /// Rechaza una orden
  Future<bool> rechazarOrden({
    required int ordenId,
    required int rechazadoPorUsuarioId,
    required String motivoRechazo,
  }) async {
    try {
      _state = OrdenInternaState.updating;
      _errorMessage = null;
      notifyListeners();

      final exito = await _repository.rechazarOrden(
        ordenId: ordenId,
        rechazadoPorUsuarioId: rechazadoPorUsuarioId,
        motivoRechazo: motivoRechazo,
      );

      if (exito) {
        await cargarOrdenes();
        print('✅ Orden rechazada');
      }

      return exito;

    } catch (e) {
      _state = OrdenInternaState.error;
      _errorMessage = 'Error al rechazar orden: $e';
      notifyListeners();

      print('❌ $_errorMessage');
      return false;
    }
  }

  // ========================================
  // CAMBIAR ESTADOS
  // ========================================

  /// Cambia el estado de una orden
  Future<bool> cambiarEstado({
    required int ordenId,
    required String nuevoEstado,
    int? usuarioId,
  }) async {
    try {
      _state = OrdenInternaState.updating;
      _errorMessage = null;
      notifyListeners();

      final exito = await _repository.cambiarEstado(
        ordenId: ordenId,
        nuevoEstado: nuevoEstado,
        usuarioId: usuarioId,
      );

      if (exito) {
        await cargarOrdenes();
        print('✅ Estado cambiado a: $nuevoEstado');
      }

      return exito;

    } catch (e) {
      _state = OrdenInternaState.error;
      _errorMessage = 'Error al cambiar estado: $e';
      notifyListeners();

      print('❌ $_errorMessage');
      return false;
    }
  }

  /// Marca como lista para envío
  Future<bool> marcarListoEnvio(int ordenId) async {
    return await cambiarEstado(ordenId: ordenId, nuevoEstado: 'listo_envio');
  }

  /// Marca como despachado
  Future<bool> marcarDespachado(int ordenId) async {
    return await cambiarEstado(ordenId: ordenId, nuevoEstado: 'despachado');
  }

  /// Cancela una orden
  Future<bool> cancelarOrden(int ordenId) async {
    return await cambiarEstado(ordenId: ordenId, nuevoEstado: 'cancelado');
  }

  // ========================================
  // FILTROS
  // ========================================

  /// Aplica filtro por estado
  void filtrarPorEstado(String? estado) {
    cargarOrdenes(estado: estado);
  }

  /// Aplica filtro por cliente
  void filtrarPorCliente(int? clienteId) {
    cargarOrdenes(clienteId: clienteId);
  }

  /// Aplica filtro por rango de fechas
  void filtrarPorFechas(DateTime? desde, DateTime? hasta) {
    cargarOrdenes(desde: desde, hasta: hasta);
  }

  /// Limpia todos los filtros
  Future<void> limpiarFiltros() async {
    _estadoFiltro = null;
    _clienteFiltro = null;
    _fechaDesde = null;
    _fechaHasta = null;
    await cargarOrdenes();
  }

  // ========================================
  // ESTADÍSTICAS
  // ========================================

  /// Carga estadísticas de órdenes por estado
  Future<void> _cargarEstadisticas() async {
    try {
      _estadisticasPorEstado = await _repository.getEstadisticasPorEstado();
    } catch (e) {
      print('❌ Error al cargar estadísticas: $e');
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Limpia el estado del provider
  void limpiar() {
    _state = OrdenInternaState.initial;
    _ordenes = [];
    _ordenSeleccionada = null;
    _errorMessage = null;
    _estadoFiltro = null;
    _clienteFiltro = null;
    _fechaDesde = null;
    _fechaHasta = null;
    _estadisticasPorEstado = {};
    notifyListeners();
  }

  /// Refresca las órdenes
  Future<void> refrescar() async {
    await cargarOrdenes();
  }

  /// Deselecciona la orden actual
  void deseleccionarOrden() {
    _ordenSeleccionada = null;
    notifyListeners();
  }
}
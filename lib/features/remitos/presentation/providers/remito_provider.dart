import 'package:flutter/foundation.dart';

import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/data/repositories/cliente_repository.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../obras/data/repositories/obra_repository.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../../stock/data/repositories/producto_repository.dart';
import '../../data/models/remito_model.dart';
import '../../data/repositories/remito_repository.dart';

class RemitoProvider extends ChangeNotifier {
  final RemitoRepository _remitoRepository = RemitoRepository();
  final ClienteRepository _clienteRepository = ClienteRepository();
  final ObraRepository _obraRepository = ObraRepository();
  final ProductoRepository _productoRepository = ProductoRepository();

  List<RemitoResumen> _remitos = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;

  List<RemitoResumen> get remitos => _remitos;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get errorMessage => _errorMessage;
  bool get hayRemitos => _remitos.isNotEmpty;

  Future<void> cargarRemitos({String? estado}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _remitos = await _remitoRepository.obtenerResumen(estado: estado);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar remitos: $e';
      notifyListeners();
    }
  }

  Future<void> refrescarRemitos() async {
    try {
      _remitos = await _remitoRepository.obtenerResumen();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al actualizar remitos: $e';
      notifyListeners();
    }
  }

  Future<bool> crearRemitoRapido({
    required int clienteId,
    int? obraId,
    String? observaciones,
    required List<Map<String, dynamic>> items,
    String? transporte,
    String? chofer,
    String? patente,
    DateTime? fechaEntrega,
  }) async {
    try {
      _isCreating = true;
      _errorMessage = null;
      notifyListeners();

      await _remitoRepository.crearRemito(
        clienteId: clienteId,
        obraId: obraId,
        observaciones: observaciones,
        transporte: transporte,
        chofer: chofer,
        patente: patente,
        fechaEntrega: fechaEntrega,
        items: items,
      );

      _isCreating = false;
      await refrescarRemitos();
      return true;
    } catch (e) {
      _isCreating = false;
      _errorMessage = 'Error al crear remito: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<ClienteModel>> obtenerClientesActivos() async {
    return _clienteRepository.obtenerTodos();
  }

  Future<List<ObraModel>> obtenerObrasPorCliente(int clienteId) async {
    return _obraRepository.obtenerPorCliente(clienteId);
  }

  Future<List<ProductoModel>> obtenerProductosActivos() async {
    return _productoRepository.obtenerTodos();
  }

  Future<List<RemitoItemDetalle>> obtenerItems(int remitoId) {
    return _remitoRepository.obtenerItems(remitoId);
  }
}

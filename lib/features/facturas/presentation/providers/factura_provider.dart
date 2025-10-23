import 'package:flutter/foundation.dart';

import '../../../clientes/data/models/cliente_model.dart';
import '../../../clientes/data/repositories/cliente_repository.dart';
import '../../../obras/data/models/obra_model.dart';
import '../../../obras/data/repositories/obra_repository.dart';
import '../../../stock/data/models/producto_model.dart';
import '../../../stock/data/repositories/producto_repository.dart';
import '../../data/models/factura_model.dart';
import '../../data/repositories/factura_repository.dart';

class FacturaProvider extends ChangeNotifier {
  final FacturaRepository _facturaRepository = FacturaRepository();
  final ClienteRepository _clienteRepository = ClienteRepository();
  final ObraRepository _obraRepository = ObraRepository();
  final ProductoRepository _productoRepository = ProductoRepository();

  List<FacturaResumen> _facturas = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isRegisteringPayment = false;
  String? _errorMessage;

  List<FacturaResumen> get facturas => _facturas;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isRegisteringPayment => _isRegisteringPayment;
  String? get errorMessage => _errorMessage;
  bool get hayFacturas => _facturas.isNotEmpty;

  Future<void> cargarFacturas({String? estado}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _facturas = await _facturaRepository.obtenerResumen(estado: estado);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar facturas: $e';
      notifyListeners();
    }
  }

  Future<void> refrescarFacturas() async {
    try {
      _facturas = await _facturaRepository.obtenerResumen();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al refrescar facturas: $e';
      notifyListeners();
    }
  }

  Future<bool> crearFacturaRapida({
    required int clienteId,
    int? obraId,
    String tipo = 'B',
    DateTime? fechaEmision,
    DateTime? fechaVencimiento,
    String? condicionPago,
    String? observaciones,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      _isCreating = true;
      _errorMessage = null;
      notifyListeners();

      await _facturaRepository.crearFactura(
        clienteId: clienteId,
        obraId: obraId,
        tipo: tipo,
        fechaEmision: fechaEmision,
        fechaVencimiento: fechaVencimiento,
        condicionPago: condicionPago,
        observaciones: observaciones,
        items: items,
      );

      _isCreating = false;
      await refrescarFacturas();
      return true;
    } catch (e) {
      _isCreating = false;
      _errorMessage = 'Error al crear factura: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarPago({
    required int facturaId,
    required double monto,
    DateTime? fecha,
    String? metodo,
    String? referencia,
    String? observaciones,
  }) async {
    try {
      _isRegisteringPayment = true;
      _errorMessage = null;
      notifyListeners();

      await _facturaRepository.registrarPago(
        facturaId: facturaId,
        monto: monto,
        fecha: fecha ?? DateTime.now(),
        metodo: metodo,
        referencia: referencia,
        observaciones: observaciones,
      );

      _isRegisteringPayment = false;
      await refrescarFacturas();
      return true;
    } catch (e) {
      _isRegisteringPayment = false;
      _errorMessage = 'Error al registrar pago: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<FacturaItemDetalle>> obtenerItems(int facturaId) {
    return _facturaRepository.obtenerItems(facturaId);
  }

  Future<List<PagoModel>> obtenerPagos(int facturaId) {
    return _facturaRepository.obtenerPagos(facturaId);
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
}

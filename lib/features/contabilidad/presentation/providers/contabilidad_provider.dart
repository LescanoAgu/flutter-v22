import 'package:flutter/material.dart';

import '../../data/models/asiento_model.dart';
import '../../data/models/cuenta_contable_model.dart';
import '../../data/repositories/contabilidad_repository.dart';

class ContabilidadProvider extends ChangeNotifier {
  final ContabilidadRepository _repository = ContabilidadRepository();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<AsientoResumen> _asientos = [];
  List<CuentaContableModel> _cuentas = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<AsientoResumen> get asientos => _asientos;
  List<CuentaContableModel> get cuentas => _cuentas;

  double get totalDebe => _asientos.fold<double>(
        0,
        (prev, asiento) => prev + asiento.totalDebe,
      );
  double get totalHaber => _asientos.fold<double>(
        0,
        (prev, asiento) => prev + asiento.totalHaber,
      );
  double get diferencia => totalDebe - totalHaber;

  Future<void> cargarDatosIniciales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final asientos = await _repository.obtenerAsientos();
      final cuentas = await _repository.obtenerCuentas();

      _asientos = asientos;
      _cuentas = cuentas;
    } catch (e) {
      _errorMessage = 'Error al cargar contabilidad: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarAsientos({String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _asientos = await _repository.obtenerAsientos(search: search);
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los asientos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cargarCuentas() async {
    try {
      _cuentas = await _repository.obtenerCuentas();
    } catch (e) {
      _errorMessage = 'No se pudieron cargar las cuentas: $e';
    }

    notifyListeners();
  }

  Future<List<AsientoMovimientoModel>> obtenerMovimientos(int asientoId) {
    return _repository.obtenerMovimientos(asientoId);
  }

  Future<bool> crearAsientoManual({
    required DateTime fecha,
    String? descripcion,
    required int cuentaDebeId,
    required int cuentaHaberId,
    required double monto,
    String? detalleDebe,
    String? detalleHaber,
  }) async {
    if (monto <= 0) {
      _errorMessage = 'El monto debe ser mayor a cero.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.crearAsiento(
        fecha: fecha,
        descripcion: descripcion,
        movimientos: [
          AsientoMovimientoInput(
            cuentaId: cuentaDebeId,
            debe: monto,
            detalle: detalleDebe,
          ),
          AsientoMovimientoInput(
            cuentaId: cuentaHaberId,
            haber: monto,
            detalle: detalleHaber,
          ),
        ],
      );

      await cargarAsientos();
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo registrar el asiento: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> refrescar() async {
    await Future.wait([
      cargarAsientos(),
      cargarCuentas(),
    ]);
  }
}

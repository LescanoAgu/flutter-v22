import 'package:flutter/material.dart';
import '../../data/models/cliente_model.dart';
import '../../data/repositories/cliente_repository.dart';

/// Provider de Clientes
///
/// Gestiona el estado de los clientes en la aplicación.
/// Usa ChangeNotifier para notificar cambios a los widgets.
class ClienteProvider extends ChangeNotifier {
  final ClienteRepository _repository = ClienteRepository();

  // Lista de clientes cargados
  List<ClienteModel> _clientes = [];

  // Estado de carga
  bool _isLoading = false;

  // Cliente seleccionado actualmente
  ClienteModel? _clienteSeleccionado;

  // Getters
  List<ClienteModel> get clientes => _clientes;
  bool get isLoading => _isLoading;
  ClienteModel? get clienteSeleccionado => _clienteSeleccionado;
  int get totalClientes => _clientes.length;

  // ========================================
  // CARGAR CLIENTES
  // ========================================

  /// Carga todos los clientes desde la base de datos
  Future<void> cargarClientes({bool soloActivos = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _clientes = await _repository.obtenerTodos(soloActivos: soloActivos);
      print('✅ ${_clientes.length} clientes cargados en el provider');
    } catch (e) {
      print('❌ Error al cargar clientes en provider: $e');
      _clientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca clientes por término
  Future<void> buscarClientes(String termino, {bool soloActivos = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (termino.isEmpty) {
        await cargarClientes(soloActivos: soloActivos);
      } else {
        _clientes = await _repository.buscar(termino, soloActivos: soloActivos);
      }
    } catch (e) {
      print('❌ Error al buscar clientes: $e');
      _clientes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // OPERACIONES CRUD
  // ========================================

  /// Crea un nuevo cliente
  Future<bool> crearCliente(ClienteModel cliente) async {
    try {
      final int id = await _repository.crear(cliente);

      // Agregar a la lista local
      _clientes.add(cliente.copyWith(id: id));
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Error al crear cliente en provider: $e');
      return false;
    }
  }

  /// Actualiza un cliente existente
  Future<bool> actualizarCliente(ClienteModel cliente) async {
    try {
      await _repository.actualizar(cliente);

      // Actualizar en la lista local
      final index = _clientes.indexWhere((c) => c.id == cliente.id);
      if (index != -1) {
        _clientes[index] = cliente;
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('❌ Error al actualizar cliente en provider: $e');
      return false;
    }
  }

  /// Elimina un cliente (soft delete)
  Future<bool> eliminarCliente(int id) async {
    try {
      await _repository.eliminar(id);

      // Remover de la lista local
      _clientes.removeWhere((c) => c.id == id);
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Error al eliminar cliente en provider: $e');
      return false;
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Selecciona un cliente
  void seleccionarCliente(ClienteModel? cliente) {
    _clienteSeleccionado = cliente;
    notifyListeners();
  }

  /// Genera el siguiente código disponible
  Future<String> generarSiguienteCodigo() async {
    return await _repository.generarSiguienteCodigo();
  }

  /// Verifica si un código ya existe
  Future<bool> existeCodigo(String codigo) async {
    return await _repository.existeCodigo(codigo);
  }

  /// Verifica si un CUIT ya existe
  Future<bool> existeCuit(String cuit) async {
    return await _repository.existeCuit(cuit);
  }
}
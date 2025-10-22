import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/producto_model.dart';
import '../../data/models/categoria_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/repositories/categoria_repository.dart';
import '../../data/repositories/producto_repository.dart';
import '../../data/repositories/stock_repository.dart';
import '../providers/producto_provider.dart';

/// Formulario para Crear/Editar Producto
///
/// - Modo CREAR: productoId = null
/// - Modo EDITAR: productoId != null
class ProductoFormPage extends StatefulWidget {
  final int? productoId; // null = crear, not null = editar

  const ProductoFormPage({
    super.key,
    this.productoId,
  });

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Repositorios
  final CategoriaRepository _categoriaRepo = CategoriaRepository();
  final ProductoRepository _productoRepo = ProductoRepository();
  final StockRepository _stockRepo = StockRepository();

  // Controllers
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _unidadController = TextEditingController();
  final TextEditingController _equivalenciaController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _stockInicialController = TextEditingController();

  // Estado
  List<CategoriaModel> _categorias = [];
  CategoriaModel? _categoriaSeleccionada;
  bool _isLoading = false;
  bool _modoEdicion = false;
  ProductoModel? _productoOriginal;

  @override
  void initState() {
    super.initState();
    _modoEdicion = widget.productoId != null;
    _cargarDatos();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _unidadController.dispose();
    _equivalenciaController.dispose();
    _precioController.dispose();
    _stockInicialController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar categorías
      _categorias = await _categoriaRepo.obtenerTodas();

      // Si es modo edición, cargar el producto
      if (_modoEdicion && widget.productoId != null) {
        _productoOriginal = await _productoRepo.obtenerPorId(widget.productoId!);

        if (_productoOriginal != null) {
          _nombreController.text = _productoOriginal!.nombre;
          _descripcionController.text = _productoOriginal!.descripcion ?? '';
          _codigoController.text = _productoOriginal!.codigo;
          _unidadController.text = _productoOriginal!.unidadBase;
          _equivalenciaController.text = _productoOriginal!.equivalencia ?? '';
          _precioController.text = _productoOriginal!.precioSinIva?.toString() ?? '';

          // Seleccionar la categoría
          _categoriaSeleccionada = _categorias.firstWhere(
                (c) => c.id == _productoOriginal!.categoriaId,
          );

          // Cargar stock actual
          final stock = await _stockRepo.obtenerPorProductoId(widget.productoId!);
          if (stock != null) {
            _stockInicialController.text = stock.cantidadDisponible.toString();
          }
        }
      } else {
        // Modo crear: seleccionar primera categoría por defecto
        if (_categorias.isNotEmpty) {
          _categoriaSeleccionada = _categorias.first;
          await _generarCodigoAutomatico();
        }
      }
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generarCodigoAutomatico() async {
    if (_categoriaSeleccionada == null) return;

    try {
      final codigo = await _productoRepo.generarSiguienteCodigo(
        _categoriaSeleccionada!.codigo,
      );
      _codigoController.text = codigo;
    } catch (e) {
      print('Error al generar código: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: Text(_modoEdicion ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ========================================
              // CATEGORÍA
              // ========================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CategoriaModel>(
                        value: _categoriaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar categoría',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categorias.map((categoria) {
                          return DropdownMenuItem(
                            value: categoria,
                            child: Text('[${categoria.codigo}] ${categoria.nombre}'),
                          );
                        }).toList(),
                        onChanged: _modoEdicion ? null : (valor) async {
                          setState(() {
                            _categoriaSeleccionada = valor;
                          });
                          await _generarCodigoAutomatico();
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccioná una categoría';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ========================================
              // INFORMACIÓN BÁSICA
              // ========================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información Básica',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Código
                      TextFormField(
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código',
                          hintText: 'OG-001',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        readOnly: true, // No se puede editar manualmente
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El código es obligatorio';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del producto *',
                          hintText: 'Ej: Cemento Portland',
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Descripción
                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          hintText: 'Ej: Cemento Portland tipo CPF-40',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ========================================
              // UNIDAD DE MEDIDA
              // ========================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unidad de Medida',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Unidad base
                      TextFormField(
                        controller: _unidadController,
                        decoration: const InputDecoration(
                          labelText: 'Unidad base *',
                          hintText: 'Ej: Bolsa, Litro, Metro, Unidad',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La unidad es obligatoria';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Equivalencia
                      TextFormField(
                        controller: _equivalenciaController,
                        decoration: const InputDecoration(
                          labelText: 'Equivalencia (opcional)',
                          hintText: 'Ej: 25kg, 4m, 50L',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ========================================
              // PRECIO Y STOCK
              // ========================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Precio y Stock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Precio
                      TextFormField(
                        controller: _precioController,
                        decoration: const InputDecoration(
                          labelText: 'Precio sin IVA',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final precio = double.tryParse(value);
                            if (precio == null || precio < 0) {
                              return 'Ingresá un precio válido';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Stock inicial (solo en modo crear)
                      if (!_modoEdicion)
                        TextFormField(
                          controller: _stockInicialController,
                          decoration: const InputDecoration(
                            labelText: 'Stock inicial',
                            hintText: '0',
                            prefixIcon: Icon(Icons.inventory),
                            helperText: 'Cantidad disponible al crear el producto',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),

                      // En modo edición, mostrar stock actual
                      if (_modoEdicion)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.textMedium),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Para ajustar el stock, usá el botón "Ajustar Stock" en la pantalla de detalle',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ========================================
              // BOTÓN GUARDAR
              // ========================================
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _guardarProducto,
                  icon: const Icon(Icons.save, size: 24),
                  label: Text(
                    _modoEdicion ? 'Guardar Cambios' : 'Crear Producto',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // GUARDAR PRODUCTO
  // ========================================
  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSeleccionada == null) {
      _mostrarError('Seleccioná una categoría');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parsear precio
      double? precio;
      if (_precioController.text.isNotEmpty) {
        precio = double.parse(_precioController.text);
      }

      if (_modoEdicion && _productoOriginal != null) {
        // ========================================
        // MODO EDICIÓN
        // ========================================
        final productoActualizado = _productoOriginal!.copyWith(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          unidadBase: _unidadController.text.trim(),
          equivalencia: _equivalenciaController.text.trim().isEmpty
              ? null
              : _equivalenciaController.text.trim(),
          precioSinIva: precio,
        );

        await _productoRepo.actualizar(productoActualizado);

        if (mounted) {
          await context.read<ProductoProvider>().cargarProductos();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // ========================================
        // MODO CREAR
        // ========================================
        final nuevoProducto = ProductoModel(
          codigo: _codigoController.text.trim(),
          categoriaId: _categoriaSeleccionada!.id!,
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          unidadBase: _unidadController.text.trim(),
          equivalencia: _equivalenciaController.text.trim().isEmpty
              ? null
              : _equivalenciaController.text.trim(),
          precioSinIva: precio,
        );

        final productoId = await _productoRepo.crear(nuevoProducto);

        // Crear stock inicial si se especificó
        if (_stockInicialController.text.isNotEmpty) {
          final stockInicial = double.parse(_stockInicialController.text);
          if (stockInicial > 0) {
            await _stockRepo.establecer(
              productoId: productoId,
              cantidad: stockInicial,
            );
          }
        }

        if (mounted) {
          await context.read<ProductoProvider>().cargarProductos();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
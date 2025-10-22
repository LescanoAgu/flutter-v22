import 'features/stock/data/repositories/producto_repository.dart';
import 'features/stock/data/models/producto_model.dart';

/// Prueba rápida del repositorio de productos
Future<void> testProductos() async {
  print('\n========================================');
  print('🧪 PROBANDO PRODUCTOS');
  print('========================================\n');

  final ProductoRepository repo = ProductoRepository();

  // ========================================
  // 1. CONTAR PRODUCTOS
  // ========================================
  print('1️⃣ Contando productos...');
  int total = await repo.contar();
  print('   ✓ Total de productos: $total\n');

  // ========================================
  // 2. OBTENER PRIMEROS 5 PRODUCTOS
  // ========================================
  print('2️⃣ Obteniendo primeros 5 productos...');
  List<ProductoModel> productos = await repo.obtenerTodos();

  int cantidad = productos.length > 5 ? 5 : productos.length;
  for (int i = 0; i < cantidad; i++) {
    var p = productos[i];
    print('   ${i + 1}. [${p.codigo}] ${p.nombre}');
    print('      Precio: ${p.precioFormateado} - ${p.unidadBase}');
  }
  print('');

  // ========================================
  // 3. OBTENER PRODUCTOS CON CATEGORÍA
  // ========================================
  print('3️⃣ Obteniendo productos CON categoría...');
  List<ProductoConCategoria> productosConCat =
  await repo.obtenerTodosConCategoria();

  cantidad = productosConCat.length > 5 ? 5 : productosConCat.length;
  for (int i = 0; i < cantidad; i++) {
    var item = productosConCat[i];
    print('   ${i + 1}. [${item.producto.codigo}] ${item.producto.nombre}');
    print('      Categoría: [${item.categoriaCodigo}] ${item.categoriaNombre}');
  }
  print('');

  // ========================================
  // 4. BUSCAR PRODUCTOS
  // ========================================
  print('4️⃣ Buscando "cemento"...');
  List<ProductoConCategoria> resultados =
  await repo.buscarConCategoria('cemento');

  print('   ✓ Resultados encontrados: ${resultados.length}');
  for (var item in resultados) {
    print('      - ${item.producto.nombre} (${item.categoriaNombre})');
  }
  print('');

  // ========================================
  // 5. CONTAR POR CATEGORÍA
  // ========================================
  print('5️⃣ Productos por categoría...');
  Map<int, int> conteo = await repo.contarPorCategoria();

  print('   ✓ Distribución:');
  conteo.forEach((categoriaId, cantidad) {
    print('      Categoría $categoriaId: $cantidad productos');
  });
  print('');

  // ========================================
  // 6. OBTENER PRODUCTOS DE UNA CATEGORÍA
  // ========================================
  print('6️⃣ Obteniendo productos de Hierros (H)...');

  // Primero necesitamos el id de la categoría H
  // Buscar un producto con código H-xxx y obtener su categoriaId
  var productoHierro = await repo.obtenerPorCodigo('H-001');

  if (productoHierro != null) {
    List<ProductoModel> hierros =
    await repo.obtenerPorCategoria(productoHierro.categoriaId);

    print('   ✓ Productos de Hierros: ${hierros.length}');
    for (var p in hierros) {
      print('      - ${p.nombre} (${p.precioFormateado})');
    }
  }
  print('');

  print('========================================');
  print('✅ PRUEBA COMPLETADA');
  print('========================================\n');
}
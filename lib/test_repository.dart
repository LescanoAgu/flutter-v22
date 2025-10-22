import 'features/stock/data/repositories/categoria_repository.dart';
import 'features/stock/data/models/categoria_model.dart';

/// Función de prueba para el repositorio de categorías
Future<void> testCategoriaRepository() async {
  print('\n========================================');
  print('🧪 PROBANDO CATEGORIA REPOSITORY');
  print('========================================\n');

  final CategoriaRepository repo = CategoriaRepository();

  // ========================================
  // 1. OBTENER TODAS LAS CATEGORÍAS
  // ========================================
  print('1️⃣ Obteniendo todas las categorías...');
  
  List<CategoriaModel> categorias = await repo.obtenerTodas();
  
  print('   ✓ Total de categorías: ${categorias.length}');
  print('   ✓ Categorías cargadas:');
  for (var cat in categorias) {
    print('      - [${cat.codigo}] ${cat.nombre}');
  }
  print('');

  // ========================================
  // 2. OBTENER POR ID
  // ========================================
  print('2️⃣ Obteniendo categoría por ID...');
  
  CategoriaModel? categoria = await repo.obtenerPorId(1);
  
  if (categoria != null) {
    print('   ✓ Encontrada: ${categoria.nombre}');
    print('      - Código: ${categoria.codigo}');
    print('      - Descripción: ${categoria.descripcion}');
  } else {
    print('   ✗ No encontrada');
  }
  print('');

  // ========================================
  // 3. OBTENER POR CÓDIGO
  // ========================================
  print('3️⃣ Obteniendo categoría por código...');
  
  CategoriaModel? categoriaOG = await repo.obtenerPorCodigo('OG');
  
  if (categoriaOG != null) {
    print('   ✓ Encontrada: ${categoriaOG.nombre}');
  } else {
    print('   ✗ No encontrada');
  }
  print('');

  // ========================================
  // 4. BUSCAR POR NOMBRE
  // ========================================
  print('4️⃣ Buscando categorías por nombre...');
  
  List<CategoriaModel> resultados = await repo.buscarPorNombre('obra');
  
  print('   ✓ Resultados para "obra": ${resultados.length}');
  for (var cat in resultados) {
    print('      - ${cat.nombre}');
  }
  print('');

  // ========================================
  // 5. CONTAR CATEGORÍAS
  // ========================================
  print('5️⃣ Contando categorías...');
  
  int total = await repo.contarTodas();
  
  print('   ✓ Total: $total categorías en la base de datos\n');

  // ========================================
  // 6. VERIFICAR SI EXISTE UN CÓDIGO
  // ========================================
  print('6️⃣ Verificando si existen códigos...');
  
  bool existeOG = await repo.existeCodigo('OG');
  bool existeXYZ = await repo.existeCodigo('XYZ');
  
  print('   ✓ ¿Existe código "OG"?: $existeOG');
  print('   ✓ ¿Existe código "XYZ"?: $existeXYZ\n');

  // ========================================
  // 7. CREAR NUEVA CATEGORÍA (PRUEBA)
  // ========================================
  print('7️⃣ Creando una nueva categoría de prueba...');
  
  CategoriaModel nuevaCategoria = CategoriaModel(
    codigo: 'TEST',
    nombre: 'Categoría de Prueba',
    descripcion: 'Esta es una categoría temporal para testing',
    orden: 99,
  );
  
  try {
    int nuevoId = await repo.crear(nuevaCategoria);
    print('   ✓ Categoría creada con id: $nuevoId\n');
    
    // ========================================
    // 8. ACTUALIZAR LA CATEGORÍA CREADA
    // ========================================
    print('8️⃣ Actualizando la categoría de prueba...');
    
    CategoriaModel paraActualizar = nuevaCategoria.copyWith(
      id: nuevoId,
      nombre: 'Categoría Actualizada',
    );
    
    int filasAfectadas = await repo.actualizar(paraActualizar);
    print('   ✓ Filas actualizadas: $filasAfectadas\n');
    
    // Verificar que se actualizó
    CategoriaModel? verificar = await repo.obtenerPorId(nuevoId);
    if (verificar != null) {
      print('   ✓ Verificación: ${verificar.nombre}');
    }
    print('');
    
    // ========================================
    // 9. ELIMINAR LA CATEGORÍA DE PRUEBA
    // ========================================
    print('9️⃣ Eliminando la categoría de prueba...');
    
    int eliminadas = await repo.eliminar(nuevoId);
    print('   ✓ Categorías eliminadas: $eliminadas\n');
    
  } catch (e) {
    print('   ✗ Error: $e\n');
  }

  // ========================================
  // 10. OBTENER LA ÚLTIMA CATEGORÍA
  // ========================================
  print('🔟 Obteniendo la última categoría...');
  
  CategoriaModel? ultima = await repo.obtenerUltima();
  
  if (ultima != null) {
    print('   ✓ Última categoría: ${ultima.nombre}');
    print('      - Orden: ${ultima.orden}');
  }
  print('');

  print('========================================');
  print('✅ PRUEBA COMPLETADA');
  print('========================================\n');
}
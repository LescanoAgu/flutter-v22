import 'features/stock/data/models/categoria_model.dart';

/// Función de prueba para entender cómo funciona CategoriaModel
void testCategoriaModel() {
  print('\n========================================');
  print('🧪 PROBANDO CATEGORIA MODEL');
  print('========================================\n');

  // ========================================
  // 1. CREAR UNA CATEGORÍA NUEVA
  // ========================================
  print('1️⃣ Creando una categoría nueva...');

  CategoriaModel categoria = CategoriaModel(
    codigo: 'OG',
    nombre: 'Obra General',
    descripcion: 'Cemento, cal, arena, etc.',
    orden: 1,
  );

  print('   ✓ Categoría creada: $categoria');
  print('   - id: ${categoria.id} (null porque no está en BD todavía)');
  print('   - codigo: ${categoria.codigo}');
  print('   - nombre: ${categoria.nombre}\n');

  // ========================================
  // 2. CONVERTIR A MAP (para guardar en BD)
  // ========================================
  print('2️⃣ Convirtiendo a Map (formato de BD)...');

  Map<String, dynamic> mapa = categoria.toMap();

  print('   ✓ Map generado: $mapa\n');

  // ========================================
  // 3. SIMULAR QUE VINO DE LA BD
  // ========================================
  print('3️⃣ Simulando que vino de la BD (con id asignado)...');

  Map<String, dynamic> mapaDesdeBD = {
    'id': 1, // La BD le asignó este id
    'codigo': 'OG',
    'nombre': 'Obra General',
    'descripcion': 'Cemento, cal, arena, etc.',
    'orden': 1,
    'created_at': '2025-01-15 10:00:00',
  };

  CategoriaModel categoriaDesdeDB = CategoriaModel.fromMap(mapaDesdeBD);

  print('   ✓ Categoría desde BD: $categoriaDesdeDB');
  print('   - Ahora tiene id: ${categoriaDesdeDB.id}\n');

  // ========================================
  // 4. COPIAR CON CAMBIOS
  // ========================================
  print('4️⃣ Creando una copia con cambios...');

  CategoriaModel categoriaModificada = categoriaDesdeDB.copyWith(
    nombre: 'Obra General Premium',
  );

  print('   ✓ Original: ${categoriaDesdeDB.nombre}');
  print('   ✓ Modificada: ${categoriaModificada.nombre}');
  print('   - El resto de los campos se mantiene igual\n');

  // ========================================
  // 5. COMPARACIÓN
  // ========================================
  print('5️⃣ Comparando categorías...');

  bool sonIguales = categoriaDesdeDB == categoriaModificada;

  print('   ✓ ¿Son iguales?: $sonIguales');
  print(
    '   - Se comparan por id: ${categoriaDesdeDB.id} == ${categoriaModificada.id}\n',
  );

  print('========================================');
  print('✅ PRUEBA COMPLETADA');
  print('========================================\n');
}

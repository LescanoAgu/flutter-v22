import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Gestor de Base de Datos SQLite
///
/// Esta clase maneja:
/// - Creación de la base de datos
/// - Creación de tablas
/// - Migraciones (actualizaciones de estructura)
/// - Acceso a la base de datos (patrón Singleton)
class DatabaseHelper {
  // ========================================
  // SINGLETON PATTERN
  // ========================================
  // Esto asegura que solo haya UNA instancia de la base de datos

  // Instancia privada única
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Factory constructor que siempre devuelve la misma instancia
  factory DatabaseHelper() => _instance;

  // Constructor privado
  DatabaseHelper._internal();

  // ========================================
  // CONFIGURACIÓN
  // ========================================

  static const String _databaseName = 'syg_materiales.db';
  static const int _databaseVersion = 2;

  // La base de datos en sí
  static Database? _database;

  /// Obtiene la base de datos (la crea si no existe)
  Future<Database> get database async {
    // Si ya existe, la devuelve
    if (_database != null) return _database!;

    // Si no existe, la crea
    _database = await _initDatabase();
    return _database!;
  }

  // ========================================
  // INICIALIZACIÓN
  // ========================================

  /// Inicializa la base de datos
  Future<Database> _initDatabase() async {
    // Obtiene el path donde se guardan las bases de datos
    String path = join(await getDatabasesPath(), _databaseName);

    print('📁 Ruta de base de datos: $path');

    // Abre/crea la base de datos
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Se ejecuta cuando se crea la base de datos por primera vez
  Future<void> _onCreate(Database db, int version) async {
    print('🏗️  Creando base de datos versión $version...');

    // Ejecuta todas las tablas en orden
    //Usuarios
    await _createUsuariosTable(db);
    //Clientes y Obras
    await _createClientesTable(db);
    await _createContactosClienteTable(db);
    await _createObrasTable(db);
    //Stock
    await _createCategoriasTable(db);
    await _createProductosTable(db);
    await _createStockTable(db);
    await _createMovimientosStockTable(db);
    //ACOPIOS
    await _createProveedoresTable(db);
    await _createAcopiosTable(db);
    await _createMovimientosAcopioTable(db);
    await _createSaldosProveedorTable(db);
    await _createCuentasCorrientesTable(db);
    await _createMovimientosCuentaTable(db);
    //ÓRDENES INTERNAS (v2)
    await _createOrdenesInternasTable(db);
    await _createOrdenItemsTable(db);

    // Carga datos iniciales
    await _seedCategorias(db);

    print('✅ Base de datos creada exitosamente');
  }

  /// Se ejecuta cuando se actualiza la versión de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de v$oldVersion a v$newVersion...');

    // Migración a versión 2: Órdenes Internas
    if (oldVersion < 2) {
      await _createOrdenesInternasTable(db);
      await _createOrdenItemsTable(db);
      print('✅ Migración v2: Órdenes Internas agregadas');
    }
  }

  // ========================================
  // CREACIÓN DE TABLAS
  // ========================================

  /// Tabla USUARIOS
  Future<void> _createUsuariosTable(Database db) async {
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        nombre_completo TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        rol TEXT NOT NULL,
        telefono TEXT,
        estado TEXT DEFAULT 'activo',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    // Crear índices para búsquedas más rápidas
    await db.execute('CREATE INDEX idx_usuarios_codigo ON usuarios(codigo)');
    await db.execute('CREATE INDEX idx_usuarios_email ON usuarios(email)');
    await db.execute('CREATE INDEX idx_usuarios_estado ON usuarios(estado)');

    print('  ✓ Tabla usuarios creada');
  }

  /// Tabla CLIENTES
  Future<void> _createClientesTable(Database db) async {
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        razon_social TEXT NOT NULL,
        cuit TEXT,
        condicion_iva TEXT,
        condicion_pago TEXT,
        email TEXT,
        estado TEXT DEFAULT 'activo',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_clientes_codigo ON clientes(codigo)');
    await db.execute('CREATE INDEX idx_clientes_estado ON clientes(estado)');
    await db.execute('CREATE INDEX idx_clientes_cuit ON clientes(cuit)');

    print('  ✓ Tabla clientes creada');
  }

  /// Tabla CONTACTOS_CLIENTE
  Future<void> _createContactosClienteTable(Database db) async {
    await db.execute('''
      CREATE TABLE contactos_cliente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        tipo TEXT,
        es_principal INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_contactos_cliente_id ON contactos_cliente(cliente_id)',
    );

    print('  ✓ Tabla contactos_cliente creada');
  }

  /// Tabla OBRAS
  Future<void> _createObrasTable(Database db) async {
    await db.execute('''
      CREATE TABLE obras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        cliente_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        direccion TEXT NOT NULL,
        horarios_descarga TEXT,
        contacto_obra TEXT,
        telefono_obra TEXT,
        maestro_obra_nombre TEXT,
        maestro_obra_telefono TEXT,
        responsable_interno_id INTEGER,
        estado TEXT DEFAULT 'activa',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes(id),
        FOREIGN KEY (responsable_interno_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_obras_codigo ON obras(codigo)');
    await db.execute('CREATE INDEX idx_obras_cliente_id ON obras(cliente_id)');
    await db.execute('CREATE INDEX idx_obras_estado ON obras(estado)');

    print('  ✓ Tabla obras creada');
  }

  /// Tabla CATEGORIAS
  Future<void> _createCategoriasTable(Database db) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        nombre TEXT UNIQUE NOT NULL,
        descripcion TEXT,
        orden INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_categorias_codigo ON categorias(codigo)',
    );

    print('  ✓ Tabla categorias creada');
  }

  /// Tabla PRODUCTOS
  Future<void> _createProductosTable(Database db) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        categoria_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        unidad_base TEXT NOT NULL,
        equivalencia TEXT,
        precio_sin_iva REAL,
        estado TEXT DEFAULT 'activo',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (categoria_id) REFERENCES categorias(id)
      )
    ''');

    await db.execute('CREATE INDEX idx_productos_codigo ON productos(codigo)');
    await db.execute(
      'CREATE INDEX idx_productos_categoria_id ON productos(categoria_id)',
    );
    await db.execute('CREATE INDEX idx_productos_estado ON productos(estado)');

    print('  ✓ Tabla productos creada');
  }

  /// Tabla STOCK
  Future<void> _createStockTable(Database db) async {
    await db.execute('''
      CREATE TABLE stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER UNIQUE NOT NULL,
        cantidad_disponible REAL NOT NULL DEFAULT 0,
        ultima_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_stock_producto_id ON stock(producto_id)',
    );

    print('  ✓ Tabla stock creada');
  }

  /// Tabla MOVIMIENTOS_STOCK
  Future<void> _createMovimientosStockTable(Database db) async {
    await db.execute('''
      CREATE TABLE movimientos_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        cantidad REAL NOT NULL,
        cantidad_anterior REAL NOT NULL,
        cantidad_posterior REAL NOT NULL,
        motivo TEXT,
        referencia TEXT,
        usuario_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (producto_id) REFERENCES productos(id),
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_movimientos_producto_id ON movimientos_stock(producto_id)',
    );
    await db.execute(
      'CREATE INDEX idx_movimientos_tipo ON movimientos_stock(tipo)',
    );
    await db.execute(
      'CREATE INDEX idx_movimientos_created_at ON movimientos_stock(created_at)',
    );

    print('  ✓ Tabla movimientos_stock creada');
  }

  // ========================================
// TABLA PROVEEDORES
// ========================================
  Future<void> _createProveedoresTable(Database db) async {
    await db.execute('''
    CREATE TABLE proveedores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      codigo TEXT UNIQUE NOT NULL,
      nombre TEXT NOT NULL,
      tipo TEXT NOT NULL,
      direccion TEXT,
      telefono TEXT,
      contacto TEXT,
      email TEXT,
      estado TEXT DEFAULT 'activo',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT
    )
  ''');

    await db.execute(
        'CREATE INDEX idx_proveedores_codigo ON proveedores(codigo)');
    await db.execute('CREATE INDEX idx_proveedores_tipo ON proveedores(tipo)');
    await db.execute(
        'CREATE INDEX idx_proveedores_estado ON proveedores(estado)');

    print('  ✓ Tabla proveedores creada');
  }

// ========================================
// TABLA ACOPIOS
// ========================================
  Future<void> _createAcopiosTable(Database db) async {
    await db.execute('''
    CREATE TABLE acopios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      producto_id INTEGER NOT NULL,
      cliente_id INTEGER NOT NULL,
      proveedor_id INTEGER NOT NULL,
      cantidad_disponible REAL NOT NULL DEFAULT 0,
      estado TEXT DEFAULT 'activo',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT,
      FOREIGN KEY (producto_id) REFERENCES productos(id),
      FOREIGN KEY (cliente_id) REFERENCES clientes(id),
      FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
      UNIQUE(producto_id, cliente_id, proveedor_id)
    )
  ''');

    await db.execute(
        'CREATE INDEX idx_acopios_producto ON acopios(producto_id)');
    await db.execute('CREATE INDEX idx_acopios_cliente ON acopios(cliente_id)');
    await db.execute(
        'CREATE INDEX idx_acopios_proveedor ON acopios(proveedor_id)');
    await db.execute('CREATE INDEX idx_acopios_estado ON acopios(estado)');

    print('  ✓ Tabla acopios creada');
  }

// ========================================
// TABLA MOVIMIENTOS ACOPIO
// ========================================
  Future<void> _createMovimientosAcopioTable(Database db) async {
    await db.execute('''
    CREATE TABLE movimientos_acopio (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      producto_id INTEGER NOT NULL,
      tipo TEXT NOT NULL,
      cantidad REAL NOT NULL,
      
      origen_tipo TEXT,
      origen_id INTEGER,
      destino_tipo TEXT,
      destino_id INTEGER,
      
      motivo TEXT,
      referencia TEXT,
      remito_numero TEXT,
      
      -- ========================================
      -- NUEVOS CAMPOS PARA FACTURA
      -- ========================================
      factura_numero TEXT,               -- Número de factura (ej: FC-0001-00012345)
      factura_fecha TEXT,                -- Fecha de la factura (ISO 8601)
      
      valorizado INTEGER DEFAULT 0,
      monto_valorizado REAL,
      
      usuario_id INTEGER,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      
      FOREIGN KEY (producto_id) REFERENCES productos(id),
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    )
  ''');

    await db.execute(
        'CREATE INDEX idx_movimientos_acopio_producto ON movimientos_acopio(producto_id)');
    await db.execute(
        'CREATE INDEX idx_movimientos_acopio_tipo ON movimientos_acopio(tipo)');
    await db.execute(
        'CREATE INDEX idx_movimientos_acopio_created_at ON movimientos_acopio(created_at)');

    // ========================================
    // NUEVO ÍNDICE PARA BUSCAR POR FACTURA
    // ========================================
    await db.execute(
        'CREATE INDEX idx_movimientos_acopio_factura ON movimientos_acopio(factura_numero)');

    print('  ✓ Tabla movimientos_acopio creada');
  }

// ========================================
// TABLA SALDOS PROVEEDOR
// ========================================
  Future<void> _createSaldosProveedorTable(Database db) async {
    await db.execute('''
    CREATE TABLE saldos_proveedor (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cliente_id INTEGER NOT NULL,
      proveedor_id INTEGER NOT NULL,
      saldo_a_favor REAL DEFAULT 0,
      moneda TEXT DEFAULT 'ARS',
      ultima_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (cliente_id) REFERENCES clientes(id),
      FOREIGN KEY (proveedor_id) REFERENCES proveedores(id),
      UNIQUE(cliente_id, proveedor_id)
    )
  ''');

    await db.execute(
        'CREATE INDEX idx_saldos_cliente ON saldos_proveedor(cliente_id)');
    await db.execute(
        'CREATE INDEX idx_saldos_proveedor ON saldos_proveedor(proveedor_id)');

    print('  ✓ Tabla saldos_proveedor creada');
  }

// ========================================
// TABLA CUENTAS CORRIENTES
// ========================================
  Future<void> _createCuentasCorrientesTable(Database db) async {
    await db.execute('''
    CREATE TABLE cuentas_corrientes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tipo TEXT NOT NULL,
      entidad_id INTEGER NOT NULL,
      saldo_actual REAL DEFAULT 0,
      saldo_pendiente REAL DEFAULT 0,
      moneda TEXT DEFAULT 'ARS',
      ultima_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(tipo, entidad_id)
    )
  ''');

    await db.execute(
        'CREATE INDEX idx_cuentas_tipo ON cuentas_corrientes(tipo)');
    await db.execute(
        'CREATE INDEX idx_cuentas_entidad ON cuentas_corrientes(entidad_id)');

    print('  ✓ Tabla cuentas_corrientes creada');
  }

// ========================================
// TABLA MOVIMIENTOS CUENTA
// ========================================
  Future<void> _createMovimientosCuentaTable(Database db) async {
    await db.execute('''
    CREATE TABLE movimientos_cuenta (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      cuenta_id INTEGER NOT NULL,
      tipo TEXT NOT NULL,
      estado TEXT DEFAULT 'pendiente',
      monto REAL NOT NULL,
      concepto TEXT,
      
      movimiento_stock_id INTEGER,
      movimiento_acopio_id INTEGER,
      remito_numero TEXT,
      
      fecha TEXT DEFAULT CURRENT_TIMESTAMP,
      confirmado_fecha TEXT,
      confirmado_por INTEGER,
      anulado_fecha TEXT,
      anulado_por INTEGER,
      motivo_anulacion TEXT,
      
      comprobante TEXT,
      observaciones TEXT,
      usuario_id INTEGER,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      
      FOREIGN KEY (cuenta_id) REFERENCES cuentas_corrientes(id),
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
      FOREIGN KEY (confirmado_por) REFERENCES usuarios(id),
      FOREIGN KEY (anulado_por) REFERENCES usuarios(id)
    )
  ''');

    await db.execute(
        'CREATE INDEX idx_movimientos_cuenta_cuenta ON movimientos_cuenta(cuenta_id)');
    await db.execute(
        'CREATE INDEX idx_movimientos_cuenta_tipo ON movimientos_cuenta(tipo)');
    await db.execute(
        'CREATE INDEX idx_movimientos_cuenta_estado ON movimientos_cuenta(estado)');
    await db.execute(
        'CREATE INDEX idx_movimientos_cuenta_fecha ON movimientos_cuenta(fecha)');

    print('  ✓ Tabla movimientos_cuenta creada');
  }

  // ========================================
  // TABLA ORDENES INTERNAS
  // ========================================
  Future<void> _createOrdenesInternasTable(Database db) async {
    await db.execute('''
      CREATE TABLE ordenes_internas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT NOT NULL UNIQUE,
        cliente_id INTEGER NOT NULL,
        obra_id INTEGER,
        solicitante_nombre TEXT NOT NULL,
        solicitante_email TEXT,
        solicitante_telefono TEXT,
        fecha_pedido TEXT NOT NULL,
        fecha_entrega_estimada TEXT,
        estado TEXT NOT NULL DEFAULT 'solicitado',
        observaciones_cliente TEXT,
        observaciones_internas TEXT,
        motivo_rechazo TEXT,
        total REAL DEFAULT 0,
        aprobado_por_usuario_id INTEGER,
        aprobado_fecha TEXT,
        usuario_creador_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id),
        FOREIGN KEY (obra_id) REFERENCES obras (id),
        FOREIGN KEY (aprobado_por_usuario_id) REFERENCES usuarios (id),
        FOREIGN KEY (usuario_creador_id) REFERENCES usuarios (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_ordenes_numero ON ordenes_internas(numero)');
    await db.execute('CREATE INDEX idx_ordenes_cliente ON ordenes_internas(cliente_id)');
    await db.execute('CREATE INDEX idx_ordenes_estado ON ordenes_internas(estado)');
    await db.execute('CREATE INDEX idx_ordenes_fecha ON ordenes_internas(fecha_pedido)');

    print('  ✓ Tabla ordenes_internas creada');
  }

  // ========================================
  // TABLA ORDEN ITEMS
  // ========================================
  Future<void> _createOrdenItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE orden_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orden_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad_solicitada REAL NOT NULL,
        cantidad_aprobada REAL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        observaciones TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (orden_id) REFERENCES ordenes_internas (id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    await db.execute('CREATE INDEX idx_orden_items_orden ON orden_items(orden_id)');
    await db.execute('CREATE INDEX idx_orden_items_producto ON orden_items(producto_id)');

    print('  ✓ Tabla orden_items creada');
  }

  /// Carga las categorías predefinidas
  Future<void> _seedCategorias(Database db) async {
    print('🌱 Cargando categorías iniciales...');

    final categorias = [
      {
        'codigo': 'A',
        'nombre': 'Agua',
        'descripcion': 'Materiales de agua potable',
        'orden': 1,
      },
      {
        'codigo': 'E',
        'nombre': 'Eléctrico',
        'descripcion': 'Materiales eléctricos',
        'orden': 2,
      },
      {
        'codigo': 'G',
        'nombre': 'Gas',
        'descripcion': 'Materiales de gas',
        'orden': 3,
      },
      {
        'codigo': 'H',
        'nombre': 'Hierros',
        'descripcion': 'Hierros y aceros',
        'orden': 4,
      },
      {
        'codigo': 'M',
        'nombre': 'Maderas',
        'descripcion': 'Maderas y derivados',
        'orden': 5,
      },
      {
        'codigo': 'OG',
        'nombre': 'Obra General',
        'descripcion': 'Cemento, cal, arena, etc.',
        'orden': 6,
      },
      {
        'codigo': 'P',
        'nombre': 'Pintura',
        'descripcion': 'Pinturas y revestimientos',
        'orden': 7,
      },
      {
        'codigo': 'S',
        'nombre': 'Sanitario',
        'descripcion': 'Materiales sanitarios',
        'orden': 8,
      },
    ];

    for (var categoria in categorias) {
      await db.insert('categorias', categoria);
    }

    print('  ✓ ${categorias.length} categorías cargadas');
  }


  // ========================================
// DATOS INICIALES - PROVEEDORES
// ========================================

  /// Carga proveedores iniciales
  Future<void> _seedProveedoresIniciales(Database db) async {
    print('🌱 Cargando proveedores iniciales...');

    final proveedores = [
      {
        'codigo': 'DEP-001',
        'nombre': 'Depósito Central S&G',
        'tipo': 'deposito_syg',
        'direccion': 'Dirección del depósito',
        'estado': 'activo',
      },
      // Proveedores de ejemplo (puedes agregar los reales después)
      {
        'codigo': 'PROV-001',
        'nombre': 'Proveedor Ejemplo 1',
        'tipo': 'proveedor',
        'direccion': '',
        'estado': 'activo',
      },
    ];

    for (var proveedor in proveedores) {
      await db.insert('proveedores', proveedor);
    }

    print('  ✓ ${proveedores.length} proveedores cargados');
  }

  // ========================================
  // MÉTODOS AUXILIARES
  // ========================================

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('🔒 Base de datos cerrada');
  }

  /// Elimina la base de datos (útil para testing)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('🗑️  Base de datos eliminada');
  }
}
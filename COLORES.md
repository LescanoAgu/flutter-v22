# 🎨 Paleta de Colores S&G

## Colores Principales (extraídos de logos)

### Verde Corporativo
```dart
// Color principal del edificio/luna
static const Color verdeS&G = Color(0xFF00A859);
static const Color verdeOscuro = Color(0xFF006B3D);
static const Color verdeClaro = Color(0xFF4CAF50);
```

### Azul Marino (texto S&G)
```dart
static const Color azulMarino = Color(0xFF1D3557);
static const Color azulOscuro = Color(0xFF0D1B2A);
```

### Grises
```dart
static const Color grisOscuro = Color(0xFF2C3E50);
static const Color grisTexto = Color(0xFF5A6A7A);
static const Color grisClaro = Color(0xFFE8ECF0);
```

### Neutros
```dart
static const Color blanco = Color(0xFFFFFFFF);
static const Color negro = Color(0xFF000000);
```

---

## Uso en Flutter Theme
```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF00A859), // Verde S&G
    primary: Color(0xFF00A859),
    secondary: Color(0xFF1D3557), // Azul marino
    tertiary: Color(0xFF006B3D),
  ),
  // ... más configuración
)
```
```

---

## **🎯 Paso 5: Tu primer commit**

Ahora que creaste los archivos, vamos a guardar estos cambios en Git:

### **En GitHub Desktop:**

1. Verás los archivos nuevos en la columna izquierda
2. En **"Summary (required)"** escribe:
```
feat: Configuración inicial del proyecto
```

3. En **"Description"** (opcional):
```
- Proyecto Flutter creado
- Estructura de roadmap agregada
- Paleta de colores S&G definida
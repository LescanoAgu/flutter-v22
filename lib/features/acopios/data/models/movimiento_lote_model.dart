import 'package:equatable/equatable.dart';
import '../../../stock/data/models/stock_model.dart';

/// Tipo de destino del movimiento en lote
enum TipoDestinoLote {
  stock,    // Stock S&G (depósito propio)
  acopio,   // Acopio (cliente en proveedor)
}

/// Item individual en un movimiento en lote
class MovimientoLoteItem extends Equatable {
  final ProductoConStock producto;
  final double cantidad;

  const MovimientoLoteItem({
    required this.producto,
    required this.cantidad,
  });

  @override
  List<Object?> get props => [producto, cantidad];

  /// Monto total del item (si se valoriza)
  double get montoTotal {
    if (producto.precioSinIva == null) return 0;
    return cantidad * producto.precioSinIva!;
  }

  MovimientoLoteItem copyWith({
    ProductoConStock? producto,
    double? cantidad,
  }) {
    return MovimientoLoteItem(
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
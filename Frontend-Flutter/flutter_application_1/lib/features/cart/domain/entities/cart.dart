import 'cart_item.dart';
import '../../../catalog/domain/entities/product.dart';

/// Carrito de compras (estado en memoria, sin persistencia en servidor).
///
/// Calcula subtotales y total de forma consistente a partir de los ítems.
class Cart {
  const Cart({this.items = const []});

  final List<CartItem> items;

  /// Si el carrito no tiene ítems.
  bool get isEmpty => items.isEmpty;

  /// Cantidad total de unidades en el carrito.
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Suma de subtotales de todos los ítems.
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  /// Total de la compra (subtotal; sin impuestos ni envío por ahora).
  double get total => subtotal;

  CartItem? _find(Product product) {
    for (final item in items) {
      if (item.product.id == product.id) return item;
    }
    return null;
  }

  /// Agrega un producto o aumenta su cantidad si ya está en el carrito.
  Cart add(Product product, {int quantity = 1}) {
    final existing = _find(product);
    if (existing != null) {
      return Cart(
        items: items.map((item) {
          if (item.product.id == product.id) {
            return item.copyWith(quantity: item.quantity + quantity);
          }
          return item;
        }).toList(),
      );
    }
    return Cart(items: [...items, CartItem(product: product, quantity: quantity)]);
  }

  /// Elimina un producto del carrito.
  Cart remove(Product product) =>
      Cart(items: items.where((item) => item.product.id != product.id).toList());

  /// Aumenta en uno la cantidad de un producto.
  Cart increment(Product product) => add(product, quantity: 1);

  /// Disminuye en uno la cantidad; si llega a cero, lo elimina.
  Cart decrement(Product product) {
    final existing = _find(product);
    if (existing == null) return this;
    if (existing.quantity <= 1) return remove(product);
    return Cart(
      items: items.map((item) {
        if (item.product.id == product.id) {
          return item.copyWith(quantity: item.quantity - 1);
        }
        return item;
      }).toList(),
    );
  }

  /// Vacía el carrito.
  Cart clear() => const Cart();
}

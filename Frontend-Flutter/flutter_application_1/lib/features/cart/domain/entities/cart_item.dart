import '../../../catalog/domain/entities/product.dart';

/// Ítem del carrito: un producto con su cantidad seleccionada.
class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  /// Precio del ítem (precio unitario × cantidad).
  double get subtotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

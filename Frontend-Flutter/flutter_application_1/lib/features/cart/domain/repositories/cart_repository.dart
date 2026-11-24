import '../entities/cart.dart';
import '../../../catalog/domain/entities/product.dart';

/// Contrato de acceso al carrito. La UI depende de esta interfaz, no de HTTP.
abstract class CartRepository {
  /// Carrito actual en memoria.
  Cart get cart;

  /// Agrega un producto al carrito.
  Future<void> addProduct(Product product, {int quantity = 1});

  /// Elimina un producto del carrito.
  Future<void> removeProduct(Product product);

  /// Aumenta en uno la cantidad de un producto.
  Future<void> incrementQuantity(Product product);

  /// Disminuye en uno la cantidad (elimina si llega a cero).
  Future<void> decrementQuantity(Product product);

  /// Vacía el carrito.
  Future<void> clearCart();
}

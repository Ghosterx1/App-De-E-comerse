import '../../domain/entities/cart.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../domain/repositories/cart_repository.dart';

/// Implementación del carrito en memoria.
///
/// No usa HTTP ni persiste en servidor: el estado vive en memoria mientras la
/// aplicación esté abierta. Esto cumple la arquitectura actual sin depender
/// de endpoints de backend inexistentes.
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl._();
  static final CartRepositoryImpl _instance = CartRepositoryImpl._();
  factory CartRepositoryImpl() => _instance;

  Cart _cart = const Cart();

  @override
  Cart get cart => _cart;

  @override
  Future<void> addProduct(Product product, {int quantity = 1}) async {
    if (quantity < 1) {
      throw const InvalidCartQuantityException('La cantidad debe ser al menos 1.');
    }
    _cart = _cart.add(product, quantity: quantity);
  }

  @override
  Future<void> removeProduct(Product product) async {
    _cart = _cart.remove(product);
  }

  @override
  Future<void> incrementQuantity(Product product) async {
    _cart = _cart.increment(product);
  }

  @override
  Future<void> decrementQuantity(Product product) async {
    _cart = _cart.decrement(product);
  }

  @override
  Future<void> clearCart() async {
    _cart = const Cart();
  }
}

/// Error de cantidad inválida en el carrito.
class InvalidCartQuantityException implements Exception {
  const InvalidCartQuantityException(this.message);
  final String message;
  @override
  String toString() => message;
}

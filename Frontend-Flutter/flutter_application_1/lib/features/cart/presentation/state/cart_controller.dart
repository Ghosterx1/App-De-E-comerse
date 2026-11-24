import 'package:flutter/foundation.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';

/// Estado del carrito de compras.
///
/// Es un [ChangeNotifier] puro: gestiona ítems, cantidades y totales sin
/// conocer widgets ni HTTP. Así se puede probar de forma aislada y se mantiene
/// coherente durante la navegación.
class CartController extends ChangeNotifier {
  CartController(this._repository);

  final CartRepository _repository;
  bool _isDisposed = false;

  /// Carrito actual.
  Cart get cart => _repository.cart;

  /// Si no hay ítems.
  bool get isEmpty => cart.isEmpty;

  /// Cantidad total de unidades.
  int get totalItems => cart.totalItems;

  /// Suma de subtotales.
  double get subtotal => cart.subtotal;

  /// Total de la compra.
  double get total => cart.total;

  /// Ítems del carrito (inmodificables desde la UI).
  List<CartItem> get items => List.unmodifiable(cart.items);

  /// Agrega un producto al carrito.
  Future<void> addProduct(Product product, {int quantity = 1}) async {
    await _repository.addProduct(product, quantity: quantity);
    _notify();
  }

  /// Elimina un producto del carrito.
  Future<void> removeProduct(Product product) async {
    await _repository.removeProduct(product);
    _notify();
  }

  /// Aumenta en uno la cantidad de un producto.
  Future<void> incrementQuantity(Product product) async {
    await _repository.incrementQuantity(product);
    _notify();
  }

  /// Disminuye en uno la cantidad (elimina si llega a cero).
  Future<void> decrementQuantity(Product product) async {
    await _repository.decrementQuantity(product);
    _notify();
  }

  /// Vacía el carrito.
  Future<void> clearCart() async {
    await _repository.clearCart();
    _notify();
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

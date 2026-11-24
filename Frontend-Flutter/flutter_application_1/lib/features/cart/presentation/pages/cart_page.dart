import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../domain/entities/cart_item.dart';
import '../state/cart_controller.dart';

/// Pantalla del carrito de compras.
///
/// Muestra los productos agregados, permite modificar cantidades, eliminarlos
/// y ver el total de la compra. El estado se mantiene en memoria mientras la
/// aplicación está abierta (sin persistencia en servidor).
class CartPage extends StatelessWidget {
  const CartPage({super.key, required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          Stack(
            alignment: Alignment.centerRight,
            children: [
              IconButton(
                tooltip: 'Carrito',
                onPressed: () {},
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (controller.totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${controller.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.isEmpty) {
            return EmptyView(
              message: 'Tu carrito está vacío.\nAgrega productos desde el catálogo.',
              icon: Icons.shopping_cart_outlined,
              actionLabel: 'Explorar catálogo',
              actionIcon: Icons.storefront_outlined,
              onAction: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) {
                    final item = controller.items[index];
                    return _CartItemTile(
                      item: item,
                      onIncrement: () =>
                          controller.incrementQuantity(item.product),
                      onDecrement: () =>
                          controller.decrementQuantity(item.product),
                      onRemove: () => _removeItem(context, item),
                    );
                  },
                ),
              ),
              _PurchaseSummary(
                items: controller.items.length,
                totalItems: controller.totalItems,
                subtotal: controller.subtotal,
                total: controller.total,
                onCheckout: () => _checkout(context),
                onClear: () => _clearCart(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removeItem(BuildContext context, CartItem item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Eliminar producto',
      message:
          '¿Quieres quitar "${item.product.name}" del carrito?',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      controller.removeProduct(item.product);
      AppSnackBar.showSuccess(context, 'Producto eliminado del carrito.');
    }
  }

  Future<void> _clearCart(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Vaciar carrito',
      message:
          '¿Estás seguro de que quieres eliminar todos los productos del carrito?',
      confirmLabel: 'Vaciar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      controller.clearCart();
      AppSnackBar.showSuccess(context, 'Carrito vacío.');
    }
  }

  Future<void> _checkout(BuildContext context) async {
    AppSnackBar.showSuccess(
      context,
      'Compra procesada por \$${formatPrice(controller.total)}. '
      '¡Gracias por tu compra!',
    );
    await controller.clearCart();
    if (context.mounted) {
      Navigator.of(context).pushNamed(AppRoutes.home);
    }
  }
}

/// Fila de un ítem del carrito: imagen, nombre, precio unitario, cantidad y eliminar.
class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final product = item.product;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                        errorBuilder: (context, error, stackTrace) => _PlaceholderImage(),
                      )
                    : _PlaceholderImage(),
              ),
            ),
            const SizedBox(width: 14),
            // Nombre, precio unitario y subtotal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(product.price),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Subtotal: ${formatPrice(item.subtotal)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // Controles de cantidad
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onPressed: onDecrement,
                      isMinus: true,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onPressed: onIncrement,
                      isMinus: false,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de cantidad (+ o -).
class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.isMinus,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isMinus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        color: colorScheme.onSurface,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }
}

/// Placeholder cuando no hay imagen del producto.
class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        color: colorScheme.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}

/// Resumen de compra al final del carrito.
class _PurchaseSummary extends StatelessWidget {
  const _PurchaseSummary({
    required this.items,
    required this.totalItems,
    required this.subtotal,
    required this.total,
    required this.onCheckout,
    required this.onClear,
  });

  final int items;
  final int totalItems;
  final double subtotal;
  final double total;
  final VoidCallback onCheckout;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen ($items ${items == 1 ? 'producto' : 'productos'})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$totalItems unidad${totalItems == 1 ? '' : 's'}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Subtotal',
            value: formatPrice(subtotal),
            isHighlighted: false,
          ),
          _SummaryRow(
            label: 'Total',
            value: formatPrice(total),
            isHighlighted: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Vaciar carrito'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onCheckout,
                  child: const Text('Continuar con la compra'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila de un concepto del resumen (subtotal / total).
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.isHighlighted,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: isHighlighted ? colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

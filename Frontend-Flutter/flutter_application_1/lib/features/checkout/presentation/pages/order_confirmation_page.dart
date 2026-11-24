import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routing/app_routes.dart';
import '../pages/checkout_page.dart' show OrderConfirmationArguments;

/// Pantalla de confirmación de orden de compra.
///
/// Muestra el número de orden, fecha y total. Es el paso final del flujo de
/// compra simulada. El carrito ya se vació al llegar a esta pantalla.
class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key, required this.arguments});

  final OrderConfirmationArguments arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compra realizada'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Compra exitosa!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tu orden ha sido procesada correctamente.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _OrderDetailRow(
                    label: 'Número de orden',
                    value: arguments.orderId,
                  ),
                  _OrderDetailRow(
                    label: 'Fecha',
                    value: '${arguments.date.day}/${arguments.date.month}/${arguments.date.year}',
                  ),
                  _OrderDetailRow(
                    label: 'Productos',
                    value: '${arguments.items} ${arguments.items == 1 ? 'producto' : 'productos'}',
                  ),
                  _OrderDetailRow(
                    label: 'Total',
                    value: formatPrice(arguments.total),
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.home,
                          (route) => false,
                        );
                      },
                      child: const Text('Volver al inicio'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de detalle de la orden.
class _OrderDetailRow extends StatelessWidget {
  const _OrderDetailRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isHighlighted ? colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

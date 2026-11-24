import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../cart/presentation/state/cart_controller.dart';

/// Pantalla de checkout (simulada).
///
/// Muestra el resumen del pedido y un formulario de pago de referencia.
/// No se procesa ningún pago real ni se envían datos de tarjeta a servidor.
/// El estado del carrito se mantiene en memoria y se vacía tras la compra.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key, required this.controller});

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar compra'),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.isEmpty) {
            return const Center(
              child: Text('Tu carrito está vacío.'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _OrderSummary(
                      items: controller.items.length,
                      totalItems: controller.totalItems,
                      subtotal: controller.subtotal,
                      total: controller.total,
                    ),
                    const SizedBox(height: 24),
                    const _PaymentForm(),
                  ],
                ),
              ),
              _CheckoutButtonBar(
                total: controller.total,
                onPay: () => _processPurchase(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processPurchase(BuildContext context) async {
    // Simular tiempo de procesamiento de pago
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProcessingDialog(),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;
    Navigator.of(context).pop(); // cerrar dialogo de procesamiento

    if (!context.mounted) return;

    // Simular éxito de compra (en un entorno real aquí iría la llamada a la pasarela)
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    await Navigator.of(context).pushNamed(
      AppRoutes.orderConfirmation,
      arguments: OrderConfirmationArguments(
        orderId: orderId,
        total: controller.total,
        items: controller.items.length,
        date: DateTime.now(),
      ),
    );

    // Vaciar carrito tras navegar a confirmación
    controller.clearCart();
    if (context.mounted) {
      AppSnackBar.showSuccess(context, 'Compra realizada con éxito.');
    }
  }
}

/// Resumen del pedido en el checkout.
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.items,
    required this.totalItems,
    required this.subtotal,
    required this.total,
  });

  final int items;
  final int totalItems;
  final double subtotal;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumen del pedido',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Productos', value: '$items ${items == 1 ? 'producto' : 'productos'}'),
            _SummaryRow(label: 'Unidades', value: '$totalItems ${totalItems == 1 ? 'unidad' : 'unidades'}'),
            const Divider(),
            _SummaryRow(label: 'Subtotal', value: formatPrice(subtotal), isHighlighted: false),
            const Divider(),
            _SummaryRow(label: 'Total', value: formatPrice(total), isHighlighted: true),
          ],
        ),
      ),
    );
  }
}

/// Formulario de pago de referencia (sin envío de datos reales).
class _PaymentForm extends StatefulWidget {
  const _PaymentForm();

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Datos de pago',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo electrónico.';
                  }
                  if (!value.contains('@')) {
                    return 'Correo inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el número de tarjeta.';
                  }
                  if (value.replaceAll(' ', '').length < 13) {
                    return 'Número de tarjeta inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Vencimiento (MM/AA)',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      maxLength: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa la fecha de vencimiento.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      maxLength: 3,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el CVV.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre en la tarjeta',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa el nombre.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de botones inferior del checkout.
class _CheckoutButtonBar extends StatelessWidget {
  const _CheckoutButtonBar({
    required this.total,
    required this.onPay,
  });

  final double total;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPay,
          child: Text('Pagar \$${formatPrice(total)}'),
        ),
      ),
    );
  }
}

/// Fila de un concepto del resumen.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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

/// Diálogo de procesamiento de pago.
class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando pago...'),
          ],
        ),
      ),
    );
  }
}

/// Argumentos para la pantalla de confirmación de orden.
class OrderConfirmationArguments {
  const OrderConfirmationArguments({
    required this.orderId,
    required this.total,
    required this.items,
    required this.date,
  });

  final String orderId;
  final double total;
  final int items;
  final DateTime date;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../cart/presentation/state/cart_controller.dart';

/// Pantalla de checkout (simulada).
///
/// Muestra el resumen del pedido y un formulario de pago de referencia.
/// No se procesa ningún pago real ni se envían datos de tarjeta a servidor.
/// El estado del carrito se mantiene en memoria y se vacía tras la compra.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.controller});

  final CartController controller;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar compra'),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isEmpty) {
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
                      items: widget.controller.items.length,
                      totalItems: widget.controller.totalItems,
                      subtotal: widget.controller.subtotal,
                      total: widget.controller.total,
                    ),
                    const SizedBox(height: 24),
                    _PaymentForm(formKey: _formKey),
                  ],
                ),
              ),
              _CheckoutButtonBar(
                total: widget.controller.total,
                onPay: () => _processPurchase(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processPurchase(BuildContext context) async {
    // Validar que todos los campos del formulario sean correctos
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnackBar.showError(
        context,
        'Por favor completa todos los campos correctamente antes de continuar.',
      );
      return;
    }

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
        total: widget.controller.total,
        items: widget.controller.items.length,
        date: DateTime.now(),
      ),
    );

    // Vaciar carrito tras navegar a confirmación
    widget.controller.clearCart();
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
  const _PaymentForm({required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
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
          key: widget.formKey,
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
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo electrónico es obligatorio.';
                  }
                  final emailRegExp = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegExp.hasMatch(value.trim())) {
                    return 'Ingresa un correo electrónico válido.';
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                maxLength: 16,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número de tarjeta es obligatorio.';
                  }
                  final digits = value.replaceAll(' ', '');
                  if (digits.length != 16) {
                    return 'El número de tarjeta debe tener 16 dígitos.';
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
                        hintText: 'MM/AA',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                        ExpiryDateFormatter(),
                      ],
                      maxLength: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La fecha de vencimiento es obligatoria.';
                        }
                        final expiryRegExp =
                            RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{2}$');
                        if (!expiryRegExp.hasMatch(value.trim())) {
                          return 'Ingresa una fecha válida en formato MM/AA.';
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
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El CVV es obligatorio.';
                        }
                        if (value.trim().length != 3) {
                          return 'El CVV debe tener 3 dígitos.';
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                  ),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  final nameRegExp = RegExp(
                    r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$',
                  );
                  if (!nameRegExp.hasMatch(value.trim())) {
                    return 'Ingresa solo letras y espacios.';
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

/// Formateador de fecha de vencimiento MM/AA.
/// Inserta automáticamente la barra después de los primeros dos dígitos.
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    if (text.length == 1) {
      return newValue.copyWith(text: text);
    }

    if (text.length >= 2) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      return newValue.copyWith(
        text: formatted.length > 5 ? formatted.substring(0, 5) : formatted,
        selection: TextSelection.collapsed(
          offset: formatted.length > 5 ? 5 : formatted.length,
        ),
      );
    }

    return newValue;
  }
}

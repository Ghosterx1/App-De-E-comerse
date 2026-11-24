import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/routing/app_routes.dart';
import 'package:flutter_application_1/features/auth/domain/entities/auth_exception.dart';
import 'package:flutter_application_1/features/auth/presentation/state/auth_controller.dart';
import 'package:flutter_application_1/features/employees/presentation/state/employee_controller.dart';
import 'package:flutter_application_1/features/cart/presentation/state/cart_controller.dart';
import 'package:flutter_application_1/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:flutter_application_1/features/home/presentation/state/home_controller.dart';

import '../../fakes/fake_auth.dart';
import '../../fakes/fake_employee_repository.dart';
import '../../fakes/fake_product_repository.dart';

Future<AuthController> _pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? repository,
  bool initialize = false,
}) async {
  final authController = AuthController(repository ?? FakeAuthRepository());
  if (initialize) {
    await authController.initialize();
  }

  final employeeController = EmployeeController(FakeEmployeeRepository());
  await employeeController.load();
  final productRepository = FakeProductRepository();
  final cartRepository = CartRepositoryImpl();
  final cartController = CartController(cartRepository);

  await tester.pumpWidget(
    EcommerceApp(
      employeeController: employeeController,
      authController: authController,
      homeController: HomeController(productRepository),
      productRepository: productRepository,
      cartController: cartController,
      initialRoute: AppRoutes.employees,
    ),
  );
  await tester.pumpAndSettle();
  return authController;
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Iniciar sesión'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abre el formulario de login desde el AppBar', (tester) async {
    await _pumpApp(tester);
    await _openLogin(tester);

    expect(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });

  testWidgets('valida campos vacíos antes de llamar al repositorio', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpApp(tester, repository: repository);
    await _openLogin(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Debes escribir tu correo.'), findsOneWidget);
    expect(find.text('Debes escribir tu contraseña.'), findsOneWidget);
    expect(repository.loginCalls, 0);
  });

  testWidgets('un login exitoso vuelve a la lista y muestra la cuenta', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final authController = await _pumpApp(tester, repository: repository);
    await _openLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Segura123');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Empleados'), findsOneWidget);
    expect(
      find.textContaining('Sesión iniciada como ana@example.com'),
      findsOneWidget,
    );
    expect(authController.isAuthenticated, isTrue);
    expect(repository.loginCalls, 1);
    expect(repository.lastLoginPassword, 'Segura123');
  });

  testWidgets('un login rechazado muestra el mensaje del backend', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      loginError: const InvalidCredentialsAuthException(
        'Credenciales inválidas.',
      ),
    );
    final authController = await _pumpApp(tester, repository: repository);
    await _openLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrecta');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Credenciales inválidas.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
    expect(authController.isAuthenticated, isFalse);
  });
}

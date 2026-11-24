import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/routing/app_routes.dart';
import 'package:flutter_application_1/features/auth/domain/entities/auth_session.dart';
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

Future<void> _openRegister(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Iniciar sesión'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('¿No tienes cuenta? Crear cuenta'));
  await tester.pumpAndSettle();
}

Future<void> _submitRegister(WidgetTester tester) async {
  final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el registro valida nombre, correo y contraseña', (tester) async {
    final repository = FakeAuthRepository();
    await _pumpApp(tester, repository: repository);
    await _openRegister(tester);

    await _submitRegister(tester);

    expect(find.text('Debes escribir tu nombre.'), findsOneWidget);
    expect(find.text('Debes escribir tu correo.'), findsOneWidget);
    expect(find.text('Debes escribir una contraseña.'), findsOneWidget);
    expect(find.text('Repite la contraseña.'), findsOneWidget);
    expect(repository.registerCalls, 0);
  });

  testWidgets('el registro rechaza contraseñas que no coinciden', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpApp(tester, repository: repository);
    await _openRegister(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Segura123');
    await tester.enterText(find.byType(TextFormField).at(3), 'Distinta123');
    await _submitRegister(tester);

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(repository.registerCalls, 0);
  });

  testWidgets('un registro exitoso autentica y vuelve a la lista', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    final authController = await _pumpApp(tester, repository: repository);
    await _openRegister(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Segura123');
    await tester.enterText(find.byType(TextFormField).at(3), 'Segura123');
    await _submitRegister(tester);

    expect(find.text('Empleados'), findsOneWidget);
    expect(authController.isAuthenticated, isTrue);
    expect(repository.lastName, 'Ana Pérez');
    expect(repository.registerCalls, 1);
  });

  testWidgets('logout pide confirmación y borra las credenciales', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      storedSession: const AuthSession(
        token: 'token',
        email: 'ana@example.com',
      ),
    );
    final authController = await _pumpApp(
      tester,
      repository: repository,
      initialize: true,
    );

    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(authController.isAuthenticated, isFalse);
    expect(repository.logoutCalls, 1);
    expect(find.byTooltip('Iniciar sesión'), findsOneWidget);
    expect(find.text('Sesión cerrada.'), findsOneWidget);
  });
}

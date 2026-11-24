// Pruebas de widget SIN red: usan un repositorio falso en memoria.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/network/api_exception.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/routing/app_routes.dart';
import 'package:flutter_application_1/features/auth/presentation/state/auth_controller.dart';
import 'package:flutter_application_1/features/employees/domain/entities/employee.dart';
import 'package:flutter_application_1/features/employees/presentation/state/employee_controller.dart';
import 'package:flutter_application_1/features/cart/presentation/state/cart_controller.dart';
import 'package:flutter_application_1/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:flutter_application_1/features/home/presentation/state/home_controller.dart';

import 'fakes/fake_auth.dart';
import 'fakes/fake_employee_repository.dart';
import 'fakes/fake_product_repository.dart';

EcommerceApp _buildApp(EmployeeController employeeController) {
  final productRepository = FakeProductRepository();
  final cartRepository = CartRepositoryImpl();
  final cartController = CartController(cartRepository);
  return EcommerceApp(
    employeeController: employeeController,
    authController: AuthController(FakeAuthRepository()),
    homeController: HomeController(productRepository),
    productRepository: productRepository,
    cartController: cartController,
    initialRoute: AppRoutes.employees,
  );
}

void main() {
  const ana = Employee(
    id: 1,
    firstName: 'Ana',
    lastName: 'Pérez',
    email: 'ana.perez@example.com',
  );

  testWidgets('muestra los empleados que devuelve el repositorio', (
    tester,
  ) async {
    final repository = FakeEmployeeRepository(employees: const [ana]);
    final controller = EmployeeController(repository);
    await controller.load();

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Empleados'), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('ana.perez@example.com'), findsOneWidget);
  });

  testWidgets('muestra el estado vacío cuando no hay empleados', (
    tester,
  ) async {
    final controller = EmployeeController(FakeEmployeeRepository());
    await controller.load();

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay empleados registrados.'), findsOneWidget);
    expect(find.text('Agregar empleado'), findsOneWidget);
  });

  testWidgets('muestra el error de red y permite reintentar', (tester) async {
    final repository = FakeEmployeeRepository(
      error: const NetworkApiException('No se pudo conectar con el servidor.'),
    );
    final controller = EmployeeController(repository);
    await controller.load();

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo conectar con el servidor.'), findsNothing);
    expect(repository.fetchCalls, 2);
  });

  testWidgets('abre el formulario de alta desde el botón Agregar', (
    tester,
  ) async {
    final controller = EmployeeController(
      FakeEmployeeRepository(employees: const [ana]),
    );
    await controller.load();

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo empleado'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nombre'), findsOneWidget);
  });

  testWidgets('abre el formulario de edición con los datos del empleado', (
    tester,
  ) async {
    final controller = EmployeeController(
      FakeEmployeeRepository(employees: const [ana]),
    );
    await controller.load();

    await tester.pumpWidget(_buildApp(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar empleado'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Ana'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'ana.perez@example.com'),
      findsOneWidget,
    );
  });
}

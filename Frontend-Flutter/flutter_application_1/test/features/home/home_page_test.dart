import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/network/api_exception.dart';
import 'package:flutter_application_1/core/routing/app_routes.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/auth/presentation/state/auth_controller.dart';
import 'package:flutter_application_1/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:flutter_application_1/features/cart/presentation/state/cart_controller.dart';
import 'package:flutter_application_1/features/home/presentation/pages/home_page.dart';
import 'package:flutter_application_1/features/home/presentation/state/home_controller.dart';

import '../../fakes/fake_auth.dart';
import '../../fakes/fake_product_repository.dart';
import '../../fakes/sample_products.dart';

Future<HomeController> _pumpHome(
  WidgetTester tester,
  FakeProductRepository repository, {
  Size size = const Size(1200, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = HomeController(repository);
  await controller.load();
  final cartRepository = CartRepositoryImpl();
  final cartController = CartController(cartRepository);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: HomePage(
        controller: controller,
        authController: AuthController(FakeAuthRepository()),
        cartController: cartController,
      ),
      routes: {
        AppRoutes.catalog: (_) =>
            const Scaffold(body: Text('Destino catálogo')),
      },
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('muestra identidad, categorías y secciones del backend', (
    tester,
  ) async {
    final repository = FakeProductRepository(
      products: sampleProducts(),
      categories: sampleCategories,
    );
    await _pumpHome(tester, repository);

    expect(find.text('E-Commerce'), findsOneWidget);
    expect(find.byTooltip('Iniciar sesión'), findsOneWidget);
    expect(find.byTooltip('Carrito'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Destacados'), findsOneWidget);
    expect(find.text('Recién llegados'), findsOneWidget);
    expect(find.text('Productos disponibles'), findsOneWidget);
    expect(find.text('Tecnología'), findsOneWidget);
    expect(find.text('Auriculares Nova Pro'), findsWidgets);
  });

  testWidgets('el buscador abre el catálogo con el término escrito', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      FakeProductRepository(
        products: sampleProducts(),
        categories: sampleCategories,
      ),
    );

    await tester.enterText(find.byType(TextField), 'reloj');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Destino catálogo'), findsOneWidget);
  });

  testWidgets('muestra el mensaje de error y se recupera', (tester) async {
    final repository = FakeProductRepository(
      products: sampleProducts(),
      categories: sampleCategories,
      error: const NetworkApiException('Sin conexión con la tienda.'),
    );
    await _pumpHome(tester, repository);

    expect(find.text('Sin conexión con la tienda.'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Productos disponibles'), findsOneWidget);
    expect(find.text('Auriculares Nova Pro'), findsWidgets);
  });

  testWidgets('muestra el estado vacío si la tienda no tiene productos', (
    tester,
  ) async {
    await _pumpHome(tester, FakeProductRepository());

    expect(
      find.text('Aún no hay productos disponibles en la tienda.'),
      findsOneWidget,
    );
  });

  testWidgets('se adapta a un viewport móvil estrecho sin desbordar', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      FakeProductRepository(
        products: sampleProducts(),
        categories: sampleCategories,
      ),
      size: const Size(360, 800),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('E-Commerce'), findsOneWidget);
    expect(find.byTooltip('Carrito'), findsOneWidget);
  });
}

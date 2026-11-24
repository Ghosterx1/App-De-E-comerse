import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/network/api_exception.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/auth/presentation/state/auth_controller.dart';
import 'package:flutter_application_1/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:flutter_application_1/features/cart/presentation/state/cart_controller.dart';
import 'package:flutter_application_1/features/catalog/presentation/pages/catalog_page.dart';

import '../../fakes/fake_auth.dart';
import '../../fakes/fake_product_repository.dart';
import '../../fakes/sample_products.dart';

Future<void> _pumpCatalog(
  WidgetTester tester,
  FakeProductRepository repository,
) async {
  final cartRepository = CartRepositoryImpl();
  final cartController = CartController(cartRepository);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CatalogPage(
        repository: repository,
        authController: AuthController(FakeAuthRepository()),
        cartController: cartController,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el catálogo del backend con sus filtros', (
    tester,
  ) async {
    final repository = FakeProductRepository(
      products: sampleProducts(),
      categories: sampleCategories,
    );
    await _pumpCatalog(tester, repository);

    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('5 productos'), findsOneWidget);
    expect(find.text('Auriculares Nova Pro'), findsOneWidget);
    expect(find.text('Solo disponibles'), findsOneWidget);
    expect(find.text('Tecnología'), findsOneWidget);
  });

  testWidgets('filtra por categoría y disponibilidad reales', (tester) async {
    final repository = FakeProductRepository(
      products: sampleProducts(),
      categories: sampleCategories,
    );
    await _pumpCatalog(tester, repository);

    await tester.tap(find.text('Tecnología'));
    await tester.pumpAndSettle();
    expect(find.text('2 productos'), findsOneWidget);
    expect(repository.requests.last.categoryId, tecnologia.id);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solo disponibles'));
    await tester.pumpAndSettle();
    expect(find.text('4 productos'), findsOneWidget);
    expect(repository.requests.last.available, isTrue);
  });

  testWidgets('la búsqueda envía el término al backend', (tester) async {
    final repository = FakeProductRepository(
      products: sampleProducts(),
      categories: sampleCategories,
    );
    await _pumpCatalog(tester, repository);

    await tester.enterText(find.byType(TextField), 'reloj');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('1 producto'), findsOneWidget);
    expect(find.text('Reloj inteligente Pulse'), findsOneWidget);
    expect(repository.requests.last.search, 'reloj');
  });

  testWidgets('muestra el estado vacío cuando no hay coincidencias', (
    tester,
  ) async {
    await _pumpCatalog(tester, FakeProductRepository());

    expect(
      find.text('Todavía no hay productos disponibles en el catálogo.'),
      findsOneWidget,
    );
  });

  testWidgets('muestra el error y permite reintentar', (tester) async {
    final repository = FakeProductRepository(
      products: sampleProducts(),
      categories: sampleCategories,
      error: const NetworkApiException('Servidor no disponible.'),
    );
    await _pumpCatalog(tester, repository);

    expect(find.text('Servidor no disponible.'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('5 productos'), findsOneWidget);
    expect(find.text('Auriculares Nova Pro'), findsOneWidget);
  });

  testWidgets('se adapta a un viewport móvil estrecho sin desbordar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpCatalog(
      tester,
      FakeProductRepository(
        products: sampleProducts(),
        categories: sampleCategories,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.text('5 productos'), findsOneWidget);
  });
}

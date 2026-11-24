import 'package:flutter/material.dart';

import 'core/routing/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/state/auth_controller.dart';
import 'features/cart/presentation/state/cart_controller.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/catalog/domain/repositories/product_repository.dart';
import 'features/catalog/presentation/pages/catalog_page.dart';
import 'features/employees/domain/entities/employee.dart';
import 'features/employees/presentation/pages/employee_form_page.dart';
import 'features/employees/presentation/pages/employee_list_page.dart';
import 'features/employees/presentation/state/employee_controller.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/state/home_controller.dart';
import 'features/profile/presentation/pages/profile_page.dart';

/// Raíz de la aplicación.
///
/// Concentra el tema, las rutas y el `MaterialApp`. La creación de
/// dependencias vive en `main.dart`, así que esta clase se puede montar en
/// pruebas con cualquier estado simulado.
class EcommerceApp extends StatelessWidget {
  const EcommerceApp({
    super.key,
    required this.employeeController,
    required this.authController,
    required this.homeController,
    required this.productRepository,
    required this.cartController,
    this.initialRoute = AppRoutes.home,
  });

  final EmployeeController employeeController;
  final AuthController authController;
  final HomeController homeController;
  final ProductRepository productRepository;
  final CartController cartController;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => HomePage(
            controller: homeController,
            authController: authController,
            cartController: cartController,
          ),
        );
      case AppRoutes.catalog:
        final arguments = settings.arguments;
        final catalogArguments = arguments is CatalogArguments
            ? arguments
            : null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => CatalogPage(
            repository: productRepository,
            authController: authController,
            cartController: cartController,
            initialQuery: catalogArguments?.query,
            initialCategoryId: catalogArguments?.categoryId,
          ),
        );
      case AppRoutes.profile:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ProfilePage(authController: authController),
        );
      case AppRoutes.cart:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => CartPage(controller: cartController),
        );
      case AppRoutes.employees:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => EmployeeListPage(
            controller: employeeController,
            authController: authController,
          ),
        );
      case AppRoutes.login:
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => LoginPage(controller: authController),
        );
      case AppRoutes.register:
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => RegisterPage(controller: authController),
        );
      case AppRoutes.employeeForm:
        final employee = settings.arguments is Employee
            ? settings.arguments as Employee
            : null;
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (_) => EmployeeFormPage(
            employee: employee,
            onSubmit: (input) async {
              final saved = await employeeController.save(
                existing: employee,
                input: input,
              );
              return saved
                  ? null
                  : employeeController.actionErrorMessage ??
                        'No se pudo guardar el empleado.';
            },
          ),
        );
    }
    // Fallback: una ruta desconocida vuelve al inicio en lugar de romper.
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) =>
          HomePage(controller: homeController, authController: authController, cartController: cartController),
    );
  }
}

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/token_storage.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/state/auth_controller.dart';
import 'features/cart/data/repositories/cart_repository_impl.dart';
import 'features/cart/presentation/state/cart_controller.dart';
import 'features/catalog/data/datasources/product_remote_data_source.dart';
import 'features/catalog/data/repositories/product_repository_impl.dart';
import 'features/catalog/domain/repositories/product_repository.dart';
import 'features/employees/data/datasources/employee_remote_data_source.dart';
import 'features/employees/data/repositories/employee_repository_impl.dart';
import 'features/employees/domain/repositories/employee_repository.dart';
import 'features/employees/presentation/state/employee_controller.dart';
import 'features/home/presentation/state/home_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final authController = buildAuthController();
  // Antes de montar la UI se recupera la sesión persistida, para que el primer
  // frame ya conozca si hay un usuario autenticado.
  await authController.initialize();

  final apiClient = buildApiClient(
    config: config,
    authController: authController,
  );
  final employeeController = buildEmployeeController(
    config: config,
    apiClient: apiClient,
  )..load();
  final productRepository = buildProductRepository(apiClient: apiClient);
  final homeController = HomeController(productRepository)..load();
  final cartRepository = CartRepositoryImpl();
  final cartController = CartController(cartRepository);

  runApp(
    EcommerceApp(
      employeeController: employeeController,
      authController: authController,
      homeController: homeController,
      productRepository: productRepository,
      cartController: cartController,
    ),
  );
}

/// Punto único de composición de la autenticación.
///
/// `PendingAuthRemoteDataSource` es el adaptador provisional mientras el
/// backend no exponga endpoints de autenticación. Cuando exista el contrato
/// real, solo se reemplaza aquí por el adaptador HTTP correspondiente.
AuthController buildAuthController({
  AuthRemoteDataSource? remoteDataSource,
  TokenStorage? tokenStorage,
}) {
  final repository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource ?? const PendingAuthRemoteDataSource(),
    tokenStorage: tokenStorage ?? SecureTokenStorage(),
  );
  return AuthController(repository);
}

/// Cliente HTTP compartido: inyecta el JWT en cada petición y notifica los 401
/// al controlador de autenticación para cerrar la sesión local.
ApiClient buildApiClient({
  required AppConfig config,
  required AuthController authController,
}) {
  return ApiClient(
    baseUrl: config.apiBaseUrl,
    timeout: config.requestTimeout,
    tokenProvider: () => authController.token,
    onUnauthorized: authController.expireSession,
  );
}

/// Punto único de composición de dependencias (inyección manual).
///
/// Aquí —y solo aquí— se decide la URL del backend, el cliente HTTP y quién
/// implementa el repositorio. Cambiar de entorno no obliga a tocar la UI.
EmployeeController buildEmployeeController({
  AppConfig? config,
  ApiClient? apiClient,
}) {
  final appConfig = config ?? AppConfig.fromEnvironment();
  final client =
      apiClient ??
      ApiClient(
        baseUrl: appConfig.apiBaseUrl,
        timeout: appConfig.requestTimeout,
      );
  final EmployeeRepository repository = EmployeeRepositoryImpl(
    EmployeeRemoteDataSource(client),
  );
  return EmployeeController(repository);
}

/// Punto de composición del catálogo. La UI solo conoce
/// [ProductRepository], de modo que las pruebas puedan sustituirlo.
ProductRepository buildProductRepository({required ApiClient apiClient}) {
  return ProductRepositoryImpl(ProductRemoteDataSource(apiClient));
}

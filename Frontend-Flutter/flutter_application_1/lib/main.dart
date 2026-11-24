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
  final apiClient = buildApiClient(config: config);
  final authController = buildAuthController(apiClient: apiClient);
  // El cliente HTTP consulta el token en cada petición y notifica los 401 al
  // controlador para cerrar la sesión local sin reconstruir dependencias.
  apiClient
    ..tokenProvider = (() => authController.token)
    ..onUnauthorized = authController.expireSession;
  // Antes de montar la UI se recupera la sesión persistida, para que el primer
  // frame ya conozca si hay un usuario autenticado.
  await authController.initialize();

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
/// Con [apiClient] se usa el adaptador HTTP real contra `/api/v1/auth`; sin él
/// se conserva el adaptador pendiente para pruebas o demos sin backend.
AuthController buildAuthController({
  AuthRemoteDataSource? remoteDataSource,
  TokenStorage? tokenStorage,
  ApiClient? apiClient,
}) {
  final effectiveRemoteDataSource =
      remoteDataSource ??
      (apiClient == null
          ? const PendingAuthRemoteDataSource()
          : HttpAuthRemoteDataSource(apiClient));
  final repository = AuthRepositoryImpl(
    remoteDataSource: effectiveRemoteDataSource,
    tokenStorage: tokenStorage ?? SecureTokenStorage(),
  );
  return AuthController(repository);
}

/// Cliente HTTP compartido por todos los repositorios.
///
/// Los callbacks de sesión se asignan en `main` después de crear el
/// [AuthController], porque ambos dependen entre sí. El cliente consulta el
/// token de forma dinámica, así que iniciar o cerrar sesión no requiere crear
/// una instancia nueva.
ApiClient buildApiClient({required AppConfig config}) {
  return ApiClient(baseUrl: config.apiBaseUrl, timeout: config.requestTimeout);
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



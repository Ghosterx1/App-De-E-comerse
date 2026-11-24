/// Nombres de ruta centralizados.
///
/// Tener las rutas en un solo lugar evita cadenas mágicas repartidas por la UI
/// y deja preparada la aplicación para añadir nuevas pantallas (login, catálogo,
/// carrito) sin acoplar las páginas entre sí.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String catalog = '/catalog';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String profile = '/profile';
  static const String employees = '/employees';
  static const String employeeForm = '/employees/form';
  static const String login = '/login';
  static const String register = '/register';
  static const String orderConfirmation = '/order-confirmation';
}

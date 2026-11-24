import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../../cart/presentation/state/cart_controller.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/domain/entities/product_category.dart';
import '../../../catalog/presentation/pages/catalog_page.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../../../catalog/presentation/widgets/product_search_field.dart';
import '../../../catalog/presentation/widgets/section_header.dart';
import '../../../catalog/presentation/widgets/store_app_bar_actions.dart';
import '../state/home_controller.dart';

/// Pantalla principal de la tienda.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.authController,
    required this.cartController,
  });

  final HomeController controller;
  final AuthController authController;
  final CartController cartController;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  HomeController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    if (!_controller.hasLoadedOnce && !_controller.isLoading) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCatalog({String? query, int? categoryId}) {
    Navigator.of(context).pushNamed(
      AppRoutes.catalog,
      arguments: CatalogArguments(query: query, categoryId: categoryId),
    );
  }

  void _submitSearch(String value) {
    final query = value.trim();
    _openCatalog(query: query.isEmpty ? null : query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const _StoreBrand(),
        actions: [
          StoreAppBarActions(authController: widget.authController),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && !_controller.hasLoadedOnce) {
            return const LoadingView(message: 'Cargando la tienda...');
          }
          if (_controller.errorMessage != null && !_controller.hasLoadedOnce) {
            return ErrorView(
              message: _controller.errorMessage!,
              details: _controller.errorDetails,
              onRetry: _controller.retry,
            );
          }
          return _HomeContent(
            controller: _controller,
            searchController: _searchController,
            onSearch: _submitSearch,
            onOpenCatalog: _openCatalog,
            onAddToCart: (product) {
              widget.cartController.addProduct(product);
            },
          );
        },
      ),
    );
  }
}

class _StoreBrand extends StatelessWidget {
  const _StoreBrand();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: colorScheme.onPrimary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'E-Commerce',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Tu tienda en línea',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.controller,
    required this.searchController,
    required this.onSearch,
    required this.onOpenCatalog,
    required this.onAddToCart,
  });

  final HomeController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final void Function({String? query, int? categoryId}) onOpenCatalog;
  final void Function(Product product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _centered(
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ProductSearchField(
                controller: searchController,
                onSubmitted: onSearch,
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: () => onSearch(searchController.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          _centered(
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _HeroBanner(onExplore: () => onOpenCatalog()),
            ),
          ),
          if (controller.categories.isNotEmpty)
            _centered(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: SectionHeader(
                  title: 'Categorías',
                  subtitle: 'Explora por tipo de producto',
                  actionLabel: 'Ver todo',
                  onAction: () => onOpenCatalog(),
                ),
              ),
            ),
          if (controller.categories.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                scrollDirection: Axis.horizontal,
                itemCount: controller.categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = controller.categories[index];
                  return _CategoryChip(
                    category: category,
                    onTap: () => onOpenCatalog(categoryId: category.id),
                  );
                },
              ),
            ),
          if (controller.featured.isNotEmpty)
            _ProductSection(
              title: 'Destacados',
              subtitle: 'Seleccionados para ti',
              products: controller.featured,
              onSeeAll: () => onOpenCatalog(),
              onAddToCart: onAddToCart,
            ),
          if (controller.recent.isNotEmpty)
            _ProductSection(
              title: 'Recién llegados',
              subtitle: 'Lo más nuevo del catálogo',
              products: controller.recent,
              onSeeAll: () => onOpenCatalog(),
              onAddToCart: onAddToCart,
            ),
          _centered(
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: SectionHeader(
                title: 'Productos disponibles',
                subtitle: controller.totalAvailable > 0
                    ? '${controller.totalAvailable} productos en la tienda'
                    : 'Consulta el catálogo completo',
                actionLabel: 'Ver catálogo',
                onAction: () => onOpenCatalog(),
              ),
            ),
          ),
          if (controller.available.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyView(
                message: 'Aún no hay productos disponibles en la tienda.',
                icon: Icons.inventory_2_outlined,
              ),
            )
          else
            _centered(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AvailableGrid(
                  products: controller.available,
                  onAddToCart: onAddToCart,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _centered(Widget child) {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: child,
    ),
  );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;

        return Container(
          padding: EdgeInsets.all(compact ? 20 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Todo lo que buscas,\nen un solo lugar',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Descubre productos para tu día a día y encuentra tu próximo favorito.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: onExplore,
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Explorar catálogo'),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 84,
                  color: colorScheme.onPrimary.withValues(alpha: 0.22),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: const Icon(Icons.category_outlined, size: 18),
      label: Text(category.name),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.title,
    required this.subtitle,
    required this.products,
    required this.onSeeAll,
    required this.onAddToCart,
  });

  final String title;
  final String subtitle;
  final List<Product> products;
  final VoidCallback onSeeAll;
  final void Function(Product product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _centered(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: SectionHeader(
              title: title,
              subtitle: subtitle,
              actionLabel: 'Ver todo',
              onAction: onSeeAll,
            ),
          ),
        ),
        SizedBox(
          height: 262,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 182,
                child: ProductCard(
                  product: products[index],
                  onAddToCart: () {
                    onAddToCart(products[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AvailableGrid extends StatelessWidget {
  const _AvailableGrid({required this.products, required this.onAddToCart});

  final List<Product> products;
  final void Function(Product product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.64,
          ),
          itemBuilder: (context, index) {
            return ProductCard(
              product: products[index],
              onAddToCart: () {
                onAddToCart(products[index]);
              },
            );
          },
        );
      },
    );
  }
}

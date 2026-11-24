import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../../cart/presentation/state/cart_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';
import '../../domain/entities/product_sort.dart';
import '../../domain/repositories/product_repository.dart';
import '../state/catalog_controller.dart';
import '../widgets/product_card.dart';
import '../widgets/product_search_field.dart';
import '../widgets/store_app_bar_actions.dart';

/// Argumentos opcionales para abrir el catálogo con una búsqueda o categoría.
class CatalogArguments {
  const CatalogArguments({this.query, this.categoryId});

  final String? query;
  final int? categoryId;
}

/// Catálogo de productos conectado al backend real.
class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.repository,
    required this.authController,
    required this.cartController,
    this.initialQuery,
    this.initialCategoryId,
  });

  final ProductRepository repository;
  final AuthController authController;
  final CartController cartController;
  final String? initialQuery;
  final int? initialCategoryId;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final TextEditingController _searchController;
  late final CatalogController _controller;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: initialQuery);
    _controller = CatalogController(
      widget.repository,
      initialQuery: initialQuery,
      initialCategoryId: widget.initialCategoryId,
    )..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _controller.setSearch('');
  }

  void _clearFilters() {
    _searchController.clear();
    _controller.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          StoreAppBarActions(authController: widget.authController),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: ProductSearchField(
              controller: _searchController,
              onChanged: _controller.setSearch,
              onSubmitted: _controller.setSearch,
              suffixIcon: IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: _clearSearch,
                icon: const Icon(Icons.close),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _CatalogFilters(
              controller: _controller,
              onClearFilters: _clearFilters,
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _CatalogResults(
                controller: _controller,
                onClearFilters: _clearFilters,
                onAddToCart: (product) {
                  widget.cartController.addProduct(product);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogFilters extends StatelessWidget {
  const _CatalogFilters({
    required this.controller,
    required this.onClearFilters,
  });

  final CatalogController controller;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: controller.selectedCategoryId == null,
                onSelected: (_) => controller.selectCategory(null),
              ),
              for (final ProductCategory category in controller.categories) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(category.name),
                  selected: controller.selectedCategoryId == category.id,
                  onSelected: (_) => controller.selectCategory(category.id),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                selected: controller.onlyAvailable,
                onSelected: (value) => controller.setOnlyAvailable(value),
                avatar: Icon(
                  controller.onlyAvailable
                      ? Icons.check_circle
                      : Icons.inventory_2_outlined,
                  size: 18,
                ),
                label: const Text('Solo disponibles'),
              ),
              PopupMenuButton<ProductSort>(
                tooltip: 'Ordenar',
                initialValue: controller.sort,
                onSelected: (value) => controller.setSort(value),
                itemBuilder: (context) => [
                  for (final sort in ProductSort.values)
                    PopupMenuItem<ProductSort>(
                      value: sort,
                      child: Text(sort.label),
                    ),
                ],
                child: Chip(
                  avatar: Icon(
                    Icons.sort,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  label: Text(controller.sort.label),
                ),
              ),
              if (controller.hasActiveFilters)
                IconButton(
                  tooltip: 'Limpiar filtros',
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                ),
            ],
          ),
        ),
        Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                controller.totalElements == 1
                    ? '1 producto'
                    : '${controller.totalElements} productos',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (controller.hasActiveFilters)
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Limpiar'),
              ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }
}

class _CatalogResults extends StatelessWidget {
  const _CatalogResults({
    required this.controller,
    required this.onClearFilters,
    required this.onAddToCart,
  });

  final CatalogController controller;
  final VoidCallback onClearFilters;
  final void Function(Product product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.products.isEmpty) {
      return const LoadingView(message: 'Cargando productos...');
    }

    if (controller.errorMessage != null && !controller.hasLoadedOnce) {
      return ErrorView(
        message: controller.errorMessage!,
        details: controller.errorDetails,
        onRetry: controller.retry,
      );
    }

    if (controller.hasLoadedOnce && controller.products.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.52,
              child: EmptyView(
                message: controller.hasActiveFilters
                    ? 'No encontramos productos con esos filtros.'
                    : 'Todavía no hay productos disponibles en el catálogo.',
                icon: controller.hasActiveFilters
                    ? Icons.search_off
                    : Icons.inventory_2_outlined,
                actionLabel: controller.hasActiveFilters
                    ? 'Limpiar filtros'
                    : null,
                onAction: controller.hasActiveFilters ? onClearFilters : null,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 700
            ? 3
            : 2;

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (controller.isLoading)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
              if (controller.errorMessage != null)
                SliverToBoxAdapter(
                  child: _InlineError(
                    message: controller.errorMessage!,
                    onRetry: controller.retry,
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.64,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        ProductCard(
                        product: controller.products[index],
                        onAddToCart: () {
                          onAddToCart(controller.products[index]);
                        },
                      ),
                    childCount: controller.products.length,
                  ),
                ),
              ),
              if (controller.hasMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: controller.isLoadingMore
                            ? null
                            : controller.loadMore,
                        icon: controller.isLoadingMore
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(
                          controller.isLoadingMore
                              ? 'Cargando...'
                              : 'Cargar más productos',
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Material(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      ),
    );
  }
}

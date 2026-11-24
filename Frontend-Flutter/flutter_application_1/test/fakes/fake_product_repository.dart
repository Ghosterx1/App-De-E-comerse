import 'package:flutter_application_1/core/network/api_exception.dart';
import 'package:flutter_application_1/features/catalog/domain/entities/product.dart';
import 'package:flutter_application_1/features/catalog/domain/entities/product_category.dart';
import 'package:flutter_application_1/features/catalog/domain/entities/product_page.dart';
import 'package:flutter_application_1/features/catalog/domain/entities/product_sort.dart';
import 'package:flutter_application_1/features/catalog/domain/repositories/product_repository.dart';

/// Registro de la última consulta recibida, para comprobar filtros.
class ProductRequest {
  const ProductRequest({
    required this.page,
    required this.size,
    required this.search,
    required this.categoryId,
    required this.featured,
    required this.available,
    required this.sort,
  });

  final int page;
  final int size;
  final String? search;
  final int? categoryId;
  final bool? featured;
  final bool? available;
  final ProductSort sort;
}

/// Repositorio de catálogo en memoria, sin red.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository({
    List<Product> products = const [],
    List<ProductCategory> categories = const [],
    this.error,
    this.totalPagesOverride,
  }) : products = [...products],
       categories = [...categories];

  final List<Product> products;
  final List<ProductCategory> categories;
  ApiException? error;
  final int? totalPagesOverride;

  int fetchCalls = 0;
  int categoryCalls = 0;
  final List<ProductRequest> requests = [];

  @override
  Future<ProductPage> getProducts({
    required int page,
    required int size,
    String? search,
    int? categoryId,
    bool? featured,
    bool? available,
    ProductSort sort = ProductSort.newest,
  }) async {
    fetchCalls++;
    requests.add(
      ProductRequest(
        page: page,
        size: size,
        search: search,
        categoryId: categoryId,
        featured: featured,
        available: available,
        sort: sort,
      ),
    );

    if (error != null) {
      throw error!;
    }

    final normalizedSearch = search?.trim().toLowerCase();
    final filtered = products.where((product) {
      final matchesSearch =
          normalizedSearch == null ||
          normalizedSearch.isEmpty ||
          product.name.toLowerCase().contains(normalizedSearch) ||
          product.description.toLowerCase().contains(normalizedSearch);
      final matchesCategory =
          categoryId == null || product.category?.id == categoryId;
      final matchesFeatured = featured == null || product.featured == featured;
      final matchesAvailable =
          available == null || product.isAvailable == available;
      return matchesSearch &&
          matchesCategory &&
          matchesFeatured &&
          matchesAvailable;
    }).toList();

    _sort(filtered, sort);
    final totalElements = filtered.length;
    final start = page * size;
    final items = start >= totalElements
        ? const <Product>[]
        : filtered.skip(start).take(size).toList(growable: false);
    final totalPages =
        totalPagesOverride ??
        (totalElements == 0 ? 0 : (totalElements / size).ceil());

    return ProductPage(
      items: items,
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages,
      isLast: page + 1 >= totalPages,
    );
  }

  @override
  Future<Product> getProductById(int id) async {
    for (final p in products) {
      if (p.id == id) return p;
    }
    throw const NetworkApiException('Producto no encontrado.');
  }

  @override
  Future<List<ProductCategory>> getCategories() async {
    categoryCalls++;
    if (error != null) {
      throw error!;
    }
    return List.unmodifiable(categories);
  }

  void _sort(List<Product> values, ProductSort sort) {
    switch (sort) {
      case ProductSort.newest:
        values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ProductSort.priceAsc:
        values.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceDesc:
        values.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.nameAsc:
        values.sort((a, b) => a.name.compareTo(b.name));
    }
  }
}

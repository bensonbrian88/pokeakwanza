import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/providers/cart_provider.dart';
import 'package:stynext/providers/product_provider.dart';
import 'package:stynext/widgets/cart_icon_with_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stynext/theme/app_theme.dart';
import '../../widgets/product_card.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({super.key});

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  int? _categoryId;
  String _categoryName = '';
  bool _isLoading = true;
  List<Product> _products = [];
  int _activeTab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _categoryId == null) {
      _categoryId = args['id'] as int?;
      _categoryName = args['name']?.toString() ?? '';
      // Instant show from cache if available
      final cached = _categoryId != null
          ? ref.read(productProvider).categoryCache[_categoryId!]
          : null;
      if (cached != null && cached.isNotEmpty) {
        _products = cached;
        _isLoading = false;
        setState(() {});
      }
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_categoryId == null) return;
    setState(() {
      _isLoading = true;
    });
    final items = await ref
        .read(productProvider.notifier)
        .getProductsByCategory(_categoryId!.toString());
    // If API path was empty, try provider general fetch with filter as a fallback
    if (items.isEmpty) {
      await ref
          .read(productProvider.notifier)
          .fetchProducts(categoryId: _categoryId);
      final fromProvider = ref
          .read(productProvider)
          .products
          .where((p) => p.categoryId == _categoryId)
          .toList();
      if (mounted) {
        setState(() {
          _products = fromProvider;
        });
      }
    }
    if (mounted) {
      setState(() {
        if (items.isNotEmpty) {
          _products = items;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
          color: AppColors.textDark,
        ),
        title: Text(
          _categoryName.isEmpty ? 'Products' : _categoryName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          CartIconWithBadge(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      bottomNavigationBar: cartState.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cartState.totalItems} items',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TZS ${cartState.totalAmount.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                      child: const Text('Go to Cart'),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProducts().isEmpty
              ? const Center(child: Text('No products found'))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const SizedBox(height: 8),
                      GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: _filteredProducts().length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts()[index];
                          return ProductCard(
                            product: product,
                            onAdd: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final isGuest =
                                  prefs.getBool('is_guest') ?? false;
                              if (isGuest) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Guest Mode'),
                                    content:
                                        const Text('Please login to continue'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacementNamed(
                                              context, '/login');
                                        },
                                        child: const Text('Login'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              await ref
                                  .read(cartProvider.notifier)
                                  .addToCart(product);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  // removed - replaced by reusable ProductCard widget

  List<Product> _filteredProducts() {
    return _products;
  }
}

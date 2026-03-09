import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  Category? _selectedCategory;
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final category = ModalRoute.of(context)?.settings.arguments as Category?;
    if (category != null && _selectedCategory?.id != category.id) {
      _selectedCategory = category;
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    if (_selectedCategory == null) return;
    setState(() => _isLoading = true);
    try {
      final products = await ref
          .read(productProvider.notifier)
          .getProductsByCategory(_selectedCategory!.id.toString());
      setState(() => _products = products);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching products: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_selectedCategory?.name ?? 'Category'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const _LoadingSkeletonGrid()
          : _products.isEmpty
              ? const _EmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      product: product,
                      onAdd: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final isGuest = prefs.getBool('is_guest') ?? false;
                        if (isGuest) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Guest Mode'),
                              content: const Text('Please login to continue'),
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
    );
  }
}
// _ProductCard replaced by shared ProductCard widget

class _LoadingSkeletonGrid extends StatelessWidget {
  const _LoadingSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No products found in this category',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/cart_provider.dart';
import 'package:stynext/widgets/cart_icon_with_badge.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stynext/core/theme/app_theme.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/models/category.dart';
import 'package:stynext/providers/banner_provider.dart';
import 'package:stynext/providers/category_provider.dart';
import 'package:stynext/providers/product_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stynext/widgets/cached_image.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  List<Product> _allProducts = [];
  List<Product> _products = [];
  List<Product> _newArrivals = [];
  List<Category> _categories = [];
  int? _activeCategoryId;
  String _searchQuery = '';
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refresh();
    });
    _controller.addListener(() async {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 50) {
        final prov = ref.read(productProvider.notifier);
        final state = ref.read(productProvider);
        if (!state.isLoading && state.hasMore) {
          await prov.fetchProducts(loadMore: true);
          if (!mounted) return;
          setState(() {
            _allProducts = ref.read(productProvider).products;
            _products = _applyLocalSearchFilter(_allProducts, _searchQuery);
          });
        }
      }
    });
  }

  Future<void> _refresh() async {
    await ref.read(categoryProvider.notifier).fetchCategories();
    await ref.read(bannerProvider.notifier).fetchBanners();
    final productProv = ref.read(productProvider.notifier);
    await productProv.fetchProducts();
    await productProv.fetchNewArrivals();
    final categories = ref.read(categoryProvider).categories;
    final products = ref.read(productProvider).products;
    setState(() {
      _categories = categories;
      _allProducts = products;
      _products = products;
      _newArrivals = ref.read(productProvider).newArrivals;
      _activeCategoryId = null;
      _searchQuery = '';
    });
  }

  // Removed local approximation; rely on backend /products/new-arrivals only.

  Future<void> _filterProductsByCategory(int? categoryId) async {
    setState(() {
      _activeCategoryId = categoryId;
    });
    final prov = ref.read(productProvider.notifier);
    await prov.fetchProducts(categoryId: categoryId, search: _searchQuery);
    final fetched = ref.read(productProvider).products;
    setState(() {
      _allProducts = fetched;
      _products = _applyLocalSearchFilter(_allProducts, _searchQuery);
    });
  }

  void _searchProducts(String query) {
    _searchQuery = query;
    Future.microtask(() async {
      final prov = ref.read(productProvider.notifier);
      await prov.fetchProducts(
        categoryId: _activeCategoryId,
        search: _searchQuery,
      );
      if (!mounted) return;
      setState(() {
        _allProducts = ref.read(productProvider).products;
        _products = _applyLocalSearchFilter(_allProducts, _searchQuery);
      });
    });
  }

  List<Product> _applyLocalSearchFilter(List<Product> base, String query) {
    if (query.isEmpty) return base;
    return base
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final cartState = ref.watch(cartProvider);
    final isLoading = productState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CartIconWithBadge(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('auth_token') ?? '';
                final isGuest = prefs.getBool('is_guest') ?? false;
                final hasFirebase = FirebaseAuth.instance.currentUser != null;
                if ((token.isEmpty && !hasFirebase) || isGuest) {
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Login Required'),
                      content: const Text('Please sign in before opening cart'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text('Sign In'),
                        )
                      ],
                    ),
                  );
                  return;
                }
                if (!context.mounted) return;
                Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: cartState.items.isNotEmpty
          ? Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TZS ${cartState.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    child: const Text('Endelea'),
                  ),
                ],
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          controller: _controller,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: _searchProducts,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Shop Products',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              if (isLoading && _products.isEmpty)
                const _LoadingSkeletonHorizontal()
              else if (_products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ShopEmptyState(message: 'No products found'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return _ProductCardHorizontal(product: product);
                    },
                  ),
                ),
              if (isLoading && _products.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'New Arrivals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const _LoadingSkeletonGrid(count: 4)
              else if (_newArrivals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ShopEmptyState(message: 'No products found'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _newArrivals.length,
                  itemBuilder: (context, index) {
                    final product = _newArrivals[index];
                    return _ProductCardVertical(product: product);
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopEmptyState extends StatelessWidget {
  final String message;
  const _ShopEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _ProductCardHorizontal extends ConsumerStatefulWidget {
  final Product product;
  const _ProductCardHorizontal({required this.product});

  @override
  ConsumerState<_ProductCardHorizontal> createState() =>
      _ProductCardHorizontalState();
}

class _ProductCardHorizontalState
    extends ConsumerState<_ProductCardHorizontal> {
  bool isFavorite = false;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_details',
          arguments: widget.product),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: widget.product.image != null
                        ? Hero(
                            tag: 'product-${widget.product.id}',
                            child: CachedImage(
                              widget.product.image!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(color: Colors.grey[200]),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token') ?? '';
                              final isGuest =
                                  prefs.getBool('is_guest') ?? false;
                              final hasFirebase =
                                  FirebaseAuth.instance.currentUser != null;
                              if ((token.isEmpty && !hasFirebase) || isGuest) {
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Login Required'),
                                    content: const Text(
                                        'Please sign in before adding to cart'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushNamed(
                                              context, '/login');
                                        },
                                        child: const Text('Sign In'),
                                      )
                                    ],
                                  ),
                                );
                                return;
                              }
                              await ref
                                  .read(cartProvider.notifier)
                                  .addToCart(widget.product, quantity: _qty);
                              if (!context.mounted) return;
                              Navigator.pushNamed(context, '/cart');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.product.price} TZS',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_qty > 1) _qty--;
                          });
                        },
                      ),
                      Text('$_qty'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _qty++;
                          });
                        },
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 36,
                        child: _AnimatedAddButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('auth_token') ?? '';
                            final isGuest = prefs.getBool('is_guest') ?? false;
                            final hasFirebase =
                                FirebaseAuth.instance.currentUser != null;
                            if ((token.isEmpty && !hasFirebase) || isGuest) {
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Login Required'),
                                  content: const Text(
                                      'Please sign in before adding to cart'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/login');
                                      },
                                      child: const Text('Sign In'),
                                    )
                                  ],
                                ),
                              );
                              return;
                            }
                            if (!context.mounted) return;
                            await ref
                                .read(cartProvider.notifier)
                                .addToCart(widget.product, quantity: _qty);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                          label: 'Add',
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCardVertical extends ConsumerStatefulWidget {
  final Product product;
  const _ProductCardVertical({required this.product});

  @override
  ConsumerState<_ProductCardVertical> createState() =>
      _ProductCardVerticalState();
}

class _ProductCardVerticalState extends ConsumerState<_ProductCardVertical> {
  bool isFavorite = false;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product_details',
          arguments: widget.product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: widget.product.image != null
                        ? Hero(
                            tag: 'product-${widget.product.id}',
                            child: CachedImage(
                              widget.product.image!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(color: Colors.grey[200]),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token') ?? '';
                              final isGuest =
                                  prefs.getBool('is_guest') ?? false;
                              final hasFirebase =
                                  FirebaseAuth.instance.currentUser != null;
                              if ((token.isEmpty && !hasFirebase) || isGuest) {
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Login Required'),
                                    content: const Text(
                                        'Please sign in before adding to cart'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Navigator.pushNamed(
                                              context, '/login');
                                        },
                                        child: const Text('Sign In'),
                                      )
                                    ],
                                  ),
                                );
                                return;
                              }
                              await ref
                                  .read(cartProvider.notifier)
                                  .addToCart(widget.product, quantity: _qty);
                              if (!context.mounted) return;
                              Navigator.pushNamed(context, '/cart');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.product.price} TZS',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_qty > 1) _qty--;
                          });
                        },
                      ),
                      Text('$_qty'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _qty++;
                          });
                        },
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('auth_token') ?? '';
                            final isGuest = prefs.getBool('is_guest') ?? false;
                            final hasFirebase =
                                FirebaseAuth.instance.currentUser != null;
                            if ((token.isEmpty && !hasFirebase) || isGuest) {
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Login Required'),
                                  content: const Text(
                                      'Please sign in before adding to cart'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(context, '/login');
                                      },
                                      child: const Text('Sign In'),
                                    )
                                  ],
                                ),
                              );
                              return;
                            }
                            if (!context.mounted) return;
                            await ref
                                .read(cartProvider.notifier)
                                .addToCart(widget.product, quantity: _qty);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                          child: const Text(
                            'Add',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeletonGrid extends StatelessWidget {
  final int count;
  const _LoadingSkeletonGrid({required this.count});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: count,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeletonHorizontal extends StatelessWidget {
  const _LoadingSkeletonHorizontal();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedAddButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String label;
  const _AnimatedAddButton({required this.onPressed, this.label = 'Add'});

  @override
  State<_AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<_AnimatedAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    try {
      await _ctrl.forward();
      await _ctrl.reverse();
      await widget.onPressed();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = 1 - _ctrl.value;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _tap,
        child: Text(widget.label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

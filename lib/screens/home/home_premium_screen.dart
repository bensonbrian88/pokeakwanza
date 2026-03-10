import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stynext/providers/cart_provider.dart';
import 'package:stynext/widgets/cart_icon_with_badge.dart';
import 'package:stynext/providers/banner_provider.dart';
import 'package:stynext/providers/category_provider.dart';
import 'package:stynext/providers/product_provider.dart';
import 'package:stynext/models/banner_model.dart';
import 'package:stynext/models/category.dart';
import 'package:stynext/theme/app_theme.dart';
import 'package:stynext/widgets/loading_shimmer.dart';
import 'package:stynext/widgets/cached_image.dart';

class HomePremiumScreen extends ConsumerStatefulWidget {
  const HomePremiumScreen({super.key});

  @override
  ConsumerState<HomePremiumScreen> createState() => _HomePremiumScreenState();
}

class _HomePremiumScreenState extends ConsumerState<HomePremiumScreen> {
  final _search = TextEditingController();
  final _bannerController = PageController(viewportFraction: 0.9);
  int _bannerIndex = 0;
  bool _initialized = false;
  Timer? _bannerTimer;
  static const Duration _slideInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _bannerTimer = Timer.periodic(_slideInterval, (_) {
      final list = ref.read(bannerProvider).banners;
      if (_bannerController.hasClients && list.length > 1) {
        final next = (_bannerIndex + 1) % list.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
        );
        setState(() {
          _bannerIndex = next;
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (_initialized) return;
    _initialized = true;
    await Future.wait<void>([
      ref.read(bannerProvider.notifier).fetchBanners(),
      ref.read(categoryProvider.notifier).fetchCategories(),
    ]);
    if (!mounted) return;
    // Prefetch products for first few categories (fast instant open)
    final cats = ref.read(categoryProvider).categories;
    if (cats.isNotEmpty) {
      final ids = cats.take(10).map((c) => c.id).toList();
      // Run without blocking UI
      // ignore: unawaited_futures
      ref
          .read(productProvider.notifier)
          .prefetchCategories(ids, maxPerCategory: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProv = ref.watch(categoryProvider);
    final bannerProv = ref.watch(bannerProvider);
    final cartState = ref.watch(cartProvider);
    // final isLoading = prov.isLoading && prov.products.isEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(cartState),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildSearchBar(),
              const SizedBox(height: 24),
              _buildBannerSlider(bannerProv.banners, bannerProv.isLoading),
              const SizedBox(height: 32),
              _buildCategoriesSection(catProv.categories, catProv.isLoading),
              const SizedBox(height: 24),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
    );
  }

  PreferredSizeWidget _buildAppBar(CartState cartProvider) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Icon(Icons.shopping_bag, color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 10),
          Text(
            'Pokeakwanza',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_2_outlined),
          onPressed: () => Navigator.pushNamed(context, '/scan'),
          color: AppColors.textDark,
        ),
        CartIconWithBadge(
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
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => Navigator.pushNamed(context, '/home'),
          color: AppColors.textDark,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
            ),
            suffixIcon: Icon(
              Icons.tune,
              color: AppColors.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(List<Category> categories, bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Categories',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
          ),
        ),
        const SizedBox(height: 16),
        if (loading)
          _buildShimmerGrid()
        else if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: Text('No categories found')),
                TextButton(
                  onPressed: () =>
                      ref.read(categoryProvider.notifier).fetchCategories(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else
          _buildCategoryGrid(categories),
      ],
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/category_products',
        arguments: {'id': category.id, 'name': category.name},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: category.image != null && category.image!.isNotEmpty
                    ? CachedImage(
                        category.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: AppColors.lightGrey,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Browse',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSlider(List<BannerModel> banners, bool loading) {
    final h = 180.0;
    if (loading) {
      return SizedBox(
        height: h,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildShimmerStrip(),
        ),
      );
    }
    if (banners.isEmpty) {
      return const SizedBox(height: 0);
    }
    return Column(
      children: [
        SizedBox(
          height: h,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (i) => setState(() => _bannerIndex = i),
            itemCount: banners.length,
            itemBuilder: (context, i) {
              final b = banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CachedImage(
                          b.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.black.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => Container(
              width: i == _bannerIndex ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: i == _bannerIndex
                    ? AppTheme.primaryColor
                    : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            LoadingShimmer(width: double.infinity, height: 160),
            SizedBox(height: 8),
            LoadingShimmer(width: double.infinity, height: 16),
            SizedBox(height: 6),
            LoadingShimmer(width: 100, height: 16),
            SizedBox(height: 10),
            LoadingShimmer(width: double.infinity, height: 44),
          ],
        );
      },
    );
  }

  Widget _buildShimmerStrip() {
    return Row(
      children: const [
        Expanded(child: LoadingShimmer(width: double.infinity, height: 160)),
      ],
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _search.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:stynext/models/product.dart';
import 'package:stynext/theme/app_theme.dart';
import 'package:stynext/widgets/cached_image.dart';
import 'package:stynext/widgets/add_to_cart_animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/cart_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductCard({
    required this.product,
    required this.onAdd,
    super.key,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _btnController;
  bool _showAdded = false;
  bool _pressed = false;
  final _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    // Show flying image animation
    if (widget.product.image != null && widget.product.image!.isNotEmpty) {
      await AddToCartAnimation.show(
        context: context,
        imageKey: _imageKey,
        imageUrl: widget.product.image!,
        duration: const Duration(milliseconds: 480),
      );
    }
    setState(() => _showAdded = true);
    widget.onAdd();
    await Future.delayed(const Duration(milliseconds: 360));
    if (mounted) setState(() => _showAdded = false);
  }

  @override
  Widget build(BuildContext context) {
    final qty = ref.watch(cartProvider).quantityForProduct(widget.product.id);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..scale(_pressed ? 0.995 : 1.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: _pressed ? 6 : 4,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildImage(key: _imageKey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "TSH ${widget.product.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  qty > 0
                      ? Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                final newQty = qty - 1;
                                if (newQty <= 0) {
                                  ref
                                      .read(cartProvider.notifier)
                                      .removeItem(widget.product.id);
                                } else {
                                  ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(
                                          widget.product.id, newQty);
                                }
                              },
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .updateQuantity(widget.product.id, qty + 1);
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined),
                              color: AppColors.primary,
                              onPressed: () {
                                // No-op: quantity UI already updates cart
                              },
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTapDown: (_) => _btnController.forward(),
                            onTapUp: (_) => _btnController.reverse(),
                            onTapCancel: () => _btnController.reverse(),
                            child: AnimatedBuilder(
                              animation: _btnController,
                              builder: (context, child) {
                                final scale = 1 - _btnController.value;
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () async {
                                  await _handleAdd();
                                  if (context.mounted) {
                                    ref
                                        .read(cartProvider.notifier)
                                        .addToCart(widget.product);
                                  }
                                },
                                child: const Text(
                                  "Add",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  if (_showAdded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 360),
                        opacity: _showAdded ? 1.0 : 0.0,
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text('Added',
                                style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage({Key? key}) {
    if (widget.product.image != null && widget.product.image!.isNotEmpty) {
      return Hero(
        tag: 'product-${widget.product.id}',
        child: CachedImage(
          widget.product.image!,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      color: AppColors.borderLight,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textGrey,
        size: 40,
      ),
    );
  }
}

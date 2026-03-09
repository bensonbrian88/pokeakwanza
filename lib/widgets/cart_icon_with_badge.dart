import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/cart_provider.dart';
import 'package:stynext/theme/app_theme.dart';

class CartIconWithBadge extends ConsumerStatefulWidget {
  final VoidCallback onPressed;
  const CartIconWithBadge({required this.onPressed, super.key});

  @override
  ConsumerState<CartIconWithBadge> createState() => _CartIconWithBadgeState();
}

class _CartIconWithBadgeState extends ConsumerState<CartIconWithBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      lowerBound: 0.0,
      upperBound: 0.12,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartProvider).totalItems;
    if (total != _lastCount) {
      // new item added -> bounce
      _ctrl.forward(from: 0.0);
      _lastCount = total;
    }

    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final scale = 1 + _ctrl.value;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.shopping_cart_outlined),
            ),
            if (total > 0)
              Positioned(
                right: 2,
                top: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

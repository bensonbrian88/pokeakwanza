import 'package:flutter/material.dart';

class AddToCartAnimation {
  /// Show a flying image animation from a widget to the cart icon position
  static Future<void> show({
    required BuildContext context,
    required GlobalKey imageKey,
    required String imageUrl,
    required Duration duration,
  }) async {
    final overlay = Overlay.of(context);
    final imageContext = imageKey.currentContext;

    if (imageContext == null) return;

    final imageBox = imageContext.findRenderObject() as RenderBox?;
    if (imageBox == null) return;

    final imagePos = imageBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // Target: top-right (cart icon area)
    const targetRadius = 24.0;
    final targetX = screenSize.width - 40;
    final targetY = 56;

    final entry = OverlayEntry(
      builder: (ctx) => _FlyingImage(
        imageUrl: imageUrl,
        startPos: imagePos,
        targetPos: Offset(targetX.toDouble(), targetY.toDouble()),
        duration: duration,
        radius: targetRadius,
      ),
    );

    overlay.insert(entry);
    await Future.delayed(duration);
    entry.remove();
  }
}

class _FlyingImage extends StatefulWidget {
  final String imageUrl;
  final Offset startPos;
  final Offset targetPos;
  final Duration duration;
  final double radius;

  const _FlyingImage({
    required this.imageUrl,
    required this.startPos,
    required this.targetPos,
    required this.duration,
    required this.radius,
  });

  @override
  State<_FlyingImage> createState() => _FlyingImageState();
}

class _FlyingImageState extends State<_FlyingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInQuart);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final t = _curve.value;
        final x =
            widget.startPos.dx + (widget.targetPos.dx - widget.startPos.dx) * t;
        final y =
            widget.startPos.dy + (widget.targetPos.dy - widget.startPos.dy) * t;
        final scale = 1.0 - t * 0.6;
        final opacity = 1.0 - t * 0.7;

        return Positioned(
          left: x - (widget.radius) / 2,
          top: y - (widget.radius) / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.radius,
                  height: widget.radius,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2 * opacity),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

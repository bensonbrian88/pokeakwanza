import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:stynext/widgets/cached_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/banner_provider.dart';
import '../models/banner_model.dart';

class HomeBannerSlider extends ConsumerStatefulWidget {
  const HomeBannerSlider({super.key});

  @override
  ConsumerState<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends ConsumerState<HomeBannerSlider> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  int activeIndex = 0;
  Timer? _timer;
  static const _slideInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _setupAutoScroll();
    // Auto fetch banners if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(bannerProvider);
      if (!state.isLoading && state.banners.isEmpty) {
        ref.read(bannerProvider.notifier).fetchBanners();
      }
    });
  }

  void _setupAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(_slideInterval, (timer) {
      final list = ref.read(bannerProvider).banners;
      if (_controller.hasClients && list.length > 1) {
        final next = (activeIndex + 1) % list.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bannerProvider);
    final List<BannerModel> list = state.banners;

    if (state.isLoading) {
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: list.length,
            onPageChanged: (index) {
              setState(() {
                activeIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = list[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedImage(banner.image, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            list.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: activeIndex == index ? 24 : 8,
              decoration: BoxDecoration(
                color: activeIndex == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

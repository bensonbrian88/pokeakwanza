import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:stynext/theme/app_theme.dart';
import 'package:stynext/core/cache/app_cache_manager.dart';

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final Duration fadeInDuration;
  final VoidCallback? onTap;

  const CachedImage(
    this.imageUrl, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!imageUrl.startsWith('http')) {
      return _buildLocalImage();
    }
    if (kIsWeb) {
      return _buildWebImage();
    }
    return _buildCachedImage();
  }

  Widget _buildLocalImage() {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: GestureDetector(
          onTap: onTap,
          child: Image.asset(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildCachedImage() {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: GestureDetector(
          onTap: onTap,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: fadeInDuration,
            placeholder: (context, url) => _buildPlaceholder(),
            errorWidget: (context, url, error) => _buildPlaceholder(),
            fadeOutDuration: const Duration(milliseconds: 200),
            memCacheHeight: height != null ? (height! * 2).toInt() : null,
            memCacheWidth: width != null ? (width! * 2).toInt() : null,
            maxHeightDiskCache: 768,
            maxWidthDiskCache: 768,
            cacheManager: AppCacheManager.instance,
          ),
        ),
      ),
    );
  }

  Widget _buildWebImage() {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: GestureDetector(
          onTap: onTap,
          child: Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.borderLight,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textGrey,
          size: 32,
        ),
      ),
    );
  }
}

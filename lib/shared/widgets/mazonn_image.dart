import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/mazonn_colors.dart';
import '../../core/theme/mazonn_metrics.dart';
import '../../models/product.dart';
import 'mazonn_visual.dart';

class MazonnImage extends StatelessWidget {
  const MazonnImage({
    super.key,
    this.url,
    this.fallbackUrls = const [],
    this.seed = 1,
    this.categoryId = 'fashion',
    this.monogram = 'M',
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final List<String> fallbackUrls;
  final int seed;
  final String categoryId;
  final String monogram;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  factory MazonnImage.product(
    Product product, {
    String? url,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.cover,
  }) {
    final urls = product.displayImageUrls;
    final primary = url ?? product.primaryImage ?? (urls.isEmpty ? null : urls.first);
    return MazonnImage(
      url: primary,
      fallbackUrls: urls.where((u) => u != primary).toList(),
      seed: product.visualSeed,
      categoryId: product.categoryId,
      monogram: product.brand.isEmpty ? 'M' : product.brand.substring(0, 1),
      borderRadius: borderRadius,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? MazonnRadius.image;
    final fallback = MazonnVisual(
      seed: seed,
      categoryId: categoryId,
      monogram: monogram,
      borderRadius: radius,
    );
    final chain = [
      if (url != null && url!.isNotEmpty) url!,
      ...fallbackUrls.where((u) => u.isNotEmpty && u != url),
    ];
    if (chain.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: radius,
      child: _FallbackNetworkImage(urls: chain, fit: fit, placeholder: fallback),
    );
  }
}

class _FallbackNetworkImage extends StatefulWidget {
  const _FallbackNetworkImage({required this.urls, required this.fit, required this.placeholder});

  final List<String> urls;
  final BoxFit fit;
  final Widget placeholder;

  @override
  State<_FallbackNetworkImage> createState() => _FallbackNetworkImageState();
}

class _FallbackNetworkImageState extends State<_FallbackNetworkImage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.urls.length) return widget.placeholder;
    return CachedNetworkImage(
      imageUrl: widget.urls[_index],
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, _) => widget.placeholder,
      errorWidget: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _index < widget.urls.length) {
            setState(() => _index++);
          }
        });
        return widget.placeholder;
      },
      fadeInDuration: const Duration(milliseconds: 180),
    );
  }
}

class MazonnImageGallery extends StatelessWidget {
  const MazonnImageGallery({
    super.key,
    required this.urls,
    required this.index,
    required this.onChanged,
    required this.seed,
    required this.categoryId,
    required this.monogram,
    this.onOpen,
    this.height = 360,
  });

  final List<String> urls;
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback? onOpen;
  final int seed;
  final String categoryId;
  final String monogram;
  final double height;

  @override
  Widget build(BuildContext context) {
    final count = urls.isEmpty ? 1 : urls.length;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            itemCount: count,
            onPageChanged: onChanged,
            itemBuilder: (context, i) {
              final child = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MazonnImage(
                  url: urls.isEmpty ? null : urls[i],
                  fallbackUrls: urls.where((u) => urls.isEmpty || u != urls[i]).toList(),
                  seed: seed + i,
                  categoryId: categoryId,
                  monogram: monogram,
                  borderRadius: BorderRadius.circular(MazonnRadius.lg),
                ),
              );
              if (onOpen == null) return child;
              return GestureDetector(onTap: onOpen, child: child);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? MazonnColors.noir : MazonnColors.linen,
                borderRadius: MazonnRadius.pillAll,
              ),
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: i == index ? MazonnColors.noir : MazonnColors.linen,
                        width: i == index ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: MazonnImage(
                      url: urls[i],
                      fallbackUrls: const [],
                      seed: seed + i,
                      categoryId: categoryId,
                      monogram: monogram,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

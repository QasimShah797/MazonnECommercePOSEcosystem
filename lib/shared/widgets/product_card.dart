import 'package:flutter/material.dart';

import '../../core/theme/mazonn_colors.dart';
import '../../core/theme/mazonn_metrics.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import 'mazonn_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.wishlisted,
    required this.onWishlist,
    required this.onAdd,
    this.width,
  });

  final Product product;
  final VoidCallback onTap;
  final bool wishlisted;
  final VoidCallback onWishlist;
  final VoidCallback onAdd;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 0.86,
          child: Stack(
            children: [
              Positioned.fill(
                child: MazonnImage.product(product, borderRadius: MazonnRadius.card),
              ),
              if (product.badges.isNotEmpty)
                Positioned(
                  left: 10,
                  top: 10,
                  child: ProductBadge(label: product.badges.first),
                ),
              Positioned(
                right: 8,
                top: 8,
                child: _RoundIconButton(
                  icon: wishlisted ? Icons.favorite : Icons.favorite_border,
                  color: wishlisted ? MazonnColors.error : MazonnColors.noir,
                  onTap: onWishlist,
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: _RoundIconButton(
                  icon: Icons.add,
                  onTap: onAdd,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product.brand.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall,
        ),
        const SizedBox(height: 2),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(MazonnFormatters.money(product.price), style: textTheme.titleSmall),
            if (product.originalPrice != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  MazonnFormatters.money(product.originalPrice!),
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: MazonnColors.stoneLight,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 14, color: MazonnColors.gold),
            const SizedBox(width: 2),
            Text(
              '${product.rating}  (${MazonnFormatters.compactCount(product.reviewCount)})',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: MazonnRadius.card,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedHeight) return column;
            return FittedBox(
              alignment: Alignment.topCenter,
              fit: BoxFit.scaleDown,
              child: SizedBox(width: constraints.maxWidth, child: column),
            );
          },
        ),
      ),
    );
  }
}

class ProductBadge extends StatelessWidget {
  const ProductBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isSale = label == 'SALE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSale ? MazonnColors.error : MazonnColors.noir,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.color = MazonnColors.noir,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/mazonn_colors.dart';
import '../../core/theme/mazonn_metrics.dart';

class MazonnVisual extends StatelessWidget {
  const MazonnVisual({
    super.key,
    required this.seed,
    this.categoryId = 'fashion',
    this.monogram = 'M',
    this.borderRadius,
  });

  final int seed;
  final String categoryId;
  final String monogram;
  final BorderRadius? borderRadius;

  static Color toneFor(String categoryId, int seed) {
    const palettes = {
      'fashion': [Color(0xFFD9C5AF), Color(0xFFB9A08A), Color(0xFF8C7460)],
      'electronics': [Color(0xFFC5CDD3), Color(0xFF8FA0AA), Color(0xFF5C6B73)],
      'beauty': [Color(0xFFE4C9C4), Color(0xFFC99B96), Color(0xFF8F6A66)],
      'home': [Color(0xFFD3D6C7), Color(0xFFA8B094), Color(0xFF6F7A62)],
      'grocery': [Color(0xFFD7CDB5), Color(0xFFB6A57E), Color(0xFF7C6E4E)],
      'sports': [Color(0xFFC9D4CF), Color(0xFF8EAAA0), Color(0xFF547068)],
      'accessories': [Color(0xFFE1D3B8), Color(0xFFC2A97A), Color(0xFF8A7348)],
    };
    final palette = palettes[categoryId] ?? palettes['fashion']!;
    return palette[seed % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = toneFor(categoryId, seed);
    return ClipRRect(
      borderRadius: borderRadius ?? MazonnRadius.image,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.18)!,
              color,
              Color.lerp(color, MazonnColors.noir, 0.18)!,
            ],
          ),
        ),
        child: CustomPaint(
          painter: _MazonnPatternPainter(seed: seed),
          child: Center(
            child: Text(
              monogram,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    letterSpacing: 1.4,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MazonnPatternPainter extends CustomPainter {
  _MazonnPatternPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final step = 28.0 + (seed % 5) * 4;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      size.shortestSide * 0.22,
      paint..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _MazonnPatternPainter oldDelegate) => oldDelegate.seed != seed;
}

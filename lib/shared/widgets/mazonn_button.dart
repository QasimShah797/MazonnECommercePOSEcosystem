import 'package:flutter/material.dart';

import '../../core/theme/mazonn_colors.dart';
import '../../core/theme/mazonn_metrics.dart';

class MazonnButton extends StatelessWidget {
  const MazonnButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.icon,
    this.tone = MazonnButtonTone.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final IconData? icon;
  final MazonnButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    late final Color background;
    late final Color foreground;
    late final BorderSide side;

    switch (tone) {
      case MazonnButtonTone.primary:
        background = enabled ? MazonnColors.noir : MazonnColors.linen;
        foreground = MazonnColors.white;
        side = BorderSide.none;
      case MazonnButtonTone.gold:
        background = enabled ? MazonnColors.gold : MazonnColors.goldSoft;
        foreground = MazonnColors.white;
        side = BorderSide.none;
      case MazonnButtonTone.outline:
        background = Colors.transparent;
        foreground = MazonnColors.noir;
        side = const BorderSide(color: MazonnColors.noir);
      case MazonnButtonTone.ghost:
        background = MazonnColors.cream;
        foreground = MazonnColors.noir;
        side = BorderSide.none;
    }

    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground),
                ),
              ),
            ],
          );

    return SizedBox(
      width: expanded ? double.infinity : null,
      height: 52,
      child: Material(
        color: background,
        borderRadius: MazonnRadius.pillAll,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: MazonnRadius.pillAll,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: MazonnRadius.pillAll,
              border: Border.fromBorderSide(side),
            ),
            child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child)),
          ),
        ),
      ),
    );
  }
}

enum MazonnButtonTone { primary, gold, outline, ghost }

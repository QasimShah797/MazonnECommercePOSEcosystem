import 'package:flutter/material.dart';

import '../../core/theme/mazonn_colors.dart';
import '../../core/theme/mazonn_metrics.dart';

class MazonnAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MazonnAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      title: title == null
          ? null
          : Text(title!, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class IconBadgeButton extends StatelessWidget {
  const IconBadgeButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.count = 0,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: MazonnColors.gold,
        label: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
        child: Icon(icon, color: MazonnColors.noir),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(MazonnSpacing.page, 8, MazonnSpacing.page, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: MazonnColors.goldDark),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(MazonnSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: MazonnColors.cream, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: MazonnColors.goldDark),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MazonnColors.stone),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Loading'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: MazonnColors.noir),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Unable to load',
      message: message,
      actionLabel: onRetry == null ? null : 'Try again',
      onAction: onRetry,
    );
  }
}

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MazonnColors.linen),
        borderRadius: MazonnRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$value', style: Theme.of(context).textTheme.titleSmall),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: MazonnRadius.pillAll,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, letterSpacing: 0.6),
      ),
    );
  }
}

class MazonnErrorText extends StatelessWidget {
  const MazonnErrorText(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        message!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MazonnColors.goldDark),
      ),
    );
  }
}

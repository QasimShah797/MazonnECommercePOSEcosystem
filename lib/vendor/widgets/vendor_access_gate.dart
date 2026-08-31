import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../models/vendor.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';

class VendorAccessGate extends StatelessWidget {
  const VendorAccessGate({
    super.key,
    required this.child,
    this.feature = 'this feature',
  });

  final Widget child;
  final String feature;

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthController>().vendor;
    if (vendor == null || vendor.canSell) return child;
    return VendorLockedScreen(vendor: vendor, feature: feature);
  }
}

class VendorLockedScreen extends StatelessWidget {
  const VendorLockedScreen({super.key, required this.vendor, required this.feature});

  final Vendor vendor;
  final String feature;

  @override
  Widget build(BuildContext context) {
    final (title, message, color) = vendor.billingStatus == 'read_only'
        ? (
            'Account is read-only',
            'Subscription payment failed and the 3-day grace period ended. Super Admin must restore billing before you can sell again.',
            MazonnColors.warning,
          )
        : switch (vendor.approvalStatus) {
      'rejected' => (
          'Application not approved',
          vendor.rejectionReason.isEmpty
              ? 'Super Admin could not verify your information. Update your profile and documents, then resubmit for review.'
              : vendor.rejectionReason,
          MazonnColors.error,
        ),
      'suspended' => (
          'Selling is paused',
          vendor.suspensionReason.isEmpty
              ? 'Your vendor account has been suspended. You can view this status and contact support, but selling is disabled until Super Admin reactivates you.'
              : vendor.suspensionReason,
          MazonnColors.warning,
        ),
      _ => (
          'Account under review',
          'Your vendor account is under review. You will be able to sell on the platform after Super Admin approval.',
          MazonnColors.goldDark,
        ),
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: MazonnColors.white,
                  borderRadius: MazonnRadius.card,
                  border: Border.all(color: MazonnColors.linen),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(Icons.lock_outline_rounded, color: color),
                    ),
                    const SizedBox(height: 16),
                    Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Access to $feature requires Super Admin approval.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    MazonnButton(
                      label: 'View profile & documents',
                      tone: MazonnButtonTone.outline,
                      onPressed: () => context.go('/studio/profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VendorStatusBanner extends StatelessWidget {
  const VendorStatusBanner({super.key, required this.vendor, this.onProfile});

  final Vendor vendor;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    if (vendor.canSell) return const SizedBox.shrink();
    final color = switch (vendor.approvalStatus) {
      'rejected' => MazonnColors.error,
      'suspended' => MazonnColors.warning,
      _ => MazonnColors.goldDark,
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: MazonnRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vendor.displayStatus.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Text(
            vendor.isRejected
                ? (vendor.rejectionReason.isEmpty
                    ? 'Your application was not approved. Update your documents and resubmit.'
                    : vendor.rejectionReason)
                : vendor.isSuspended
                    ? (vendor.suspensionReason.isEmpty
                        ? 'Your store is hidden from customers until Super Admin reactivates it.'
                        : vendor.suspensionReason)
                    : 'Your vendor account is under review. You will be able to sell on the platform after Super Admin approval.',
          ),
          if (onProfile != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onProfile, child: const Text('Complete verification')),
          ],
        ],
      ),
    );
  }
}

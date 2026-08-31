import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/mazonn_colors.dart';
import '../../shared/controllers/auth_controller.dart';
import '../../shared/widgets/mazonn_button.dart';
import '../../shared/widgets/mazonn_text_field.dart';
import '../../shared/widgets/mazonn_ui.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController(text: AppConstants.demoAdminEmail);
  final _password = TextEditingController(text: AppConstants.demoAdminPassword);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: MazonnColors.ivory,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MAZONN', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 3)),
                const SizedBox(height: 8),
                Text('Super Admin', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text('Vendor approval lives in the React Super Admin dashboard (admin-web). This Flutter console remains available for catalog moderation.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 28),
                MazonnTextField(label: 'Email', controller: _email),
                const SizedBox(height: 12),
                MazonnTextField(label: 'Password', controller: _password, obscure: true),
                const SizedBox(height: 12),
                MazonnErrorText(auth.error),
                MazonnButton(
                  label: 'Enter console',
                  loading: auth.busy,
                  onPressed: () async {
                    final ok = await auth.loginUser(_email.text, _password.text);
                    if (!ok || !context.mounted) return;
                    if (!context.read<AuthController>().isAdmin) {
                      await auth.logout();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This account is not a Super Admin.')),
                      );
                      return;
                    }
                    context.go('/admin');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

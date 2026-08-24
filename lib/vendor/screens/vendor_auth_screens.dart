import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/mock/mock_catalog.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_text_field.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/vendor_studio_controller.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await auth.loginVendor(_email.text, _password.text);
    if (!ok || !mounted) return;
    await context.read<VendorStudioController>().load();
    if (mounted) context.go('/studio');
  }

  Future<void> _reset() async {
    if (MazonnValidators.email(_email.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your vendor email first.')),
      );
      return;
    }
    final ok = await context.read<AuthController>().sendPasswordReset(_email.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'A reset link was sent to this email.' : (context.read<AuthController>().error ?? 'Could not send a reset link.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VENDOR STUDIO', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Text('Welcome back', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text('Manage your atelier from one calm place.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MazonnColors.stone)),
              const SizedBox(height: 28),
              MazonnErrorText(auth.error),
              MazonnTextField(label: 'Email', controller: _email, validator: MazonnValidators.email),
              const SizedBox(height: 16),
              MazonnTextField(
                label: 'Password',
                controller: _password,
                obscure: _obscure,
                validator: MazonnValidators.password,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _reset,
                  child: const Text('Forgot password'),
                ),
              ),
              MazonnButton(
                label: 'Log in',
                loading: auth.busy,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              MazonnButton(
                label: 'Register as vendor',
                tone: MazonnButtonTone.outline,
                onPressed: () => context.push('/vendor/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VendorRegisterScreen extends StatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  State<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends State<VendorRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _owner = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  String _category = 'Fashion';
  bool _terms = false;

  @override
  void dispose() {
    _business.dispose();
    _owner.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Open your studio', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text('Tell Mazonn about your atelier.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MazonnColors.stone)),
              const SizedBox(height: 24),
              MazonnErrorText(auth.error),
              MazonnTextField(label: 'Business name', controller: _business, validator: (v) => MazonnValidators.requiredField(v, label: 'Business name')),
              const SizedBox(height: 12),
              MazonnTextField(label: 'Owner name', controller: _owner, validator: (v) => MazonnValidators.requiredField(v, label: 'Owner name')),
              const SizedBox(height: 12),
              MazonnTextField(label: 'Email', controller: _email, validator: MazonnValidators.email),
              const SizedBox(height: 12),
              MazonnTextField(label: 'Phone', controller: _phone, validator: MazonnValidators.phone),
              const SizedBox(height: 12),
              MazonnTextField(label: 'Password', controller: _password, obscure: true, validator: MazonnValidators.password),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: MockCatalog.categories
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
                decoration: const InputDecoration(labelText: 'Business category'),
              ),
              const SizedBox(height: 12),
              MazonnTextField(label: 'Business address', controller: _address, validator: (v) => MazonnValidators.requiredField(v, label: 'Address')),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _terms,
                onChanged: (v) => setState(() => _terms = v ?? false),
                title: const Text('I accept the vendor terms'),
              ),
              MazonnButton(
                label: 'Register',
                loading: auth.busy,
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  if (!_terms) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the terms.')));
                    return;
                  }
                  final ok = await auth.registerVendor(
                    businessName: _business.text,
                    ownerName: _owner.text,
                    email: _email.text,
                    phone: _phone.text,
                    password: _password.text,
                    category: _category,
                    address: _address.text,
                  );
                  if (!ok || !context.mounted) return;
                  await context.read<VendorStudioController>().load();
                  if (context.mounted) context.go('/studio');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

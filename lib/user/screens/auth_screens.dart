import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/mazonn_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_text_field.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/order_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _afterUserLogin() async {
    await Future.wait([
      context.read<OrderController>().load(),
      context.read<CatalogController>().load(),
    ]);
    if (mounted) context.go(RouteNames.userHome);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context.read<AuthController>().loginUser(_email.text, _password.text);
    if (ok && mounted) await _afterUserLogin();
  }

  Future<void> _google() async {
    final ok = await context.read<AuthController>().loginWithGoogle();
    if (ok && mounted) await _afterUserLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MAZONN', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 12),
                Text('Welcome back', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your edit.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MazonnColors.stone),
                ),
                const SizedBox(height: 32),
                MazonnErrorText(auth.error),
                MazonnTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: MazonnValidators.email,
                ),
                const SizedBox(height: 16),
                MazonnTextField(
                  label: 'Password',
                  controller: _password,
                  obscure: _obscure,
                  validator: MazonnValidators.password,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? false),
                    ),
                    const Text('Remember me'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push(RouteNames.forgotPassword),
                      child: const Text('Forgot password'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MazonnButton(label: 'Log in', loading: auth.busy, onPressed: _submit),
                const SizedBox(height: 16),
                MazonnButton(
                  label: 'Continue with Google',
                  tone: MazonnButtonTone.outline,
                  icon: Icons.g_mobiledata,
                  loading: auth.busy,
                  onPressed: _google,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New to Mazonn?', style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => context.push(RouteNames.signup),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(RouteNames.vendorLogin),
                    child: Text(
                      'Sell on Mazonn',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: MazonnColors.goldDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _terms = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _afterUserLogin() async {
    await Future.wait([
      context.read<OrderController>().load(),
      context.read<CatalogController>().load(),
    ]);
    if (mounted) context.go(RouteNames.userHome);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_terms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }
    final ok = await context.read<AuthController>().registerUser(
          fullName: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _password.text,
        );
    if (ok && mounted) await _afterUserLogin();
  }

  Future<void> _google() async {
    if (!_terms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }
    final ok = await context.read<AuthController>().loginWithGoogle();
    if (ok && mounted) await _afterUserLogin();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create account', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  'Join Mazonn for a quieter way to shop.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MazonnColors.stone),
                ),
                const SizedBox(height: 28),
                MazonnErrorText(auth.error),
                MazonnTextField(
                  label: 'Full name',
                  controller: _name,
                  validator: (v) => MazonnValidators.requiredField(v, label: 'Full name'),
                ),
                const SizedBox(height: 16),
                MazonnTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: MazonnValidators.email,
                ),
                const SizedBox(height: 16),
                MazonnTextField(
                  label: 'Phone',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: MazonnValidators.phone,
                ),
                const SizedBox(height: 16),
                MazonnTextField(
                  label: 'Password',
                  controller: _password,
                  obscure: _obscure,
                  validator: MazonnValidators.password,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                ),
                const SizedBox(height: 16),
                MazonnTextField(
                  label: 'Confirm password',
                  controller: _confirm,
                  obscure: true,
                  validator: (v) => MazonnValidators.confirmPassword(v, _password.text),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false)),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('I agree to the Terms & Conditions and Privacy Policy.'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MazonnButton(label: 'Create account', loading: auth.busy, onPressed: _submit),
                const SizedBox(height: 16),
                MazonnButton(
                  label: 'Continue with Google',
                  tone: MazonnButtonTone.outline,
                  icon: Icons.g_mobiledata,
                  loading: auth.busy,
                  onPressed: _google,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(onPressed: () => context.go(RouteNames.login), child: const Text('Log in')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context.read<AuthController>().sendPasswordReset(_email.text);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset password', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                _sent
                    ? 'If an account exists for that email, a reset link is on its way.'
                    : 'Enter your email and we will send a reset link.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MazonnColors.stone),
              ),
              const SizedBox(height: 28),
              if (!_sent) ...[
                MazonnErrorText(auth.error),
                MazonnTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: MazonnValidators.email,
                ),
                const SizedBox(height: 24),
                MazonnButton(label: 'Send reset link', loading: auth.busy, onPressed: _send),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

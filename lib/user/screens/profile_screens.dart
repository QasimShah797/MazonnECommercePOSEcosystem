import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/validators.dart';
import '../../../data/mock/mock_catalog.dart';
import '../../../models/address.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_text_field.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/address_controller.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/wishlist_controller.dart';
import 'categories_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: MazonnColors.goldSoft,
                  child: Text(user?.avatarLabel ?? 'M', style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Mazonn member', style: Theme.of(context).textTheme.headlineSmall),
                      Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
                      Text(user?.phone ?? '', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MazonnButton(
              label: 'Edit profile',
              tone: MazonnButtonTone.outline,
              onPressed: () => context.push('/shop/profile/edit'),
            ),
            const SizedBox(height: 20),
            _tile(context, Icons.receipt_long_outlined, 'My orders', '/shop/orders'),
            _tile(context, Icons.favorite_border, 'Wishlist', '/shop/wishlist'),
            _tile(context, Icons.place_outlined, 'Addresses', '/shop/profile/addresses'),
            _tile(context, Icons.credit_card_outlined, 'Payment methods', '/shop/profile/payments'),
            _tile(context, Icons.notifications_none, 'Notifications', '/shop/notifications'),
            _tile(context, Icons.settings_outlined, 'Settings', '/shop/settings'),
            _tile(context, Icons.help_outline, 'Help & support', '/shop/help'),
            const SizedBox(height: 12),
            MazonnButton(
              label: 'Log out',
              tone: MazonnButtonTone.ghost,
              onPressed: () async {
                await context.read<AuthController>().logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String path) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: MazonnColors.ink),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: MazonnColors.stoneLight),
      onTap: () {
        if (path == '/shop/orders') {
          context.go(path);
        } else {
          context.push(path);
        }
      },
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _name = TextEditingController(text: user?.fullName);
    _email = TextEditingController(text: user?.email);
    _phone = TextEditingController(text: user?.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Edit profile'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            MazonnTextField(label: 'Full name', controller: _name, validator: (v) => MazonnValidators.requiredField(v, label: 'Name')),
            const SizedBox(height: 16),
            MazonnTextField(label: 'Email', controller: _email, validator: MazonnValidators.email),
            const SizedBox(height: 16),
            MazonnTextField(label: 'Phone', controller: _phone, validator: MazonnValidators.phone),
            const Spacer(),
            MazonnButton(
              label: 'Save changes',
              onPressed: () async {
                final auth = context.read<AuthController>();
                final current = auth.user;
                if (current == null) return;
                await auth.updateUser(current.copyWith(fullName: _name.text, email: _email.text, phone: _phone.text));
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ids = context.watch<WishlistController>().ids;
    final catalog = context.watch<CatalogController>();
    final typed = ids.map(catalog.byId).where((e) => e != null).map((e) => e!).toList();
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Wishlist'),
      body: typed.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'Nothing saved yet',
              message: 'Tap the heart on a piece to keep it here.',
            )
          : ProductGrid(products: typed),
    );
  }
}

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddressController>();
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Addresses'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MazonnColors.noir,
        onPressed: () => context.push('/shop/profile/addresses/form'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: controller.addresses.isEmpty
          ? const EmptyState(icon: Icons.place_outlined, title: 'No addresses', message: 'Add a place for deliveries.')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: controller.addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = controller.addresses[i];
                return ListTile(
                  tileColor: MazonnColors.white,
                  shape: RoundedRectangleBorder(borderRadius: MazonnRadius.card),
                  title: Text('${a.label} · ${a.fullName}'),
                  subtitle: Text(a.summary),
                  trailing: a.isDefault ? const StatusChip(label: 'Default', color: MazonnColors.success) : null,
                  onTap: () => context.push('/shop/profile/addresses/form', extra: a),
                );
              },
            ),
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.existing});
  final Address? existing;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late final TextEditingController _label;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _postal;
  bool _default = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _label = TextEditingController(text: a?.label ?? 'Home');
    _name = TextEditingController(text: a?.fullName ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
    _line = TextEditingController(text: a?.line1 ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _region = TextEditingController(text: a?.region ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _default = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _name.dispose();
    _phone.dispose();
    _line.dispose();
    _city.dispose();
    _region.dispose();
    _postal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MazonnAppBar(title: widget.existing == null ? 'Add address' : 'Edit address'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MazonnTextField(label: 'Label', controller: _label),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Full name', controller: _name),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Phone', controller: _phone),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Address', controller: _line),
          const SizedBox(height: 12),
          MazonnTextField(label: 'City', controller: _city),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Region', controller: _region),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Postal code', controller: _postal),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Default address'),
            value: _default,
            onChanged: (v) => setState(() => _default = v),
          ),
          MazonnButton(
            label: 'Save address',
            onPressed: () async {
              await context.read<AddressController>().save(
                    Address(
                      id: widget.existing?.id ?? 'a_${DateTime.now().millisecondsSinceEpoch}',
                      label: _label.text,
                      fullName: _name.text,
                      phone: _phone.text,
                      line1: _line.text,
                      city: _city.text,
                      region: _region.text,
                      postalCode: _postal.text,
                      isDefault: _default,
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Payment methods'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ListTile(leading: Icon(Icons.payments_outlined), title: Text('Cash on Delivery'), subtitle: Text('Available at checkout')),
          ListTile(leading: Icon(Icons.credit_card), title: Text('Visa · 4242'), subtitle: Text('Expires 08/28')),
          ListTile(leading: Icon(Icons.account_balance_wallet_outlined), title: Text('Mobile Wallet'), subtitle: Text('Apple Pay, Google Pay')),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Notifications'),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: MockCatalog.notifications.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, i) {
          final n = MockCatalog.notifications[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(n.title),
            subtitle: Text('${n.body}\n${n.time}'),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Settings'),
      body: ListView(
        children: const [
          SwitchListTile(title: Text('Push notifications'), value: true, onChanged: null),
          SwitchListTile(title: Text('Email updates'), value: false, onChanged: null),
          ListTile(title: Text('Language'), subtitle: Text('English')),
          ListTile(title: Text('Currency'), subtitle: Text('USD')),
        ],
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Help & support'),
      body: ListView(
        children: const [
          ExpansionTile(title: Text('Where is my order?'), children: [ListTile(title: Text('Open Orders, then Track to see atelier-to-door progress.'))]),
          ExpansionTile(title: Text('How do returns work?'), children: [ListTile(title: Text('Most pieces can be returned within 14 days in original condition.'))]),
          ExpansionTile(title: Text('Contact Mazonn'), children: [ListTile(title: Text('hello@mazonn.app · Mon–Fri, 9–6 PT'))]),
        ],
      ),
    );
  }
}

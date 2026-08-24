import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_text_field.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/vendor_studio_controller.dart';

class VendorAnalyticsScreen extends StatelessWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<VendorStudioController>();
    final activeOrders = studio.orderList.where((o) => o.status != OrderStatus.cancelled).toList();
    final revenue = activeOrders.fold<double>(0, (s, o) => s + o.total);
    final sold = studio.products.fold<int>(0, (s, p) => s + p.sales);
    final aov = activeOrders.isEmpty ? 0.0 : revenue / activeOrders.length;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _stat(context, 'Revenue', MazonnFormatters.money(revenue)),
              _stat(context, 'Orders', '${studio.orderList.length}'),
              _stat(context, 'Products sold', '$sold'),
              _stat(context, 'Avg. order', MazonnFormatters.money(aov)),
            ],
          ),
          const SizedBox(height: 24),
          Text('Weekly revenue', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: MazonnColors.white, borderRadius: MazonnRadius.card),
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final i = v.toInt();
                        return Text(i >= 0 && i < days.length ? days[i] : '');
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < 7; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (2 + (i * 1.1) + (i.isEven ? 1.4 : 0.3)),
                          color: MazonnColors.gold,
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Top products', style: Theme.of(context).textTheme.titleMedium),
          ...studio.topProducts.map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              subtitle: Text('${p.sales} sold'),
              trailing: Text(MazonnFormatters.money(p.price * p.sales)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 50) / 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: MazonnColors.white, borderRadius: MazonnRadius.card, boxShadow: MazonnShadows.soft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthController>().vendor;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: MazonnColors.goldSoft,
              child: Text(vendor?.logoLabel ?? 'V', style: Theme.of(context).textTheme.headlineSmall),
            ),
            const SizedBox(height: 12),
            Text(vendor?.businessName ?? 'Studio', style: Theme.of(context).textTheme.headlineSmall),
            Text(vendor?.bio ?? '', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            _kv('Owner', vendor?.ownerName ?? ''),
            _kv('Email', vendor?.email ?? ''),
            _kv('Phone', vendor?.phone ?? ''),
            _kv('Category', vendor?.category ?? ''),
            _kv('Address', vendor?.address ?? ''),
            _kv('Store status', vendor?.storeStatus ?? ''),
            const SizedBox(height: 16),
            MazonnButton(label: 'Edit profile', tone: MazonnButtonTone.outline, onPressed: () => context.push('/studio/profile/edit')),
            const SizedBox(height: 8),
            MazonnButton(label: 'Settings', tone: MazonnButtonTone.ghost, onPressed: () => context.push('/studio/settings')),
            const SizedBox(height: 8),
            MazonnButton(
              label: 'Log out',
              onPressed: () async {
                await context.read<AuthController>().logout();
                if (context.mounted) context.go('/vendor/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: MazonnColors.stone))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}

class VendorEditProfileScreen extends StatefulWidget {
  const VendorEditProfileScreen({super.key});

  @override
  State<VendorEditProfileScreen> createState() => _VendorEditProfileScreenState();
}

class _VendorEditProfileScreenState extends State<VendorEditProfileScreen> {
  late final TextEditingController _business;
  late final TextEditingController _owner;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final v = context.read<AuthController>().vendor;
    _business = TextEditingController(text: v?.businessName);
    _owner = TextEditingController(text: v?.ownerName);
    _email = TextEditingController(text: v?.email);
    _phone = TextEditingController(text: v?.phone);
    _address = TextEditingController(text: v?.address);
    _bio = TextEditingController(text: v?.bio);
  }

  @override
  void dispose() {
    _business.dispose();
    _owner.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Edit studio'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MazonnTextField(label: 'Business name', controller: _business),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Owner', controller: _owner),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Email', controller: _email),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Phone', controller: _phone),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Address', controller: _address),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Store information', controller: _bio, maxLines: 3),
          const SizedBox(height: 20),
          MazonnButton(
            label: 'Save',
            onPressed: () async {
              final auth = context.read<AuthController>();
              final current = auth.vendor;
              if (current == null) return;
              await auth.updateVendor(
                current.copyWith(
                  businessName: _business.text,
                  ownerName: _owner.text,
                  email: _email.text,
                  phone: _phone.text,
                  address: _address.text,
                  bio: _bio.text,
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

class VendorSettingsScreen extends StatelessWidget {
  const VendorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MazonnAppBar(title: 'Studio settings'),
      body: ListView(
        children: const [
          SwitchListTile(title: Text('Store open'), value: true, onChanged: null),
          SwitchListTile(title: Text('Order alerts'), value: true, onChanged: null),
          ListTile(title: Text('Payout currency'), subtitle: Text('USD')),
        ],
      ),
    );
  }
}

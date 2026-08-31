import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/firebase/mazonn_firebase.dart';
import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order.dart';
import '../../../models/vendor.dart';
import '../../../services/vendor_document_service.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_button.dart';
import '../../../shared/widgets/mazonn_text_field.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../controllers/vendor_studio_controller.dart';
import '../widgets/vendor_access_gate.dart';

class VendorAnalyticsScreen extends StatelessWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studio = context.watch<VendorStudioController>();
    final activeOrders = studio.orderList
        .where((o) => o.status != OrderStatus.cancelled && o.status != OrderStatus.rejected)
        .toList();
    final revenue = activeOrders.fold<double>(0, (s, o) => s + o.total);
    final sold = studio.products.fold<int>(0, (s, p) => s + p.sales);
    final aov = activeOrders.isEmpty ? 0.0 : revenue / activeOrders.length;

    return VendorAccessGate(
      feature: 'seller analytics and earnings',
      child: Scaffold(
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

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _docs = VendorDocumentService();
  final _support = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().reloadVendor();
    });
  }

  @override
  void dispose() {
    _support.dispose();
    super.dispose();
  }

  Future<void> _upload(String type, String label) async {
    final auth = context.read<AuthController>();
    final vendor = auth.vendor;
    if (vendor == null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await _docs.pickImage(source: source);
      if (file == null) return;
      setState(() => _busy = true);
      final url = await _docs.upload(vendorId: vendor.id, file: file, kind: type);
      final next = [
        ...vendor.documents.where((d) => d.type != type),
        VendorDocument(id: '${vendor.id}_$type', name: label, type: type, url: url),
      ];
      await auth.updateVendor(vendor.copyWith(documents: next));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is StateError ? e.message : 'Upload failed. ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resubmit() async {
    final auth = context.read<AuthController>();
    final vendor = auth.vendor;
    if (vendor == null || !vendor.canResubmit) return;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      await auth.updateVendor(
        vendor.copyWith(
          approvalStatus: 'pending',
          clearRejection: true,
          history: [
            ...vendor.history,
            VendorHistoryEntry(
              at: now,
              action: 'resubmitted',
              actorId: vendor.id,
              actorName: vendor.ownerName,
              detail: 'Vendor resubmitted information for Super Admin review.',
            ),
          ],
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your application was resubmitted for Super Admin review.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _contactSupport() async {
    final vendor = context.read<AuthController>().vendor;
    final message = _support.text.trim();
    if (vendor == null || message.isEmpty) return;
    if (!MazonnFirebase.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support is unavailable offline.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('supportRequests').add({
        'vendorId': vendor.id,
        'storeName': vendor.businessName,
        'ownerName': vendor.ownerName,
        'email': vendor.email,
        'message': message,
        'status': 'open',
        'createdAt': DateTime.now().toIso8601String(),
      });
      _support.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support request sent to Super Admin.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthController>().vendor;
    return Scaffold(
      body: SafeArea(
        bottom: false,
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
            if (vendor != null) ...[
              const SizedBox(height: 12),
              StatusChip(
                label: vendor.displayStatus,
                color: switch (vendor.approvalStatus) {
                  'approved' => MazonnColors.success,
                  'rejected' => MazonnColors.error,
                  'suspended' => MazonnColors.warning,
                  _ => MazonnColors.goldDark,
                },
              ),
              VendorStatusBanner(vendor: vendor),
            ],
            const SizedBox(height: 8),
            _kv('Owner', vendor?.ownerName ?? ''),
            _kv('Email', vendor?.email ?? ''),
            _kv('Phone', vendor?.phone ?? ''),
            _kv('Category', vendor?.category ?? ''),
            _kv('Address', vendor?.address ?? ''),
            _kv('CNIC / ID', vendor?.cnic.isEmpty == true ? 'Not provided' : (vendor?.cnic ?? '')),
            _kv('Documents', vendor?.documentsStatusLabel ?? 'Not uploaded'),
            const SizedBox(height: 16),
            Text('Verification documents', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _docRow('CNIC / ID card', 'cnic', vendor),
            _docRow('Business registration', 'registration', vendor),
            _docRow('Store logo', 'logo', vendor),
            _docRow('Bank proof', 'bank', vendor),
            if (_busy) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator()),
            if (vendor?.canResubmit == true) ...[
              const SizedBox(height: 12),
              MazonnButton(label: 'Resubmit for review', onPressed: _busy ? null : _resubmit),
            ],
            const SizedBox(height: 16),
            MazonnButton(label: 'Edit profile', tone: MazonnButtonTone.outline, onPressed: () => context.push('/studio/profile/edit')),
            const SizedBox(height: 16),
            Text('Request support', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            MazonnTextField(label: 'How can we help?', controller: _support, maxLines: 3),
            const SizedBox(height: 8),
            MazonnButton(label: 'Send to Super Admin', tone: MazonnButtonTone.outline, onPressed: _busy ? null : _contactSupport),
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

  Widget _docRow(String label, String type, Vendor? vendor) {
    final docs = vendor?.documents.where((d) => d.type == type).toList() ?? const <VendorDocument>[];
    final doc = docs.isEmpty ? null : docs.first;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(doc == null ? 'Not uploaded' : doc.status),
      trailing: TextButton(onPressed: _busy ? null : () => _upload(type, label), child: Text(doc == null ? 'Upload' : 'Replace')),
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
  late final TextEditingController _cnic;
  late final TextEditingController _bankName;
  late final TextEditingController _accountTitle;
  late final TextEditingController _accountNumber;
  late final TextEditingController _iban;

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
    _cnic = TextEditingController(text: v?.cnic);
    _bankName = TextEditingController(text: v?.bankName);
    _accountTitle = TextEditingController(text: v?.accountTitle);
    _accountNumber = TextEditingController(text: v?.accountNumber);
    _iban = TextEditingController(text: v?.iban);
  }

  @override
  void dispose() {
    _business.dispose();
    _owner.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _bio.dispose();
    _cnic.dispose();
    _bankName.dispose();
    _accountTitle.dispose();
    _accountNumber.dispose();
    _iban.dispose();
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
          const SizedBox(height: 12),
          MazonnTextField(label: 'CNIC / business ID', controller: _cnic),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Bank name', controller: _bankName),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Account title', controller: _accountTitle),
          const SizedBox(height: 12),
          MazonnTextField(label: 'Account number', controller: _accountNumber),
          const SizedBox(height: 12),
          MazonnTextField(label: 'IBAN', controller: _iban),
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
                  cnic: _cnic.text,
                  bankName: _bankName.text,
                  accountTitle: _accountTitle.text,
                  accountNumber: _accountNumber.text,
                  iban: _iban.text,
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
          ListTile(title: Text('Payout currency'), subtitle: Text('PKR')),
        ],
      ),
    );
  }
}

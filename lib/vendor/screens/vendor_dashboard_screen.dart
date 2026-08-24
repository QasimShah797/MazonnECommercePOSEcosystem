import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/mazonn_colors.dart';
import '../../../core/theme/mazonn_metrics.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product.dart';
import '../../../shared/controllers/auth_controller.dart';
import '../../../shared/widgets/mazonn_ui.dart';
import '../../../user/screens/orders_screen.dart';
import '../controllers/vendor_studio_controller.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendor = context.watch<AuthController>().vendor;
    final studio = context.watch<VendorStudioController>();
    if (studio.loading && studio.products.isEmpty) {
      return const Scaffold(body: LoadingState(label: 'Opening studio'));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              '${MazonnFormatters.greeting(DateTime.now())}, ${vendor?.ownerName.split(' ').first ?? 'Vendor'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(vendor?.businessName ?? 'Studio', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(label: "Today's revenue", value: MazonnFormatters.money(studio.todayRevenue * 0.18), icon: Icons.payments_outlined),
                _MetricCard(label: 'Total orders', value: '${studio.orderList.length}', icon: Icons.local_shipping_outlined),
                _MetricCard(label: 'Pending', value: '${studio.pendingCount}', icon: Icons.hourglass_empty),
                _MetricCard(label: 'Products', value: '${studio.products.length}', icon: Icons.inventory_2_outlined),
                _MetricCard(label: 'Low stock', value: '${studio.lowStockCount}', icon: Icons.warning_amber_outlined),
              ],
            ),
            const SizedBox(height: 24),
            Text('Sales overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: MazonnColors.white, borderRadius: MazonnRadius.card),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: MazonnColors.goldDark,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      spots: const [
                        FlSpot(0, 2.2),
                        FlSpot(1, 3.1),
                        FlSpot(2, 2.8),
                        FlSpot(3, 4.4),
                        FlSpot(4, 3.9),
                        FlSpot(5, 5.2),
                        FlSpot(6, 4.8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent orders', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...studio.orderList.take(3).map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OrderCard(order: o, showVendorActions: true),
                )),
            const SizedBox(height: 12),
            Text('Top products', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...studio.topProducts.map((p) => _ProductRow(product: p)),
            const SizedBox(height: 16),
            Text('Low-stock alerts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (studio.lowStock.isEmpty)
              Text('All pieces are comfortably in stock.', style: Theme.of(context).textTheme.bodySmall)
            else
              ...studio.lowStock.map((p) => _ProductRow(product: p, alert: true)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 50) / 2,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: MazonnColors.white, borderRadius: MazonnRadius.card, boxShadow: MazonnShadows.soft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: MazonnColors.goldDark),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, this.alert = false});
  final Product product;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text('${MazonnFormatters.money(product.price)} · ${product.sales} sold · ${product.stock} left'),
      trailing: alert ? const Icon(Icons.warning_amber, color: MazonnColors.warning) : null,
    );
  }
}

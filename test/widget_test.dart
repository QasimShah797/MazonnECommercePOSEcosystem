import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mazon_ecommerce_pos_ecosystem/app.dart';
import 'package:mazon_ecommerce_pos_ecosystem/core/utils/formatters.dart';
import 'package:mazon_ecommerce_pos_ecosystem/core/utils/validators.dart';
import 'package:mazon_ecommerce_pos_ecosystem/data/mock/mock_catalog.dart';
import 'package:mazon_ecommerce_pos_ecosystem/models/bulk_pricing.dart';
import 'package:mazon_ecommerce_pos_ecosystem/models/order.dart';
import 'package:mazon_ecommerce_pos_ecosystem/services/session_service.dart';
import 'package:mazon_ecommerce_pos_ecosystem/shared/widgets/product_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('currency formatting is stable', () {
    expect(MazonnFormatters.money(128), contains('128'));
    expect(MazonnFormatters.money(128), contains('Rs'));
    expect(MazonnFormatters.date(DateTime(2026, 8, 30)), '30-08-2026');
  });

  test('email and password validators', () {
    expect(MazonnValidators.email('bad'), isNotNull);
    expect(MazonnValidators.email('sophie@mazonn.app'), isNull);
    expect(MazonnValidators.password('123'), isNotNull);
    expect(MazonnValidators.password('mazonn123'), isNull);
    expect(MazonnValidators.confirmPassword('a', 'b'), isNotNull);
  });

  test('bulk pricing engine uses backend tiers', () {
    final rules = PricingEngine.defaultVendorTiers();
    expect(PricingEngine.quote(unitPrice: 1000, quantity: 4, rules: rules).discount, 0);
    expect(PricingEngine.quote(unitPrice: 1000, quantity: 5, rules: rules).discount, 250);
    expect(PricingEngine.quote(unitPrice: 1000, quantity: 10, rules: rules).discount, 1000);
    expect(PricingEngine.quote(unitPrice: 1000, quantity: 25, rules: rules).discount, 3750);
    expect(PricingEngine.quote(unitPrice: 1000, quantity: 50, rules: rules).total, 40000);
    expect(PricingEngine.rangesOverlap(rules), isFalse);
    expect(
      PricingEngine.rangesOverlap([
        const BulkPricingRule(id: 'a', minQty: 5, maxQty: 12, discountType: DiscountType.percent, discountValue: 5),
        const BulkPricingRule(id: 'b', minQty: 10, maxQty: 24, discountType: DiscountType.percent, discountValue: 10),
      ]),
      isTrue,
    );
  });

  test('order transitions are enforced', () {
    expect(OrderTransitions.canTransition(OrderStatus.pending, OrderStatus.processing), isTrue);
    expect(OrderTransitions.canTransition(OrderStatus.pending, OrderStatus.rejected), isTrue);
    expect(OrderTransitions.canTransition(OrderStatus.pending, OrderStatus.shipped), isFalse);
    expect(OrderTransitions.canTransition(OrderStatus.processing, OrderStatus.shipped), isTrue);
    expect(OrderTransitions.canTransition(OrderStatus.delivered, OrderStatus.cancelled), isFalse);
    expect(OrderTransitions.canTransition(OrderStatus.rejected, OrderStatus.processing), isFalse);
  });

  testWidgets('product cards do not overflow in compact grid cells', (tester) async {
    final product = MockCatalog.products.first;
    for (final size in [const Size(360, 640), const Size(390, 844), const Size(412, 915)]) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: 0.56,
              ),
              itemCount: 4,
              itemBuilder: (_, _) => ProductCard(
                product: product,
                wishlisted: false,
                onTap: () {},
                onWishlist: () {},
                onAdd: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Mazonn launches into splash branding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MazonnApp(session: SessionService(prefs)));
    await tester.pump();
    expect(find.textContaining('MAZONN'), findsWidgets);
    await tester.pump(const Duration(seconds: 4));
  });
}

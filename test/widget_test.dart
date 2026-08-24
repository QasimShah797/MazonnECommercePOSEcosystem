import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mazon_ecommerce_pos_ecosystem/app.dart';
import 'package:mazon_ecommerce_pos_ecosystem/core/utils/formatters.dart';
import 'package:mazon_ecommerce_pos_ecosystem/core/utils/validators.dart';
import 'package:mazon_ecommerce_pos_ecosystem/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('currency formatting is stable', () {
    expect(MazonnFormatters.money(128), contains('128'));
  });

  test('email and password validators', () {
    expect(MazonnValidators.email('bad'), isNotNull);
    expect(MazonnValidators.email('sophie@mazonn.app'), isNull);
    expect(MazonnValidators.password('123'), isNotNull);
    expect(MazonnValidators.password('mazonn123'), isNull);
    expect(MazonnValidators.confirmPassword('a', 'b'), isNotNull);
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

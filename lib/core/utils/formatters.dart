import 'package:intl/intl.dart';

abstract final class MazonnFormatters {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  static String money(num value) => _currency.format(value);

  static String date(DateTime value) => DateFormat('dd-MM-yyyy').format(value);

  static String dateTime(DateTime value) =>
      DateFormat('dd-MM-yyyy · HH:mm').format(value);

  static String compactCount(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return '$value';
  }

  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

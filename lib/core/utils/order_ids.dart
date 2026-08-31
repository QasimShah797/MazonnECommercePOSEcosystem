import 'dart:math';

abstract final class OrderIds {
  static final Random _random = Random();

  static String next() {
    final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
    final noise = _random.nextInt(90) + 10;
    return 'MZN-$stamp$noise';
  }
}

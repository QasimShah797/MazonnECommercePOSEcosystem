import '../../models/cart_item.dart';
import '../../models/product.dart';

class VendorCartGroup {
  const VendorCartGroup({
    required this.vendorId,
    required this.vendorName,
    required this.items,
    this.couponDiscount = 0,
    this.deliveryFee = 0,
  });

  final String vendorId;
  final String vendorName;
  final List<CartItem> items;
  final double couponDiscount;
  final double deliveryFee;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get merchandiseSubtotal => items.fold(0, (sum, item) => sum + item.quote.subtotal);
  double get bulkDiscount => items.fold(0, (sum, item) => sum + item.bulkDiscount);
  double get catalogDiscount => items.fold(0.0, (sum, item) {
        final original = item.product.originalPrice;
        if (original == null || original <= item.product.price) return sum;
        return sum + ((original - item.product.price) * item.quantity);
      });
  double get vendorTotal => (merchandiseSubtotal - bulkDiscount - couponDiscount + deliveryFee).clamp(0, double.infinity);
}

extension CartGrouping on List<CartItem> {
  List<VendorCartGroup> grouped({double Function(VendorCartGroup group)? deliveryFeeFor}) {
    final map = <String, List<CartItem>>{};
    for (final item in this) {
      map.putIfAbsent(item.product.vendorId, () => []).add(item);
    }
    return map.entries.map((entry) {
      final items = entry.value;
      final group = VendorCartGroup(
        vendorId: entry.key,
        vendorName: items.first.product.vendorName,
        items: items,
      );
      final fee = deliveryFeeFor?.call(group) ?? 0;
      return VendorCartGroup(
        vendorId: group.vendorId,
        vendorName: group.vendorName,
        items: items,
        deliveryFee: fee,
      );
    }).toList();
  }
}

bool productInStockFor(Product product, int quantity) => product.stock >= quantity;

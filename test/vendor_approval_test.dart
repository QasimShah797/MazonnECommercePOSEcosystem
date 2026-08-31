import 'package:flutter_test/flutter_test.dart';

import 'package:mazon_ecommerce_pos_ecosystem/models/product.dart';
import 'package:mazon_ecommerce_pos_ecosystem/models/vendor.dart';

void main() {
  Product product({required String vendorStatus, ProductModeration moderation = ProductModeration.approved, bool active = true}) {
    return Product(
      id: 'p_test',
      name: 'Test',
      brand: 'Mazonn',
      description: 'desc',
      categoryId: 'fashion',
      vendorId: 'v1',
      vendorName: 'Studio',
      price: 10,
      rating: 5,
      reviewCount: 0,
      stock: 4,
      sku: 'SKU',
      visualSeed: 1,
      isActive: active,
      moderation: moderation,
      vendorApprovalStatus: vendorStatus,
    );
  }

  test('pending, rejected, and suspended vendors cannot sell', () {
    expect(const Vendor(id: '1', businessName: 'A', ownerName: 'B', email: 'a@b.c', phone: '1', category: 'Fashion', address: 'x', approvalStatus: 'pending').canSell, isFalse);
    expect(const Vendor(id: '1', businessName: 'A', ownerName: 'B', email: 'a@b.c', phone: '1', category: 'Fashion', address: 'x', approvalStatus: 'rejected').canResubmit, isTrue);
    expect(const Vendor(id: '1', businessName: 'A', ownerName: 'B', email: 'a@b.c', phone: '1', category: 'Fashion', address: 'x', approvalStatus: 'suspended').isSuspended, isTrue);
    expect(const Vendor(id: '1', businessName: 'A', ownerName: 'B', email: 'a@b.c', phone: '1', category: 'Fashion', address: 'x').canSell, isTrue);
  });

  test('marketplace hides products unless the vendor is approved', () {
    expect(product(vendorStatus: 'approved').isMarketplaceVisible, isTrue);
    expect(product(vendorStatus: 'pending').isMarketplaceVisible, isFalse);
    expect(product(vendorStatus: 'rejected').isMarketplaceVisible, isFalse);
    expect(product(vendorStatus: 'suspended').isMarketplaceVisible, isFalse);
    expect(product(vendorStatus: 'approved', moderation: ProductModeration.pending).isMarketplaceVisible, isFalse);
    expect(product(vendorStatus: 'approved', active: false).isMarketplaceVisible, isFalse);
  });
}

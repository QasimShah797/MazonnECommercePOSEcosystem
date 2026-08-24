import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../services/session_service.dart';

abstract class CartRepository {
  Future<List<CartItem>> load();
  Future<void> save(List<CartItem> items);
}

class MockCartRepository implements CartRepository {
  MockCartRepository(this._session);

  final SessionService _session;

  @override
  Future<List<CartItem>> load() async => _session.readCart();

  @override
  Future<void> save(List<CartItem> items) => _session.writeCart(items);
}

abstract class VendorRepository {
  Future<List<Product>> loadCatalog();
  Future<void> saveCatalog(List<Product> products);
}

class MockVendorRepository implements VendorRepository {
  MockVendorRepository(this._session, this._fallback);

  final SessionService _session;
  final List<Product> _fallback;

  @override
  Future<List<Product>> loadCatalog() async => _session.readVendorProducts(_fallback);

  @override
  Future<void> saveCatalog(List<Product> products) => _session.writeVendorProducts(products);
}

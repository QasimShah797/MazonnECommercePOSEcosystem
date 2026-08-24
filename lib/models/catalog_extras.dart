class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.seed,
  });

  final String id;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String actionLabel;
  final int seed;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final bool read;
}

enum PaymentOption { cashOnDelivery, card, mobileWallet }

extension PaymentOptionX on PaymentOption {
  String get label => switch (this) {
        PaymentOption.cashOnDelivery => 'Cash on Delivery',
        PaymentOption.card => 'Card',
        PaymentOption.mobileWallet => 'Mobile Wallet',
      };

  String get subtitle => switch (this) {
        PaymentOption.cashOnDelivery => 'Pay when your order arrives',
        PaymentOption.card => 'Visa, Mastercard, Amex',
        PaymentOption.mobileWallet => 'Apple Pay, Google Pay, local wallets',
      };
}

enum DeliveryOption { standard, express }

extension DeliveryOptionX on DeliveryOption {
  String get label => switch (this) {
        DeliveryOption.standard => 'Standard delivery',
        DeliveryOption.express => 'Express delivery',
      };

  String get subtitle => switch (this) {
        DeliveryOption.standard => '3–5 business days',
        DeliveryOption.express => '1–2 business days',
      };
}

enum ProductSort { relevance, priceLow, priceHigh, rating, newest }

class SearchFilters {
  const SearchFilters({
    this.minPrice = 0,
    this.maxPrice = 1000,
    this.categoryId,
    this.minRating = 0,
    this.onSaleOnly = false,
    this.inStockOnly = false,
    this.sort = ProductSort.relevance,
  });

  final double minPrice;
  final double maxPrice;
  final String? categoryId;
  final double minRating;
  final bool onSaleOnly;
  final bool inStockOnly;
  final ProductSort sort;

  SearchFilters copyWith({
    double? minPrice,
    double? maxPrice,
    String? categoryId,
    bool clearCategory = false,
    double? minRating,
    bool? onSaleOnly,
    bool? inStockOnly,
    ProductSort? sort,
  }) {
    return SearchFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minRating: minRating ?? this.minRating,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      sort: sort ?? this.sort,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.recipientId,
    this.type = 'system',
    this.orderId,
    this.read = false,
    this.time = '',
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String recipientId;
  final String type;
  final String? orderId;
  final bool read;

  /// Legacy display string used by older mock data.
  final String time;

  String get displayTime => time.isNotEmpty ? time : _relative(createdAt);

  static String _relative(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        recipientId: recipientId,
        type: type,
        orderId: orderId,
        read: read ?? this.read,
        time: time,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'recipientId': recipientId,
        'type': type,
        'orderId': orderId,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        recipientId: json['recipientId'] as String? ?? '',
        type: json['type'] as String? ?? 'system',
        orderId: json['orderId'] as String?,
        read: json['read'] as bool? ?? false,
        time: json['time'] as String? ?? '',
      );
}

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

enum PaymentOption { cashOnDelivery, jazzCash, easyPaisa, card }

extension PaymentOptionX on PaymentOption {
  String get label => switch (this) {
        PaymentOption.cashOnDelivery => 'Cash on Delivery (PKR)',
        PaymentOption.jazzCash => 'JazzCash',
        PaymentOption.easyPaisa => 'Easypaisa',
        PaymentOption.card => 'Debit / Credit card (PKR)',
      };

  String get subtitle => switch (this) {
        PaymentOption.cashOnDelivery => 'Pay in rupees when your order arrives',
        PaymentOption.jazzCash => 'Pay in PKR through JazzCash',
        PaymentOption.easyPaisa => 'Pay in PKR through Easypaisa',
        PaymentOption.card => 'Visa and Mastercard charged in PKR',
      };
}

enum DeliveryOption { standard, express }

extension DeliveryOptionX on DeliveryOption {
  String get label => switch (this) {
        DeliveryOption.standard => 'Standard delivery',
        DeliveryOption.express => 'Express delivery',
      };

  String get subtitle => switch (this) {
        DeliveryOption.standard => '3–5 business days across Pakistan',
        DeliveryOption.express => '1–2 business days in major cities',
      };
}

enum ProductSort { relevance, priceLow, priceHigh, rating, newest }

class SearchFilters {
  const SearchFilters({
    this.minPrice = 0,
    this.maxPrice = 1200,
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

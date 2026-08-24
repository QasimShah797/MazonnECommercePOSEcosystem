class OrderItem {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.price,
    required this.quantity,
    required this.visualSeed,
    this.color,
    this.size,
  });

  final String productId;
  final String name;
  final String brand;
  final double price;
  final int quantity;
  final int visualSeed;
  final String? color;
  final String? size;

  double get lineTotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'brand': brand,
        'price': price,
        'quantity': quantity,
        'visualSeed': visualSeed,
        'color': color,
        'size': size,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        visualSeed: json['visualSeed'] as int? ?? 1,
        color: json['color'] as String?,
        size: json['size'] as String?,
      );
}

enum OrderStatus { processing, shipped, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.processing => 'Processing',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  static OrderStatus fromName(String name) =>
      OrderStatus.values.firstWhere((e) => e.name == name, orElse: () => OrderStatus.processing);
}

class Order {
  const Order({
    required this.id,
    required this.placedAt,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.addressLabel,
    required this.addressLine,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.vendorId,
    this.trackingCode,
    this.customerId = '',
  });

  final String id;
  final DateTime placedAt;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String addressLabel;
  final String addressLine;
  final String deliveryMethod;
  final String paymentMethod;
  final String vendorId;
  final String? trackingCode;
  final String customerId;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({OrderStatus? status, String? trackingCode, String? customerId}) {
    return Order(
      id: id,
      placedAt: placedAt,
      items: items,
      status: status ?? this.status,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      addressLabel: addressLabel,
      addressLine: addressLine,
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
      vendorId: vendorId,
      trackingCode: trackingCode ?? this.trackingCode,
      customerId: customerId ?? this.customerId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'placedAt': placedAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.name,
        'subtotal': subtotal,
        'discount': discount,
        'deliveryFee': deliveryFee,
        'total': total,
        'addressLabel': addressLabel,
        'addressLine': addressLine,
        'deliveryMethod': deliveryMethod,
        'paymentMethod': paymentMethod,
        'vendorId': vendorId,
        'trackingCode': trackingCode,
        'customerId': customerId,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        placedAt: DateTime.parse(json['placedAt'] as String),
        items: (json['items'] as List)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: OrderStatusX.fromName(json['status'] as String),
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        deliveryFee: (json['deliveryFee'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        addressLabel: json['addressLabel'] as String,
        addressLine: json['addressLine'] as String,
        deliveryMethod: json['deliveryMethod'] as String,
        paymentMethod: json['paymentMethod'] as String,
        vendorId: json['vendorId'] as String,
        trackingCode: json['trackingCode'] as String?,
        customerId: json['customerId'] as String? ?? '',
      );
}

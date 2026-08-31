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
    this.imageUrl,
    this.bulkDiscount = 0,
  });

  final String productId;
  final String name;
  final String brand;
  final double price;
  final int quantity;
  final int visualSeed;
  final String? color;
  final String? size;
  final String? imageUrl;
  final double bulkDiscount;

  double get lineSubtotal => price * quantity;
  double get lineTotal => lineSubtotal - bulkDiscount;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'brand': brand,
        'price': price,
        'quantity': quantity,
        'visualSeed': visualSeed,
        'color': color,
        'size': size,
        'imageUrl': imageUrl,
        'bulkDiscount': bulkDiscount,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
        visualSeed: (json['visualSeed'] as num?)?.toInt() ?? 1,
        color: json['color'] as String?,
        size: json['size'] as String?,
        imageUrl: json['imageUrl'] as String?,
        bulkDiscount: (json['bulkDiscount'] as num?)?.toDouble() ?? 0,
      );
}

enum OrderStatus { pending, processing, shipped, delivered, cancelled, rejected }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.processing => 'Processing',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.rejected => 'Rejected',
      };

  static OrderStatus fromName(String name) => OrderStatus.values.firstWhere(
        (e) => e.name == name,
        orElse: () => OrderStatus.pending,
      );
}

abstract final class OrderTransitions {
  static const Map<OrderStatus, Set<OrderStatus>> allowed = {
    OrderStatus.pending: {OrderStatus.processing, OrderStatus.rejected, OrderStatus.cancelled},
    OrderStatus.processing: {OrderStatus.shipped, OrderStatus.cancelled},
    OrderStatus.shipped: {OrderStatus.delivered},
    OrderStatus.delivered: {},
    OrderStatus.cancelled: {},
    OrderStatus.rejected: {},
  };

  static bool canTransition(OrderStatus from, OrderStatus to) => allowed[from]?.contains(to) ?? false;
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
    this.vendorName = '',
    this.customerName = '',
    this.trackingCode,
    this.customerId = '',
    this.couponDiscount = 0,
    this.disputeStatus = 'none',
    this.disputeNote = '',
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
  final String vendorName;
  final String customerName;
  final String? trackingCode;
  final String customerId;
  final double couponDiscount;
  final String disputeStatus;
  final String disputeNote;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    OrderStatus? status,
    String? trackingCode,
    String? customerId,
    String? customerName,
    String? vendorName,
    String? disputeStatus,
    String? disputeNote,
  }) {
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
      vendorName: vendorName ?? this.vendorName,
      customerName: customerName ?? this.customerName,
      trackingCode: trackingCode ?? this.trackingCode,
      customerId: customerId ?? this.customerId,
      couponDiscount: couponDiscount,
      disputeStatus: disputeStatus ?? this.disputeStatus,
      disputeNote: disputeNote ?? this.disputeNote,
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
        'vendorName': vendorName,
        'customerName': customerName,
        'trackingCode': trackingCode,
        'customerId': customerId,
        'couponDiscount': couponDiscount,
        'disputeStatus': disputeStatus,
        'disputeNote': disputeNote,
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
        vendorName: json['vendorName'] as String? ?? '',
        customerName: json['customerName'] as String? ?? '',
        trackingCode: json['trackingCode'] as String?,
        customerId: json['customerId'] as String? ?? '',
        couponDiscount: (json['couponDiscount'] as num?)?.toDouble() ?? 0,
        disputeStatus: json['disputeStatus'] as String? ?? 'none',
        disputeNote: json['disputeNote'] as String? ?? '',
      );
}

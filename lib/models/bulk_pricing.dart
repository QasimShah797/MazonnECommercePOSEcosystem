enum DiscountType { percent, fixed }

class BulkPricingRule {
  const BulkPricingRule({
    required this.id,
    required this.minQty,
    this.maxQty,
    required this.discountType,
    required this.discountValue,
    this.active = true,
    this.source = 'vendor',
  });

  final String id;
  final int minQty;
  final int? maxQty;
  final DiscountType discountType;
  final double discountValue;
  final bool active;
  /// `vendor` or `platform`
  final String source;

  bool appliesTo(int quantity) {
    if (!active) return false;
    if (quantity < minQty) return false;
    if (maxQty != null && quantity > maxQty!) return false;
    return true;
  }

  BulkPricingRule copyWith({
    int? minQty,
    int? maxQty,
    DiscountType? discountType,
    double? discountValue,
    bool? active,
    bool clearMax = false,
  }) {
    return BulkPricingRule(
      id: id,
      minQty: minQty ?? this.minQty,
      maxQty: clearMax ? null : (maxQty ?? this.maxQty),
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      active: active ?? this.active,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'minQty': minQty,
        'maxQty': maxQty,
        'discountType': discountType.name,
        'discountValue': discountValue,
        'active': active,
        'source': source,
      };

  factory BulkPricingRule.fromJson(Map<String, dynamic> json) => BulkPricingRule(
        id: json['id'] as String? ?? 'tier',
        minQty: (json['minQty'] as num?)?.toInt() ?? 1,
        maxQty: (json['maxQty'] as num?)?.toInt(),
        discountType: DiscountType.values.firstWhere(
          (e) => e.name == json['discountType'],
          orElse: () => DiscountType.percent,
        ),
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
        active: json['active'] as bool? ?? true,
        source: json['source'] as String? ?? 'vendor',
      );
}

class LinePrice {
  const LinePrice({
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.appliedRule,
  });

  final double unitPrice;
  final int quantity;
  final double subtotal;
  final double discount;
  final double total;
  final BulkPricingRule? appliedRule;

  double get discountedUnit => quantity == 0 ? unitPrice : total / quantity;
}

abstract final class PricingEngine {
  static List<BulkPricingRule> defaultVendorTiers() => const [
        BulkPricingRule(id: 't5', minQty: 5, maxQty: 9, discountType: DiscountType.percent, discountValue: 5),
        BulkPricingRule(id: 't10', minQty: 10, maxQty: 24, discountType: DiscountType.percent, discountValue: 10),
        BulkPricingRule(id: 't25', minQty: 25, maxQty: 49, discountType: DiscountType.percent, discountValue: 15),
        BulkPricingRule(id: 't50', minQty: 50, discountType: DiscountType.percent, discountValue: 20),
      ];

  static BulkPricingRule? matchingRule(List<BulkPricingRule> rules, int quantity) {
    final matches = rules.where((r) => r.appliesTo(quantity)).toList()
      ..sort((a, b) => b.minQty.compareTo(a.minQty));
    return matches.isEmpty ? null : matches.first;
  }

  static BulkPricingRule? nextRule(List<BulkPricingRule> rules, int quantity) {
    final upcoming = rules.where((r) => r.active && quantity < r.minQty).toList()
      ..sort((a, b) => a.minQty.compareTo(b.minQty));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  static LinePrice quote({
    required double unitPrice,
    required int quantity,
    List<BulkPricingRule> rules = const [],
  }) {
    final qty = quantity < 0 ? 0 : quantity;
    final subtotal = unitPrice * qty;
    final rule = matchingRule(rules, qty);
    var discount = 0.0;
    if (rule != null) {
      discount = switch (rule.discountType) {
        DiscountType.percent => subtotal * (rule.discountValue / 100),
        DiscountType.fixed => rule.discountValue * qty,
      };
      if (discount > subtotal) discount = subtotal;
    }
    return LinePrice(
      unitPrice: unitPrice,
      quantity: qty,
      subtotal: subtotal,
      discount: discount,
      total: subtotal - discount,
      appliedRule: rule,
    );
  }

  static bool rangesOverlap(List<BulkPricingRule> rules) {
    final active = rules.where((r) => r.active).toList()..sort((a, b) => a.minQty.compareTo(b.minQty));
    for (var i = 0; i < active.length; i++) {
      for (var j = i + 1; j < active.length; j++) {
        final a = active[i];
        final b = active[j];
        final aMax = a.maxQty ?? 1 << 30;
        final bMax = b.maxQty ?? 1 << 30;
        if (a.minQty <= bMax && b.minQty <= aMax) return true;
      }
    }
    return false;
  }
}

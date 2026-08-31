class ProductImage {
  const ProductImage({
    required this.id,
    required this.productId,
    required this.url,
    this.isPrimary = false,
    this.sortOrder = 0,
    this.altText = '',
    this.createdAt,
  });

  final String id;
  final String productId;
  final String url;
  final bool isPrimary;
  final int sortOrder;
  final String altText;
  final DateTime? createdAt;

  ProductImage copyWith({bool? isPrimary, int? sortOrder, String? altText, String? url}) {
    return ProductImage(
      id: id,
      productId: productId,
      url: url ?? this.url,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
      altText: altText ?? this.altText,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'url': url,
        'isPrimary': isPrimary,
        'sortOrder': sortOrder,
        'altText': altText,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        id: json['id'] as String? ?? 'img',
        productId: json['productId'] as String? ?? '',
        url: json['url'] as String? ?? json['image_url'] as String? ?? '',
        isPrimary: json['isPrimary'] as bool? ?? json['is_primary'] as bool? ?? false,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? (json['sort_order'] as num?)?.toInt() ?? 0,
        altText: json['altText'] as String? ?? json['alt_text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  static List<ProductImage> fromUrls({
    required String productId,
    required List<String> urls,
    String altText = '',
  }) {
    return [
      for (var i = 0; i < urls.length; i++)
        ProductImage(
          id: '${productId}_img_$i',
          productId: productId,
          url: urls[i],
          isPrimary: i == 0,
          sortOrder: i + 1,
          altText: altText.isEmpty ? '' : (i == 0 ? altText : '$altText view ${i + 1}'),
          createdAt: DateTime(2026, 8, 1),
        ),
    ];
  }
}

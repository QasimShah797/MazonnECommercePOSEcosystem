class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.categoryId,
    required this.vendorId,
    required this.vendorName,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    required this.sku,
    required this.visualSeed,
    this.colors = const [],
    this.sizes = const [],
    this.specifications = const {},
    this.badges = const [],
    this.isFeatured = false,
    this.isPopular = false,
    this.isNewArrival = false,
    this.isFlashSale = false,
    this.isRecommended = false,
    this.isActive = true,
    this.sales = 0,
  });

  final String id;
  final String name;
  final String brand;
  final String description;
  final String categoryId;
  final String vendorId;
  final String vendorName;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final int stock;
  final String sku;
  final int visualSeed;
  final List<String> colors;
  final List<String> sizes;
  final Map<String, String> specifications;
  final List<String> badges;
  final bool isFeatured;
  final bool isPopular;
  final bool isNewArrival;
  final bool isFlashSale;
  final bool isRecommended;
  final bool isActive;
  final int sales;

  bool get inStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 6;

  int get discountPercent {
    final original = originalPrice;
    if (original == null || original <= price) return 0;
    return (((original - price) / original) * 100).round();
  }

  Product copyWith({
    String? name,
    String? brand,
    String? description,
    String? categoryId,
    double? price,
    double? originalPrice,
    int? stock,
    String? sku,
    List<String>? colors,
    List<String>? sizes,
    Map<String, String>? specifications,
    List<String>? badges,
    bool? isActive,
    int? sales,
    int? visualSeed,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      vendorId: vendorId,
      vendorName: vendorName,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating,
      reviewCount: reviewCount,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
      visualSeed: visualSeed ?? this.visualSeed,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      specifications: specifications ?? this.specifications,
      badges: badges ?? this.badges,
      isFeatured: isFeatured,
      isPopular: isPopular,
      isNewArrival: isNewArrival,
      isFlashSale: isFlashSale,
      isRecommended: isRecommended,
      isActive: isActive ?? this.isActive,
      sales: sales ?? this.sales,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'description': description,
        'categoryId': categoryId,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'price': price,
        'originalPrice': originalPrice,
        'rating': rating,
        'reviewCount': reviewCount,
        'stock': stock,
        'sku': sku,
        'visualSeed': visualSeed,
        'colors': colors,
        'sizes': sizes,
        'specifications': specifications,
        'badges': badges,
        'isFeatured': isFeatured,
        'isPopular': isPopular,
        'isNewArrival': isNewArrival,
        'isFlashSale': isFlashSale,
        'isRecommended': isRecommended,
        'isActive': isActive,
        'sales': sales,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        brand: json['brand'] as String,
        description: json['description'] as String,
        categoryId: json['categoryId'] as String,
        vendorId: json['vendorId'] as String,
        vendorName: json['vendorName'] as String,
        price: (json['price'] as num).toDouble(),
        originalPrice: (json['originalPrice'] as num?)?.toDouble(),
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['reviewCount'] as int,
        stock: json['stock'] as int,
        sku: json['sku'] as String,
        visualSeed: json['visualSeed'] as int? ?? 1,
        colors: List<String>.from(json['colors'] as List? ?? const []),
        sizes: List<String>.from(json['sizes'] as List? ?? const []),
        specifications: Map<String, String>.from(json['specifications'] as Map? ?? const {}),
        badges: List<String>.from(json['badges'] as List? ?? const []),
        isFeatured: json['isFeatured'] as bool? ?? false,
        isPopular: json['isPopular'] as bool? ?? false,
        isNewArrival: json['isNewArrival'] as bool? ?? false,
        isFlashSale: json['isFlashSale'] as bool? ?? false,
        isRecommended: json['isRecommended'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        sales: json['sales'] as int? ?? 0,
      );
}

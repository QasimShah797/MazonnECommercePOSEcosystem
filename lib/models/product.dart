import 'bulk_pricing.dart';
import 'product_image.dart';

enum ProductModeration { draft, pending, approved, rejected }

extension ProductModerationX on ProductModeration {
  String get label => switch (this) {
        ProductModeration.draft => 'Draft',
        ProductModeration.pending => 'Pending approval',
        ProductModeration.approved => 'Approved',
        ProductModeration.rejected => 'Rejected',
      };

  static ProductModeration fromName(String? name) => ProductModeration.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ProductModeration.approved,
      );
}

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
    this.barcode = '',
    this.colors = const [],
    this.sizes = const [],
    this.specifications = const {},
    this.badges = const [],
    this.imageUrls = const [],
    this.images = const [],
    this.searchKeywords = const [],
    this.subcategory = '',
    this.bulkPricing = const [],
    this.moderation = ProductModeration.approved,
    this.rejectionReason = '',
    this.isFeatured = false,
    this.isPopular = false,
    this.isNewArrival = false,
    this.isFlashSale = false,
    this.isRecommended = false,
    this.isActive = true,
    this.sales = 0,
    this.vendorApprovalStatus = 'approved',
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
  final String barcode;
  final int visualSeed;
  final List<String> colors;
  final List<String> sizes;
  final Map<String, String> specifications;
  final List<String> badges;
  final List<String> imageUrls;
  final List<ProductImage> images;
  final List<String> searchKeywords;
  final String subcategory;
  final List<BulkPricingRule> bulkPricing;
  final ProductModeration moderation;
  final String rejectionReason;
  final bool isFeatured;
  final bool isPopular;
  final bool isNewArrival;
  final bool isFlashSale;
  final bool isRecommended;
  final bool isActive;
  final int sales;
  final String vendorApprovalStatus;

  bool get inStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 6;
  bool get isMarketplaceVisible =>
      isActive && moderation == ProductModeration.approved && vendorApprovalStatus == 'approved';

  List<ProductImage> get orderedImages {
    final owned = images.where((img) => img.url.isNotEmpty && (img.productId.isEmpty || img.productId == id)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (owned.isNotEmpty) return owned;
    return ProductImage.fromUrls(productId: id, urls: imageUrls.where((u) => u.isNotEmpty).toList(), altText: name);
  }

  List<String> get displayImageUrls {
    final fromImages = orderedImages.map((e) => e.url).where((u) => u.isNotEmpty).toList();
    if (fromImages.isNotEmpty) return fromImages;
    return imageUrls.where((u) => u.isNotEmpty).toList();
  }

  String? get primaryImage {
    for (final img in orderedImages) {
      if (img.isPrimary && img.url.isNotEmpty) return img.url;
    }
    final urls = displayImageUrls;
    return urls.isEmpty ? null : urls.first;
  }

  bool get hasValidPrimaryImage {
    final url = primaryImage;
    return url != null && url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('assets/'));
  }

  bool get canPublish => hasValidPrimaryImage && name.trim().isNotEmpty && price > 0;

  int get discountPercent {
    final original = originalPrice;
    if (original == null || original <= price) return 0;
    return (((original - price) / original) * 100).round();
  }

  LinePrice quote(int quantity) => PricingEngine.quote(
        unitPrice: price,
        quantity: quantity,
        rules: bulkPricing,
      );

  Product copyWith({
    String? name,
    String? brand,
    String? description,
    String? categoryId,
    double? price,
    double? originalPrice,
    int? stock,
    String? sku,
    String? barcode,
    List<String>? colors,
    List<String>? sizes,
    Map<String, String>? specifications,
    List<String>? badges,
    List<String>? imageUrls,
    List<ProductImage>? images,
    List<String>? searchKeywords,
    String? subcategory,
    List<BulkPricingRule>? bulkPricing,
    ProductModeration? moderation,
    String? rejectionReason,
    bool? isActive,
    int? sales,
    int? visualSeed,
    String? vendorApprovalStatus,
  }) {
    final nextImages = images ?? this.images;
    final nextUrls = imageUrls ?? (nextImages.isNotEmpty ? nextImages.map((e) => e.url).toList() : this.imageUrls);
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
      barcode: barcode ?? this.barcode,
      visualSeed: visualSeed ?? this.visualSeed,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      specifications: specifications ?? this.specifications,
      badges: badges ?? this.badges,
      imageUrls: nextUrls,
      images: nextImages,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      subcategory: subcategory ?? this.subcategory,
      bulkPricing: bulkPricing ?? this.bulkPricing,
      moderation: moderation ?? this.moderation,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isFeatured: isFeatured,
      isPopular: isPopular,
      isNewArrival: isNewArrival,
      isFlashSale: isFlashSale,
      isRecommended: isRecommended,
      isActive: isActive ?? this.isActive,
      sales: sales ?? this.sales,
      vendorApprovalStatus: vendorApprovalStatus ?? this.vendorApprovalStatus,
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
        'barcode': barcode,
        'visualSeed': visualSeed,
        'colors': colors,
        'sizes': sizes,
        'specifications': specifications,
        'badges': badges,
        'imageUrls': displayImageUrls,
        'images': orderedImages.map((e) => e.toJson()).toList(),
        'searchKeywords': searchKeywords,
        'subcategory': subcategory,
        'bulkPricing': bulkPricing.map((e) => e.toJson()).toList(),
        'moderation': moderation.name,
        'rejectionReason': rejectionReason,
        'isFeatured': isFeatured,
        'isPopular': isPopular,
        'isNewArrival': isNewArrival,
        'isFlashSale': isFlashSale,
        'isRecommended': isRecommended,
        'isActive': isActive,
        'sales': sales,
        'vendorApprovalStatus': vendorApprovalStatus,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    final urls = List<String>.from(json['imageUrls'] as List? ?? const []);
    final rawImages = json['images'] as List?;
    final images = rawImages == null
        ? ProductImage.fromUrls(productId: id, urls: urls, altText: name)
        : rawImages
            .map((e) => ProductImage.fromJson(Map<String, dynamic>.from(e as Map)))
            .where((img) => img.url.isNotEmpty)
            .toList();
    return Product(
      id: id,
      name: name,
      brand: json['brand'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String? ?? '',
      visualSeed: (json['visualSeed'] as num?)?.toInt() ?? 1,
      colors: List<String>.from(json['colors'] as List? ?? const []),
      sizes: List<String>.from(json['sizes'] as List? ?? const []),
      specifications: Map<String, String>.from(json['specifications'] as Map? ?? const {}),
      badges: List<String>.from(json['badges'] as List? ?? const []),
      imageUrls: urls.isNotEmpty ? urls : images.map((e) => e.url).toList(),
      images: images,
      searchKeywords: List<String>.from(json['searchKeywords'] as List? ?? const []),
      subcategory: json['subcategory'] as String? ?? '',
      bulkPricing: (json['bulkPricing'] as List? ?? const [])
          .map((e) => BulkPricingRule.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      moderation: ProductModerationX.fromName(json['moderation'] as String?),
      rejectionReason: json['rejectionReason'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
      isNewArrival: json['isNewArrival'] as bool? ?? false,
      isFlashSale: json['isFlashSale'] as bool? ?? false,
      isRecommended: json['isRecommended'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      sales: (json['sales'] as num?)?.toInt() ?? 0,
      vendorApprovalStatus: json['vendorApprovalStatus'] as String? ?? 'approved',
    );
  }
}

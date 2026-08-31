import '../models/product.dart';
import '../models/product_image.dart';

class CatalogIssue {
  const CatalogIssue(this.productId, this.field, this.message);
  final String productId;
  final String field;
  final String message;

  @override
  String toString() => '[$productId] $field: $message';
}

class CatalogQualityReport {
  const CatalogQualityReport({required this.productCount, required this.issues, required this.lines});

  final int productCount;
  final List<CatalogIssue> issues;
  final List<String> lines;

  bool get ok => issues.isEmpty;
  String get asText => lines.join('\n');

  static CatalogQualityReport validate(List<Product> products) {
    final issues = <CatalogIssue>[];
    final lines = <String>[
      'Mazonn catalog quality report',
      'Products: ${products.length}',
      '',
    ];

    for (final product in products) {
      void fail(String field, String message) => issues.add(CatalogIssue(product.id, field, message));

      if (product.name.trim().isEmpty) fail('name', 'missing');
      if (product.description.trim().isEmpty) fail('description', 'missing');
      if (product.categoryId.trim().isEmpty) fail('category', 'missing');
      if (product.vendorId.trim().isEmpty || product.vendorName.trim().isEmpty) fail('vendor', 'missing');
      if (product.price <= 0) fail('price', 'must be greater than 0');
      if (product.stock < 0) fail('stock', 'must be >= 0');

      final primary = product.primaryImage;
      if (primary == null || primary.isEmpty) {
        fail('primary_image', 'missing');
      } else if (!_validUrl(primary)) {
        fail('image_url', 'invalid primary URL');
      }

      for (final image in product.images) {
        if (image.productId.isNotEmpty && image.productId != product.id) {
          fail('image_association', 'image ${image.id} belongs to ${image.productId}');
        }
        if (image.url.isNotEmpty && !_validUrl(image.url)) {
          fail('image_url', 'invalid URL ${image.url}');
        }
      }

      if (product.searchKeywords.isEmpty) fail('search_keywords', 'missing');
      if (!product.isMarketplaceVisible) fail('searchable', 'not marketplace visible');

      final kindHint = product.subcategory.isEmpty ? product.categoryId : product.subcategory;
      lines.add(
        '${product.okMark(issues)} ${product.id}  ${product.name}  '
        'cat=${product.categoryId}/$kindHint  vendor=${product.vendorName}  '
        'price=${product.price}  stock=${product.stock}  '
        'primary=${product.hasValidPrimaryImage}  keywords=${product.searchKeywords.length}',
      );
    }

    lines
      ..add('')
      ..add(issues.isEmpty ? 'RESULT: PASS' : 'RESULT: FAIL (${issues.length} issues)')
      ..addAll(issues.map((e) => ' - $e'));
    return CatalogQualityReport(productCount: products.length, issues: issues, lines: lines);
  }

  static bool _validUrl(String url) =>
      url.startsWith('https://') || url.startsWith('http://') || url.startsWith('assets/');
}

extension on Product {
  String okMark(List<CatalogIssue> issues) => issues.any((e) => e.productId == id) ? '✗' : '✓';
}

bool imagesBelongToProduct(Product product) {
  return product.orderedImages.every(
    (ProductImage image) => image.productId.isEmpty || image.productId == product.id,
  );
}

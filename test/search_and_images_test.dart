import 'package:flutter_test/flutter_test.dart';

import 'package:mazon_ecommerce_pos_ecosystem/data/catalog_quality.dart';
import 'package:mazon_ecommerce_pos_ecosystem/data/mock/demo_media.dart';
import 'package:mazon_ecommerce_pos_ecosystem/data/mock/mock_catalog.dart';
import 'package:mazon_ecommerce_pos_ecosystem/models/product.dart';
import 'package:mazon_ecommerce_pos_ecosystem/services/search_service.dart';

void main() {
  final catalog = MockCatalog.products.where((p) => p.isMarketplaceVisible).toList();
  final search = LocalCatalogSearchService();

  List<Product> find(String q) => search.search(catalog: catalog, query: q);

  test('seed catalog quality: name, images, keywords, vendor, price, stock', () {
    final report = CatalogQualityReport.validate(catalog);
    // ignore: avoid_print
    print(report.asText);
    expect(report.ok, isTrue, reason: report.asText);
    expect(catalog.length, greaterThanOrEqualTo(34));
  });

  test('images are product-specific and deterministic, never hashed by category pool', () {
    final tv = MockCatalog.byId('p29')!;
    final phone = MockCatalog.byId('p32')!;
    final again = DemoMedia.assign(
      productId: tv.id,
      name: tv.name,
      brand: tv.brand,
      description: tv.description,
      categoryId: tv.categoryId,
    );
    expect(tv.primaryImage, isNotEmpty);
    expect(tv.primaryImage, again.first.url);
    expect(tv.images.every((img) => img.productId == tv.id), isTrue);
    expect(tv.primaryImage, isNot(phone.primaryImage));
    expect(DemoMedia.detectKind(name: tv.name, description: tv.description, categoryId: tv.categoryId), 'television');
    expect(DemoMedia.detectKind(name: phone.name, description: phone.description, categoryId: phone.categoryId), 'smartphone');
    expect(DemoMedia.detectKind(name: 'Everyday Runners', description: 'road shoe', categoryId: 'sports'), 'runners');
    expect(DemoMedia.detectKind(name: 'Quiet Buds Pro', description: 'wireless earbuds', categoryId: 'electronics'), 'earbuds');
  });

  test('predictive suggestions use catalog and synonyms', () {
    final tel = search.suggest(catalog: catalog, query: 'tel');
    expect(tel.map((e) => e.label.toLowerCase()).any((e) => e.contains('tv') || e.contains('television')), isTrue);

    final telly = search.suggest(catalog: catalog, query: 'telly');
    expect(telly.map((e) => e.label.toLowerCase()).any((e) => e.contains('television') || e.contains('tv')), isTrue);

    final iph = search.suggest(catalog: catalog, query: 'iph');
    expect(iph.map((e) => e.label.toLowerCase()).any((e) => e.contains('iphone')), isTrue);

    final head = search.suggest(catalog: catalog, query: 'head');
    expect(head.map((e) => e.label.toLowerCase()).any((e) => e.contains('headphone')), isTrue);
  });

  test('required search cases return the correct product type and image', () {
    void expectKind(String query, String kind, {String? nameContains}) {
      final results = find(query);
      expect(results, isNotEmpty, reason: 'No results for "$query"');
      final top = results.first;
      expect(
        DemoMedia.detectKind(name: top.name, description: top.description, categoryId: top.categoryId),
        kind,
        reason: '"$query" ranked ${top.name} first',
      );
      if (nameContains != null) {
        expect(results.any((p) => p.name.toLowerCase().contains(nameContains)), isTrue);
      }
      expect(top.hasValidPrimaryImage, isTrue);
      expect(top.vendorName, isNotEmpty);
      expect(top.price, greaterThan(0));
      final unrelated = results.where((p) {
        final detected = DemoMedia.detectKind(name: p.name, description: p.description, categoryId: p.categoryId);
        return detected != kind && (kind != 'headphones' || detected != 'earbuds');
      });
      expect(unrelated.length, lessThan(results.length), reason: '"$query" returned only unrelated products');
    }

    expectKind('telly', 'television', nameContains: 'tv');
    expectKind('tv', 'television');
    expectKind('television', 'television');
    expectKind('televison', 'television');
    expectKind('iphne', 'smartphone', nameContains: 'iphone');
    expectKind('fridge', 'refrigerator', nameContains: 'refrigerat');
    expectKind('shoes', 'runners');
    expectKind('headphones', 'headphones');
  });

  test('telly does not rank unrelated electronics such as phones or speakers first', () {
    final results = find('telly');
    expect(results.first.name.toLowerCase(), contains('tv'));
    expect(results.take(3).every((p) => p.name.toLowerCase().contains('tv') || p.name.toLowerCase().contains('television')), isTrue);
    expect(results.take(3).any((p) => p.name.contains('Speaker') || p.name.contains('iPhone')), isFalse);
  });

  test('search ranking prefers exact and synonym name matches over parent category', () {
    final results = find('telly');
    expect(results.map((e) => e.id).toList(), containsAll(['p29', 'p30', 'p31']));
    expect(results.take(3).map((e) => e.id).toSet(), containsAll(['p29', 'p30', 'p31']));
    expect(results.take(3).any((p) => p.id == 'p12' || p.id == 'p32'), isFalse);
  });
}

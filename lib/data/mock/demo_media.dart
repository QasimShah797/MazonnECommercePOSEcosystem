import '../../models/product.dart';
import '../../models/product_image.dart';

/// Deterministic product-type image assignment.
/// Same name + category always yields the same image set. Never uses Random or id hashing.
abstract final class DemoMedia {
  static const _host = 'https://images.unsplash.com';

  static String src(String photoId) => '$_host/photo-$photoId?auto=format&fit=crop&w=900&q=80';

  static const kinds = <String, List<String>>{
    'coat': ['1539533018447-63fcce2678e3', '1483985988355-763728e1935b', '1520975954732-492c5d4ba0ef'],
    'dress': ['1595777457583-95e059d581b8', '1515372039744-b8f02a3ae446', '1496747616402-7e0dfa5e57c2'],
    'trousers': ['1594938298603-c8148c4dae35', '1506629082955-511b1aa562c8', '1473963964850-60c7f5022b56'],
    'knit': ['1434389677669-e08b4cac3105', '1576566588028-4147f3842d08', '1485230895905-ec40ba36b9bc'],
    'lounge': ['1521572163474-6864f9cf17ab', '1489987707025-941c1a274d34', '1551488831-00ddcb6c6bd3'],
    'pourOver': ['1495474472287-4d71bcdd2085', '1511920170033-f83992f482bb', '1447933601403-0c6688de566e'],
    'board': ['1606313564200-e75d5e30476e', '1556910103-1c02745aae4d', '1466637574441-749b8f19452f'],
    'bedding': ['1522771739844-6a9f6d5f14af', '1631049307264-da0ec9d70304', '1505693416388-ac5ce068fe85'],
    'lamp': ['1507473883500-efb67989d646', '1513506003901-1e6a229e2d15', '1513506003901-1e6a229e2d15'],
    'earbuds': ['1590658268037-6bf12165a8df', '1606220945770-b5b6c2c37bf1', '1572569511254-d8f925fe2cbb'],
    'organizer': ['1586075010923-2dd4570fb338', '1497366216548-37526070297c', '1454165804606-c3d57bc86b40'],
    'speaker': ['1608043152269-423dbba4e7e1', '1545454675-3531b54a2c18', '1545454675-3531b54a2c18'],
    'perfume': ['1541643600914-78b084683601', '1594035910387-fea47794261f', '1615634260167-c8cdede054de'],
    'bodyOil': ['1608248543803-ba4f8c70ae0b', '1556228578-8c89e6adf883', '1571781926291-c477ebfd024b'],
    'facial': ['1556228720-195a672e8a03', '1570172619644-dfd03ed5d881', '1596462502278-27bfdc403348'],
    'oliveOil': ['1474979266404-7ea48cd53acc', '1477763858572-cda7deaa9bc5', '1466637574441-749b8f19452f'],
    'honey': ['1587049352846-4a222e784d38', '1558642452-9d2a7deb7f62', '1471943038886-bb893b9a5d53'],
    'granola': ['1517677208171-0ec87531525f', '1490885577081-39ef1c5e8d37', '1490474418585-ba9bad8fd0ea'],
    'tee': ['1521572163474-6864f9cf17ab', '1583743814966-8936f5b7be1a', '1562157873-818bc0726aa9'],
    'yogaMat': ['1544367567-0f2fcb009e0b', '1518611012118-696072aa579a', '1571019614242-c5c5dee9f50b'],
    'runners': ['1542291026-7eec264c27ff', '1460353581641-37baddab0fa2', '1606107557195-0e29a4b5b4aa'],
    'earrings': ['1535632066927-ab7c9ab60908', '1611652022419-a9419f74343d', '1599643478518-a784e5dc4c8f'],
    'bag': ['1548036328-c9fa89d128fa', '1590874103328-eac38a941956', '1553062407-98eeb64c6a62'],
    'watch': ['1523275335684-37898b6baf30', '1522312346375-d1a52e2b99b3', '1508685096489-7aacd43bd3b1'],
    'scarf': ['1601924993428-7def96980463', '1483985988355-763728e1935b', '1434389677669-e08b4cac3105'],
    'cap': ['1588850561407-42e59df82beb', '1521369909029-2afed882baee', '1576871337622-98d48d1cf531'],
    'vase': ['1578749556568-bc2c40e68b61', '1484101403633-562f891dc89a', '1578749556568-bc2c40e68b61'],
    'candle': ['1603006905003-ea3e1bdb5481', '1513519245088-0e12902e35a6', '1570829463276-a94bdc79eae8'],
    'television': ['1593359677879-a4bb92f829d1', '1461151304267-38535e780c79', '1593784991095-a205069470b6'],
    'smartphone': ['1510557880182-3d4d3cba35a5', '1511707171634-5f897ff02aa9', '1592899677977-9c10ca588bbd'],
    'refrigerator': ['1571175443880-49e1d25b2bc5', '1584568694244-14fbdf83bd30', '1570222094114-d054a817e56b'],
    'headphones': ['1505740420928-5e560c06d30e', '1484704849700-f032a568e944', '1583394838336-acd977736f90'],
    'fashion': ['1490481651871-ab68de25d43d', '1483985988355-763728e1935b', '1515886657613-9f3515e0c785'],
    'electronics': ['1511707171634-5f897ff02aa9', '1546868871-7041f2a55e12', '1518444065439-e933c06ce9cd'],
    'beauty': ['1596462502278-27bfdc403348', '1522335789203-aabd1fc54bc9', '1612817288484-6f916006741a'],
    'home': ['1555041469-a586c61ea9bc', '1493663284031-b7e3aefcae8e', '1586023492125-27b2c045efd7'],
    'grocery': ['1542838132-92c53300491e', '1512621776951-a57141f2eefd', '1504674900247-0877df9cc836'],
    'sports': ['1571019614242-c5c5dee9f50b', '1517836357463-d25dfeac3438', '1542291026-7eec264c27ff'],
    'accessories': ['1523275335684-37898b6baf30', '1572635196237-14b3f281503f', '1599643478518-a784e5dc4c8f'],
  };

  static const _rules = <String, List<String>>{
    'television': ['television', 'smart tv', 'led tv', '4k tv', '4k smart', 'inch 4k'],
    'smartphone': ['iphone', 'smartphone', 'mobile phone', 'cell phone'],
    'headphones': ['headphone', 'headphones', 'headset', 'over-ear', 'over ear'],
    'earbuds': ['earbud', 'earbuds', 'buds pro', 'quiet buds', 'wireless buds'],
    'refrigerator': ['refrigerator', 'fridge', 'freezer'],
    'runners': ['runner', 'runners', 'running shoe', 'road shoe', 'sneaker', 'sneakers', 'trainer', 'trainers', 'footwear', 'shoes'],
    'lounge': ['lounge', 'linen set'],
    'coat': ['wrap coat', 'overcoat', 'wool coat', 'coat'],
    'dress': ['dress'],
    'trousers': ['trouser', 'trousers', 'pant', 'pants'],
    'knit': ['knit', 'cashmere', 'sweater', 'crew'],
    'pourOver': ['pour-over', 'pour over', 'dripper', 'carafe', 'coffee maker', 'coffee machine'],
    'board': ['serving board', 'cutting board', 'oak board'],
    'bedding': ['bedding', 'duvet', 'linen bedding'],
    'lamp': ['lamp'],
    'organizer': ['organizer', 'desk tray'],
    'speaker': ['speaker'],
    'perfume': ['parfum', 'perfume', 'eau de'],
    'bodyOil': ['body oil'],
    'facial': ['facial', 'clay'],
    'oliveOil': ['olive oil'],
    'honey': ['honey'],
    'granola': ['granola'],
    'tee': ['training tee', 't-shirt', ' t shirt', ' tee'],
    'yogaMat': ['training mat', 'yoga mat', 'studio mat'],
    'earrings': ['earring', 'earrings'],
    'bag': ['crossbody', 'handbag', 'shoulder bag'],
    'watch': ['watch'],
    'scarf': ['scarf'],
    'cap': ['cap', 'hat'],
    'vase': ['vase'],
    'candle': ['candle'],
  };

  static const subcategoryForKind = <String, String>{
    'television': 'televisions',
    'smartphone': 'smartphones',
    'headphones': 'headphones',
    'earbuds': 'headphones',
    'refrigerator': 'refrigerators',
    'runners': 'footwear',
    'coat': 'outerwear',
    'dress': 'dresses',
    'trousers': 'bottoms',
    'knit': 'knitwear',
    'lounge': 'loungewear',
    'tee': 'tops',
    'speaker': 'audio',
    'perfume': 'fragrance',
    'earrings': 'earrings',
    'bag': 'bags',
    'watch': 'watches',
    'scarf': 'scarves',
    'cap': 'hats',
    'vase': 'decor',
    'candle': 'home fragrance',
    'organizer': 'desk',
    'lamp': 'lighting',
    'bedding': 'bedding',
    'board': 'kitchen',
    'pourOver': 'coffee',
    'yogaMat': 'fitness',
  };

  static const keywordsForKind = <String, List<String>>{
    'television': ['tv', 'telly', 'television', 'smart tv', 'led tv', '4k tv', '4k television'],
    'smartphone': ['iphone', 'phone', 'mobile', 'smartphone', 'cell', 'cellphone'],
    'headphones': ['headphones', 'headset', 'wireless headphones', 'bluetooth headphones', 'gaming headset'],
    'earbuds': ['earbuds', 'wireless earbuds', 'buds', 'earphones', 'headphones'],
    'refrigerator': ['fridge', 'refrigerator', 'freezer'],
    'runners': ['shoes', 'sneakers', 'trainers', 'footwear', 'running shoes'],
    'coat': ['coat', 'outerwear'],
    'speaker': ['speaker', 'bluetooth speaker'],
    'watch': ['watch', 'timepiece'],
  };

  static String detectKind({
    required String name,
    required String description,
    required String categoryId,
  }) {
    final hay = ' ${name.toLowerCase()} ${description.toLowerCase()} ';
    for (final entry in _rules.entries) {
      if (entry.value.any((key) => _containsTerm(hay, key))) return entry.key;
    }
    return categoryId;
  }

  static bool _containsTerm(String hay, String key) {
    final term = key.trim();
    if (term.contains(' ')) return hay.contains(term);
    return RegExp('\\b${RegExp.escape(term)}\\b').hasMatch(hay);
  }

  static String subcategoryFor({
    required String name,
    required String description,
    required String categoryId,
  }) {
    final kind = detectKind(name: name, description: description, categoryId: categoryId);
    return subcategoryForKind[kind] ?? categoryId;
  }

  static List<String> keywordsFor({
    required String name,
    required String brand,
    required String description,
    required String categoryId,
  }) {
    final kind = detectKind(name: name, description: description, categoryId: categoryId);
    final words = <String>{
      ...name.toLowerCase().split(RegExp(r'[^a-z0-9+]+')).where((w) => w.length > 1),
      brand.toLowerCase(),
      categoryId,
      subcategoryFor(name: name, description: description, categoryId: categoryId),
      ...?keywordsForKind[kind],
    };
    return words.toList();
  }

  static List<ProductImage> assign({
    required String productId,
    required String name,
    required String brand,
    required String description,
    required String categoryId,
  }) {
    final kind = detectKind(name: name, description: description, categoryId: categoryId);
    final photos = kinds[kind] ?? kinds[categoryId] ?? kinds['fashion']!;
    final unique = <String>[];
    for (final id in photos) {
      if (!unique.contains(id)) unique.add(id);
    }
    final alt = '$name by $brand';
    return [
      for (var i = 0; i < unique.length; i++)
        ProductImage(
          id: '${productId}_img_$i',
          productId: productId,
          url: src(unique[i]),
          isPrimary: i == 0,
          sortOrder: i + 1,
          altText: i == 0 ? '$alt front view' : '$alt view ${i + 1}',
          createdAt: DateTime(2026, 8, 1),
        ),
    ];
  }

  static List<String> urlsFor(Product product) =>
      assign(
        productId: product.id,
        name: product.name,
        brand: product.brand,
        description: product.description,
        categoryId: product.categoryId,
      ).map((e) => e.url).toList();
}

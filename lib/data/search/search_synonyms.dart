/// Configurable search aliases. Keep this as data — never scatter synonym lists in widgets.
class SearchSynonymTable {
  const SearchSynonymTable({
    required this.aliases,
    this.popular = const [],
    this.blocked = const [],
  });

  /// Lowercase term → related terms (including canonical names).
  final Map<String, List<String>> aliases;
  final List<String> popular;
  final List<String> blocked;

  SearchSynonymTable merge(SearchSynonymTable other) {
    final next = <String, List<String>>{};
    for (final e in aliases.entries) {
      next[e.key] = List<String>.from(e.value);
    }
    for (final e in other.aliases.entries) {
      final bucket = next.putIfAbsent(e.key, () => <String>[]);
      for (final v in e.value) {
        if (!bucket.contains(v)) bucket.add(v);
      }
    }
    return SearchSynonymTable(
      aliases: next,
      popular: {...popular, ...other.popular}.toList(),
      blocked: {...blocked, ...other.blocked}.toList(),
    );
  }

  SearchSynonymTable withAlias(String from, String to) {
    final key = from.trim().toLowerCase();
    final value = to.trim().toLowerCase();
    if (key.isEmpty || value.isEmpty) return this;
    final next = {
      for (final e in aliases.entries) e.key: List<String>.from(e.value),
    };
    final bucket = next.putIfAbsent(key, () => <String>[]);
    if (!bucket.contains(value)) bucket.add(value);
    return SearchSynonymTable(aliases: next, popular: popular, blocked: blocked);
  }

  SearchSynonymTable withoutAlias(String from, String to) {
    final next = {
      for (final e in aliases.entries) e.key: List<String>.from(e.value),
    };
    next[from]?.remove(to);
    if (next[from]?.isEmpty ?? false) next.remove(from);
    return SearchSynonymTable(aliases: next, popular: popular, blocked: blocked);
  }

  Map<String, dynamic> toJson() => {
        'aliases': aliases,
        'popular': popular,
        'blocked': blocked,
      };

  factory SearchSynonymTable.fromJson(Map<String, dynamic> json) {
    final raw = json['aliases'] as Map? ?? const {};
    return SearchSynonymTable(
      aliases: {
        for (final e in raw.entries) e.key.toString(): List<String>.from(e.value as List? ?? const []),
      },
      popular: List<String>.from(json['popular'] as List? ?? const []),
      blocked: List<String>.from(json['blocked'] as List? ?? const []),
    );
  }

  static SearchSynonymTable defaults() => const SearchSynonymTable(
        aliases: {
          'telly': ['television', 'tv', 'smart tv', 'led tv', '4k tv', '4k television'],
          'tv': ['television', 'smart tv', 'led tv', '4k tv'],
          'television': ['tv', 'smart tv', 'led tv', 'telly'],
          'tele': ['television', 'tv', 'smart tv'],
          'mob': ['mobile', 'smartphone', 'phone'],
          'cell': ['mobile phone', 'smartphone', 'cellphone'],
          'cellphone': ['mobile phone', 'smartphone', 'phone'],
          'phone': ['smartphone', 'iphone', 'mobile'],
          'iphone': ['smartphone', 'phone', 'iphone 15', 'iphone 15 pro', 'iphone 15 pro max'],
          'iph': ['iphone', 'iphone 15', 'iphone 15 pro'],
          'fridge': ['refrigerator', 'freezer'],
          'refrigerator': ['fridge'],
          'shoes': ['footwear', 'sneakers', 'trainers', 'running shoes'],
          'sneakers': ['shoes', 'footwear', 'trainers'],
          'trainers': ['shoes', 'sneakers', 'footwear'],
          'footwear': ['shoes', 'sneakers'],
          'laptop': ['notebook'],
          'notebook': ['laptop'],
          'earbuds': ['wireless earbuds', 'earphones', 'headphones'],
          'earphones': ['earbuds', 'headphones'],
          'headphones': ['headset', 'wireless headphones', 'bluetooth headphones', 'earbuds'],
          'headset': ['headphones', 'gaming headset'],
          'head': ['headphones', 'headset', 'wireless headphones'],
        },
        popular: [
          'Television',
          'iPhone',
          'Fridge',
          'Running shoes',
          'Headphones',
        ],
      );
}

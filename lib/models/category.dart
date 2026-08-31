import 'package:flutter/material.dart';

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.tone,
    this.subcategories = const [],
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final List<String> subcategories;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'subcategories': subcategories,
      };

  factory ProductCategory.fromJson(Map<String, dynamic> json, {required IconData icon, required Color tone}) {
    final rawSubs = json['subcategories'] as List? ?? const [];
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      icon: icon,
      tone: tone,
      subcategories: rawSubs.map((e) {
        if (e is String) return e;
        if (e is Map) return (e['name'] as String?) ?? '';
        return e.toString();
      }).where((e) => e.isNotEmpty).toList(),
    );
  }
}

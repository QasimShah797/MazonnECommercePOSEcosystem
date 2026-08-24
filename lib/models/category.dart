import 'package:flutter/material.dart';

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.tone,
  });

  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color tone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
      };

  factory ProductCategory.fromJson(Map<String, dynamic> json, {required IconData icon, required Color tone}) {
    return ProductCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String,
      icon: icon,
      tone: tone,
    );
  }
}

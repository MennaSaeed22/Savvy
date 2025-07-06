import 'package:flutter/material.dart';
enum CategoryType { regular, savings }

class Category {
  final String id;
  final String name;
  final IconData icon;
  final CategoryType type;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.type = CategoryType.regular,
  });
}

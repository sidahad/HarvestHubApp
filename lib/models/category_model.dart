import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconEmoji;
  final String image;
  final int itemCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconEmoji,
    required this.image,
    required this.itemCount,
  });

  String get icon => iconEmoji;
  int get productCount => itemCount;

  IconData get iconData {
    final lower = name.toLowerCase();
    if (lower.contains('fruit')) return Icons.apple_rounded;
    if (lower.contains('veg')) return Icons.eco_rounded;
    if (lower.contains('dairy') || lower.contains('milk')) return Icons.local_drink_rounded;
    if (lower.contains('grain') ||
        lower.contains('wheat') ||
        lower.contains('atta') ||
        lower.contains('rice')) {
      return Icons.grass_rounded;
    }
    if (lower.contains('honey') || lower.contains('jam')) return Icons.hive_rounded;
    if (lower.contains('organic') || lower.contains('herb')) return Icons.spa_rounded;
    if (lower.contains('egg') || lower.contains('poultry')) return Icons.egg_outlined;
    return Icons.inventory_2_outlined;
  }
}

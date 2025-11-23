import 'package:flutter/material.dart';

class CategoryReportItem {
  final String categoryId;
  final String categoryName;
  final double amount;
  final Color color;
  final IconData? iconData;

  CategoryReportItem({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.color,
    this.iconData,
  });
}

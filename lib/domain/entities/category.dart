import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final int color;
  final String defaultType; // 'expense' or 'income'

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.defaultType,
  });

  @override
  List<Object?> get props => [id, name, icon, color, defaultType];
}

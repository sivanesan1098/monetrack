import 'package:monetrack/core/constants/db_constants.dart';
import 'package:monetrack/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.color,
    required super.defaultType,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map[DbConstants.colId],
      name: map[DbConstants.colName],
      icon: map[DbConstants.colIcon],
      color: map[DbConstants.colColor],
      defaultType: map[DbConstants.colDefaultType],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colId: id,
      DbConstants.colName: name,
      DbConstants.colIcon: icon,
      DbConstants.colColor: color,
      DbConstants.colDefaultType: defaultType,
    };
  }
}

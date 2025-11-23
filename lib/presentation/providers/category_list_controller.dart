import 'package:monetrack/domain/entities/category.dart';
import 'package:monetrack/presentation/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_list_controller.g.dart';

@riverpod
class CategoryListController extends _$CategoryListController {
  @override
  Future<List<Category>> build() async {
    return _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.getCategories();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (categories) => categories,
    );
  }
}

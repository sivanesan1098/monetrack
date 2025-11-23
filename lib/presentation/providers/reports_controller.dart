import 'package:flutter/material.dart';
import 'package:monetrack/domain/entities/category.dart';
import 'package:monetrack/domain/entities/category_report_item.dart';
import 'package:monetrack/domain/entities/transaction.dart';
import 'package:monetrack/presentation/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_controller.g.dart';

@riverpod
class ReportsController extends _$ReportsController {
  @override
  Future<List<TransactionEntity>> build() async {
    return _fetchTransactions();
  }

  Future<List<TransactionEntity>> _fetchTransactions() async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await repository.getTransactions();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (transactions) => transactions,
    );
  }

  Future<List<CategoryReportItem>> getCategoryReport(List<TransactionEntity> transactions, String type) async {
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final categoriesResult = await categoryRepo.getCategories();
    
    final List<Category> categories = categoriesResult.fold(
      (l) => [], 
      (r) => r
    );
    
    final Map<String, Category> categoryMap = {
      for (var c in categories) c.id: c
    };

    final Map<String, double> totals = {};
    
    for (var t in transactions) {
      if (t.type == type) {
        final catId = t.categoryId ?? 'uncategorized';
        totals[catId] = (totals[catId] ?? 0) + t.amount;
      }
    }

    final List<CategoryReportItem> reportItems = [];
    
    for (var entry in totals.entries) {
      final catId = entry.key;
      final amount = entry.value;
      
      String name = 'Uncategorized';
      Color color = Colors.grey;
      
      if (categoryMap.containsKey(catId)) {
        final cat = categoryMap[catId]!;
        name = cat.name;
        color = Color(cat.color);
      } else if (catId == 'uncategorized') {
        name = 'Uncategorized';
        color = Colors.grey;
      } else {
         // Fallback for deleted categories or IDs not found
         name = 'Unknown ($catId)';
      }

      reportItems.add(CategoryReportItem(
        categoryId: catId,
        categoryName: name,
        amount: amount,
        color: color,
      ));
    }
    
    // Sort by amount descending
    reportItems.sort((a, b) => b.amount.compareTo(a.amount));
    
    return reportItems;
  }
}

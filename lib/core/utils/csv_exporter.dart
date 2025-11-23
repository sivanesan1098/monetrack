import 'dart:io';
import 'package:csv/csv.dart';
import 'package:monetrack/domain/entities/transaction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvExporter {
  static Future<void> exportTransactions(List<TransactionEntity> transactions) async {
    final List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'ID',
      'Date',
      'Type',
      'Amount',
      'Currency',
      'Payee',
      'Category',
      'Notes',
      'Source'
    ]);

    // Data
    for (var t in transactions) {
      rows.add([
        t.id,
        t.date.toIso8601String(),
        t.type,
        t.amount,
        t.currency,
        t.payee,
        t.categoryId ?? '',
        t.notes ?? '',
        t.source
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/monetrack_export_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(path)], text: 'Monetrack Transaction Export');
  }
}

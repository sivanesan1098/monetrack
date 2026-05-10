import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetrack/domain/entities/transaction.dart';
import 'package:monetrack/presentation/providers/repository_providers.dart';
import 'package:monetrack/presentation/providers/transaction_list_controller.dart';
import 'package:monetrack/presentation/providers/reports_controller.dart';
import 'package:intl/intl.dart';

class SmsImportScreen extends ConsumerStatefulWidget {
  const SmsImportScreen({super.key});

  @override
  ConsumerState<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends ConsumerState<SmsImportScreen> {
  bool _isLoading = false;
  List<TransactionEntity> _foundTransactions = [];
  final Set<String> _selectedIds = {};
  String _activeFilter = 'Last Month'; // Default

  @override
  void initState() {
    super.initState();
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTransactions();
    });
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _foundTransactions = [];
      _selectedIds.clear();
    });

    try {
      final smsService = ref.read(smsServiceProvider);
      
      DateTime now = DateTime.now();
      DateTime? start;
      
      switch (_activeFilter) {
        case 'Last Week':
          start = now.subtract(const Duration(days: 7));
          break;
        case 'Last Month':
          start = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'Last 3 Months':
          start = DateTime(now.year, now.month - 3, now.day);
          break;
      }

      final transactions = await smsService.fetchAndParseSms(start: start);
      
      setState(() {
        _foundTransactions = transactions;
        // Select all by default
        _selectedIds.addAll(transactions.map((t) => t.id));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _importSelected() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(transactionRepositoryProvider);
      int count = 0;
      
      final toImport = _foundTransactions.where((t) => _selectedIds.contains(t.id));
      
      for (final t in toImport) {
        final result = await repo.addTransaction(t);
        if (result.isRight()) count++;
      }

      ref.invalidate(transactionListControllerProvider);
      ref.invalidate(reportsControllerProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count transactions')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Transactions'),
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: ['Last Week', 'Last Month', 'Last 3 Months'].map((filter) {
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _activeFilter = filter);
                        _fetchTransactions();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _foundTransactions.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                        itemCount: _foundTransactions.length,
                        itemBuilder: (context, index) {
                          final t = _foundTransactions[index];
                          final isSelected = _selectedIds.contains(t.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIds.add(t.id);
                                } else {
                                  _selectedIds.remove(t.id);
                                }
                              });
                            },
                            title: Text(
                              '${t.type == 'spent' ? '-' : '+'} ${t.currency} ${t.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: t.type == 'spent' ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.payee),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(t.date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  t.notes ?? '',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            secondary: Icon(
                              t.type == 'spent' ? Icons.arrow_upward : Icons.arrow_downward,
                              color: t.type == 'spent' ? Colors.red : Colors.green,
                            ),
                          );
                        },
                      ),
          ),
          
          // Action Button
          if (!_isLoading && _foundTransactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedIds.isEmpty ? null : _importSelected,
                  child: Text('Import Selected (${_selectedIds.length})'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monetrack/domain/entities/category_report_item.dart';
import 'package:monetrack/presentation/providers/reports_controller.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(reportsControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: transactionsAsync.when(
          data: (transactions) {
            return TabBarView(
              children: [
                _ReportTab(transactions: transactions, type: 'spent'),
                _ReportTab(transactions: transactions, type: 'received'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _ReportTab extends ConsumerStatefulWidget {
  final List<dynamic> transactions;
  final String type;

  const _ReportTab({required this.transactions, required this.type});

  @override
  ConsumerState<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends ConsumerState<_ReportTab> {
  List<CategoryReportItem>? _reportItems;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void didUpdateWidget(covariant _ReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions || oldWidget.type != widget.type) {
      _loadReport();
    }
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final controller = ref.read(reportsControllerProvider.notifier);
    final items = await controller.getCategoryReport(widget.transactions.cast(), widget.type);
    if (mounted) {
      setState(() {
        _reportItems = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reportItems == null || _reportItems!.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final List<PieChartSectionData> sections = _reportItems!.map((item) {
      return PieChartSectionData(
        color: item.color,
        value: item.amount,
        title: '${item.amount.toStringAsFixed(0)}',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _reportItems!.length,
            itemBuilder: (context, index) {
              final item = _reportItems![index];
              return ListTile(
                leading: CircleAvatar(backgroundColor: item.color, radius: 10),
                title: Text(item.categoryName),
                trailing: Text('₹ ${item.amount.toStringAsFixed(2)}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:monetrack/presentation/providers/add_edit_transaction_controller.dart';
import 'package:monetrack/presentation/providers/category_list_controller.dart';
import 'package:monetrack/domain/entities/category.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final String? id;
  const AddEditTransactionScreen({super.key, this.id});

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _type = 'spent';
  String? _selectedCategoryId;
  DateTime _date = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loadTransaction();
    }
  }
  
  Future<void> _loadTransaction() async {
    setState(() => _isLoading = true);
    final transaction = await ref.read(addEditTransactionControllerProvider.notifier).getTransaction(widget.id!);
    if (transaction != null) {
      _amountController.text = transaction.amount.toString();
      _payeeController.text = transaction.payee;
      _notesController.text = transaction.notes ?? '';
      setState(() {
        _type = transaction.type;
        _date = transaction.date;
        _selectedCategoryId = transaction.categoryId;
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final payee = _payeeController.text;
    final notes = _notesController.text.isEmpty ? null : _notesController.text;

    try {
      if (widget.id == null) {
        await ref.read(addEditTransactionControllerProvider.notifier).addTransaction(
          amount: amount,
          type: _type,
          payee: payee,
          date: _date,
          categoryId: _selectedCategoryId,
          notes: notes,
        );
      } else {
        await ref.read(addEditTransactionControllerProvider.notifier).updateTransaction(
          id: widget.id!,
          amount: amount,
          type: _type,
          payee: payee,
          date: _date,
          categoryId: _selectedCategoryId,
          notes: notes,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addEditTransactionControllerProvider);
    final isSaving = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Add Transaction' : 'Edit Transaction'),
        actions: [
          if (isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.check))
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Type Toggle
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'spent', label: Text('Expense'), icon: Icon(Icons.arrow_downward)),
                        ButtonSegment(value: 'received', label: Text('Income'), icon: Icon(Icons.arrow_upward)),
                      ],
                      selected: {_type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _type = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter amount';
                        if (double.tryParse(value) == null) return 'Invalid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Payee
                    TextFormField(
                      controller: _payeeController,
                      decoration: const InputDecoration(
                        labelText: 'Payee / Payer',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter payee';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Consumer(
                      builder: (context, ref, child) {
                        final categoriesAsync = ref.watch(categoryListControllerProvider);
                        return categoriesAsync.when(
                          data: (categories) {
                            return DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: categories.map((Category cat) {
                                return DropdownMenuItem<String>(
                                  value: cat.id,
                                  child: Row(
                                    children: [
                                      Icon(IconData(0xe5f9, fontFamily: 'MaterialIcons'), color: Color(cat.color)), // Placeholder icon logic
                                      const SizedBox(width: 8),
                                      Text(cat.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Failed to load categories'),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(DateFormat.yMMMd().format(_date)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _date = picked);
                        }
                      },
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

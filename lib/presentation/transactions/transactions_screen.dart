import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/drawer_helper.dart';
import '../../core/routing.dart';
import '../../core/providers.dart';
import '../../data/api/project_api.dart';
import '../../data/api/transaction_api.dart';
import '../../data/models/pagination.dart';
import '../../data/models/project.dart';
import '../../data/models/transaction.dart';

final transactionsProvider = FutureProvider<Paginated<Transaction>>((ref) async {
  final api = TransactionApi.create();
  return api.listTransactions();
});

final projectsListProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects(pageSize: 100);
});

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTransactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final navigate = ref.read(tabNavigationProvider);
            if (navigate != null) {
              navigate(RootTab.dashboard);
            }
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => DrawerHelper.openDrawer(context),
            ),
          ),
        ],
      ),
      body: asyncTransactions.when(
        data: (paged) {
          if (paged.items.isEmpty) {
            return const Center(child: Text('No transactions yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final transaction = paged.items[index];
              return ListTile(
                title: Text(
                  transaction.type == 'credit' ? 'Credit' : 'Debit',
                  style: TextStyle(
                    color: transaction.type == 'credit' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: ₹${transaction.amount.toStringAsFixed(2)}'),
                    Text('Category: ${transaction.category}'),
                    Text('Payment: ${transaction.paymentMethod}'),
                    Text('Date: ${DateFormat('MMM dd, yyyy').format(transaction.date)}'),
                    if (transaction.notes != null && transaction.notes!.isNotEmpty)
                      Text('Notes: ${transaction.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.type == 'credit' ? '+₹${transaction.amount.toStringAsFixed(0)}' : '-₹${transaction.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: transaction.type == 'credit' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () async {
                        final updated = await showModalBottomSheet<Transaction>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => _TransactionFormSheet(transaction: transaction),
                        );
                        if (updated != null) {
                          ref.invalidate(transactionsProvider);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Transaction'),
                            content: Text('Are you sure you want to delete this ${transaction.type} transaction of ₹${transaction.amount.toStringAsFixed(2)}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            final api = TransactionApi.create();
                            await api.deleteTransaction(transaction.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaction deleted successfully')),
                              );
                              ref.invalidate(transactionsProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete transaction: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
                isThreeLine: transaction.notes != null && transaction.notes!.isNotEmpty,
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: paged.items.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Failed to load transactions: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<Transaction>(
            context: context,
            isScrollControlled: true,
            builder: (context) => const _TransactionFormSheet(),
          );
          if (created != null) {
            ref.invalidate(transactionsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }
}

class _TransactionFormSheet extends ConsumerStatefulWidget {
  const _TransactionFormSheet({this.transaction});

  final Transaction? transaction;

  @override
  ConsumerState<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<_TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _selectedProjectId;
  String _type = 'debit';
  String _category = 'misc';
  String _paymentMethod = 'cash';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes ?? '';
      _selectedProjectId = widget.transaction!.projectId;
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
      _paymentMethod = widget.transaction!.paymentMethod;
      _date = widget.transaction!.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final api = TransactionApi.create();
      final transaction = Transaction(
        id: widget.transaction?.id ?? '',
        projectId: _selectedProjectId!,
        amount: double.parse(_amountController.text.trim()),
        type: _type,
        category: _category,
        paymentMethod: _paymentMethod,
        date: _date,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      final result = widget.transaction != null
          ? await api.updateTransaction(widget.transaction!.id, transaction)
          : await api.createTransaction(transaction);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final projectsAsync = ref.watch(projectsListProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              projectsAsync.when(
                data: (projects) => DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: const InputDecoration(labelText: 'Project *'),
                  items: projects.items.map((project) {
                    return DropdownMenuItem(
                      value: project.id,
                      child: Text(project.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a project';
                    }
                    return null;
                  },
                ),
                loading: () => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Project *', hintText: 'Loading...'),
                  items: const [],
                  onChanged: (_) {},
                ),
                error: (_, __) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Project *', hintText: 'Error loading projects'),
                  items: const [],
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'credit', child: Text('Credit')),
                  DropdownMenuItem(value: 'debit', child: Text('Debit')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Type *'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹) *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'material', child: Text('Material')),
                  DropdownMenuItem(value: 'labor', child: Text('Labor')),
                  DropdownMenuItem(value: 'transport', child: Text('Transport')),
                  DropdownMenuItem(value: 'misc', child: Text('Misc')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Category *'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentMethod = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Payment Method *'),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_date),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.transaction != null ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

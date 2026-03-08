import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/drawer_helper.dart';
import '../../core/routing.dart';
import '../../core/providers.dart';
import '../../data/api/project_api.dart';
import '../../data/api/quotation_api.dart';
import '../../data/models/pagination.dart';
import '../../data/models/project.dart';
import '../../data/models/quotation.dart';

final quotationsProvider = FutureProvider<Paginated<Quotation>>((ref) async {
  final api = QuotationApi.create();
  return api.listQuotations();
});

final projectsListProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects(pageSize: 100);
});

class QuotationsScreen extends ConsumerWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuotations = ref.watch(quotationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotations & Reminders'),
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
      body: asyncQuotations.when(
        data: (paged) {
          if (paged.items.isEmpty) {
            return const Center(child: Text('No quotations yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final quotation = paged.items[index];
              return ListTile(
                title: Text(quotation.vendorName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: ₹${quotation.expectedAmount.toStringAsFixed(2)}'),
                    Text('Reminder: ${DateFormat('MMM dd, yyyy').format(quotation.reminderDate)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(quotation.status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        quotation.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () async {
                        final updated = await showModalBottomSheet<Quotation>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => _QuotationFormSheet(quotation: quotation),
                        );
                        if (updated != null) {
                          ref.invalidate(quotationsProvider);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Quotation'),
                            content: Text('Are you sure you want to delete quotation for ${quotation.vendorName}?'),
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
                            final api = QuotationApi.create();
                            await api.deleteQuotation(quotation.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Quotation deleted successfully')),
                              );
                              ref.invalidate(quotationsProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete quotation: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
                isThreeLine: false,
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: paged.items.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Failed to load quotations: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<Quotation>(
            context: context,
            isScrollControlled: true,
            builder: (context) => const _QuotationFormSheet(),
          );
          if (created != null) {
            ref.invalidate(quotationsProvider);
          }
        },
        icon: const Icon(Icons.add_alert),
        label: const Text('Add Quotation'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _QuotationFormSheet extends ConsumerStatefulWidget {
  const _QuotationFormSheet({this.quotation});

  final Quotation? quotation;

  @override
  ConsumerState<_QuotationFormSheet> createState() => _QuotationFormSheetState();
}

class _QuotationFormSheetState extends ConsumerState<_QuotationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _vendorNameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _submitting = false;
  String? _selectedProjectId;
  DateTime _reminderDate = DateTime.now().add(const Duration(days: 7));
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    if (widget.quotation != null) {
      _vendorNameController.text = widget.quotation!.vendorName;
      _amountController.text = widget.quotation!.expectedAmount.toString();
      _selectedProjectId = widget.quotation!.projectId;
      _reminderDate = widget.quotation!.reminderDate;
      _status = widget.quotation!.status;
    }
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _reminderDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final api = QuotationApi.create();
      final quotation = Quotation(
        id: widget.quotation?.id ?? '',
        projectId: _selectedProjectId,
        vendorName: _vendorNameController.text.trim(),
        expectedAmount: double.parse(_amountController.text.trim()),
        reminderDate: _reminderDate,
        status: _status,
      );
      final result = widget.quotation != null
          ? await api.updateQuotation(widget.quotation!.id, quotation)
          : await api.createQuotation(quotation);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create quotation: $e')),
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
                widget.quotation != null ? 'Edit Quotation' : 'Add Quotation',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _vendorNameController,
                decoration: const InputDecoration(labelText: 'Vendor Name *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vendor name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Expected Amount (₹) *'),
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
              projectsAsync.when(
                data: (projects) => DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: const InputDecoration(labelText: 'Project (Optional)'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...projects.items.map((project) {
                      return DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedProjectId = value;
                    });
                  },
                ),
                loading: () => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Project (Optional)', hintText: 'Loading...'),
                  items: const [],
                  onChanged: (_) {},
                ),
                error: (_, __) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Project (Optional)', hintText: 'Error loading projects'),
                  items: const [],
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectReminderDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Reminder Date *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_reminderDate),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Status *'),
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
                      : Text(widget.quotation != null ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

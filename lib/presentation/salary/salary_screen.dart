import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/drawer_helper.dart';
import '../../core/routing.dart';
import '../../core/providers.dart';
import '../../data/api/salary_api.dart';
import '../../data/api/project_api.dart';
import '../../data/models/salary.dart';
import '../../data/models/pagination.dart';
import '../../data/models/project.dart';
import '../transactions/transactions_screen.dart';

final salaryCalculationProvider = FutureProvider.family<SalaryCalculationResponse, DateTime>((ref, month) async {
  final api = SalaryApi.create();
  return api.calculateSalaries(month: month);
});

final salaryProjectsProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects(pageSize: 100);
});

// Note: We'll invalidate the transactionsProvider from transactions_screen.dart
// by accessing it through the provider system

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final salaryAsync = ref.watch(salaryCalculationProvider(_selectedMonth));
    final projectsAsync = ref.watch(salaryProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => DrawerHelper.openDrawer(context),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Month',
            onPressed: _selectMonth,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(salaryCalculationProvider(_selectedMonth));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Salary for: ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectMonth,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Change Month'),
                ),
              ],
            ),
          ),
          // Salary list
          Expanded(
            child: salaryAsync.when(
              data: (data) {
                if (data.salaries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No employees found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add employees to calculate salaries',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.salaries.length,
                  itemBuilder: (context, index) {
                    final salary = data.salaries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        salary.employeeName,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        salary.wageType == 'daily'
                                            ? 'Daily Wage: ${salary.dailyWage?.toStringAsFixed(0) ?? 0}'
                                            : 'Monthly Salary: ${salary.monthlySalary?.toStringAsFixed(0) ?? 0}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (salary.netSalary > 0)
                                  ElevatedButton.icon(
                                    onPressed: () => _showPaySalaryDialog(
                                      context,
                                      salary,
                                      projectsAsync.valueOrNull?.items ?? [],
                                    ),
                                    icon: const Icon(Icons.payment, size: 18),
                                    label: const Text('Pay'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _SalaryInfoItem(
                                    label: 'Present Days',
                                    value: salary.presentDays.toString(),
                                    icon: Icons.calendar_today,
                                  ),
                                ),
                                Expanded(
                                  child: _SalaryInfoItem(
                                    label: 'Calculated Salary',
                                    value: '₹${salary.calculatedSalary.toStringAsFixed(0)}',
                                    icon: Icons.calculate,
                                  ),
                                ),
                              ],
                            ),
                            if (salary.advanceAmount > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SalaryInfoItem(
                                      label: 'Advance',
                                      value: '₹${salary.advanceAmount.toStringAsFixed(0)}',
                                      icon: Icons.remove_circle_outline,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: salary.netSalary > 0
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Net Salary',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${salary.netSalary.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: salary.netSalary > 0 ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load salary data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(salaryCalculationProvider(_selectedMonth));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPaySalaryDialog(
    BuildContext context,
    SalaryCalculation salary,
    List<Project> projects,
  ) async {
    final amountController = TextEditingController(
      text: salary.netSalary.toStringAsFixed(0),
    );
    String? selectedProjectId;
    String paymentMethod = 'cash';
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pay Salary - ${salary.employeeName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Month: ${DateFormat('MMMM yyyy').format(salary.month)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount to Pay *',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Project (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No Project'),
                    ),
                    ...projects.map((project) {
                      return DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(project.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProjectId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        paymentMethod = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Pay Salary'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text) ?? salary.netSalary;
      await _paySalary(
        salary,
        amount,
        selectedProjectId,
        paymentMethod,
        notesController.text,
      );
    }
  }

  Future<void> _paySalary(
    SalaryCalculation salary,
    double amount,
    String? projectId,
    String paymentMethod,
    String notes,
  ) async {
    try {
      final api = SalaryApi.create();
      await api.paySalary(
        employeeId: salary.employeeId,
        month: salary.month,
        amount: amount,
        projectId: projectId,
        paymentMethod: paymentMethod,
        notes: notes.isEmpty ? null : notes,
      );

      if (mounted) {
        // Refresh salary calculations
        ref.invalidate(salaryCalculationProvider(_selectedMonth));
        // Refresh transactions list so the new salary transaction appears automatically
        ref.invalidate(transactionsProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(
                  child: Text('Salary payment of ₹${amount.toStringAsFixed(0)} recorded successfully. Transaction added automatically.'),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    // Navigate to transactions screen
                    final navigate = ref.read(tabNavigationProvider);
                    if (navigate != null) {
                      navigate(RootTab.transactions);
                    }
                  },
                  child: const Text('View', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pay salary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SalaryInfoItem extends StatelessWidget {
  const _SalaryInfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

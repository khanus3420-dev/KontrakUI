import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/drawer_helper.dart';
import '../../core/routing.dart';
import '../../core/providers.dart';
import '../../data/api/employee_api.dart';
import '../../data/api/project_api.dart';
import '../../data/models/employee.dart';
import '../../data/models/pagination.dart';
import '../../data/models/project.dart';

final employeesProvider = FutureProvider<Paginated<Employee>>((ref) async {
  final api = EmployeeApi.create();
  return api.listEmployees();
});

final projectsListProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects(pageSize: 100);
});

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEmployees = ref.watch(employeesProvider);
    final projectsAsync = ref.watch(projectsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
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
      body: asyncEmployees.when(
        data: (paged) {
          if (paged.items.isEmpty) {
            return const Center(child: Text('No employees yet.'));
          }
          return projectsAsync.when(
            data: (projects) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final employee = paged.items[index];
                  Project? project;
                  if (employee.projectId != null) {
                    try {
                      project = projects.items.firstWhere((p) => p.id == employee.projectId);
                    } catch (_) {
                      project = null;
                    }
                  }
                  return ListTile(
                    title: Text(employee.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project != null) Text('Project: ${project.name}'),
                        Text(employee.phoneNumber ?? 'Wage Type: ${employee.wageType}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          employee.wageType == 'daily'
                              ? '₹${employee.dailyWage?.toStringAsFixed(0) ?? 'N/A'}/day'
                              : '₹${employee.monthlySalary?.toStringAsFixed(0) ?? 'N/A'}/month',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () async {
                            final updated = await showModalBottomSheet<Employee>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => _EmployeeFormSheet(employee: employee),
                            );
                            if (updated != null) {
                              ref.invalidate(employeesProvider);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Employee'),
                                content: Text('Are you sure you want to delete ${employee.name}?'),
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
                                final api = EmployeeApi.create();
                                await api.deleteEmployee(employee.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Employee deleted successfully')),
                                  );
                                  ref.invalidate(employeesProvider);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete employee: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: paged.items.length,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Failed to load projects')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Failed to load employees: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<Employee>(
            context: context,
            isScrollControlled: true,
            builder: (context) => const _EmployeeFormSheet(),
          );
          if (created != null) {
            ref.invalidate(employeesProvider);
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
    );
  }
}

class _EmployeeFormSheet extends ConsumerStatefulWidget {
  const _EmployeeFormSheet({this.employee});

  final Employee? employee;

  @override
  ConsumerState<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends ConsumerState<_EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadharController = TextEditingController();
  final _dailyWageController = TextEditingController();
  final _monthlySalaryController = TextEditingController();
  final _advanceController = TextEditingController();
  bool _submitting = false;
  String _wageType = 'daily';
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      _nameController.text = widget.employee!.name;
      _phoneController.text = widget.employee!.phoneNumber ?? '';
      _aadharController.text = widget.employee!.aadharNumber ?? '';
      _wageType = widget.employee!.wageType;
      _dailyWageController.text = widget.employee!.dailyWage?.toString() ?? '';
      _monthlySalaryController.text = widget.employee!.monthlySalary?.toString() ?? '';
      _advanceController.text = widget.employee!.advanceAmount.toString();
      _selectedProjectId = widget.employee!.projectId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aadharController.dispose();
    _dailyWageController.dispose();
    _monthlySalaryController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Project is optional - employees can work on multiple projects
    // Attendance will require project selection when marking
    setState(() {
      _submitting = true;
    });
    try {
      final api = EmployeeApi.create();
      final employee = Employee(
        id: widget.employee?.id ?? '',
        name: _nameController.text.trim(),
        wageType: _wageType,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        aadharNumber: _aadharController.text.trim().isEmpty
            ? null
            : _aadharController.text.trim(),
        dailyWage: _wageType == 'daily' && _dailyWageController.text.trim().isNotEmpty
            ? double.tryParse(_dailyWageController.text.trim())
            : null,
        monthlySalary: _wageType == 'monthly' && _monthlySalaryController.text.trim().isNotEmpty
            ? double.tryParse(_monthlySalaryController.text.trim())
            : null,
        advanceAmount: _advanceController.text.trim().isEmpty
            ? 0
            : (double.tryParse(_advanceController.text.trim()) ?? 0),
        projectId: _selectedProjectId,
      );
      final result = widget.employee != null
          ? await api.updateEmployee(widget.employee!.id, employee)
          : await api.createEmployee(employee);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save employee: $e')),
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
      padding: EdgeInsets.only(
        bottom: bottomInset,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.employee != null ? 'Edit Employee' : 'Add Employee',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              projectsAsync.when(
                data: (projects) => DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: 'Primary Project (Optional)',
                    helperText: 'Employee can work on multiple projects',
                  ),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Employee Name *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Employee name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _aadharController,
                decoration: const InputDecoration(labelText: 'Aadhar Number'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _wageType,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily Wage')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly Salary')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _wageType = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Wage Type *'),
              ),
              const SizedBox(height: 8),
              if (_wageType == 'daily')
                TextFormField(
                  controller: _dailyWageController,
                  decoration: const InputDecoration(labelText: 'Daily Wage (₹)'),
                  keyboardType: TextInputType.number,
                )
              else
                TextFormField(
                  controller: _monthlySalaryController,
                  decoration: const InputDecoration(labelText: 'Monthly Salary (₹)'),
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _advanceController,
                decoration: const InputDecoration(labelText: 'Advance Amount (₹)'),
                keyboardType: TextInputType.number,
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
                      : Text(widget.employee != null ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/api/attendance_api.dart';
import '../../data/api/employee_api.dart';
import '../../data/api/project_api.dart';
import '../../data/models/attendance.dart';
import '../../data/models/employee.dart';
import '../../data/models/pagination.dart';
import '../../data/models/project.dart';

final attendanceProvider = FutureProvider.family<Paginated<Attendance>, DateTime>((ref, date) async {
  final api = AttendanceApi.create();
  final startOfMonth = DateTime(date.year, date.month, 1);
  final endOfMonth = DateTime(date.year, date.month + 1, 0);
  return api.listAttendance(
    dateFrom: startOfMonth,
    dateTo: endOfMonth,
    pageSize: 100,
  );
});

final employeesListProvider = FutureProvider<Paginated<Employee>>((ref) async {
  final api = EmployeeApi.create();
  return api.listEmployees(pageSize: 100);
});

final projectsListProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects(pageSize: 100);
});

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _filterProjectId; // For filtering the list view

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesListProvider);
    final projectsAsync = ref.watch(projectsListProvider);
    final attendanceAsync = ref.watch(attendanceProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Month',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          TextButton.icon(
            onPressed: () {
              employeesAsync.whenData((employees) {
                if (employees.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No employees available')),
                  );
                  return;
                }
                _showQuickMarkAttendanceDialog(context, employees.items);
              });
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text('Mark', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                projectsAsync.when(
                  data: (projects) => DropdownButton<String>(
                    value: _filterProjectId,
                    hint: const Text('All Projects'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Projects'),
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
                        _filterProjectId = value;
                      });
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: employeesAsync.when(
              data: (employees) {
                // Filter employees by project if selected (for list view only)
                // Note: Employees can work on multiple projects, so we show all employees
                // but filter the list view if a project is selected
                final filteredEmployees = _filterProjectId != null
                    ? employees.items.where((e) => e.projectId == _filterProjectId).toList()
                    : employees.items;

                if (filteredEmployees.isEmpty) {
                  return const Center(child: Text('No employees found'));
                }

                return attendanceAsync.when(
                  data: (attendance) {
                    // Create a map of attendance by employee_id and date
                    final attendanceMap = <String, Map<String, Attendance>>{};
                    for (final att in attendance.items) {
                      final dateKey = DateFormat('yyyy-MM-dd').format(att.date);
                      attendanceMap.putIfAbsent(att.employeeId, () => <String, Attendance>{});
                      attendanceMap[att.employeeId]![dateKey] = att;
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = filteredEmployees[index];
                        final empAttendance = attendanceMap[employee.id] ?? {};
                        
                        // Count present days in the month
                        final presentDays = empAttendance.values
                            .where((a) => a.status == 'present')
                            .length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(employee.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Primary Project: ${employee.projectId != null ? _getProjectName(projectsAsync, employee.projectId!) : "Not assigned"}'),
                                Text('Wage Type: ${employee.wageType == 'daily' ? 'Daily' : 'Monthly'}'),
                                Text('Present Days (this month): $presentDays'),
                                if (empAttendance.isNotEmpty)
                                  Text(
                                    'Projects worked: ${empAttendance.values.map((a) => _getProjectName(projectsAsync, a.projectId)).toSet().join(", ")}',
                                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    // Show project selection first
                                    final projectsAsync = ref.read(projectsListProvider);
                                    await projectsAsync.whenData((projects) async {
                                      if (projects.items.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('No projects available')),
                                        );
                                        return;
                                      }

                                      // If employee has a primary project, use it; otherwise show selection
                                      Project? selectedProject;
                                      if (employee.projectId != null) {
                                        try {
                                          selectedProject = projects.items.firstWhere(
                                            (p) => p.id == employee.projectId,
                                          );
                                        } catch (_) {
                                          // Project not found, show selection
                                        }
                                      }

                                      if (selectedProject == null) {
                                        selectedProject = await showDialog<Project>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Select Project'),
                                            content: SizedBox(
                                              width: double.maxFinite,
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                itemCount: projects.items.length,
                                                itemBuilder: (context, index) {
                                                  final project = projects.items[index];
                                                  return ListTile(
                                                    title: Text(project.name),
                                                    onTap: () => Navigator.of(context).pop(project),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      if (selectedProject != null) {
                                        _showMarkAttendanceDialog(
                                          context,
                                          employee,
                                          selectedProject,
                                          _selectedDate,
                                        );
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Failed to load attendance: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load employees: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          employeesAsync.whenData((employees) {
            if (employees.items.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No employees available')),
              );
              return;
            }

            // Show project selection first, then employee selection
            _showQuickMarkAttendanceDialog(context, employees.items);
          });
        },
        icon: const Icon(Icons.check_circle),
        label: const Text('Mark Attendance'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _getProjectName(AsyncValue<Paginated<Project>> projectsAsync, String projectId) {
    return projectsAsync.maybeWhen(
      data: (projects) {
        try {
          return projects.items.firstWhere((p) => p.id == projectId).name;
        } catch (_) {
          return 'Unknown';
        }
      },
      orElse: () => 'Unknown',
    );
  }

  void _showQuickMarkAttendanceDialog(
    BuildContext context,
    List<Employee> employees,
  ) async {
    final projectsAsync = ref.read(projectsListProvider);
    await projectsAsync.whenData((projects) async {
      if (projects.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No projects available. Please create a project first.')),
        );
        return;
      }

      // First select project
      final selectedProject = await showDialog<Project>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Project'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: projects.items.length,
              itemBuilder: (context, index) {
                final project = projects.items[index];
                return ListTile(
                  title: Text(project.name),
                  onTap: () => Navigator.of(context).pop(project),
                );
              },
            ),
          ),
        ),
      );

      if (selectedProject == null) return;

      // Then select employee
      final selectedEmployee = await showDialog<Employee>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Employee'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return ListTile(
                  title: Text(employee.name),
                  subtitle: Text(employee.phoneNumber ?? ''),
                  onTap: () => Navigator.of(context).pop(employee),
                );
              },
            ),
          ),
        ),
      );

      if (selectedEmployee == null) return;

      // Now show attendance dialog
      _showMarkAttendanceDialog(
        context,
        selectedEmployee,
        selectedProject,
        _selectedDate,
      );
    });
  }

  void _showMarkAttendanceDialog(
    BuildContext context,
    Employee employee,
    Project project,
    DateTime selectedDate,
  ) async {
    final result = await showDialog<Attendance>(
      context: context,
      builder: (context) => _MarkAttendanceDialog(
        employee: employee,
        project: project,
        selectedDate: selectedDate,
      ),
    );
    if (result != null) {
      ref.invalidate(attendanceProvider(_selectedDate));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance marked successfully')),
        );
      }
    }
  }
}

class _MarkAttendanceDialog extends ConsumerStatefulWidget {
  const _MarkAttendanceDialog({
    required this.employee,
    required this.project,
    required this.selectedDate,
  });

  final Employee employee;
  final Project project;
  final DateTime selectedDate;

  @override
  ConsumerState<_MarkAttendanceDialog> createState() => _MarkAttendanceDialogState();
}

class _MarkAttendanceDialogState extends ConsumerState<_MarkAttendanceDialog> {
  DateTime _selectedDate = DateTime.now();
  String _status = 'present';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
    });
    try {
      final api = AttendanceApi.create();
      final attendance = Attendance(
        id: '',
        employeeId: widget.employee.id,
        projectId: widget.project.id, // Required - use selected project
        date: _selectedDate,
        status: _status,
      );
      final created = await api.markAttendance(attendance);
      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark attendance: $e')),
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
    return AlertDialog(
      title: Text('Mark Attendance - ${widget.employee.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project: ${widget.project.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'present', child: Text('Present')),
                DropdownMenuItem(value: 'absent', child: Text('Absent')),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mark'),
        ),
      ],
    );
  }
}

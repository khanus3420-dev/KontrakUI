import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/drawer_helper.dart';
import '../../core/routing.dart';
import '../../core/providers.dart';
import '../../data/api/project_api.dart';
import '../../data/models/project.dart';
import '../../data/models/pagination.dart';

final projectsProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects();
});

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProjects = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
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
      body: asyncProjects.when(
        data: (paged) {
          if (paged.items.isEmpty) {
            return const Center(child: Text('No projects yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final project = paged.items[index];
              return ListTile(
                title: Text(project.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (project.clientName != null) Text(project.clientName!),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (project.startDate != null)
                          Text(
                            'Start: ${DateFormat('MMM dd, yyyy').format(project.startDate!)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (project.startDate != null && project.dueDate != null)
                          const Text(' • ', style: TextStyle(fontSize: 12)),
                        if (project.dueDate != null)
                          Text(
                            'Due: ${DateFormat('MMM dd, yyyy').format(project.dueDate!)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(project.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () async {
                        final updated = await showModalBottomSheet<Project>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => _ProjectFormSheet(project: project),
                        );
                        if (updated != null) {
                          ref.invalidate(projectsProvider);
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
        error: (error, stackTrace) => Center(
          child: Text('Failed to load projects: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<Project>(
            context: context,
            isScrollControlled: true,
            builder: (context) => const _ProjectFormSheet(),
          );
          if (created != null) {
            ref.invalidate(projectsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Project'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ongoing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'on_hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _ProjectFormSheet extends StatefulWidget {
  const _ProjectFormSheet({this.project});

  final Project? project;

  @override
  State<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<_ProjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _submitting = false;
  String _status = 'ongoing';
  DateTime? _startDate;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _nameController.text = widget.project!.name;
      _clientController.text = widget.project!.clientName ?? '';
      _locationController.text = widget.project!.location ?? '';
      _budgetController.text = widget.project!.estimatedBudget?.toString() ?? '';
      _status = widget.project!.status;
      _startDate = widget.project!.startDate;
      _dueDate = widget.project!.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // If due date is before start date, clear it
        if (_dueDate != null && _dueDate!.isBefore(picked)) {
          _dueDate = null;
        }
      });
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
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
      final api = ProjectApi.create();
      final project = Project(
        id: widget.project?.id ?? '',
        name: _nameController.text.trim(),
        status: _status,
        clientName: _clientController.text.trim().isEmpty
            ? null
            : _clientController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        estimatedBudget: _budgetController.text.trim().isEmpty
            ? null
            : double.tryParse(_budgetController.text.trim()),
        startDate: _startDate,
        dueDate: _dueDate,
      );
      
      final result = widget.project != null
          ? await api.updateProject(widget.project!.id, project)
          : await api.createProject(project);
      
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save project: $e')),
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
                widget.project != null ? 'Edit Project' : 'Add Project',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(labelText: 'Client Name'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                decoration:
                    const InputDecoration(labelText: 'Estimated Budget (base currency)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                        : 'Select start date',
                    style: TextStyle(
                      color: _startDate != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dueDate != null
                        ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                        : 'Select due date',
                    style: TextStyle(
                      color: _dueDate != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Status'),
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
                      : Text(widget.project != null ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



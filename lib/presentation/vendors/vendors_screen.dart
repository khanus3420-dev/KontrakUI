import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/drawer_helper.dart';
import '../../core/routing.dart';
import '../../core/providers.dart';
import '../../data/api/vendor_api.dart';
import '../../data/api/project_api.dart';
import '../../data/models/vendor.dart';
import '../../data/models/pagination.dart';
import '../../data/models/project.dart';

final vendorsProvider = FutureProvider<Paginated<Vendor>>((ref) async {
  final api = VendorApi.create();
  return api.listVendors();
});

final projectsListProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects(pageSize: 100);
});

class VendorsScreen extends ConsumerWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVendors = ref.watch(vendorsProvider);
    final projectsAsync = ref.watch(projectsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors & Suppliers'),
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
      body: asyncVendors.when(
        data: (paged) {
          if (paged.items.isEmpty) {
            return const Center(child: Text('No vendors yet.'));
          }
          return projectsAsync.when(
            data: (projects) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final vendor = paged.items[index];
                  Project? project;
                  if (vendor.projectId != null) {
                    try {
                      project = projects.items.firstWhere((p) => p.id == vendor.projectId);
                    } catch (_) {
                      project = null;
                    }
                  }
                  return ListTile(
                    title: Text(vendor.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (project != null) Text('Project: ${project.name}'),
                        Text(vendor.materialType ?? vendor.contactNumber ?? 'No details'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (vendor.contactNumber != null) Text(vendor.contactNumber!),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () async {
                            final updated = await showModalBottomSheet<Vendor>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => _VendorFormSheet(vendor: vendor),
                            );
                            if (updated != null) {
                              ref.invalidate(vendorsProvider);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Vendor'),
                                content: Text('Are you sure you want to delete ${vendor.name}?'),
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
                                final api = VendorApi.create();
                                await api.deleteVendor(vendor.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vendor deleted successfully')),
                                  );
                                  ref.invalidate(vendorsProvider);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete vendor: $e')),
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
          child: Text('Failed to load vendors: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<Vendor>(
            context: context,
            isScrollControlled: true,
            builder: (context) => const _VendorFormSheet(),
          );
          if (created != null) {
            ref.invalidate(vendorsProvider);
          }
        },
        icon: const Icon(Icons.add_business),
        label: const Text('Add Vendor'),
      ),
    );
  }
}

class _VendorFormSheet extends ConsumerStatefulWidget {
  const _VendorFormSheet({this.vendor});

  final Vendor? vendor;

  @override
  ConsumerState<_VendorFormSheet> createState() => _VendorFormSheetState();
}

class _VendorFormSheetState extends ConsumerState<_VendorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _materialController = TextEditingController();
  bool _submitting = false;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    if (widget.vendor != null) {
      _nameController.text = widget.vendor!.name;
      _contactController.text = widget.vendor!.contactNumber ?? '';
      _materialController.text = widget.vendor!.materialType ?? '';
      _selectedProjectId = widget.vendor!.projectId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    try {
      final api = VendorApi.create();
      final vendor = Vendor(
        id: widget.vendor?.id ?? '',
        name: _nameController.text.trim(),
        contactNumber: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        materialType: _materialController.text.trim().isEmpty
            ? null
            : _materialController.text.trim(),
        projectId: _selectedProjectId,
      );
      final result = widget.vendor != null
          ? await api.updateVendor(widget.vendor!.id, vendor)
          : await api.createVendor(vendor);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save vendor: $e')),
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
                widget.vendor != null ? 'Edit Vendor' : 'Add Vendor',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Vendor Name *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vendor name is required';
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
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _materialController,
                decoration: const InputDecoration(labelText: 'Material Type'),
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
                      : Text(widget.vendor != null ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/api/organization_api.dart';
import '../../data/models/organization.dart';

class CustomerEditScreen extends ConsumerStatefulWidget {
  final Organization organization;

  const CustomerEditScreen({
    super.key,
    required this.organization,
  });

  @override
  ConsumerState<CustomerEditScreen> createState() => _CustomerEditScreenState();
}

class _CustomerEditScreenState extends ConsumerState<CustomerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _gstController = TextEditingController();
  final _panController = TextEditingController();
  final _registrationController = TextEditingController();
  
  DateTime? _subscriptionStartDate;
  DateTime? _subscriptionEndDate;
  bool? _isActive;
  
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizationData();
  }

  void _loadOrganizationData() {
    final org = widget.organization;
    
    _orgNameController.text = org.name;
    _contactPersonController.text = org.contactPerson ?? '';
    _contactEmailController.text = org.contactEmail ?? '';
    _contactPhoneController.text = org.contactPhone ?? '';
    _addressLine1Controller.text = org.addressLine1 ?? '';
    _addressLine2Controller.text = org.addressLine2 ?? '';
    _cityController.text = org.city ?? '';
    _stateController.text = org.state ?? '';
    _postalCodeController.text = org.postalCode ?? '';
    _countryController.text = org.country ?? 'India';
    _gstController.text = org.gstNumber ?? '';
    _panController.text = org.panNumber ?? '';
    _registrationController.text = org.registrationNumber ?? '';
    
    _subscriptionStartDate = org.subscriptionStartDate;
    _subscriptionEndDate = org.subscriptionEndDate;
    _isActive = org.isActive;
    
    setState(() {
      _isLoadingData = false;
    });
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_subscriptionStartDate ?? DateTime.now())
          : (_subscriptionEndDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _subscriptionStartDate = picked;
        } else {
          _subscriptionEndDate = picked;
        }
      });
    }
  }

  Future<void> _updateOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate subscription dates
    if (_subscriptionStartDate != null && _subscriptionEndDate != null) {
      if (_subscriptionStartDate!.isAfter(_subscriptionEndDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription end date must be after start date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final orgApi = OrganizationApi.create();
      final orgUpdate = OrganizationUpdate(
        name: _orgNameController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty
            ? null
            : _contactPersonController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty
            ? null
            : _contactPhoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim().isEmpty
            ? null
            : _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isEmpty
            ? null
            : _addressLine2Controller.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty
            ? null
            : _postalCodeController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? 'India'
            : _countryController.text.trim(),
        subscriptionStartDate: _subscriptionStartDate,
        subscriptionEndDate: _subscriptionEndDate,
        isActive: _isActive,
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        panNumber: _panController.text.trim().isEmpty ? null : _panController.text.trim(),
        registrationNumber: _registrationController.text.trim().isEmpty
            ? null
            : _registrationController.text.trim(),
      );

      await orgApi.updateOrganization(widget.organization.id, orgUpdate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Customer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _orgNameController,
                        decoration: const InputDecoration(
                          labelText: 'Organization Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Organization name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactPersonController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Contact person is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Invalid email format';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Contact phone is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Phone number must be at least 10 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressLine1Controller,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 1 *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address line 1 is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressLine2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 2',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'City is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'State *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'State is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Subscription Start Date',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  errorText: _subscriptionStartDate == null &&
                                          _subscriptionEndDate != null
                                      ? 'Start date is required'
                                      : null,
                                ),
                                child: Text(
                                  _subscriptionStartDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_subscriptionStartDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _subscriptionStartDate == null
                                        ? Colors.grey[600]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Subscription End Date',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  errorText: _subscriptionEndDate == null &&
                                          _subscriptionStartDate != null
                                      ? 'End date is required'
                                      : null,
                                ),
                                child: Text(
                                  _subscriptionEndDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_subscriptionEndDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    color: _subscriptionEndDate == null
                                        ? Colors.grey[600]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_subscriptionStartDate != null &&
                          _subscriptionEndDate != null &&
                          _subscriptionStartDate!.isAfter(_subscriptionEndDate!))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'End date must be after start date',
                            style: TextStyle(color: Colors.red[700], fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gstController,
                        decoration: const InputDecoration(
                          labelText: 'GST Number *',
                          border: OutlineInputBorder(),
                          helperText: '15-character GST number',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'GST number is required';
                          }
                          if (value.trim().length != 15) {
                            return 'GST number must be 15 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _panController,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _registrationController,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: const Text('Enable or disable this customer'),
                        value: _isActive ?? true,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateOrganization,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

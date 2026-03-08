import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/api/organization_api.dart';
import '../../data/api/user_api.dart';
import '../../data/models/organization.dart';
import '../../data/models/user.dart';

final organizationsProvider = FutureProvider((ref) async {
  final api = OrganizationApi.create();
  return api.listOrganizations(pageSize: 100);
});

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Organization form fields
  final _orgFormKey = GlobalKey<FormState>();
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

  // User form fields
  final _userFormKey = GlobalKey<FormState>();
  final List<UserFormData> _users = [];
  String? _selectedOrganizationId;

  bool _isLoading = false;

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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_subscriptionStartDate ?? DateTime.now())
          : (_subscriptionEndDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime.now(),
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

  void _addUser() {
    setState(() {
      _users.add(UserFormData());
    });
  }

  void _removeUser(int index) {
    setState(() {
      _users.removeAt(index);
    });
  }

  Future<void> _createOrganization() async {
    if (!_orgFormKey.currentState!.validate()) return;

    // Validate subscription dates
    if (_subscriptionStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select subscription start date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_subscriptionEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select subscription end date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_subscriptionStartDate!.isAfter(_subscriptionEndDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription end date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orgApi = OrganizationApi.create();
      final org = OrganizationCreate(
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
        gstNumber: _gstController.text.trim().isEmpty ? null : _gstController.text.trim(),
        panNumber: _panController.text.trim().isEmpty ? null : _panController.text.trim(),
        registrationNumber: _registrationController.text.trim().isEmpty
            ? null
            : _registrationController.text.trim(),
      );

      final createdOrg = await orgApi.createOrganization(org);
      _selectedOrganizationId = createdOrg.id;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Move to next step
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep = 1);
        ref.invalidate(organizationsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create organization: $e'),
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

  Future<void> _createUsers() async {
    if (_users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one user'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate all user forms
    for (var user in _users) {
      if (user.formKey.currentState != null && !user.formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final userApi = UserApi.create();
      int successCount = 0;
      int failCount = 0;

      for (var userData in _users) {
        try {
          final user = UserCreate(
            email: userData.emailController.text.trim(),
            password: userData.passwordController.text,
            fullName: userData.nameController.text.trim().isEmpty
                ? null
                : userData.nameController.text.trim(),
            organizationId: _selectedOrganizationId!,
            role: userData.selectedRole,
          );
          await userApi.createUser(user);
          successCount++;
        } catch (e) {
          failCount++;
          print('Failed to create user ${userData.emailController.text}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Created $successCount user(s)${failCount > 0 ? '. Failed: $failCount' : ''}',
            ),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        // Reset and go back to start
        _resetForms();
        _pageController.jumpToPage(0);
        setState(() => _currentStep = 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create users: $e'),
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

  void _resetForms() {
    _orgFormKey.currentState?.reset();
    _orgNameController.clear();
    _contactPersonController.clear();
    _contactEmailController.clear();
    _contactPhoneController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _stateController.clear();
    _postalCodeController.clear();
    _countryController.clear();
    _gstController.clear();
    _panController.clear();
    _registrationController.clear();
    _subscriptionStartDate = null;
    _subscriptionEndDate = null;
    _users.clear();
    _selectedOrganizationId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Onboarding'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildOrganizationForm(),
          _buildUserForm(),
        ],
      ),
    );
  }

  Widget _buildOrganizationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _orgFormKey,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              border: OutlineInputBorder(),
                            ),
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
                                labelText: 'Subscription Start Date *',
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                                errorText: _subscriptionStartDate == null
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
                                labelText: 'Subscription End Date *',
                                border: const OutlineInputBorder(),
                                suffixIcon: const Icon(Icons.calendar_today),
                                errorText: _subscriptionEndDate == null
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
                        // Basic validation: should be 15 characters
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createOrganization,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Organization & Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Users',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: _addUser,
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add users for this organization. At least one owner is recommended.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_users.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No users added yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addUser,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First User'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...List.generate(_users.length, (index) {
              final userData = _users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: userData.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeUser(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: userData.nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: userData.emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email (Username) *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Invalid email format';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: userData.passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password *',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: userData.selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role *',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'owner', child: Text('Owner')),
                            DropdownMenuItem(value: 'manager', child: Text('Manager')),
                            DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                            DropdownMenuItem(value: 'employee', child: Text('Employee')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                userData.selectedRole = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          setState(() => _currentStep = 0);
                        },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createUsers,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Users & Finish'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserFormData {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'manager';

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}

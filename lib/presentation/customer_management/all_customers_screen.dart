import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/api/organization_api.dart';
import '../../data/models/organization.dart';
import '../customer_edit/customer_edit_screen.dart';

final allCustomersProvider = FutureProvider<List<Organization>>((ref) async {
  final api = OrganizationApi.create();
  final result = await api.listOrganizations(pageSize: 1000);
  return result.items;
});

class AllCustomersScreen extends ConsumerWidget {
  const AllCustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allCustomersProvider);
            },
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No customers found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use Customer Onboarding to add new customers',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final org = customers[index];
              return _buildCustomerCard(context, ref, org);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load customers',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allCustomersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    WidgetRef ref,
    Organization org,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final endDate = org.subscriptionEndDate;
    final isExpired = endDate != null && endDate.isBefore(DateTime.now());
    final isExpiring = endDate != null &&
        !isExpired &&
        endDate.isBefore(DateTime.now().add(const Duration(days: 30)));
    final daysUntilExpiry = endDate != null
        ? endDate.difference(DateTime.now()).inDays
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomerEditScreen(
                organization: org,
              ),
            ),
          );
          // Refresh list if customer was updated
          if (result == true && context.mounted) {
            ref.invalidate(allCustomersProvider);
          }
        },
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
                          org.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (org.contactPerson != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Contact: ${org.contactPerson}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.red.withOpacity(0.1)
                              : isExpiring
                                  ? Colors.orange.withOpacity(0.1)
                                  : org.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isExpired
                              ? 'EXPIRED'
                              : isExpiring
                                  ? 'EXPIRING'
                                  : org.isActive
                                      ? 'ACTIVE'
                                      : 'INACTIVE',
                          style: TextStyle(
                            color: isExpired
                                ? Colors.red
                                : isExpiring
                                    ? Colors.orange
                                    : org.isActive
                                        ? Colors.green
                                        : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
              if (org.contactEmail != null || org.contactPhone != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    if (org.contactEmail != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            org.contactEmail!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    if (org.contactPhone != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            org.contactPhone!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
              if (endDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isExpired
                          ? Colors.red
                          : isExpiring
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expires: ${dateFormat.format(endDate)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isExpired
                                ? Colors.red
                                : isExpiring
                                    ? Colors.orange
                                    : Colors.grey[700],
                          ),
                    ),
                    if (daysUntilExpiry != null && !isExpired) ...[
                      const SizedBox(width: 8),
                      Text(
                        daysUntilExpiry < 0
                            ? '(Expired ${daysUntilExpiry.abs()} days ago)'
                            : '($daysUntilExpiry days remaining)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isExpiring ? Colors.orange : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
              if (org.gstNumber != null) ...[
                const SizedBox(height: 8),
                Text(
                  'GST: ${org.gstNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

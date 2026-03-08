import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/drawer_helper.dart';
import '../../data/api/customer_stats_api.dart';
import '../../data/models/organization.dart';
import '../customer_edit/customer_edit_screen.dart';
import 'all_customers_screen.dart';

final customerStatsProvider = FutureProvider<CustomerStats>((ref) async {
  final api = CustomerStatsApi.create();
  return api.getCustomerStats(daysAhead: 30);
});

class CustomerManagementScreen extends ConsumerWidget {
  const CustomerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(customerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => DrawerHelper.openDrawer(context),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(customerStatsProvider);
            },
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load customer statistics',
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
                onPressed: () => ref.invalidate(customerStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CustomerStats stats) {
    return Consumer(
      builder: (context, ref, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Total Customers',
                      stats.totalCustomers.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Active',
                      stats.activeCustomers.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Inactive',
                      stats.inactiveCustomers.toString(),
                      Icons.cancel,
                      Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Expiring Soon',
                      stats.expiringSoon.length.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                context,
                'Expired',
                stats.expired.length.toString(),
                Icons.error,
                Colors.red,
                fullWidth: true,
              ),
              const SizedBox(height: 24),

              // Expiring Soon Section
              if (stats.expiringSoon.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Subscriptions Expiring Soon (${stats.expiringSoon.length})',
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                ...stats.expiringSoon.map((org) => _buildCustomerCard(context, ref, org, isExpiring: true)),
                const SizedBox(height: 24),
              ],

              // Expired Section
              if (stats.expired.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'Expired Subscriptions (${stats.expired.length})',
                  Colors.red,
                ),
                const SizedBox(height: 12),
                ...stats.expired.map((org) => _buildCustomerCard(context, ref, org, isExpired: true)),
                const SizedBox(height: 24),
              ],

              // All Customers Section - Show link to view all
              _buildSectionHeader(
                context,
                'All Customers (${stats.totalCustomers})',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.list, color: Colors.blue),
                  title: const Text('View All Customers'),
                  subtitle: const Text('View and edit all onboarded customers'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllCustomersScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    WidgetRef ref,
    Organization org, {
    bool isExpiring = false,
    bool isExpired = false,
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final endDate = org.subscriptionEndDate;
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
          // Refresh stats if customer was updated
          if (result == true && context.mounted) {
            ref.invalidate(customerStatsProvider);
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
                                : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isExpired
                            ? 'EXPIRED'
                            : isExpiring
                                ? 'EXPIRING'
                                : 'ACTIVE',
                        style: TextStyle(
                          color: isExpired
                              ? Colors.red
                              : isExpiring
                                  ? Colors.orange
                                  : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: Colors.blue,
                      onPressed: () async {
                        // Stop event propagation to prevent InkWell from firing
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CustomerEditScreen(
                              organization: org,
                            ),
                          ),
                        );
                        // Refresh stats if customer was updated
                        if (result == true && context.mounted) {
                          ref.invalidate(customerStatsProvider);
                        }
                      },
                      tooltip: 'Edit Customer',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
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

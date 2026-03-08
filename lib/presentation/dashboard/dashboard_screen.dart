import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/drawer_helper.dart';
import '../../core/routing.dart';
import '../../core/providers.dart';
import '../../data/api/project_api.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/api/analytics_api.dart';
import '../../data/api/employee_api.dart';
import '../../data/api/vendor_api.dart';
import '../../data/api/transaction_api.dart';
import '../../data/models/project.dart';
import '../../data/models/pagination.dart';
import '../../data/models/analytics.dart';
import '../../data/models/employee.dart';
import '../../data/models/vendor.dart';
import '../../data/models/transaction.dart';

final dashboardCategoryExpensesProvider = FutureProvider.family<CategoryExpenseData, String?>((ref, projectId) async {
  final api = AnalyticsApi.create();
  return api.getCategoryExpenses(projectId: projectId);
});

final dashboardProjectsProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects(pageSize: 100);
});

final dashboardEmployeesProvider = FutureProvider<Paginated<Employee>>((ref) async {
  final api = EmployeeApi.create();
  return api.listEmployees(pageSize: 100);
});

final dashboardVendorsProvider = FutureProvider<Paginated<Vendor>>((ref) async {
  final api = VendorApi.create();
  return api.listVendors(pageSize: 100);
});

final dashboardTransactionsProvider = FutureProvider<Paginated<Transaction>>((ref) async {
  final api = TransactionApi.create();
  return api.listTransactions(pageSize: 100);
});

// Use a tuple-like class for stable provider family keys
class MonthlyExpensesParams {
  final int year;
  final String? projectId;
  
  MonthlyExpensesParams({required this.year, this.projectId});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyExpensesParams &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          projectId == other.projectId;

  @override
  int get hashCode => year.hashCode ^ projectId.hashCode;
}

final monthlyExpensesProvider = FutureProvider.family<MonthlyExpenseData, MonthlyExpensesParams>((ref, params) async {
  final api = AnalyticsApi.create();
  return api.getMonthlyExpenses(
    year: params.year,
    projectId: params.projectId,
  );
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedYear = DateTime.now().year;
  bool _showPieChart = false; // Toggle between line chart and pie chart

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(dashboardProjectsProvider);
    final employeesAsync = ref.watch(dashboardEmployeesProvider);
    final vendorsAsync = ref.watch(dashboardVendorsProvider);
    final transactionsAsync = ref.watch(dashboardTransactionsProvider);
    final allExpensesParams = MonthlyExpensesParams(year: _selectedYear, projectId: null);
    final allExpensesAsync = ref.watch(monthlyExpensesProvider(allExpensesParams));

    // Calculate KPI values
    final totalProjects = projectsAsync.valueOrNull?.items.length ?? 0;
    final totalEmployees = employeesAsync.valueOrNull?.items.length ?? 0;
    final totalVendors = vendorsAsync.valueOrNull?.items.length ?? 0;
    final totalTransactions = transactionsAsync.valueOrNull?.items.length ?? 0;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('KONTRAK Dashboard'),
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => DrawerHelper.openDrawer(context),
            ),
          ),
          actions: [
            DropdownButton<int>(
              value: _selectedYear,
              items: List.generate(5, (index) {
                final year = DateTime.now().year - index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true && mounted) {
                  await AuthRepository.instance.signOut();
                  // Clear login date to force login next time
                  await AuthRepository.instance.clearLoginDate();
                  if (mounted) {
                    ref.read(isAuthenticatedProvider.notifier).state = false;
                  }
                }
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              // KPI Cards Row
              Row(
                children: [
                  Expanded(
                    child: _KPICard(
                      title: 'Total Projects',
                      value: totalProjects.toString(),
                      icon: Icons.work,
                      color: Colors.blue,
                      onTap: () {
                        final navigate = ref.read(tabNavigationProvider);
                        if (navigate != null) {
                          navigate(RootTab.projects);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KPICard(
                      title: 'Total Employees',
                      value: totalEmployees.toString(),
                      icon: Icons.people,
                      color: Colors.green,
                      onTap: () {
                        final navigate = ref.read(tabNavigationProvider);
                        if (navigate != null) {
                          navigate(RootTab.employees);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KPICard(
                      title: 'Total Vendors',
                      value: totalVendors.toString(),
                      icon: Icons.storefront,
                      color: Colors.orange,
                      onTap: () {
                        final navigate = ref.read(tabNavigationProvider);
                        if (navigate != null) {
                          navigate(RootTab.vendors);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KPICard(
                      title: 'Transactions',
                      value: totalTransactions.toString(),
                      icon: Icons.receipt,
                      color: Colors.purple,
                      onTap: () {
                        final navigate = ref.read(tabNavigationProvider);
                        if (navigate != null) {
                          navigate(RootTab.transactions);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              projectsAsync.when(
                data: (paged) {
                  final ongoing =
                      paged.items.where((p) => p.status == 'ongoing').length;
                  final completed =
                      paged.items.where((p) => p.status == 'completed').length;
                  return Row(
                    children: [
                      Expanded(
                        child: _DashboardCard(
                          title: 'Ongoing Projects',
                          value: ongoing.toString(),
                          onTap: () {
                            final navigate = ref.read(tabNavigationProvider);
                            if (navigate != null) {
                              navigate(RootTab.projects);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardCard(
                          title: 'Completed Projects',
                          value: completed.toString(),
                        ),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _DashboardCard(
                  title: 'Projects',
                  value: 'Error',
                ),
              ),
              const SizedBox(height: 16),
              // Chart Type Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Line Chart'), icon: Icon(Icons.show_chart)),
                      ButtonSegment(value: true, label: Text('Pie Chart'), icon: Icon(Icons.pie_chart)),
                    ],
                    selected: {_showPieChart},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showPieChart = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              allExpensesAsync.when(
                data: (data) {
                  if (data.points.isEmpty) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Projects - Monthly Expenses ($_selectedYear)',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('No expense data available for $_selectedYear.'),
                            const SizedBox(height: 4),
                            Text(
                              'To see data: Add debit transactions with dates in $_selectedYear',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (_showPieChart) {
                    return _MonthlyExpensePieChart(
                      points: data.points,
                      title: 'All Projects - Monthly Expenses ($_selectedYear)',
                    );
                  }
                  return _MonthlyExpenseChart(
                    points: data.points,
                    title: 'All Projects - Monthly Expenses ($_selectedYear)',
                  );
                },
                loading: () => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Projects - Monthly Expenses ($_selectedYear)',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
                error: (e, _) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load expenses chart: $e'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              projectsAsync.when(
                data: (paged) {
                  if (paged.items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project-wise Monthly Expenses',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...paged.items.map((project) {
                        final projectParams = MonthlyExpensesParams(year: _selectedYear, projectId: project.id);
                        final projectExpensesAsync = ref.watch(monthlyExpensesProvider(projectParams));
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: projectExpensesAsync.when(
                            data: (data) {
                              if (data.points.isEmpty) {
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text('No expense data for this project yet.'),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              if (_showPieChart) {
                                return _MonthlyExpensePieChart(
                                  points: data.points,
                                  title: project.name,
                                );
                              }
                              return _MonthlyExpenseChart(
                                points: data.points,
                                title: project.name,
                              );
                            },
                            loading: () => const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                            ),
                            error: (e, _) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('Failed to load expenses for ${project.name}: $e'),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cardContent = Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

class _KPICard extends StatelessWidget {
  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

class _MonthlyExpenseChart extends StatelessWidget {
  const _MonthlyExpenseChart({
    required this.points,
    this.title,
  });

  final List<MonthlyExpensePoint> points;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const _DashboardCard(
        title: 'Monthly Expenses',
        value: 'No data',
      );
    }

    final maxY =
        points.map((e) => e.totalExpense).fold<double>(0, (a, b) => b > a ? b : a);
    
    // If maxY is 0, set a minimum for chart display
    final chartMaxY = (maxY > 0 ? maxY * 1.2 : 1000).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final month = points[index].month;
                          return Text('${month.month}/${month.year % 100}');
                        },
                      ),
                    ),
                  ),
                  minY: 0,
                  maxY: chartMaxY,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                      ),
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].totalExpense),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyExpensePieChart extends StatelessWidget {
  const _MonthlyExpensePieChart({
    required this.points,
    this.title,
  });

  final List<MonthlyExpensePoint> points;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Card(
        margin: EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No data')),
        ),
      );
    }

    final total = points.fold<double>(0, (sum, p) => sum + p.totalExpense);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
      Colors.brown,
      Colors.lime,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          for (var i = 0; i < points.length; i++)
                            PieChartSectionData(
                              value: points[i].totalExpense,
                              title: total > 0
                                  ? '${((points[i].totalExpense / total) * 100).toStringAsFixed(1)}%'
                                  : '0%',
                              color: colors[i % colors.length],
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < points.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${points[i].month.month}/${points[i].month.year % 100}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${points[i].totalExpense.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


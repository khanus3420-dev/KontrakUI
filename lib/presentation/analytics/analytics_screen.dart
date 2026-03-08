import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/drawer_helper.dart';
import '../../core/routing.dart';
import '../../core/providers.dart';
import '../../data/api/analytics_api.dart';
import '../../data/api/project_api.dart';
import '../../data/api/employee_api.dart';
import '../../data/api/vendor_api.dart';
import '../../data/api/transaction_api.dart';
import '../../data/models/analytics.dart';
import '../../data/models/pagination.dart';
import '../../data/models/project.dart';
import '../../data/models/employee.dart';
import '../../data/models/vendor.dart';
import '../../data/models/transaction.dart';

final analyticsProjectsProvider = FutureProvider<Paginated<Project>>((ref) async {
  final api = ProjectApi.create();
  return api.listProjects(pageSize: 100);
});

final analyticsEmployeesProvider = FutureProvider<Paginated<Employee>>((ref) async {
  final api = EmployeeApi.create();
  return api.listEmployees(pageSize: 100);
});

final analyticsVendorsProvider = FutureProvider<Paginated<Vendor>>((ref) async {
  final api = VendorApi.create();
  return api.listVendors(pageSize: 100);
});

final analyticsTransactionsProvider = FutureProvider<Paginated<Transaction>>((ref) async {
  final api = TransactionApi.create();
  return api.listTransactions(pageSize: 100);
});

// Use a tuple-like class for stable provider family keys
class AnalyticsParams {
  final int year;
  final String? projectId;
  
  AnalyticsParams({required this.year, this.projectId});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsParams &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          projectId == other.projectId;

  @override
  int get hashCode => year.hashCode ^ projectId.hashCode;
}

final analyticsMonthlyExpensesProvider = FutureProvider.family<MonthlyExpenseData, AnalyticsParams>((ref, params) async {
  try {
    print('Fetching analytics for year: ${params.year}, projectId: ${params.projectId}');
    final api = AnalyticsApi.create();
    final result = await api.getMonthlyExpenses(
      year: params.year,
      projectId: params.projectId,
    );
    print('Analytics fetch completed: ${result.points.length} points');
    return result;
  } catch (e, stackTrace) {
    print('Error in analyticsMonthlyExpensesProvider: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});

final projectProfitProvider = FutureProvider<ProjectProfitData>((ref) async {
  final api = AnalyticsApi.create();
  return api.getProjectProfit();
});

final categoryExpensesProvider = FutureProvider.family<CategoryExpenseData, String?>((ref, projectId) async {
  final api = AnalyticsApi.create();
  return api.getCategoryExpenses(projectId: projectId);
});

final budgetVsActualProvider = FutureProvider<BudgetVsActualData>((ref) async {
  final api = AnalyticsApi.create();
  return api.getBudgetVsActual();
});

final employeeSalaryProvider = FutureProvider.family<EmployeeSalaryData, DateTime?>((ref, month) async {
  final api = AnalyticsApi.create();
  return api.getEmployeeSalaryDistribution(month: month);
});

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(analyticsProjectsProvider);
    final employeesAsync = ref.watch(analyticsEmployeesProvider);
    final vendorsAsync = ref.watch(analyticsVendorsProvider);
    final transactionsAsync = ref.watch(analyticsTransactionsProvider);
    final allExpensesAsync = ref.watch(analyticsMonthlyExpensesProvider(AnalyticsParams(year: _selectedYear, projectId: null)));
    final projectProfitAsync = ref.watch(projectProfitProvider);
    final categoryExpensesAsync = ref.watch(categoryExpensesProvider(null));
    final budgetVsActualAsync = ref.watch(budgetVsActualProvider);
    final employeeSalaryAsync = ref.watch(employeeSalaryProvider(DateTime(_selectedYear, DateTime.now().month, 1)));

    // Calculate KPIs
    final totalProjects = projectsAsync.valueOrNull?.items.length ?? 0;
    final totalEmployees = employeesAsync.valueOrNull?.items.length ?? 0;
    final totalVendors = vendorsAsync.valueOrNull?.items.length ?? 0;
    final totalTransactions = transactionsAsync.valueOrNull?.items.length ?? 0;
    
    final totalExpenses = allExpensesAsync.valueOrNull?.points.fold<double>(0, (sum, p) => sum + p.totalExpense) ?? 0.0;
    final totalRevenue = projectProfitAsync.valueOrNull?.points.fold<double>(0, (sum, p) => sum + p.totalCredit) ?? 0.0;
    final totalProfit = projectProfitAsync.valueOrNull?.points.fold<double>(0, (sum, p) => sum + p.profit) ?? 0.0;
    final avgProjectProfit = projectProfitAsync.valueOrNull?.points.isEmpty == true 
        ? 0.0 
        : totalProfit / (projectProfitAsync.valueOrNull?.points.length ?? 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(analyticsProjectsProvider);
              ref.invalidate(analyticsEmployeesProvider);
              ref.invalidate(analyticsVendorsProvider);
              ref.invalidate(analyticsTransactionsProvider);
              ref.invalidate(analyticsMonthlyExpensesProvider(AnalyticsParams(year: _selectedYear, projectId: null)));
              ref.invalidate(projectProfitProvider);
              ref.invalidate(categoryExpensesProvider(null));
              ref.invalidate(budgetVsActualProvider);
              ref.invalidate(employeeSalaryProvider(DateTime(_selectedYear, DateTime.now().month, 1)));
            },
          ),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column - KPI Cards
            Flexible(
              flex: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
                child: Column(
                  children: [
                  _KPICard(
                    title: 'Total Projects',
                    value: totalProjects.toString(),
                    icon: Icons.work,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _KPICard(
                    title: 'Total Employees',
                    value: totalEmployees.toString(),
                    icon: Icons.people,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _KPICard(
                    title: 'Total Vendors',
                    value: totalVendors.toString(),
                    icon: Icons.storefront,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _KPICard(
                    title: 'Transactions',
                    value: totalTransactions.toString(),
                    icon: Icons.receipt,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _KPICard(
                    title: 'Total Expenses',
                    value: _formatCurrency(totalExpenses),
                    icon: Icons.trending_down,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _KPICard(
                    title: 'Total Revenue',
                    value: _formatCurrency(totalRevenue),
                    icon: Icons.trending_up,
                    color: Colors.teal,
                  ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Right Column - Charts
            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row - Line Charts
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 1,
                        child: _buildMonthlyExpensesChart(allExpensesAsync),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 1,
                        child: _buildBudgetVsActualChart(budgetVsActualAsync),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Middle Row - Pie Chart and Bar Chart
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 1,
                        child: _buildCategoryExpensesChart(categoryExpensesAsync),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 1,
                        child: _buildEmployeeSalaryChart(employeeSalaryAsync),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bottom Row - Project Profit Charts
                  _buildProjectProfitCharts(projectProfitAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildMonthlyExpensesChart(AsyncValue<MonthlyExpenseData> asyncData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Monthly Expenses ($_selectedYear)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SizedBox(
                height: 200,
                child: asyncData.when(
                  data: (data) {
                    if (data.points.isEmpty) {
                      return const Center(child: Text('No data available'));
                    }
                    return _MonthlyExpenseLineChart(points: data.points);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetVsActualChart(AsyncValue<BudgetVsActualData> asyncData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Budget vs Actual',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SizedBox(
                height: 200,
                child: asyncData.when(
                  data: (data) {
                    if (data.points.isEmpty) {
                      return const Center(child: Text('No data available'));
                    }
                    return _BudgetVsActualBarChart(points: data.points);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryExpensesChart(AsyncValue<CategoryExpenseData> asyncData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Expenses by Category',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SizedBox(
                height: 200,
                child: asyncData.when(
                  data: (data) {
                    if (data.points.isEmpty) {
                      return const Center(child: Text('No data available'));
                    }
                    return _CategoryExpensePieChart(points: data.points);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSalaryChart(AsyncValue<EmployeeSalaryData> asyncData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Employee Salary Distribution',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SizedBox(
                height: 200,
                child: asyncData.when(
                  data: (data) {
                    if (data.points.isEmpty) {
                      return const Center(child: Text('No data available'));
                    }
                    return _EmployeeSalaryBarChart(points: data.points);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectProfitCharts(AsyncValue<ProjectProfitData> asyncData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Top Projects by Profit',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: asyncData.when(
                data: (data) {
                  if (data.points.isEmpty) {
                    return const Center(child: Text('No data available'));
                  }
                  // Sort by profit and take top 3
                  final sorted = List<ProjectProfitPoint>.from(data.points)
                    ..sort((a, b) => b.profit.compareTo(a.profit));
                  final top3 = sorted.take(3).toList();
                  return _ProjectProfitBarChart(points: top3);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
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
  }
}

class _MonthlyExpenseLineChart extends StatelessWidget {
  const _MonthlyExpenseLineChart({required this.points});

  final List<MonthlyExpensePoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((e) => e.totalExpense).fold<double>(0, (a, b) => b > a ? b : a);
    final chartMaxY = (maxY > 0 ? maxY * 1.2 : 1000).toDouble();

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].totalExpense),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetVsActualBarChart extends StatelessWidget {
  const _BudgetVsActualBarChart({required this.points});

  final List<BudgetVsActualPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((e) => e.estimatedBudget > e.actualExpense ? e.estimatedBudget : e.actualExpense)
        .fold<double>(0, (a, b) => b > a ? b : a);
    final chartMaxY = (maxY > 0 ? maxY * 1.2 : 1000).toDouble();

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                final name = points[index].projectName;
                return Text(name.length > 10 ? '${name.substring(0, 10)}...' : name, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        minY: 0,
        maxY: chartMaxY,
        groupsSpace: 12,
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].estimatedBudget,
                  color: Colors.blue,
                  width: 10,
                ),
                BarChartRodData(
                  toY: points[i].actualExpense,
                  color: Colors.orange,
                  width: 10,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryExpensePieChart extends StatelessWidget {
  const _CategoryExpensePieChart({required this.points});

  final List<CategoryExpensePoint> points;

  @override
  Widget build(BuildContext context) {
    final total = points.fold<double>(0, (sum, p) => sum + p.totalExpense);
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: [
                for (var i = 0; i < points.length; i++)
                  PieChartSectionData(
                    value: points[i].totalExpense,
                    title: '${((points[i].totalExpense / total) * 100).toStringAsFixed(0)}%',
                    color: colors[i % colors.length],
                    radius: 60,
                  ),
              ],
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
                        color: colors[i % colors.length],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          points[i].category,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmployeeSalaryBarChart extends StatelessWidget {
  const _EmployeeSalaryBarChart({required this.points});

  final List<EmployeeSalaryPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((e) => e.totalSalary).fold<double>(0, (a, b) => b > a ? b : a);
    final chartMaxY = (maxY > 0 ? maxY * 1.2 : 1000).toDouble();

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                final name = points[index].employeeName;
                return Text(name.length > 8 ? '${name.substring(0, 8)}...' : name, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        minY: 0,
        maxY: chartMaxY,
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].totalSalary,
                  color: Colors.green,
                  width: 16,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProjectProfitBarChart extends StatelessWidget {
  const _ProjectProfitBarChart({required this.points});

  final List<ProjectProfitPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((e) => e.profit.abs()).fold<double>(0, (a, b) => b > a ? b : a);
    final chartMaxY = (maxY > 0 ? maxY * 1.2 : 1000).toDouble();
    final minY = points.map((e) => e.profit).fold<double>(0, (a, b) => b < a ? b : a);
    final chartMinY = (minY < 0 ? minY * 1.2 : 0).toDouble();

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                final name = points[index].projectName;
                return Text(name.length > 10 ? '${name.substring(0, 10)}...' : name, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        minY: chartMinY,
        maxY: chartMaxY,
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].profit,
                  color: points[i].profit >= 0 ? Colors.green : Colors.red,
                  width: 20,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/dashboard/dashboard_screen.dart';
import '../presentation/projects/projects_screen.dart';
import '../presentation/employees/employees_screen.dart';
import '../presentation/vendors/vendors_screen.dart';
import '../presentation/transactions/transactions_screen.dart';
import '../presentation/analytics/analytics_screen.dart';
import '../presentation/quotations/quotations_screen.dart';
import '../presentation/attendance/attendance_screen.dart';
import '../presentation/salary/salary_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/customer_management/customer_management_screen.dart';
import '../data/auth/auth_repository.dart';
import 'providers.dart';

enum RootTab {
  dashboard,
  projects,
  analytics,
  employees,
  vendors,
  transactions,
  quotations,
}

class RootScaffold extends ConsumerStatefulWidget {
  const RootScaffold({super.key});

  @override
  ConsumerState<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends ConsumerState<RootScaffold> {
  RootTab _currentTab = RootTab.dashboard;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = RootTab.values[index];
    });
  }

  void _navigateToTab(RootTab tab) {
    setState(() {
      _currentTab = tab;
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }
  
  // Expose drawer opening function via provider
  static void openRootDrawer(BuildContext context) {
    // This will be set by RootScaffold
    final openFn = context.findAncestorStateOfType<_RootScaffoldState>();
    openFn?._openDrawer();
  }

  // Expose navigation function to child widgets
  void navigateToTab(RootTab tab) {
    _navigateToTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    // Register navigation and drawer functions with providers after build completes
    // Using Future.microtask to defer the update until after the current build cycle
    Future.microtask(() {
      if (mounted) {
        if (ref.read(tabNavigationProvider) != _navigateToTab) {
          ref.read(tabNavigationProvider.notifier).state = _navigateToTab;
        }
        if (ref.read(drawerOpenProvider) != _openDrawer) {
          ref.read(drawerOpenProvider.notifier).state = _openDrawer;
        }
      }
    });
    
    // Check if user is superadmin
    final isSuperadminAsync = ref.watch(isSuperadminProvider);
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: isSuperadminAsync.when(
        data: (isSuperadmin) {
          if (isSuperadmin) {
            // Show customer management screen for superadmin
            return const CustomerManagementScreen();
          } else {
            // Show regular app for builder admin
            return IndexedStack(
              index: _currentTab.index,
              children: const [
                DashboardScreen(),
                ProjectsScreen(),
                AnalyticsScreen(),
                EmployeesScreen(),
                VendorsScreen(),
                TransactionsScreen(),
                QuotationsScreen(),
              ],
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading user data')),
      ),
      bottomNavigationBar: isSuperadminAsync.when(
        data: (isSuperadmin) {
          // Hide bottom navigation for superadmin
          if (isSuperadmin) {
            return null;
          }
          // Show bottom navigation for builder admin
          return NavigationBar(
            selectedIndex: _currentTab == RootTab.dashboard
                ? 0
                : _currentTab == RootTab.projects
                    ? 1
                    : _currentTab == RootTab.analytics
                        ? 2
                        : 0,
            onDestinationSelected: (index) {
              if (index == 0) {
                _navigateToTab(RootTab.dashboard);
              } else if (index == 1) {
                _navigateToTab(RootTab.projects);
              } else if (index == 2) {
                _navigateToTab(RootTab.analytics);
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.work_outline),
                selectedIcon: Icon(Icons.work),
                label: 'Projects',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Analytics',
              ),
            ],
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'KONTRAK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, child) {
                          final isSuperadminAsync = ref.watch(isSuperadminProvider);
                          return isSuperadminAsync.when(
                            data: (isSuperadmin) => Text(
                              isSuperadmin ? 'Super Admin' : 'Management Menu',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Show different menu items based on user type
                Consumer(
                  builder: (context, ref, child) {
                    final isSuperadminAsync = ref.watch(isSuperadminProvider);
                    return isSuperadminAsync.when(
                      data: (isSuperadmin) {
                        if (isSuperadmin) {
                          // Superadmin menu: Only Customer Onboarding and Logout
                          return Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person_add),
                                title: const Text('Customer Onboarding'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const OnboardingScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.logout),
                                title: const Text('Logout'),
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await AuthRepository.instance.signOut();
                                  await AuthRepository.instance.clearLoginDate();
                                  if (mounted) {
                                    ref.read(isAuthenticatedProvider.notifier).state = false;
                                  }
                                },
                              ),
                            ],
                          );
                        } else {
                          // Builder admin menu: All regular menu items
                          return Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.people_outline),
                                title: const Text('Employees'),
                                onTap: () => _navigateToTab(RootTab.employees),
                              ),
                              ListTile(
                                leading: const Icon(Icons.storefront_outlined),
                                title: const Text('Vendors'),
                                onTap: () => _navigateToTab(RootTab.vendors),
                              ),
                              ListTile(
                                leading: const Icon(Icons.payments_outlined),
                                title: const Text('Transactions'),
                                onTap: () => _navigateToTab(RootTab.transactions),
                              ),
                              ListTile(
                                leading: const Icon(Icons.notifications_outlined),
                                title: const Text('Reminders'),
                                onTap: () => _navigateToTab(RootTab.quotations),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.calendar_today_outlined),
                                title: const Text('Attendance'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const AttendanceScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.account_balance_wallet),
                                title: const Text('Salary Management'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SalaryScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.logout),
                                title: const Text('Logout'),
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await AuthRepository.instance.signOut();
                                  await AuthRepository.instance.clearLoginDate();
                                  if (mounted) {
                                    ref.read(isAuthenticatedProvider.notifier).state = false;
                                  }
                                },
                              ),
                            ],
                          );
                        }
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Copyright © 2026 Khanoos Enterprises',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


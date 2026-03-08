import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/routing.dart';
import 'core/theme.dart';
import 'data/auth/auth_repository.dart';
import 'data/cache/cache_service.dart';
import 'presentation/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService.init();
  await AuthRepository.instance.init();
  
  // Check if user is logged in today (session persistence)
  final isLoggedInToday = await AuthRepository.instance.isLoggedInToday();
  if (isLoggedInToday) {
    // Set authenticated state if logged in today
    // We'll set this in the app widget
  }
  
  runApp(const ProviderScope(child: KontrakApp()));
}

class KontrakApp extends ConsumerStatefulWidget {
  const KontrakApp({super.key});

  @override
  ConsumerState<KontrakApp> createState() => _KontrakAppState();
}

class _KontrakAppState extends ConsumerState<KontrakApp> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Check if user is logged in today
    final isLoggedInToday = await AuthRepository.instance.isLoggedInToday();
    if (isLoggedInToday && mounted) {
      // Set authenticated state to true if logged in today
      ref.read(isAuthenticatedProvider.notifier).state = true;
    }
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Show loading indicator while checking session
    if (!_isInitialized) {
      return MaterialApp(
        title: 'KONTRAK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'KONTRAK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: isAuthenticated ? const RootScaffold() : const LoginScreen(),
    );
  }
}



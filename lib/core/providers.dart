import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth/auth_repository.dart';
import 'routing.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// Simple in-memory auth flag set on login/logout.
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.instance;
});

// Provider for tab navigation - allows child widgets to navigate between tabs
typedef TabNavigationCallback = void Function(RootTab);
final tabNavigationProvider = StateProvider<TabNavigationCallback?>((ref) => null);

// Provider for drawer opening - allows child widgets to open the root drawer
typedef DrawerOpenCallback = void Function();
final drawerOpenProvider = StateProvider<DrawerOpenCallback?>((ref) => null);

// Provider for superadmin status
final isSuperadminProvider = FutureProvider<bool>((ref) async {
  return await AuthRepository.instance.isSuperadmin();
});



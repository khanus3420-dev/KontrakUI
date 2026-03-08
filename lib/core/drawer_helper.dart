import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

class DrawerHelper {
  static void openDrawer(BuildContext context) {
    // First try to use the provider if available (most reliable)
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final openFn = container.read(drawerOpenProvider);
      if (openFn != null) {
        openFn();
        return;
      }
    } catch (e) {
      // Provider not available, fall back to context traversal
    }
    
    // Fallback: Try to find Scaffold with drawer by traversing up
    BuildContext? current = context;
    
    while (current != null) {
      // Try Scaffold.maybeOf first (finds nearest Scaffold)
      final scaffoldState = Scaffold.maybeOf(current);
      if (scaffoldState != null) {
        try {
          scaffoldState.openDrawer();
          return;
        } catch (e) {
          // This Scaffold doesn't have a drawer, continue up
        }
      }
      
      // Try Scaffold.of which requires a drawer
      try {
        Scaffold.of(current).openDrawer();
        return;
      } catch (e) {
        // No drawer here, continue up
      }
      
      // Move to parent context
      current = current.findAncestorStateOfType<State>()?.context;
      if (current == null) break;
    }
  }
}

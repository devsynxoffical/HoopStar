import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/management/viewmodel/academy_provider.dart';

class PermissionWrapper extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;
  final bool useRoleFallback;

  const PermissionWrapper({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.useRoleFallback = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final hasPermission = provider.hasPermission(permission);
        
        if (hasPermission) {
          return child;
        }
        
        // Show fallback if provided
        if (fallback != null) {
          return fallback!;
        }
        
        // Show nothing or disabled widget based on useRoleFallback
        if (useRoleFallback) {
          return const SizedBox.shrink();
        }
        
        // Return disabled version of the child
        return IgnorePointer(
          child: Opacity(
            opacity: 0.5,
            child: child,
          ),
        );
      },
    );
  }
}

class RoleWrapper extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleWrapper({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final userRole = provider.currentUser?.role;
        final isAllowed = userRole != null && allowedRoles.contains(userRole);
        
        if (isAllowed) {
          return child;
        }
        
        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

class ConditionalVisibility extends StatelessWidget {
  final bool condition;
  final Widget child;
  final Widget? fallback;

  const ConditionalVisibility({
    super.key,
    required this.condition,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

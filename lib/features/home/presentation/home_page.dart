import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/widgets/app_logo.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/providers/admin_auth_providers.dart';
import 'package:hr_portal/providers/auth_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isEmployeeSession = ref.watch(isEmployeeSessionProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitle(),
        actions: [
          if (isEmployeeSession)
            TextButton.icon(
              onPressed: () async {
                ref.read(adminAuthProvider.notifier).logoutAdminOnly();
                await ref.read(authServiceProvider).signOut();
                ref.invalidate(currentEmployeeProvider);
                if (context.mounted) {
                  context.go(AppRoutes.home);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white),
              ),
            ),
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.adminLogin),
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            label: const Text('Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ResponsivePadding(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 96),
                const SizedBox(height: 32),
                Text(
                  'Welcome',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (isEmployeeSession && authUser?.email != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    authUser!.email!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isEmployeeSession) {
                        context.go(AppRoutes.attendanceLeaves);
                      } else {
                        context.go(AppRoutes.login);
                      }
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      isEmployeeSession
                          ? 'My Attendance and Leaves'
                          : 'Attendance and Leaves',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.loginHours),
                    icon: const Icon(Icons.access_time_outlined),
                    label: const Text('Login Hours'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

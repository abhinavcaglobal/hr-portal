import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/providers/auth_providers.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email =
        ref.watch(authStateProvider).valueOrNull?.email ??
        AppConstants.adminEmail;

    return AdminShell(
      current: AdminNavItem.settings,
      body: ResponsivePadding(
        child: ListView(
          children: [
            Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Signed in as $email',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use Sign Out in the header to leave the Admin Portal. '
                      'Additional settings will appear here as the portal grows.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
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

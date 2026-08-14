import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/features/admin/presentation/widgets/upload_history_section.dart';
import 'package:hr_portal/providers/admin_providers.dart';

class AdminUploadHistoryPage extends ConsumerWidget {
  const AdminUploadHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadHistory = ref.watch(uploadHistoryProvider);

    return AdminShell(
      current: AdminNavItem.uploadHistory,
      body: ResponsivePadding(
        child: ListView(
          children: [
            Text(
              'Upload History',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            UploadHistorySection(uploadHistory: uploadHistory),
          ],
        ),
      ),
    );
  }
}

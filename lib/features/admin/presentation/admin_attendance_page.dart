import 'package:flutter/material.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/features/admin/presentation/widgets/create_attendance_card.dart';

class AdminAttendancePage extends StatelessWidget {
  const AdminAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      current: AdminNavItem.attendance,
      body: ResponsivePadding(
        child: ListView(
          children: [
            Text(
              'Attendance',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Create and manage employee attendance records',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            const CreateAttendanceCard(),
          ],
        ),
      ),
    );
  }
}

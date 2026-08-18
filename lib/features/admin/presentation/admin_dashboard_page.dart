import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/core/constants/app_constants.dart';
import 'package:hr_portal/core/router/app_router.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/features/admin/presentation/widgets/dashboard_feature_card.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = !ResponsiveLayout.isDesktop(context);
    final crossAxisCount = MediaQuery.sizeOf(context).width < 700 ? 1 : 2;

    return AdminShell(
      current: AdminNavItem.dashboard,
      syncEmployeeAccessOnLoad: true,
      body: ResponsivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome to ${AppConstants.appName}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isNarrow ? 2.1 : 2.4,
                children: [
                  DashboardFeatureCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Attendance',
                    description:
                        'Create and manage employee attendance records',
                    buttonLabel: 'Create Attendance',
                    onPressed: () => context.go(AppRoutes.adminAttendance),
                  ),
                  DashboardFeatureCard(
                    icon: Icons.event_note_outlined,
                    title: 'Leave Requests',
                    description:
                        'Review, approve or decline employee leave requests',
                    buttonLabel: 'Open Leave Requests',
                    onPressed: () => context.go(AppRoutes.adminLeaveRequests),
                  ),
                  DashboardFeatureCard(
                    icon: Icons.email_outlined,
                    title: 'Employee Emails',
                    description: 'Send an email to employees using Outlook',
                    buttonLabel: 'Email an Employee',
                    onPressed: () => context.go(AppRoutes.adminEmployeeEmails),
                  ),
                  DashboardFeatureCard(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Data Upload',
                    description:
                        'Upload attendance, roster and opening balance files',
                    buttonLabel: 'Open Data Upload',
                    onPressed: () => context.go(AppRoutes.adminUpload),
                  ),
                  DashboardFeatureCard(
                    icon: Icons.history,
                    title: 'Upload History',
                    description:
                        'View all previously uploaded files and history',
                    buttonLabel: 'View History',
                    onPressed: () => context.go(AppRoutes.adminUploadHistory),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

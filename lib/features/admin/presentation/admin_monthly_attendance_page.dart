import 'package:flutter/material.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/features/monthly_attendance/presentation/monthly_attendance_page.dart';

class AdminMonthlyAttendancePage extends StatelessWidget {
  const AdminMonthlyAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      current: AdminNavItem.monthlyAttendance,
      subtitle: 'Monthly Attendance',
      body: ResponsivePadding(
        child: MonthlyAttendancePage(embedded: true),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hr_portal/core/widgets/responsive_layout.dart';
import 'package:hr_portal/features/admin/presentation/admin_nav.dart';
import 'package:hr_portal/features/admin/presentation/widgets/admin_shell.dart';
import 'package:hr_portal/features/login_hours/presentation/login_hours_page.dart';

class AdminLoginHoursPage extends StatelessWidget {
  const AdminLoginHoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      current: AdminNavItem.loginHours,
      subtitle: 'Login Hours',
      body: ResponsivePadding(
        child: LoginHoursPage(embedded: true),
      ),
    );
  }
}

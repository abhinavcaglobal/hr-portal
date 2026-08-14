import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/theme/app_theme.dart';
import 'package:hr_portal/features/dashboard/presentation/employee_dashboard_page.dart';
import 'package:hr_portal/features/home/presentation/home_page.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/providers/employee_providers.dart';

void main() {
  testWidgets('homepage shows Attendance and Leaves button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          currentEmployeeProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: const HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Attendance and Leaves'), findsOneWidget);
  });

  testWidgets('dashboard shows employee profile without selector', (
    WidgetTester tester,
  ) async {
    const employee = Employee(
      name: 'Mayur Kumar',
      email: 'mayur.kumar@caglobal.com',
      openingBalance: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          currentEmployeeProvider.overrideWith((ref) async => employee),
          leaveBalanceProvider.overrideWith((ref) async => 5),
          monthlyAttendanceProvider.overrideWith((ref, params) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const EmployeeDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CA Global Leave Portal'), findsOneWidget);
    expect(find.text('Pending Leave Balance'), findsOneWidget);
    expect(find.text('Mayur Kumar'), findsOneWidget);
    expect(find.text('mayur.kumar@caglobal.com'), findsWidgets);
    expect(find.text('Select employee'), findsNothing);
  });
}

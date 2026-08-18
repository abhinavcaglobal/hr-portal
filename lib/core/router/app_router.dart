import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hr_portal/features/admin/presentation/admin_attendance_page.dart';
import 'package:hr_portal/features/admin/presentation/admin_dashboard_page.dart';
import 'package:hr_portal/features/admin/presentation/admin_leave_requests_page.dart';
import 'package:hr_portal/features/admin/presentation/admin_login_page.dart';
import 'package:hr_portal/features/admin/presentation/admin_settings_page.dart';
import 'package:hr_portal/features/admin/presentation/admin_upload_history_page.dart';
import 'package:hr_portal/features/admin/presentation/admin_upload_page.dart';
import 'package:hr_portal/features/admin/presentation/biometric_attendance_results_page.dart';
import 'package:hr_portal/features/admin/presentation/employee_emails_page.dart';
import 'package:hr_portal/features/auth/presentation/employee_auth_page.dart';
import 'package:hr_portal/features/dashboard/presentation/employee_dashboard_page.dart';
import 'package:hr_portal/features/holiday_calendar/presentation/holiday_calendar_page.dart';
import 'package:hr_portal/features/home/presentation/home_page.dart';
import 'package:hr_portal/features/login_hours/presentation/login_hours_page.dart';
import 'package:hr_portal/providers/admin_auth_providers.dart';
import 'package:hr_portal/providers/auth_providers.dart';
import 'package:hr_portal/core/router/app_route_guard.dart';

class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const login = '/login';
  static const attendanceLeaves = '/attendance-leaves';
  static const loginHours = '/attendance-leaves/login-hours';
  static const holidayCalendar = '/attendance-leaves/holiday-calendar';
  static const adminLogin = '/admin/login';
  static const adminDashboard = '/admin/dashboard';
  static const adminAttendance = '/admin/attendance';
  static const adminLeaveRequests = '/admin/leave-requests';
  static const adminUpload = '/admin/upload';
  static const adminUploadHistory = '/admin/upload-history';
  static const adminSettings = '/admin/settings';
  static const adminBiometricResults = '/admin/create-attendance/results';
  static const adminEmployeeEmails = '/admin/employee-emails';

  /// Legacy alias kept for compatibility.
  static const admin = adminDashboard;
  static const dashboard = attendanceLeaves;
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAdminAuthenticated = ref.read(adminAuthProvider);
      final authUser = ref.read(authStateProvider).valueOrNull;
      final isEmployeeSession = ref.read(isEmployeeSessionProvider);
      final employeeAsync = ref.read(currentEmployeeProvider);

      return AppRouteGuard.redirect(
        location: location,
        isAdminAuthenticated: isAdminAuthenticated,
        hasAuthUser: authUser != null,
        isEmployeeSession: isEmployeeSession,
        isEmployeeLoading: employeeAsync.isLoading,
        redirect: state.uri.queryParameters['redirect'],
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const EmployeeAuthPage(),
      ),
      GoRoute(
        path: AppRoutes.attendanceLeaves,
        builder: (context, state) => const EmployeeDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.loginHours,
        builder: (context, state) => const LoginHoursPage(),
      ),
      GoRoute(
        path: AppRoutes.holidayCalendar,
        builder: (context, state) => const HolidayCalendarPage(),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.adminAttendance,
        builder: (context, state) => const AdminAttendancePage(),
      ),
      GoRoute(
        path: AppRoutes.adminLeaveRequests,
        builder: (context, state) => const AdminLeaveRequestsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminUpload,
        builder: (context, state) => const AdminUploadPage(),
      ),
      GoRoute(
        path: AppRoutes.adminUploadHistory,
        builder: (context, state) => const AdminUploadHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => const AdminSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminBiometricResults,
        builder: (context, state) => const BiometricAttendanceResultsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminEmployeeEmails,
        builder: (context, state) => const EmployeeEmailsPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );

  ref.listen(adminAuthProvider, (_, __) => router.refresh());
  ref.listen(authStateProvider, (_, __) => router.refresh());
  ref.listen(currentEmployeeProvider, (_, __) => router.refresh());
  ref.onDispose(router.dispose);

  return router;
});

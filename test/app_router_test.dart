import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/router/app_route_guard.dart';

void main() {
  group('AppRouteGuard', () {
    test('redirects unauthenticated users from attendance to login', () {
      expect(
        AppRouteGuard.redirect(
          location: '/attendance-leaves',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/login',
      );
    });

    test('redirects authenticated employee away from login page', () {
      expect(
        AppRouteGuard.redirect(
          location: '/login',
          isAdminAuthenticated: false,
          hasAuthUser: true,
          isEmployeeSession: true,
          isEmployeeLoading: false,
        ),
        '/attendance-leaves',
      );
    });

    test('allows authenticated employee on attendance route', () {
      expect(
        AppRouteGuard.redirect(
          location: '/attendance-leaves',
          isAdminAuthenticated: false,
          hasAuthUser: true,
          isEmployeeSession: true,
          isEmployeeLoading: false,
        ),
        isNull,
      );
    });

    test('waits while employee profile is loading', () {
      expect(
        AppRouteGuard.redirect(
          location: '/attendance-leaves',
          isAdminAuthenticated: false,
          hasAuthUser: true,
          isEmployeeSession: false,
          isEmployeeLoading: true,
        ),
        isNull,
      );
    });

    test('redirects authed user without roster entry to login', () {
      expect(
        AppRouteGuard.redirect(
          location: '/attendance-leaves',
          isAdminAuthenticated: false,
          hasAuthUser: true,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/login',
      );
    });

    test('allows unauthenticated access to login hours', () {
      expect(
        AppRouteGuard.redirect(
          location: '/attendance-leaves/login-hours',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        isNull,
      );
    });

    test('protects holiday calendar for employee sessions', () {
      expect(
        AppRouteGuard.redirect(
          location: '/attendance-leaves/holiday-calendar',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/login',
      );
    });

    test('allows employees to view the holiday calendar', () {
      expect(
        AppRouteGuard.redirect(
          location: '/attendance-leaves/holiday-calendar',
          isAdminAuthenticated: false,
          hasAuthUser: true,
          isEmployeeSession: true,
          isEmployeeLoading: false,
        ),
        isNull,
      );
    });

    test('protects admin dashboard route', () {
      expect(
        AppRouteGuard.redirect(
          location: '/admin/dashboard',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/admin/login',
      );
    });

    test('redirects authenticated admin from login to dashboard', () {
      expect(
        AppRouteGuard.redirect(
          location: '/admin/login',
          isAdminAuthenticated: true,
          hasAuthUser: true,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/admin/dashboard',
      );
    });

    test('protects admin attendance and settings routes', () {
      expect(
        AppRouteGuard.redirect(
          location: '/admin/attendance',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/admin/login',
      );
      expect(
        AppRouteGuard.redirect(
          location: '/admin/settings',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/admin/login',
      );
      expect(
        AppRouteGuard.redirect(
          location: '/admin/upload-history',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/admin/login',
      );
      expect(
        AppRouteGuard.redirect(
          location: '/admin/upload',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/admin/login',
      );
    });

    test('protects admin employee emails route', () {
      expect(
        AppRouteGuard.redirect(
          location: '/admin/employee-emails',
          isAdminAuthenticated: false,
          hasAuthUser: false,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        '/admin/login',
      );
    });

    test('allows authenticated admin on employee emails route', () {
      expect(
        AppRouteGuard.redirect(
          location: '/admin/employee-emails',
          isAdminAuthenticated: true,
          hasAuthUser: true,
          isEmployeeSession: false,
          isEmployeeLoading: false,
        ),
        isNull,
      );
    });
  });
}

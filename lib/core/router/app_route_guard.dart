class AppRouteGuard {
  AppRouteGuard._();

  static const loginHoursRedirect = 'login-hours';

  static String? redirect({
    required String location,
    required bool isAdminAuthenticated,
    required bool hasAuthUser,
    required bool isEmployeeSession,
    required bool isEmployeeLoading,
    String? redirect,
  }) {
    if (location.startsWith('/admin') &&
        location != '/admin/login' &&
        !isAdminAuthenticated) {
      return '/admin/login';
    }

    if (location == '/admin/login' && isAdminAuthenticated) {
      return '/admin/dashboard';
    }

    if (location == '/admin') {
      return isAdminAuthenticated ? '/admin/dashboard' : '/admin/login';
    }

    if (location == '/attendance-leaves' && !hasAuthUser) {
      return '/login';
    }

    if (location == '/attendance-leaves' && hasAuthUser && !isEmployeeSession) {
      if (isEmployeeLoading) {
        return null;
      }
      return '/login';
    }

    if (location == '/attendance-leaves/holiday-calendar' &&
        (!hasAuthUser || !isEmployeeSession)) {
      if (hasAuthUser && isEmployeeLoading) {
        return null;
      }
      return '/login';
    }

    if (location == '/attendance-leaves/login-hours' &&
        (!hasAuthUser || !isEmployeeSession)) {
      if (hasAuthUser && isEmployeeLoading) {
        return null;
      }
      return '/login?redirect=$loginHoursRedirect';
    }

    if (location == '/login' && isEmployeeSession) {
      if (redirect == loginHoursRedirect) {
        return '/attendance-leaves/login-hours';
      }
      return '/attendance-leaves';
    }

    return null;
  }
}

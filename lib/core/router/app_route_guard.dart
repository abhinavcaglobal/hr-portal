class AppRouteGuard {
  AppRouteGuard._();

  static String? redirect({
    required String location,
    required bool isAdminAuthenticated,
    required bool hasAuthUser,
    required bool isEmployeeSession,
    required bool isEmployeeLoading,
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

    if (location == '/login' && isEmployeeSession) {
      return '/attendance-leaves';
    }

    return null;
  }
}

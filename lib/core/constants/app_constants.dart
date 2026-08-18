class AppConstants {
  AppConstants._();

  static const String appName = 'CA Global Leave Portal';
  static const String companyDomain = 'caglobal.com';
  static const String allowedEmailDomain = '@caglobal.com';
  static const String adminEmail = 'hr-india@caglobal.com';
  static const String indiaTeamEmail = 'indiateam@caglobal.com';

  /// HR admin display name in the employee roster (dual employee + admin role).
  static const String hrAdminEmployeeName = 'Ritu Sharma';

  /// Azure tenant ID for Microsoft sign-in (future). Use `organizations` for any work account.
  static const String microsoftTenantId = 'organizations';
  static const String adminPassword = 'Caglobal@1234';

  /// Default employee used when authentication is not enabled.
  static const String defaultEmployeeEmail = 'employee@caglobal.com';
  static const String defaultEmployeeName = 'Employee';

  static const String employeesCollection = 'employees';
  static const String employeesByEmailCollection = 'employees_by_email';
  static const String attendanceCollection = 'attendance';
  static const String loginHoursCollection = 'login_hours';
  static const String uploadHistoryCollection = 'upload_history';
  static const String holidayCalendarsCollection = 'holiday_calendars';
  static const String leaveRequestsCollection = 'leave_requests';
  static const String leaveRequestLocksCollection = 'leave_request_locks';

  /// Opening balance in the sheet is the balance through end of May.
  static const int openingBalanceAsOfMonth = 5;

  /// Monthly leave accrual begins each June (first month after opening balance).
  static const int leaveCycleStartMonth = 6;

  /// First year the uploaded opening balance applies (balance through May 2026).
  static const int firstAccrualYear = 2026;
}

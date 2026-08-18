import 'package:flutter/material.dart';
import 'package:hr_portal/core/router/app_router.dart';

enum AdminNavItem {
  dashboard,
  attendance,
  leaveRequests,
  employeeEmails,
  dataUpload,
  uploadHistory,
  settings,
}

extension AdminNavItemX on AdminNavItem {
  String get label => switch (this) {
    AdminNavItem.dashboard => 'Dashboard',
    AdminNavItem.attendance => 'Attendance',
    AdminNavItem.leaveRequests => 'Leave Requests',
    AdminNavItem.employeeEmails => 'Employee Emails',
    AdminNavItem.dataUpload => 'Data Upload',
    AdminNavItem.uploadHistory => 'Upload History',
    AdminNavItem.settings => 'Settings',
  };

  IconData get icon => switch (this) {
    AdminNavItem.dashboard => Icons.dashboard_outlined,
    AdminNavItem.attendance => Icons.calendar_month_outlined,
    AdminNavItem.leaveRequests => Icons.event_note_outlined,
    AdminNavItem.employeeEmails => Icons.email_outlined,
    AdminNavItem.dataUpload => Icons.cloud_upload_outlined,
    AdminNavItem.uploadHistory => Icons.history,
    AdminNavItem.settings => Icons.settings_outlined,
  };

  String get route => switch (this) {
    AdminNavItem.dashboard => AppRoutes.adminDashboard,
    AdminNavItem.attendance => AppRoutes.adminAttendance,
    AdminNavItem.leaveRequests => AppRoutes.adminLeaveRequests,
    AdminNavItem.employeeEmails => AppRoutes.adminEmployeeEmails,
    AdminNavItem.dataUpload => AppRoutes.adminUpload,
    AdminNavItem.uploadHistory => AppRoutes.adminUploadHistory,
    AdminNavItem.settings => AppRoutes.adminSettings,
  };
}

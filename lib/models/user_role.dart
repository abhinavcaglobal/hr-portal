import 'package:hr_portal/core/constants/app_constants.dart';

enum UserRole {
  admin,
  employee;

  bool get isAdmin => this == UserRole.admin;
}

extension UserRoleX on String? {
  UserRole toUserRole() {
    if (this?.toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
      return UserRole.admin;
    }
    return UserRole.employee;
  }
}

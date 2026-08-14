import 'package:hr_portal/core/constants/app_constants.dart';

class AdminAuthService {
  const AdminAuthService();

  bool validateCredentials({required String email, required String password}) {
    return email.trim().toLowerCase() ==
            AppConstants.adminEmail.toLowerCase() &&
        password == AppConstants.adminPassword;
  }
}

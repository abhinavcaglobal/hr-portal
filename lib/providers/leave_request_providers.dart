import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/models/leave_request.dart';
import 'package:hr_portal/providers/employee_providers.dart';
import 'package:hr_portal/providers/repository_providers.dart';

final employeeLeaveRequestsProvider = StreamProvider<List<LeaveRequest>>((ref) {
  final email = ref.watch(selectedEmployeeEmailProvider);
  if (email == null) {
    return Stream.value(const []);
  }
  return ref
      .watch(leaveRequestRepositoryProvider)
      .watchRequestsForEmployee(email);
});

final adminLeaveRequestsProvider = StreamProvider<List<LeaveRequest>>((ref) {
  return ref.watch(leaveRequestRepositoryProvider).watchAllRequests();
});

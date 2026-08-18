import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/models/leave_request.dart';
import 'package:hr_portal/repositories/attendance_repository.dart';
import 'package:hr_portal/repositories/leave_request_repository.dart';
import 'package:hr_portal/services/leave_calculation_service.dart';
import 'package:hr_portal/services/leave_request_rules.dart';

class LeaveRequestService {
  LeaveRequestService({
    required LeaveRequestRepository leaveRequestRepository,
    required AttendanceRepository attendanceRepository,
    LeaveCalculationService leaveCalculationService =
        const LeaveCalculationService(),
    LeaveRequestRules rules = const LeaveRequestRules(),
  }) : _leaveRequestRepository = leaveRequestRepository,
       _attendanceRepository = attendanceRepository,
       _leaveCalculationService = leaveCalculationService,
       _rules = rules;

  final LeaveRequestRepository _leaveRequestRepository;
  final AttendanceRepository _attendanceRepository;
  final LeaveCalculationService _leaveCalculationService;
  final LeaveRequestRules _rules;

  Future<void> submitRequest({
    required Employee employee,
    required DateTime leaveDate,
    required String leaveType,
    required String leaveDuration,
    String? halfDayType,
    String? fromTime,
    String? toTime,
    String? reason,
  }) async {
    _rules.validateSubmit(
      leaveType: leaveType,
      leaveDuration: leaveDuration,
      halfDayType: halfDayType,
      fromTime: fromTime,
      toTime: toTime,
    );

    final deduction = _rules.deductionFor(leaveDuration);
    final now = DateTime.now();
    final date = DateTime(leaveDate.year, leaveDate.month, leaveDate.day);

    await _leaveRequestRepository.createRequest(
      LeaveRequest(
        requestId: '',
        employeeId: employee.email.trim().toLowerCase(),
        employeeName: employee.name,
        leaveDate: date,
        leaveType: leaveType,
        leaveDuration: leaveDuration,
        leaveDeduction: deduction,
        halfDayType: leaveDuration == LeaveDuration.halfDay ? halfDayType : null,
        fromTime: leaveDuration == LeaveDuration.shortLeave ? fromTime : null,
        toTime: leaveDuration == LeaveDuration.shortLeave ? toTime : null,
        reason: reason?.trim().isEmpty == true ? null : reason?.trim(),
        status: LeaveRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<double> currentBalanceFor(Employee employee) async {
    final attendance = await _attendanceRepository
        .getAllAttendanceForEmployeeEmail(employee.email);
    return _leaveCalculationService.calculateCurrentBalance(
      openingBalance: employee.openingBalance,
      attendanceRecords: attendance,
    );
  }

  /// True when paid leave cannot cover this request (balance is zero, negative,
  /// or smaller than the requested deduction).
  Future<bool> shouldApproveAsUnpaid({
    required Employee employee,
    required LeaveRequest request,
  }) async {
    final balance = await currentBalanceFor(employee);
    return _rules.isUnpaidLeave(balance, request.leaveDeduction);
  }

  Future<LeaveRequestActionResult> approve({
    required LeaveRequest request,
    required String adminId,
    required Employee employee,
    String? adminComment,
    bool asUnpaid = false,
  }) async {
    final unpaid =
        asUnpaid ||
        await shouldApproveAsUnpaid(employee: employee, request: request);

    return _leaveRequestRepository.approveRequest(
      requestId: request.requestId,
      adminId: adminId,
      adminComment: adminComment,
      attendanceStatus: unpaid
          ? AttendanceStatus.unpaidLeave
          : _rules.attendanceStatusFor(request.leaveDuration),
      isUnpaid: unpaid,
      employeeNote: unpaid ? UnpaidLeave.employeeNote : null,
      paidDeduction: unpaid ? 0 : request.leaveDeduction,
    );
  }

  Future<void> decline({
    required LeaveRequest request,
    required String adminId,
    String? adminComment,
  }) {
    return _leaveRequestRepository.declineRequest(
      requestId: request.requestId,
      adminId: adminId,
      adminComment: adminComment,
    );
  }
}

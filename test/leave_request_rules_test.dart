import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/constants/attendance_status.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/services/leave_request_rules.dart';

void main() {
  const rules = LeaveRequestRules();

  group('LeaveRequestRules deductions', () {
    test('maps durations to existing attendance deductions', () {
      expect(rules.deductionFor(LeaveDuration.fullDay), 1.0);
      expect(rules.deductionFor(LeaveDuration.halfDay), 0.5);
      expect(rules.deductionFor(LeaveDuration.shortLeave), 0.25);
    });

    test('maps durations to attendance statuses used by leave balance', () {
      expect(rules.attendanceStatusFor(LeaveDuration.fullDay), AttendanceStatus.leave);
      expect(rules.attendanceStatusFor(LeaveDuration.halfDay), AttendanceStatus.halfLeave);
      expect(
        rules.attendanceStatusFor(LeaveDuration.shortLeave),
        AttendanceStatus.shortLeave,
      );
    });
  });

  group('calendar overlay labels', () {
    test('pending and approved use duration labels', () {
      expect(
        rules.calendarOverlayLabel(
          status: LeaveRequestStatus.pending,
          duration: LeaveDuration.fullDay,
        ),
        'Requested — Full Day',
      );
      expect(
        rules.calendarOverlayLabel(
          status: LeaveRequestStatus.approved,
          duration: LeaveDuration.halfDay,
        ),
        'Approved — Half Day',
      );
      expect(
        rules.calendarOverlayLabel(
          status: LeaveRequestStatus.approved,
          duration: LeaveDuration.shortLeave,
        ),
        'Approved — Short Leave',
      );
    });

    test('declined uses a single leave label', () {
      expect(
        rules.calendarOverlayLabel(
          status: LeaveRequestStatus.declined,
          duration: LeaveDuration.fullDay,
        ),
        'Declined — Leave',
      );
    });

    test('approved unpaid leave uses unpaid label', () {
      expect(
        rules.calendarOverlayLabel(
          status: LeaveRequestStatus.approved,
          duration: LeaveDuration.fullDay,
          isUnpaid: true,
        ),
        'Approved — Unpaid Leave',
      );
    });
  });

  group('unpaid leave threshold', () {
    test('treats zero, negative, or insufficient balance as unpaid', () {
      expect(rules.isUnpaidLeave(0, 1), isTrue);
      expect(rules.isUnpaidLeave(-11.25, 1), isTrue);
      expect(rules.isUnpaidLeave(0.5, 1), isTrue);
      expect(rules.isUnpaidLeave(5, 1), isFalse);
    });
  });

  group('validation', () {
    test('requires leave type and duration', () {
      expect(
        () => rules.validateSubmit(leaveType: '', leaveDuration: LeaveDuration.fullDay),
        throwsA(isA<LeaveRequestValidationException>()),
      );
      expect(
        () => rules.validateSubmit(leaveType: LeaveCategory.casual, leaveDuration: ''),
        throwsA(isA<LeaveRequestValidationException>()),
      );
    });

    test('requires half-day type', () {
      expect(
        () => rules.validateSubmit(
          leaveType: LeaveCategory.casual,
          leaveDuration: LeaveDuration.halfDay,
        ),
        throwsA(isA<LeaveRequestValidationException>()),
      );
      expect(
        () => rules.validateSubmit(
          leaveType: LeaveCategory.sick,
          leaveDuration: LeaveDuration.halfDay,
          halfDayType: HalfDayType.firstHalf,
        ),
        returnsNormally,
      );
    });

    test('requires short-leave times and from < to', () {
      expect(
        () => rules.validateSubmit(
          leaveType: LeaveCategory.casual,
          leaveDuration: LeaveDuration.shortLeave,
        ),
        throwsA(isA<LeaveRequestValidationException>()),
      );
      expect(
        () => rules.validateSubmit(
          leaveType: LeaveCategory.casual,
          leaveDuration: LeaveDuration.shortLeave,
          fromTime: '16:00',
          toTime: '16:00',
        ),
        throwsA(isA<LeaveRequestValidationException>()),
      );
      expect(
        () => rules.validateSubmit(
          leaveType: LeaveCategory.casual,
          leaveDuration: LeaveDuration.shortLeave,
          fromTime: '16:00',
          toTime: '18:00',
        ),
        returnsNormally,
      );
    });
  });
}

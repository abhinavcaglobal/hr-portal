/// Leave request statuses, durations, and category labels.
///
/// Duration values map to existing attendance deductions (L / HL / SL).
/// Category types (Casual / Sick) did not exist in the app; they are the
/// HR leave categories used on requests and are independent of duration.
class LeaveRequestStatus {
  LeaveRequestStatus._();

  static const pending = 'PENDING';
  static const approved = 'APPROVED';
  static const declined = 'DECLINED';

  static const all = [pending, approved, declined];

  static String label(String status) => switch (status) {
    pending => 'Pending',
    approved => 'Approved',
    declined => 'Declined',
    _ => status,
  };
}

class LeaveDuration {
  LeaveDuration._();

  static const fullDay = 'FULL_DAY';
  static const halfDay = 'HALF_DAY';
  static const shortLeave = 'SHORT_LEAVE';

  static const all = [fullDay, halfDay, shortLeave];

  static const Map<String, double> deductions = {
    fullDay: 1.0,
    halfDay: 0.5,
    shortLeave: 0.25,
  };

  static const Map<String, String> labels = {
    fullDay: 'Full Day Leave',
    halfDay: 'Half Day Leave',
    shortLeave: 'Short Leave',
  };

  static const Map<String, String> shortLabels = {
    fullDay: 'Full Day',
    halfDay: 'Half Day',
    shortLeave: 'Short Leave',
  };

  static double deductionFor(String duration) {
    final value = deductions[duration];
    if (value == null || value <= 0) {
      throw ArgumentError('Invalid leave duration: $duration');
    }
    return value;
  }
}

class HalfDayType {
  HalfDayType._();

  static const firstHalf = 'FIRST_HALF';
  static const secondHalf = 'SECOND_HALF';

  static const all = [firstHalf, secondHalf];

  static const Map<String, String> labels = {
    firstHalf: 'First Half',
    secondHalf: 'Second Half',
  };
}

class LeaveCategory {
  LeaveCategory._();

  static const casual = 'Casual Leave';
  static const sick = 'Sick Leave';

  static const all = [casual, sick];
}

class UnpaidLeave {
  UnpaidLeave._();

  static const employeeNote = 'Unpaid Leave';
}

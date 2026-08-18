class AttendanceStatus {
  AttendanceStatus._();

  static const String present = 'P';
  static const String latePunch = 'LP';
  static const String leave = 'L';
  static const String halfLeave = 'HL';
  static const String shortLeave = 'SL';
  static const String unpaidLeave = 'UL';
  static const String absent = 'A';
  static const String wfh = 'WFH';

  static const Map<String, String> labels = {
    present: 'Present',
    latePunch: 'Late Punch',
    absent: 'Absent',
    wfh: 'Work From Home',
    leave: 'Leave',
    halfLeave: 'Half Leave',
    shortLeave: 'Short Leave',
    unpaidLeave: 'Unpaid Leave',
  };

  static const Map<String, int> _severity = {
    present: 0,
    wfh: 0,
    latePunch: 1,
    shortLeave: 2,
    halfLeave: 3,
    unpaidLeave: 4,
    absent: 4,
    leave: 4,
  };

  static const Map<String, double> leaveDeductions = {
    present: 0,
    latePunch: 0,
    wfh: 0,
    leave: 1.0,
    halfLeave: 0.5,
    shortLeave: 0.25,
    unpaidLeave: 0,
    absent: 1.0,
  };

  static double deductionFor(String status) =>
      leaveDeductions[status.toUpperCase()] ?? 0;

  static String moreSevere(String a, String b) {
    final severityA = _severity[a.toUpperCase()] ?? 0;
    final severityB = _severity[b.toUpperCase()] ?? 0;
    return severityA >= severityB ? a.toUpperCase() : b.toUpperCase();
  }
}

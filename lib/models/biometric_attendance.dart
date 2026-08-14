class BiometricPunch {
  const BiometricPunch({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.time,
    required this.isIn,
    required this.isOut,
  });

  final String employeeId;
  final String employeeName;
  final DateTime date;
  final String time;
  final bool isIn;
  final bool isOut;
}

class BiometricDailyAttendance {
  const BiometricDailyAttendance({
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.status,
    this.firstIn,
    this.lastOut,
  });

  final String employeeId;
  final String employeeName;
  final DateTime date;
  final String status;
  final String? firstIn;
  final String? lastOut;

  bool get isLeave => status == 'L';
  bool get isWeekOff => status == 'weekoff';
  bool get isPresent => status == 'P';
  bool get isAbsent => status == 'A';
  bool get isWfh => status.toUpperCase() == 'WFH';
}

class BiometricProcessResult {
  const BiometricProcessResult({
    required this.fileName,
    required this.periodStart,
    required this.periodEnd,
    required this.records,
  });

  final String fileName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<BiometricDailyAttendance> records;

  int get absentCount => records.where((record) => record.isAbsent).length;
  int get leaveCount => records.where((record) => record.isLeave).length;
  int get weekOffCount => records.where((record) => record.isWeekOff).length;
  int get presentCount => records.where((record) => record.isPresent).length;
}

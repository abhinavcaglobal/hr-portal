/// Documents the wide-matrix attendance sheet layout used by HR.
///
/// ```
/// Row 1: S.no | June      | 1  | 2  | 3  | ...  (month name + day numbers)
/// Row 2:      | EMPLOYEE NAME | Mon | Tue | Wed | ...  (weekday labels)
/// Row 3+: 1   | Mayur Kumar   | P  | P  | L  | ...
/// ```
///
/// - Data is read **by row** (one employee per row).
/// - Days are **columns** starting at column C (index 2).
/// - Status codes: P, L, HL, SL. Weekends/off days use "-" and are skipped.
class AttendanceSheetFormat {
  AttendanceSheetFormat._();

  static const int headerRowIndex = 0;
  static const int weekdayRowIndex = 1;
  static const int firstDataRowIndex = 2;
  static const int serialColumnIndex = 0;
  static const int employeeNameColumnIndex = 1;
  static const int firstDayColumnIndex = 2;

  static const Set<String> validStatuses = {'P', 'L', 'HL', 'SL', 'WFH'};
  static const Set<String> skipStatuses = {'-', '—', ''};
}

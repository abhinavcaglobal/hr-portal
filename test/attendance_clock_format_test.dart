import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/core/utils/attendance_clock_format.dart';

void main() {
  test('formats 24-hour punch times as AM and PM', () {
    expect(formatAttendanceClock('11:00'), '11:00 AM');
    expect(formatAttendanceClock('21:00'), '9:00 PM');
    expect(formatAttendanceClock('00:05'), '12:05 AM');
    expect(formatAttendanceClock('12:00'), '12:00 PM');
    expect(formatAttendanceClock('13:06'), '1:06 PM');
    expect(formatAttendanceClock('09:15:30'), '9:15 AM');
  });

  test('leaves blank punch times blank', () {
    expect(formatAttendanceClock(null), '');
    expect(formatAttendanceClock(''), '');
    expect(formatAttendanceClock('-'), '');
  });

  test('normalizes a time that is already AM or PM', () {
    expect(formatAttendanceClock('9:00 pm'), '9:00 PM');
    expect(formatAttendanceClock('11:00 AM'), '11:00 AM');
  });
}

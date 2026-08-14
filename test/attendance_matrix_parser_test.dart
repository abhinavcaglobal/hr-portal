import 'package:flutter_test/flutter_test.dart';
import 'package:hr_portal/services/attendance_matrix_parser.dart';

void main() {
  const parser = AttendanceMatrixParser(year: 2025);

  final sampleSheet = [
    ['S.no', 'June', '1', '2', '3', '4', '5', '6', '7'],
    ['', 'EMPLOYEE NAME', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    ['1', 'Mayur Kumar', 'P', 'P', 'L', 'P', 'P', '-', '-'],
    ['2', 'Sukhwinder Kaur', 'P', 'HL', 'P', 'SL', 'P', '-', '-'],
  ];

  test('parses wide matrix attendance sheet', () {
    final result = parser.parse(sampleSheet);

    expect(result.month, 6);
    expect(result.year, 2025);
    expect(result.records.length, 10);

    final mayurDay1 = result.records.firstWhere(
      (r) => r.employeeName == 'Mayur Kumar' && r.day == 1,
    );
    expect(mayurDay1.status, 'P');
    expect(mayurDay1.dateKey, '2025-06-01');

    final mayurDay3 = result.records.firstWhere(
      (r) => r.employeeName == 'Mayur Kumar' && r.day == 3,
    );
    expect(mayurDay3.status, 'L');
  });

  test('skips weekend dash cells', () {
    final result = parser.parse(sampleSheet);
    expect(
      result.records.any((r) => r.employeeName == 'Mayur Kumar' && r.day == 6),
      isFalse,
    );
  });

  test('parses HL and SL statuses', () {
    final result = parser.parse(sampleSheet);
    expect(
      result.records.any(
        (r) => r.employeeName == 'Sukhwinder Kaur' && r.status == 'HL',
      ),
      isTrue,
    );
    expect(
      result.records.any(
        (r) => r.employeeName == 'Sukhwinder Kaur' && r.status == 'SL',
      ),
      isTrue,
    );
  });
}

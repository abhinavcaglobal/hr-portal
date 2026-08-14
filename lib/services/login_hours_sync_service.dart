import 'package:hr_portal/models/biometric_attendance.dart';
import 'package:hr_portal/models/login_hours_record.dart';
import 'package:hr_portal/services/attendance_status_calculator.dart';

class LoginHoursSyncService {
  const LoginHoursSyncService({
    this.statusCalculator = const AttendanceStatusCalculator(),
  });

  final AttendanceStatusCalculator statusCalculator;

  LoginHoursSyncDecision decide({
    LoginHoursRecord? existing,
    required BiometricDailyAttendance incoming,
  }) {
    if (existing == null) {
      return LoginHoursSyncDecision(
        action: LoginHoursSyncAction.create,
        record: LoginHoursRecord.fromBiometric(incoming),
      );
    }

    if (existing.manuallyEdited) {
      return const LoginHoursSyncDecision(action: LoginHoursSyncAction.skip);
    }

    if (existing.hasCompleteOut) {
      return _widenSpan(existing: existing, incoming: incoming);
    }

    final uploadedOut = incoming.lastOut?.trim();
    if (uploadedOut != null && uploadedOut.isNotEmpty) {
      final status = statusCalculator.calculate(
        firstIn: existing.firstIn,
        lastOut: uploadedOut,
      );
      return LoginHoursSyncDecision(
        action: LoginHoursSyncAction.updateOutOnly,
        record: existing.copyWith(lastOut: uploadedOut, status: status),
      );
    }

    return const LoginHoursSyncDecision(action: LoginHoursSyncAction.skip);
  }

  /// Corrects a stored day when a re-upload proves the working span was wider
  /// than what is saved — for example when the original upload was a mid-day
  /// export, or when a mis-tagged closing punch shortened the day.
  ///
  /// The span is only ever widened, so a partial re-upload can never shorten a
  /// day that is already complete.
  LoginHoursSyncDecision _widenSpan({
    required LoginHoursRecord existing,
    required BiometricDailyAttendance incoming,
  }) {
    final firstIn = _earlier(existing.firstIn, incoming.firstIn);
    final lastOut = _later(existing.lastOut, incoming.lastOut);

    if (firstIn == existing.firstIn && lastOut == existing.lastOut) {
      return const LoginHoursSyncDecision(action: LoginHoursSyncAction.skip);
    }

    final status = statusCalculator.calculate(
      firstIn: firstIn,
      lastOut: lastOut,
    );

    return LoginHoursSyncDecision(
      action: LoginHoursSyncAction.correctSpan,
      record: existing.copyWith(
        firstIn: firstIn,
        lastOut: lastOut,
        status: status,
      ),
    );
  }

  String? _earlier(String? current, String? candidate) {
    final currentMinutes = statusCalculator.timeToMinutes(current);
    final candidateMinutes = statusCalculator.timeToMinutes(candidate);
    if (candidateMinutes == null) return current;
    if (currentMinutes == null) return candidate!.trim();
    return candidateMinutes < currentMinutes ? candidate!.trim() : current;
  }

  String? _later(String? current, String? candidate) {
    final currentMinutes = statusCalculator.timeToMinutes(current);
    final candidateMinutes = statusCalculator.timeToMinutes(candidate);
    if (candidateMinutes == null) return current;
    if (currentMinutes == null) return candidate!.trim();
    return candidateMinutes > currentMinutes ? candidate!.trim() : current;
  }
}

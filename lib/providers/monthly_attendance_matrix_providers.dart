import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/employee_list.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/attendance_month_note.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/monthly_attendance_excel_exporter.dart';
import 'package:hr_portal/services/monthly_attendance_matrix_builder.dart';

class SelectedAttendanceMonth {
  const SelectedAttendanceMonth({required this.year, required this.month});

  final int year;
  final int month;

  SelectedAttendanceMonth copyWith({int? year, int? month}) {
    return SelectedAttendanceMonth(
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectedAttendanceMonth &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}

final selectedMonthlyAttendanceMonthProvider =
    StateProvider<SelectedAttendanceMonth>((ref) {
      final now = DateTime.now();
      return SelectedAttendanceMonth(year: now.year, month: now.month);
    });

final monthlyAttendanceMatrixBuilderProvider =
    Provider<MonthlyAttendanceMatrixBuilder>((ref) {
      return const MonthlyAttendanceMatrixBuilder();
    });

final monthlyAttendanceExcelExporterProvider =
    Provider<MonthlyAttendanceExcelExporter>((ref) {
      return const MonthlyAttendanceExcelExporter();
    });

final monthlyAttendanceMatrixProvider =
    FutureProvider<MonthlyAttendanceMatrix>((ref) async {
      final selected = ref.watch(selectedMonthlyAttendanceMonthProvider);
      final attendanceRepo = ref.watch(attendanceRepositoryProvider);
      final notesRepo = ref.watch(attendanceMonthNotesRepositoryProvider);
      final employeeRepo = ref.watch(employeeRepositoryProvider);
      final loginHoursRepo = ref.watch(loginHoursRepositoryProvider);
      final calendarSync = ref.watch(biometricCalendarSyncServiceProvider);
      final builder = ref.watch(monthlyAttendanceMatrixBuilderProvider);

      // Persist calculated P/A/LP/HL/SL/WFH from login hours into attendance so
      // the grid (and Firebase) stay complete even before a fresh biometric upload.
      try {
        final monthStart = DateTime(selected.year, selected.month, 1);
        final monthEnd = DateTime(selected.year, selected.month + 1, 0);
        final loginHours = await loginHoursRepo.getRecordsForDateRange(
          start: monthStart,
          end: monthEnd,
        );
        if (loginHours.isNotEmpty) {
          await calendarSync.syncFromLoginHours(loginHours);
        }
      } catch (_) {
        // Grid can still render from whatever attendance docs already exist.
      }

      final records = await attendanceRepo.getAttendanceForMonthAll(
        year: selected.year,
        month: selected.month,
      );

      List<AttendanceMonthNote> notes = const [];
      try {
        notes = await notesRepo.getNotesForMonth(
          year: selected.year,
          month: selected.month,
        );
      } catch (_) {
        notes = const [];
      }

      var emailByName = <String, String>{};
      try {
        final employees = await employeeRepo.getAllEmployees();
        emailByName = {
          for (final employee in employees)
            if (employee.email.trim().isNotEmpty) employee.name: employee.email,
        };
      } catch (_) {
        emailByName = const {};
      }

      return builder.build(
        year: selected.year,
        month: selected.month,
        employeeNames: EmployeeList.names,
        records: records,
        notes: notes,
        emailByEmployeeName: emailByName,
      );
    });

class MonthlyAttendanceEditController
    extends StateNotifier<AsyncValue<void>> {
  MonthlyAttendanceEditController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> updateStatus({
    required String employeeName,
    String? employeeEmail,
    required DateTime date,
    required String status,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _ref
          .read(attendanceRepositoryProvider)
          .upsertAttendanceStatus(
            employeeName: employeeName,
            employeeEmail: employeeEmail,
            date: date,
            status: status,
          );
      _ref.invalidate(monthlyAttendanceMatrixProvider);
    });
  }

  Future<void> updateNotes({
    required String employeeName,
    String? employeeEmail,
    required int year,
    required int month,
    required String remarks,
    required String reference,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _ref
          .read(attendanceMonthNotesRepositoryProvider)
          .upsertNote(
            AttendanceMonthNote(
              employeeName: employeeName,
              employeeEmail: employeeEmail,
              year: year,
              month: month,
              remarks: remarks,
              reference: reference,
            ),
          );
      _ref.invalidate(monthlyAttendanceMatrixProvider);
    });
  }
}

final monthlyAttendanceEditControllerProvider =
    StateNotifierProvider<MonthlyAttendanceEditController, AsyncValue<void>>((
      ref,
    ) {
      return MonthlyAttendanceEditController(ref);
    });

String monthlyAttendanceErrorMessage(Object error) {
  if (error is AppException) return error.message;
  return error.toString();
}

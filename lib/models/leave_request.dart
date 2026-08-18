import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';

class LeaveRequest {
  const LeaveRequest({
    required this.requestId,
    required this.employeeId,
    required this.employeeName,
    required this.leaveDate,
    required this.leaveType,
    required this.leaveDuration,
    required this.leaveDeduction,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.halfDayType,
    this.fromTime,
    this.toTime,
    this.reason,
    this.actionBy,
    this.actionAt,
    this.adminComment,
    this.isUnpaid = false,
    this.employeeNote,
    this.paidDeduction,
  });

  final String requestId;
  /// Authenticated employee email (stable identifier in this app).
  final String employeeId;
  final String employeeName;
  final DateTime leaveDate;
  final String leaveType;
  final String leaveDuration;
  final double leaveDeduction;
  final String? halfDayType;
  final String? fromTime;
  final String? toTime;
  final String? reason;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? actionBy;
  final DateTime? actionAt;
  final String? adminComment;
  final bool isUnpaid;
  final String? employeeNote;
  /// Amount actually deducted from paid leave. Zero when recorded as unpaid.
  final double? paidDeduction;

  String get employeeEmail => employeeId;

  factory LeaveRequest.fromMap(Map<String, dynamic> map, String id) {
    return LeaveRequest(
      requestId: map['requestId'] as String? ?? id,
      employeeId: (map['employeeId'] as String? ??
              map['employeeEmail'] as String? ??
              '')
          .trim()
          .toLowerCase(),
      employeeName: map['employeeName'] as String? ?? '',
      leaveDate: _parseDate(map['leaveDate']),
      leaveType: map['leaveType'] as String? ?? '',
      leaveDuration: map['leaveDuration'] as String? ?? '',
      leaveDeduction: _toDouble(map['leaveDeduction']),
      halfDayType: map['halfDayType'] as String?,
      fromTime: map['fromTime'] as String?,
      toTime: map['toTime'] as String?,
      reason: map['reason'] as String?,
      status: (map['status'] as String? ?? LeaveRequestStatus.pending)
          .toUpperCase(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      actionBy: map['actionBy'] as String?,
      actionAt: map['actionAt'] == null ? null : _parseDateTime(map['actionAt']),
      adminComment: map['adminComment'] as String?,
      isUnpaid: map['isUnpaid'] == true,
      employeeNote: map['employeeNote'] as String?,
      paidDeduction: map['paidDeduction'] == null
          ? null
          : _toDouble(map['paidDeduction']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'employeeId': employeeId.trim().toLowerCase(),
      'employeeEmail': employeeId.trim().toLowerCase(),
      'employeeName': employeeName,
      'leaveDate': formatDate(leaveDate),
      'leaveType': leaveType,
      'leaveDuration': leaveDuration,
      'leaveDeduction': leaveDeduction,
      'halfDayType': halfDayType,
      'fromTime': fromTime,
      'toTime': toTime,
      'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'actionBy': actionBy,
      'actionAt': actionAt == null ? null : Timestamp.fromDate(actionAt!),
      'adminComment': adminComment,
      'isUnpaid': isUnpaid,
      'employeeNote': employeeNote,
      'paidDeduction': paidDeduction,
    };
  }

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }
    if (value is Timestamp) {
      final d = value.toDate();
      return DateTime(d.year, d.month, d.day);
    }
    if (value is String) {
      final parts = value.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    }
    return DateTime.now();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_portal/core/constants/leave_request_constants.dart';
import 'package:hr_portal/core/errors/app_exception.dart';
import 'package:hr_portal/models/employee.dart';
import 'package:hr_portal/providers/repository_providers.dart';
import 'package:hr_portal/services/leave_request_rules.dart';
import 'package:intl/intl.dart';

class ApplyLeaveDialog extends ConsumerStatefulWidget {
  const ApplyLeaveDialog({
    super.key,
    required this.employee,
    required this.leaveDate,
  });

  final Employee employee;
  final DateTime leaveDate;

  static Future<bool?> show(
    BuildContext context, {
    required Employee employee,
    required DateTime leaveDate,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          ApplyLeaveDialog(employee: employee, leaveDate: leaveDate),
    );
  }

  @override
  ConsumerState<ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends ConsumerState<ApplyLeaveDialog> {
  static const _rules = LeaveRequestRules();

  String? _leaveType;
  String? _duration;
  String? _halfDayType;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;
  final _reasonController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool from}) async {
    final initial = from
        ? (_fromTime ?? const TimeOfDay(hour: 16, minute: 0))
        : (_toTime ?? const TimeOfDay(hour: 18, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (from) {
        _fromTime = picked;
      } else {
        _toTime = picked;
      }
    });
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) return 'Select time';
    return _rules.formatTimeOfDay(time.hour, time.minute);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    try {
      _rules.validateSubmit(
        leaveType: _leaveType ?? '',
        leaveDuration: _duration ?? '',
        halfDayType: _halfDayType,
        fromTime: _fromTime == null ? null : _timeLabel(_fromTime),
        toTime: _toTime == null ? null : _timeLabel(_toTime),
      );
    } on LeaveRequestValidationException catch (e) {
      setState(() => _error = e.message);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(leaveRequestServiceProvider)
          .submitRequest(
            employee: widget.employee,
            leaveDate: widget.leaveDate,
            leaveType: _leaveType!,
            leaveDuration: _duration!,
            halfDayType: _halfDayType,
            fromTime: _fromTime == null ? null : _timeLabel(_fromTime),
            toTime: _toTime == null ? null : _timeLabel(_toTime),
            reason: _reasonController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = DataException.fromUnknown(e).message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(widget.leaveDate);

    return AlertDialog(
      title: const Text('Apply Leave'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Date',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event),
                ),
                child: Text(dateLabel),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _leaveType,
                decoration: const InputDecoration(labelText: 'Leave Type'),
                items: LeaveCategory.all
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _leaveType = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _duration,
                decoration: const InputDecoration(labelText: 'Leave Duration'),
                items: LeaveDuration.all
                    .map(
                      (duration) => DropdownMenuItem(
                        value: duration,
                        child: Text(
                          '${LeaveDuration.labels[duration]} '
                          '(${LeaveDuration.deductions[duration]!.toStringAsFixed(2)})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _duration = value;
                  if (value != LeaveDuration.halfDay) _halfDayType = null;
                  if (value != LeaveDuration.shortLeave) {
                    _fromTime = null;
                    _toTime = null;
                  }
                }),
              ),
              if (_duration == LeaveDuration.halfDay) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _halfDayType,
                  decoration: const InputDecoration(labelText: 'Half'),
                  items: HalfDayType.all
                      .map(
                        (half) => DropdownMenuItem(
                          value: half,
                          child: Text(HalfDayType.labels[half]!),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _halfDayType = value),
                ),
              ],
              if (_duration == LeaveDuration.shortLeave) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(from: true),
                        icon: const Icon(Icons.schedule),
                        label: Text('From: ${_timeLabel(_fromTime)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(from: false),
                        icon: const Icon(Icons.schedule),
                        label: Text('To: ${_timeLabel(_toTime)}'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason / Comment (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Apply Leave'),
        ),
      ],
    );
  }
}

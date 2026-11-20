import 'package:timezone/timezone.dart' as tz;

import '../../data/models/leave_request_model.dart';

class LeaveValidationException implements Exception {
  final String message;

  const LeaveValidationException(this.message);

  @override
  String toString() => message;
}

class LeaveValidationService {
  void validate({
    required String type,
    required String startDate,
    required String endDate,
    required String reason,
    required int availableBalance,
    required List<LeaveRequestModel> existingRequests,
    required String timezone,
  }) {
    if (!['Casual', 'Sick'].contains(type)) {
      throw const LeaveValidationException('Please select a valid leave type.');
    }

    final start = _parseDate(startDate);
    final end = _parseDate(endDate);

    if (start == null || end == null) {
      throw const LeaveValidationException('Please select valid leave dates.');
    }

    final companyToday = tz.TZDateTime.now(tz.getLocation(timezone));

    final today = DateTime.utc(
      companyToday.year,
      companyToday.month,
      companyToday.day,
    );

    final startUtc = DateTime.utc(start.year, start.month, start.day);

    final endUtc = DateTime.utc(end.year, end.month, end.day);

    if (startUtc.isBefore(today)) {
      throw const LeaveValidationException(
        'Leave cannot be requested for past dates.',
      );
    }

    if (endUtc.isBefore(startUtc)) {
      throw const LeaveValidationException(
        'End date cannot be before start date.',
      );
    }

    if (reason.trim().length < 10) {
      throw const LeaveValidationException(
        'Reason must contain at least 10 characters.',
      );
    }

    final requestedDays = endUtc.difference(startUtc).inDays + 1;

    if (requestedDays > availableBalance) {
      throw const LeaveValidationException(
        'Requested leave exceeds your available balance.',
      );
    }

    final hasOverlap = existingRequests.any((request) {
      if (!['Pending', 'Approved'].contains(request.status)) {
        return false;
      }

      final existingStart = _parseDate(request.startDate);
      final existingEnd = _parseDate(request.endDate);

      if (existingStart == null || existingEnd == null) {
        return false;
      }

      final existingStartUtc = DateTime.utc(
        existingStart.year,
        existingStart.month,
        existingStart.day,
      );

      final existingEndUtc = DateTime.utc(
        existingEnd.year,
        existingEnd.month,
        existingEnd.day,
      );

      return !startUtc.isAfter(existingEndUtc) &&
          !endUtc.isBefore(existingStartUtc);
    });

    if (hasOverlap) {
      throw const LeaveValidationException(
        'These dates overlap with an existing pending or approved leave.',
      );
    }
  }

  DateTime? _parseDate(String value) {
    try {
      final parsed = DateTime.parse(value);

      // Require a date-only value in YYYY-MM-DD format.
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
        return null;
      }

      if (parsed.toIso8601String().substring(0, 10) != value) {
        return null;
      }

      return parsed;
    } catch (_) {
      return null;
    }
  }

  int calculateDays(String startDate, String endDate) {
    final start = _parseDate(startDate);
    final end = _parseDate(endDate);

    if (start == null || end == null || end.isBefore(start)) {
      return 0;
    }

    final startUtc = DateTime.utc(start.year, start.month, start.day);
    final endUtc = DateTime.utc(end.year, end.month, end.day);

    return endUtc.difference(startUtc).inDays + 1;
  }
}

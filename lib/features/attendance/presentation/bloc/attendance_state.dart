import 'package:equatable/equatable.dart';

import '../../data/models/attendance_event_model.dart';

class AttendanceState extends Equatable {
  final bool isLoading;
  final List<AttendanceEventModel> events;
  final String? message;
  final String? error;

  const AttendanceState({
    this.isLoading = false,
    this.events = const [],
    this.message,
    this.error,
  });

  AttendanceState copyWith({
    bool? isLoading,
    List<AttendanceEventModel>? events,
    String? message,
    String? error,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      message: clearMessage ? null : message ?? this.message,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [isLoading, events, message, error];
}

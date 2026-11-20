import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/attendance_local_datasource.dart';
import '../../data/models/attendance_event_model.dart';
import '../../domain/services/attendance_action_service.dart';
import '../../domain/services/attendance_sync_service.dart';
import '../../../dashboard/data/models/employee_model.dart';

import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceActionService actionService;
  final AttendanceLocalDataSource localDataSource;
  final AttendanceSyncService syncService;
  final EmployeeModel employee;

  AttendanceBloc({
    required this.actionService,
    required this.localDataSource,
    required this.syncService,
    required this.employee,
  }) : super(const AttendanceState()) {
    on<AttendanceLoadRequested>(_onLoad);
    on<AttendanceCheckInRequested>(_onCheckIn);
    on<AttendanceCheckOutRequested>(_onCheckOut);
    on<AttendanceSyncRequested>(_onSync);
  }

  Future<void> _onLoad(
    AttendanceLoadRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final events = await localDataSource.getAllEvents();

      emit(state.copyWith(isLoading: false, events: events));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Unable to load attendance: $e',
        ),
      );
    }
  }

  Future<void> _onCheckIn(
    AttendanceCheckInRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    await _recordAttendance(AttendanceEventType.checkIn, emit);
  }

  Future<void> _onCheckOut(
    AttendanceCheckOutRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    await _recordAttendance(AttendanceEventType.checkOut, emit);
  }

  Future<void> _recordAttendance(
    AttendanceEventType type,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));

    try {
      await actionService.recordAttendance(eventType: type, employee: employee);

      final syncResult = await syncService.syncPendingEvents();

      final events = await localDataSource.getAllEvents();

      emit(
        state.copyWith(
          isLoading: false,
          events: events,
          message: syncResult.rejectionReason != null
              ? 'Attendance rejected: ${syncResult.rejectionReason}'
              : syncResult.synced > 0
              ? 'Attendance recorded and synced successfully.'
              : 'Attendance saved locally. Waiting to sync.',
        ),
      );
    } catch (e) {
      final events = await localDataSource.getAllEvents();

      emit(
        state.copyWith(
          isLoading: false,
          events: events,
          error: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSync(
    AttendanceSyncRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearError: true, clearMessage: true));

    try {
      final result = await syncService.syncPendingEvents();
      final events = await localDataSource.getAllEvents();

      final rejectedEvent = events
          .where((e) => e.syncStatus == SyncStatus.rejected)
          .lastOrNull;

      String message;

      if (result.rejectionReason != null) {
        message = 'Attendance rejected: ${result.rejectionReason}';
      } else if (result.rejected > 0) {
        message = 'Attendance sync rejected.';
      } else if (result.synced == 0 &&
          result.pending == 0 &&
          rejectedEvent != null) {
        message =
            'Previous attendance rejection: '
            '${rejectedEvent.lastError ?? 'Server rejected the event.'}';
      } else if (result.synced == 0 && result.pending == 0) {
        message = 'No pending attendance events to sync.';
      } else {
        message =
            'Sync complete: ${result.synced} synced, '
            '${result.rejected} rejected, '
            '${result.pending} pending.';
      }

      emit(state.copyWith(isLoading: false, events: events, message: message));
    } catch (e) {
      final events = await localDataSource.getAllEvents();

      emit(
        state.copyWith(
          isLoading: false,
          events: events,
          error: 'Sync failed: $e',
        ),
      );
    }
  }
}

import 'package:dio/dio.dart';

import '../../data/datasources/attendance_local_datasource.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/models/attendance_event_model.dart';

class AttendanceSyncResult {
  final int synced;
  final int rejected;
  final int pending;
  final String? rejectionReason;

  const AttendanceSyncResult({
    required this.synced,
    required this.rejected,
    required this.pending,
    this.rejectionReason,
  });
}

class AttendanceSyncService {
  final AttendanceLocalDataSource localDataSource;
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceSyncService({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  Future<AttendanceSyncResult> syncPendingEvents() async {
    var synced = 0;
    var rejected = 0;
    String? rejectionReason;

    final pendingEvents = await localDataSource.getPendingEvents();

    for (final event in pendingEvents) {
      try {
        await localDataSource.incrementAttemptCount(event.eventId);

        await remoteDataSource.submitEvent(event);

        await localDataSource.updateEventStatus(
          eventId: event.eventId,
          status: SyncStatus.synced,
        );

        synced++;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          final rejectionReasonFromServer = e.response?.data is Map
              ? e.response?.data['message']?.toString()
              : null;

          rejectionReason =
              rejectionReasonFromServer ?? 'Server rejected attendance event.';

          await localDataSource.updateEventStatus(
            eventId: event.eventId,
            status: SyncStatus.rejected,
            error: rejectionReason,
          );

          rejected++;
          break;
        } else {
      
          await localDataSource.updateEventStatus(
            eventId: event.eventId,
            status: SyncStatus.pending,
            error: e.message ?? 'Network error during sync.',
          );

          break;
        }
      } catch (e) {
        await localDataSource.updateEventStatus(
          eventId: event.eventId,
          status: SyncStatus.pending,
          error: e.toString(),
        );

        break;
      }
    }

    final remainingEvents = await localDataSource.getPendingEvents();

    return AttendanceSyncResult(
      synced: synced,
      rejected: rejected,
      pending: remainingEvents.length,
      rejectionReason: rejectionReason,
    );
  }
}

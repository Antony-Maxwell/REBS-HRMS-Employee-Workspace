import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../dashboard/data/models/employee_model.dart';
import '../../data/datasources/attendance_local_datasource.dart';
import '../../data/models/attendance_event_model.dart';
import '../../domain/services/attendance_sync_service.dart';
import '../../domain/services/attendance_action_service.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';

const Color _navy = Color(0xFF172554);
const Color _indigo = Color(0xFF4F46E5);
const Color _teal = Color(0xFF0D9488);
const Color _background = Color(0xFFF4F6FB);
const Color _secondaryText = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);

class AttendancePage extends StatefulWidget {
  final EmployeeModel employee;
  final AttendanceActionService actionService;
  final AttendanceLocalDataSource localDataSource;
  final AttendanceSyncService syncService;

  const AttendancePage({
    super.key,
    required this.employee,
    required this.actionService,
    required this.localDataSource,
    required this.syncService,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late final AttendanceBloc _attendanceBloc;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    _attendanceBloc = AttendanceBloc(
      actionService: widget.actionService,
      localDataSource: widget.localDataSource,
      syncService: widget.syncService,
      employee: widget.employee,
    )..add(const AttendanceLoadRequested());

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final isConnected = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (isConnected && mounted) {
    _attendanceBloc.add(
      const AttendanceSyncRequested(),
    );
  }
    });

  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();

    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (isConnected && mounted) {
      _attendanceBloc.add(const AttendanceSyncRequested());
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _attendanceBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _attendanceBloc,
      child: _AttendanceView(employee: widget.employee),
    );
  }
}

class _AttendanceView extends StatelessWidget {
  final EmployeeModel employee;

  const _AttendanceView({required this.employee});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) =>
          previous.message != current.message ||
          previous.error != current.error,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: _teal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _navy,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'Attendance',
            style: TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            final location = tz.getLocation(contextEmployeeTimezone(context));

            final companyNow = tz.TZDateTime.now(location);

            final employeeEvents = state.events
                .where((event) => event.syncStatus != SyncStatus.rejected)
                .toList();

            final todayEvents = employeeEvents.where((event) {
              final eventDate = tz.TZDateTime.from(event.timestamp, location);

              return eventDate.year == companyNow.year &&
                  eventDate.month == companyNow.month &&
                  eventDate.day == companyNow.day;
            }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

            final checkIn = todayEvents
                .where(
                  (event) => event.eventType == AttendanceEventType.checkIn,
                )
                .firstOrNull;

            final checkOut = todayEvents
                .where(
                  (event) => event.eventType == AttendanceEventType.checkOut,
                )
                .firstOrNull;

            final status = checkIn == null
                ? 'Not Checked In'
                : checkOut == null
                ? 'Checked In'
                : 'Checked Out';

            final statusColor = checkIn == null
                ? _secondaryText
                : checkOut == null
                ? _teal
                : _indigo;

            final pendingToday = todayEvents.any(
              (event) => event.syncStatus == SyncStatus.pending,
            );

            final recentEvents = [...state.events]
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return RefreshIndicator(
              color: _indigo,
              onRefresh: () async {
                context.read<AttendanceBloc>().add(
                  const AttendanceLoadRequested(),
                );
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  _buildDateHeader(companyNow),

                  const SizedBox(height: 22),

                  _buildStatusCard(
                    status: status,
                    statusColor: statusColor,
                    checkIn: checkIn,
                    checkOut: checkOut,
                    pendingToday: pendingToday,
                    location: location,
                  ),

                  const SizedBox(height: 20),

                  _buildActionButtons(
                    context: context,
                    state: state,
                    checkIn: checkIn,
                    checkOut: checkOut,
                  ),

                  if (state.isLoading) ...[
                    const SizedBox(height: 18),
                    const LinearProgressIndicator(
                      color: _indigo,
                      backgroundColor: _border,
                    ),
                  ],

                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    _MessageCard(message: state.error!, isError: true),
                  ],

                  const SizedBox(height: 28),

                  _buildSectionHeader(
                    title: 'Attendance History',
                    subtitle: 'Your recent attendance activity',
                    icon: Icons.history_rounded,
                  ),

                  const SizedBox(height: 14),

                  if (recentEvents.isEmpty)
                    _buildEmptyState()
                  else
                    ...recentEvents.map(
                      (event) => _AttendanceEventCard(
                        event: event,
                        location: location,
                      ),
                    ),

                  const SizedBox(height: 22),

                  _buildSyncButton(context, state),

                  const SizedBox(height: 10),

                  const Text(
                    'Pending attendance events will sync when an internet '
                    'connection is available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String contextEmployeeTimezone(BuildContext context) {
    return employee.office.timezone;
  }

  Widget _buildDateHeader(tz.TZDateTime now) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your attendance',
          style: TextStyle(
            color: _navy,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          DateFormat('EEEE, dd MMMM yyyy').format(now),
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String status,
    required Color statusColor,
    required AttendanceEventModel? checkIn,
    required AttendanceEventModel? checkOut,
    required bool pendingToday,
    required tz.Location location,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Attendance Overview',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _StatusBadge(label: status, color: statusColor),
              ),
            ],
          ),

          if (pendingToday) ...[
            const SizedBox(height: 12),
            const _StatusBadge(
              label: 'Pending Sync',
              color: Color(0xFFD97706),
              icon: Icons.cloud_upload_outlined,
            ),
          ],

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _TimeInfoTile(
                  icon: Icons.login_rounded,
                  label: 'Check-in',
                  value: _formatTime(checkIn?.timestamp, location),
                  color: _indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeInfoTile(
                  icon: Icons.logout_rounded,
                  label: 'Check-out',
                  value: _formatTime(checkOut?.timestamp, location),
                  color: _teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: _secondaryText,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Working duration',
                  style: TextStyle(color: _secondaryText, fontSize: 13),
                ),
              ),
              Text(
                _workingDuration(checkIn, checkOut, location),
                style: const TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required AttendanceState state,
    required AttendanceEventModel? checkIn,
    required AttendanceEventModel? checkOut,
  }) {
    final canCheckIn = !state.isLoading && checkIn == null;
    final canCheckOut = !state.isLoading && checkIn != null && checkOut == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: canCheckIn
                ? () => context.read<AttendanceBloc>().add(
                    const AttendanceCheckInRequested(),
                  )
                : null,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Check In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _indigo,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: _secondaryText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            onPressed: canCheckOut
                ? () => context.read<AttendanceBloc>().add(
                    const AttendanceCheckOutRequested(),
                  )
                : null,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Check Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _teal,
              disabledForegroundColor: _secondaryText,
              side: BorderSide(color: canCheckOut ? _teal : _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _indigo.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _indigo, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: _secondaryText, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_note_rounded, size: 38, color: _secondaryText),
          SizedBox(height: 12),
          Text(
            'No attendance records yet',
            style: TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Your attendance activity will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, AttendanceState state) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: state.isLoading
            ? null
            : () => context.read<AttendanceBloc>().add(
                const AttendanceSyncRequested(),
              ),
        icon: const Icon(Icons.sync_rounded),
        label: Text(state.isLoading ? 'Syncing...' : 'Sync Now'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _indigo,
          side: const BorderSide(color: _indigo),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _formatTime(DateTime? date, tz.Location location) {
    if (date == null) return '--:--';

    final companyTime = tz.TZDateTime.from(date, location);
    return DateFormat('hh:mm a').format(companyTime);
  }

  String _workingDuration(
    AttendanceEventModel? checkIn,
    AttendanceEventModel? checkOut,
    tz.Location location,
  ) {
    if (checkIn == null) return '--';

    final end = checkOut?.timestamp ?? tz.TZDateTime.now(location);

    final duration = end.difference(checkIn.timestamp);

    if (duration.isNegative) return '--';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '${hours}h ${minutes}m';
  }
}

class _TimeInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimeInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: _navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceEventCard extends StatelessWidget {
  final AttendanceEventModel event;
  final tz.Location location;

  const _AttendanceEventCard({required this.event, required this.location});

  @override
  Widget build(BuildContext context) {
    final isCheckIn = event.eventType == AttendanceEventType.checkIn;

    final color = isCheckIn ? _indigo : _teal;

    final companyTime = tz.TZDateTime.from(event.timestamp, location);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckIn ? 'Check In' : 'Check Out',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('dd MMM yyyy').format(companyTime)} • '
                  '${DateFormat('hh:mm a').format(companyTime)}',
                  style: const TextStyle(color: _secondaryText, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  'GPS: ${event.latitude.toStringAsFixed(4)}, '
                  '${event.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: _secondaryText, fontSize: 10),
                ),
                if (event.syncStatus == SyncStatus.rejected &&
                    event.lastError != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    event.lastError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _EventSyncBadge(status: event.syncStatus),
        ],
      ),
    );
  }
}

class _EventSyncBadge extends StatelessWidget {
  final SyncStatus status;

  const _EventSyncBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SyncStatus.pending => ('Pending', const Color(0xFFD97706)),
      SyncStatus.synced => ('Synced', _teal),
      SyncStatus.rejected => ('Rejected', Colors.red.shade700),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final bool isError;

  const _MessageCard({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade700 : _teal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

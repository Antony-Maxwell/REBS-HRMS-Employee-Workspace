import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../attendance/data/datasources/attendance_local_datasource.dart';
import '../../../attendance/data/models/attendance_event_model.dart';
import '../../../attendance/domain/services/attendance_action_service.dart';
import '../../../attendance/domain/services/attendance_sync_service.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';

import '../../../leave/data/repositories/leave_repository_impl.dart';
import '../../../leave/domain/repositories/leave_repository.dart';
import '../../../leave/domain/services/leave_validation_service.dart';
import '../../../leave/presentation/pages/leave_page.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardPage extends StatefulWidget {
  final AttendanceActionService actionService;
  final AttendanceLocalDataSource attendanceLocalDataSource;
  final AttendanceSyncService syncService;
  final LeaveRepository leaveRepository;
  final LeaveValidationService leaveValidationService;

  const DashboardPage({
    super.key,
    required this.actionService,
    required this.attendanceLocalDataSource,
    required this.syncService,
    required this.leaveRepository,
    required this.leaveValidationService,
  });

  static const navy = Color(0xFF172554);
  static const indigo = Color(0xFF4F46E5);
  static const teal = Color(0xFF0D9488);
  static const background = Color(0xFFF4F6FB);
  static const secondaryText = Color(0xFF64748B);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int? leaveBalance;
  bool isLeaveBalanceLoading = true;
  String? leaveBalanceError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardBloc>().add(const DashboardLoadRequested());
      }
    });
  }

  Future<void> _loadLeaveBalance(String employeeId) async {
    setState(() {
      isLeaveBalanceLoading = true;
      leaveBalanceError = null;
    });

    try {
      final result = await widget.leaveRepository.getLeaveBalance(employeeId);

      if (!mounted) return;

      setState(() {
        leaveBalance = result.balance;
        isLeaveBalanceLoading = false;
        leaveBalanceError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLeaveBalanceLoading = false;
        leaveBalanceError = 'Unable to load balance';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardPage.background,
      appBar: AppBar(
        backgroundColor: DashboardPage.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'REBS HRMS',
          style: TextStyle(
            color: DashboardPage.navy,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              context.read<DashboardBloc>().add(const DashboardLoadRequested());
            },
            icon: const Icon(Icons.refresh_rounded),
            color: DashboardPage.navy,
            tooltip: 'Refresh dashboard',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardLoaded) {
            _loadLeaveBalance(state.employee.id);
          }
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const SpinKitThreeBounce(
                color: Color(0xFF6366F1),
                size: 30,
              );
            }

            if (state is DashboardError) {
              return _buildError(context, state.message);
            }

            if (state is DashboardLoaded) {
              final employee = state.employee;
              final summary = state.attendanceSummary;
              final duration = summary.workingDuration ?? Duration.zero;

              return RefreshIndicator(
                color: DashboardPage.indigo,
                onRefresh: () async {
                  context.read<DashboardBloc>().add(
                    const DashboardLoadRequested(),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEmployeeHeader(
                        employee.name,
                        employee.id,
                        employee.department,
                      ),

                      const SizedBox(height: 22),

                      _buildSectionTitle("Today's Attendance"),

                      const SizedBox(height: 12),

                      _buildAttendanceCard(
                        context,
                        summary.status,
                        summary.checkIn,
                        summary.checkOut,
                        duration,
                        employee,
                      ),

                      const SizedBox(height: 18),

                      _buildQuickInfo(
                        employee.office.radius,
                        employee.office.timezone,
                      ),

                      const SizedBox(height: 18),

                      _buildLeaveBalanceCard(),

                      const SizedBox(height: 18),

                      _buildLeaveCard(context, employee),

                      const SizedBox(height: 26),

                      _buildSectionTitle('Recent Attendance'),

                      const SizedBox(height: 12),

                      _buildRecentAttendance(summary.recentEvents),

                      const SizedBox(height: 24),

                      _buildSectionTitle('Office Configuration'),

                      const SizedBox(height: 12),

                      _buildOfficeCard(
                        employee.office.radius,
                        employee.office.timezone,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: ElevatedButton(
                onPressed: () {
                  context.read<DashboardBloc>().add(
                    const DashboardLoadRequested(),
                  );
                },
                child: const Text('Load Dashboard'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DashboardPage.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: DashboardPage.teal,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Leave Balance',
                  style: TextStyle(
                    color: DashboardPage.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                if (isLeaveBalanceLoading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: SpinKitThreeBounce(
                      color: Color(0xFF6366F1),
                      size: 30,
                    ),
                  )
                else if (leaveBalanceError != null)
                  Text(
                    leaveBalanceError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  )
                else
                  Text(
                    '${leaveBalance ?? 0} Days',
                    style: const TextStyle(
                      color: DashboardPage.navy,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              final state = context.read<DashboardBloc>().state;
              if (state is DashboardLoaded) {
                _loadLeaveBalance(state.employee.id);
              }
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: DashboardPage.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(BuildContext context, employee) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeavePage(
              employee: employee,
              repository: widget.leaveRepository,
              validationService: widget.leaveValidationService,
            ),
          ),
        );

        if (!mounted) return;

        _loadLeaveBalance(employee.id);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECF4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DashboardPage.teal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: DashboardPage.teal,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave Management',
                    style: TextStyle(
                      color: DashboardPage.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check balance and manage leave requests',
                    style: TextStyle(
                      color: DashboardPage.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: DashboardPage.indigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader(String name, String id, String department) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF172554), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardPage.navy.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$id  •  $department',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: DashboardPage.navy,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    String status,
    DateTime? checkIn,
    DateTime? checkOut,
    Duration duration,
    dynamic employee,
  ) {
    final isCheckedIn = status == 'Checked In';
    final isCheckedOut = status == 'Checked Out';

    final statusColor = isCheckedOut
        ? DashboardPage.teal
        : isCheckedIn
        ? DashboardPage.indigo
        : DashboardPage.secondaryText;

    final statusLabel = isCheckedOut
        ? 'Completed'
        : isCheckedIn
        ? 'In Progress'
        : 'Not Started';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: [
          BoxShadow(
            color: DashboardPage.navy.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Attendance Overview',
                  style: TextStyle(
                    color: DashboardPage.secondaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            status,
            style: const TextStyle(
              color: DashboardPage.navy,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _timeInfo(
                  Icons.login_rounded,
                  'Check-in',
                  _formatTime(checkIn),
                  DashboardPage.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeInfo(
                  Icons.logout_rounded,
                  'Check-out',
                  _formatTime(checkOut),
                  DashboardPage.indigo,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFEDF0F5)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 19,
                    color: DashboardPage.secondaryText,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Working duration',
                    style: TextStyle(
                      color: DashboardPage.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                style: const TextStyle(
                  color: DashboardPage.navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 49,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardPage.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttendancePage(
                      employee: employee,
                      actionService: widget.actionService,
                      localDataSource: widget.attendanceLocalDataSource,
                      syncService: widget.syncService,
                    ),
                  ),
                );

                if (context.mounted) {
                  context.read<DashboardBloc>().add(
                    const DashboardLoadRequested(),
                  );
                }
              },
              icon: const Icon(Icons.access_time_rounded, size: 19),
              label: const Text(
                'Open Attendance',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeInfo(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardPage.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: DashboardPage.navy,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(double radius, String timezone) {
    return Row(
      children: [
        Expanded(
          child: _quickInfoCard(
            icon: Icons.location_on_outlined,
            title: '${radius.toStringAsFixed(0)}m',
            subtitle: 'Office radius',
            color: DashboardPage.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickInfoCard(
            icon: Icons.public_rounded,
            title: timezone,
            subtitle: 'Company timezone',
            color: DashboardPage.teal,
          ),
        ),
      ],
    );
  }

  Widget _quickInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 13),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DashboardPage.navy,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: DashboardPage.secondaryText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAttendance(List<AttendanceEventModel> events) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: DashboardPage.secondaryText,
              size: 30,
            ),
            SizedBox(height: 10),
            Text(
              'No attendance records yet',
              style: TextStyle(color: DashboardPage.secondaryText),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Column(
        children: events.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;

          final isCheckIn = event.eventType == AttendanceEventType.checkIn;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                leading: CircleAvatar(
                  radius: 19,
                  backgroundColor: isCheckIn
                      ? const Color(0xFFE0F2F1)
                      : const Color(0xFFEEF2FF),
                  child: Icon(
                    isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                    size: 18,
                    color: isCheckIn
                        ? DashboardPage.teal
                        : DashboardPage.indigo,
                  ),
                ),
                title: Text(
                  isCheckIn ? 'Check In' : 'Check Out',
                  style: const TextStyle(
                    color: DashboardPage.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  DateFormat(
                    'dd MMM yyyy • hh:mm a',
                  ).format(event.timestamp.toLocal()),
                  style: const TextStyle(
                    color: DashboardPage.secondaryText,
                    fontSize: 11,
                  ),
                ),
                trailing: _syncBadge(event.syncStatus),
              ),
              if (index != events.length - 1)
                const Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 15,
                  color: Color(0xFFEDF0F5),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _syncBadge(SyncStatus status) {
    final color = switch (status) {
      SyncStatus.synced => DashboardPage.teal,
      SyncStatus.pending => const Color(0xFFD97706),
      SyncStatus.rejected => const Color(0xFFDC2626),
    };

    final label = switch (status) {
      SyncStatus.synced => 'Synced',
      SyncStatus.pending => 'Pending',
      SyncStatus.rejected => 'Rejected',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOfficeCard(double radius, String timezone) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8ECF4)),
      ),
      child: Column(
        children: [
          _officeInfoRow(
            Icons.location_on_outlined,
            'Allowed radius',
            '${radius.toStringAsFixed(0)} metres',
          ),
          const SizedBox(height: 15),
          _officeInfoRow(Icons.public_rounded, 'Company timezone', timezone),
        ],
      ),
    );
  }

  Widget _officeInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 19, color: DashboardPage.indigo),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: DashboardPage.secondaryText,
              fontSize: 12,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: DashboardPage.navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: DashboardPage.secondaryText,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DashboardPage.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DashboardPage.secondaryText),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                context.read<DashboardBloc>().add(
                  const DashboardLoadRequested(),
                );
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';

    return DateFormat('hh:mm a').format(date.toLocal());
  }
}

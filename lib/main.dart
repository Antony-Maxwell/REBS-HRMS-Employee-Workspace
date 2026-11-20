import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rebs_hrms/core/widgets/splash_screen.dart';
import 'package:rebs_hrms/features/dashboard/domain/services/attendance_summary_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'core/network/dio_client.dart';
import 'core/location/location_service.dart';

import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';

import 'features/attendance/data/datasources/attendance_local_datasource.dart';
import 'features/attendance/domain/services/attendance_action_service.dart';
import 'features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'features/attendance/domain/services/attendance_sync_service.dart';

import 'features/leave/data/datasources/leave_local_datasource.dart';
import 'features/leave/data/datasources/leave_remote_datasource.dart';
import 'features/leave/data/repositories/leave_repository_impl.dart';
import 'features/leave/domain/repositories/leave_repository.dart';
import 'features/leave/domain/services/leave_validation_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  final dio = DioClient.create();

  final leaveLocalDataSource = LeaveLocalDataSource();

  final leaveRemoteDataSource = LeaveRemoteDataSource(dio);

  final LeaveRepository leaveRepository = LeaveRepositoryImpl(
    remoteDataSource: leaveRemoteDataSource,
    localDataSource: leaveLocalDataSource,
  );

  final leaveValidationService = LeaveValidationService();

  final dashboardRemoteDataSource = DashboardRemoteDataSource(dio);
  final dashboardLocalDataSource = DashboardLocalDataSource();

  final DashboardRepository dashboardRepository = DashboardRepositoryImpl(
    remoteDataSource: dashboardRemoteDataSource,
    localDataSource: dashboardLocalDataSource,
  );

  final attendanceLocalDataSource = AttendanceLocalDataSource();

  final attendanceRemoteDataSource = AttendanceRemoteDataSource(dio);

  final attendanceSyncService = AttendanceSyncService(
    localDataSource: attendanceLocalDataSource,
    remoteDataSource: attendanceRemoteDataSource,
  );

  final attendanceActionService = AttendanceActionService(
    locationService: LocationService(),
    localDataSource: attendanceLocalDataSource,
  );

  final attendanceSummaryService = AttendanceSummaryService(
    localDataSource: attendanceLocalDataSource,
  );

  runApp(
    RepositoryProvider<DashboardRepository>.value(
      value: dashboardRepository,
      child: BlocProvider(
        create: (_) => DashboardBloc(
          attendanceSummaryService: attendanceSummaryService,
          repository: dashboardRepository,
        ),
        child: MyApp(
          attendanceActionService: attendanceActionService,
          attendanceLocalDataSource: attendanceLocalDataSource,
          attendanceSyncService: attendanceSyncService,
          leaveRepository: leaveRepository,
          leaveValidationService: leaveValidationService,
        ),
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  final AttendanceActionService attendanceActionService;
  final AttendanceLocalDataSource attendanceLocalDataSource;
  final AttendanceSyncService attendanceSyncService;
  final LeaveRepository leaveRepository;
  final LeaveValidationService leaveValidationService;

  const MyApp({
    super.key,
    required this.attendanceActionService,
    required this.attendanceLocalDataSource,
    required this.attendanceSyncService,
    required this.leaveRepository,
    required this.leaveValidationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'REBS HRMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (navigatorContext) {
          return SplashScreen(
            onFinished: () {
              Navigator.of(navigatorContext).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => DashboardPage(
                    actionService: attendanceActionService,
                    attendanceLocalDataSource:
                        attendanceLocalDataSource,
                    syncService: attendanceSyncService,
                    leaveRepository: leaveRepository,
                    leaveValidationService:
                        leaveValidationService,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

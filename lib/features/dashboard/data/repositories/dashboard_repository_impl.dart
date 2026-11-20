import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/employee_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<EmployeeModel> getEmployee() async {
    try {
      final employee = await remoteDataSource.getEmployee();

      await localDataSource.cacheEmployee(employee);

      return employee;
    } catch (error) {
      final cachedEmployee = await localDataSource.getCachedEmployee();

      if (cachedEmployee != null) {
        return cachedEmployee;
      }

      rethrow;
    }
  }
}

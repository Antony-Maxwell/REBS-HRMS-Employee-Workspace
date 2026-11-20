import 'package:dio/dio.dart';
import '../models/employee_model.dart';

class DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSource(this.dio);

  Future<EmployeeModel> getEmployee() async {
    try {
      final response = await dio.get('/employee/me');

      return EmployeeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to parse employee data: $e');
    }
  }
}

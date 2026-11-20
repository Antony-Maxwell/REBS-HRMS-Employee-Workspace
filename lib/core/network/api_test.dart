import 'dio_client.dart';

Future<void> testApi() async {
  try {
    final dio = DioClient.create();

    final response = await dio.get('/employee/me');

    print('Status: ${response.statusCode}');
    print('Employee: ${response.data}');
  } catch (e) {
    print('API Error: $e');
  }
}

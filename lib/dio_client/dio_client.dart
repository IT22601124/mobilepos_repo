import 'package:dio/dio.dart';
import 'package:mpos/resources/api_routes.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late final Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiRoutes.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add token here
          options.headers['Authorization'] = 'Bearer YOUR_TOKEN';

          print('REQUEST => ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('RESPONSE => ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('ERROR => ${error.message}');
          handler.next(error);
        },
      ),
    );
  }
}
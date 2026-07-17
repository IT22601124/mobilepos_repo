import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:mpos/resources/api_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Temporary SSL bypass for development only.
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();

        client.badCertificateCallback = (
            X509Certificate certificate,
            String host,
            int port,
            ) {
          return host == 'mpos.studiorespectweddings.com';
        };

        return client;
      },
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('access_token');

            if (token != null &&
                token.isNotEmpty &&
                token != 'demo-token') {
              options.headers['Authorization'] = 'Bearer $token';
            }

            handler.next(options);
          } catch (error) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: error,
                message: 'Failed to read access token',
              ),
            );
          }
        },
        onError: (error, handler) {
          print('Dio error type: ${error.type}');
          print('Dio error message: ${error.message}');
          print('Original error: ${error.error}');

          handler.next(error);
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    );
  }
}
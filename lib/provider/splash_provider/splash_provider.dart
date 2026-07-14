import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/resources/api_routes.dart';

class SplashProvider extends ChangeNotifier {
  final _dioClient = DioClient().dio;

  Future<Response> verifyConnection() async {
    try {
      Response response = await _dioClient.get(ApiRoutes.checkConnection);
      if (response.statusCode == 200) {
        debugPrint('Connection verified successfully');
      } else {
        debugPrint('Failed to verify connection: ${response.statusCode}');
      }
      return response;
    } catch (e) {
      debugPrint('Error verifying connection: $e');
      rethrow;
    }
  }
}

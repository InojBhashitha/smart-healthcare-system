import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'token_storage.dart';
import '../exceptions/unauthorized_exception.dart';

class DioClient {
  DioClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      headers: {
        "Accept": "application/json",
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
  onRequest: (options, handler) async {

    if (options.path == ApiConstants.login ||
        options.path == ApiConstants.register) {
      handler.next(options);
      return;
    }

    final token = await TokenStorage.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers["Authorization"] =
          "Bearer $token";
    }

    handler.next(options);
  },

  onError: (error, handler) async {

    if (error.response?.statusCode == 401) {

      await TokenStorage.deleteToken();

      handler.reject(
        DioException(
          requestOptions: error.requestOptions,
          error: UnauthorizedException(),
        ),
      );

      return;
    }

    handler.next(error);
  },
)
    );
}
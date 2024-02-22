// coverage:ignore-file
import 'package:cloudloop_mobile/core/core.dart';
import 'package:dio/dio.dart';

extension DioErrorExtension on DioError {
  ErrorException toServerException() {
    final Object? responseData = response?.data;
    final Map? metadata;
    if (responseData is Map) {
      metadata = responseData['meta'] as Map;
    } else {
      metadata = null;
    }
    final errorMessage = metadata?['message']?.toString() ?? message;
    final Object? errorCode = metadata?['errorCode'] ?? response?.statusCode;

    switch (type) {
      case DioErrorType.badResponse:
        switch (response?.statusCode) {
          case 401:
            return UnAuthenticationServerException(
              message: errorMessage.toString(),
              code: errorCode,
            );
          case 403:
            return UnAuthorizeServerException(
              message: errorMessage.toString(),
              code: errorCode,
            );
          case 404:
            return NotFoundServerException(
              message: errorMessage.toString(),
              code: errorCode,
            );
          case 500:
          case 502:
            return InternalServerException(
              message: errorMessage.toString(),
              code: errorCode,
            );
          default:
            return GeneralServerException(
              message: errorMessage.toString(),
              code: errorCode,
            );
        }

      case DioErrorType.connectionTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.connectionError:
      case DioErrorType.receiveTimeout:
        return TimeOutServerException(
          message: errorMessage.toString(),
          code: response?.statusCode,
        );

      case DioErrorType.cancel:
      case DioErrorType.badCertificate:
      case DioErrorType.unknown:
        return GeneralServerException(
          message: errorMessage.toString(),
          code: response?.statusCode,
        );
    }
  }
}

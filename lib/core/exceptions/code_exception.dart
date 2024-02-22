import 'package:cloudloop_mobile/core/core.dart';

/// Throws when code have error
///
class ErrorCodeException extends ErrorException {
  const ErrorCodeException({required String message, Object? code})
      : super(
          message: message,
          code: code,
        );

  @override
  String toString() => 'ErrorCodeException(message: $message, code: $code)';
}

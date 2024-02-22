import 'package:cloudloop_mobile/core/core.dart';

class GeneralServerException extends ErrorException {
  const GeneralServerException({
    required String message,
    Object? code,
  }) : super(
          message: message,
          code: code,
        );

  @override
  String toString() => 'GeneralServerException(message: $message, code: $code)';
}

class TimeOutServerException extends ErrorException {
  const TimeOutServerException({
    required String message,
    Object? code,
  }) : super(
          message: message,
          code: code,
        );

  @override
  String toString() => 'TimeOutServerException(message: $message, code: $code)';
}

class NotFoundServerException extends ErrorException {
  const NotFoundServerException({
    required String message,
    Object? code,
  }) : super(
          message: message,
          code: code,
        );

  @override
  String toString() =>
      'NotFoundServerException(message: $message, code: $code)';
}

class UnAuthenticationServerException extends ErrorException {
  const UnAuthenticationServerException({
    required String message,
    Object? code,
  }) : super(
          message: message,
          code: code,
        );

  @override
  String toString() =>
      'UnAuthenticationServerException(message: $message, code: $code)';
}

class UnAuthorizeServerException extends ErrorException {
  const UnAuthorizeServerException({
    required String message,
    Object? code,
  }) : super(
          message: message,
          code: code,
        );

  @override
  String toString() =>
      'UnAuthorizeServerException(message: $message, code: $code)';
}

class InternalServerException extends ErrorException {
  const InternalServerException({
    required String message,
    Object? code,
  }) : super(
          message: message,
          code: code,
        );

  @override
  String toString() =>
      'InternalServerException(message: $message, code: $code)';
}

import 'dart:developer';

extension RecordErrorExtensions on Object {
  void recordError({
    Object? exception,
    Object? stackTrace,
    String? reason,
  }) {
    // like Sentry of Firebase Crashlytics http://sentry.io
    log(
      reason ?? (exception ?? this).toString(),
      name: 'ERROR',
      stackTrace: stackTrace is StackTrace?
          ? stackTrace
          : StackTrace.fromString(stackTrace.toString()),
    );
  }
}

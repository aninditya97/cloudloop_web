import 'dart:async';
import 'dart:developer';
import 'package:cloudloop_mobile/app/flavor.dart';
import 'package:cloudloop_mobile/app/runner.dart';

@pragma('vm:entry-point')
Future<void> main([List<String>? args]) async {
  F.flavor = Flavor.dev;

  runZonedGuarded(
    runnerApp,
    (error, stackTrace) => log(
      error.toString(),
      name: 'ERROR',
      stackTrace: stackTrace,
    ),
  );
}

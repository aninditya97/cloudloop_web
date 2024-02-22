import 'dart:async';
import 'dart:developer';

import 'package:cloudloop_mobile/app/flavor.dart';
import 'package:cloudloop_mobile/app/runner.dart';

Future<void> main() async {
  F.flavor = Flavor.staging;

  runZonedGuarded(
    runnerApp,
    (error, stackTrace) => log(
      error.toString(),
      name: 'ERROR',
      stackTrace: stackTrace,
    ),
  );
}

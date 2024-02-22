import 'dart:async';
import 'dart:developer';

import 'package:cloudloop_mobile/app/app.dart';
import 'package:cloudloop_mobile/app/locator.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void runnerApp() {
  Bloc.observer = AppBlocObserver();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await setupLocator();
      runApp(const App());
    },
    (error, stackTrace) {
      // Implement Logging Error in this body,
      // like Sentry of Firebase Crashlytics
      log(
        error.toString(),
        name: 'LOG',
        stackTrace: stackTrace,
      );
    },
  );
}

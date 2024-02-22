import 'package:background/background_scope.dart';
import 'package:cloudloop_mobile/app/config.dart';
import 'package:cloudloop_mobile/app/routes.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/presentation/blocs/blocs.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/blocs/input_alarm_profile/input_alarm_bloc.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/StateMgr.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<ThemeBloc>()..add(const ThemeStarted()),
        ),
        BlocProvider(
          create: (context) =>
              GetIt.I<LanguageBloc>()..add(const LanguageStarted()),
        ),
        BlocProvider(
          create: (context) => GetIt.I<AuthenticationBloc>()
            ..add(const AuthenticationInitialized()),
        ),
        BlocProvider(
          create: (context) => GetIt.I<RegisterBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<InputBloodGlucoseBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<InputInsulinBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<GlucoseReportBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<InsulinReportBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<CarbohydrateReportBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<SetAutoModeBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<SetAnnounceMealBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<GetAutoModeBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<GetAnnounceMealBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<InputAlarmProfileBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<SummaryReportBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<AgpReportBloc>(),
        ),
      ],

      // child: const _AppView(),
      //kai_20230613 blocked below due to ConnectivityMgr() is created again
      // we have to create connectivityMgr provide only once
      // let's add app.dart and only refer to it in other page or widget.

      child: ChangeNotifierProvider<ConnectivityMgr>(
        create: (_) => ConnectivityMgr(),
        child: ChangeNotifierProvider<SwitchState>(
          create: (_) => SwitchState(),
          child: ChangeNotifierProvider<StateMgr>(
            create: (_) => StateMgr(),
            child: const _AppView(),
          ),
        ),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              key: AppRouter.navigatorKey,
              title: AppConfig.titleSiteWeb,
              theme: themeState.theme.toTheme().data,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              locale: languageState.language != null
                  ? Locale(languageState.language!.code)
                  : null,
              debugShowCheckedModeBanner: false,
              supportedLocales: AppLocalizations.supportedLocales,
              routerDelegate: AppRouter.router.routerDelegate,
              routeInformationParser: AppRouter.router.routeInformationParser,
              routeInformationProvider:
                  AppRouter.router.routeInformationProvider,
              //kai_20231030 blocked
              /* builder: (context, child) => BackgroundScope(
                autoOpen: true,
                child: child!,
              ),
		*/
              builder: (context, child) {
                return BackgroundScope(
                  child: child!,
                );
              },
            );
          },
        );
      },
    );
  }
}

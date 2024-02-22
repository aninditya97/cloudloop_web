import 'dart:developer';

import 'package:cloudloop_mobile/app/config.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/database/database.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:cloudloop_mobile/firebase_options.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:path_provider/path_provider.dart';

// ignore_for_file: cascade_invocations
final getIt = GetIt.instance;
Future<void> setupLocator() async {
  await _setupCore();

  // |+-----------------------------------------------------------------------+|
  // |+                               FEATURES                                +|
  // |+-----------------------------------------------------------------------+|

  // ---------------------------------- AUTH -----------------------------------

  // Domain
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      httpClient: getIt(),
      cacheClient: getIt(),
      localDatabase: getIt(),
    ),
  );
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(cacheClient: getIt()),
  );

  getIt.registerLazySingleton(
    () => GetCurrentUserUsecase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetCurrentTokenUsecase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => LoginEmailUsecase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => LoginFirebaseUsecase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => RegisterEmailUsecase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => RegisterFirebaseUsecase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => LogoutUsecase(
      repository: getIt(),
      googleSignIn: getIt(),
      firebaseAuth: getIt(),
    ),
  );
  getIt.registerLazySingleton(() => AuthGoogleUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateProfileCacheUseCase(getIt()));
  getIt.registerLazySingleton(() => InputBloodGlucoseUsecase(getIt()));
  getIt.registerLazySingleton(() => InputInsulinUsecase(getIt()));
  getIt.registerLazySingleton(() => InputCarbohydratesUsecase(getIt()));

  // Presentation
  getIt.registerFactory(
    () => AuthenticationBloc(
      currentUser: getIt(),
      logout: getIt(),
      saveUser: getIt(),
    ),
  );
  getIt.registerFactory(() => RegisterBloc(registerFirebase: getIt()));
  getIt.registerFactory(
    () => GoogleAuthBloc(authGoogle: getIt(), loginFirebase: getIt()),
  );

  // Helper
  getIt.registerLazySingleton(
    () => AuthHttpInterceptor(source: getIt(), dio: getIt()),
  );
  getIt<Dio>().interceptors.add(getIt<AuthHttpInterceptor>());

  // -------------------------------- END AUTH ---------------------------------

  // -------------------------------- SETTINGS ---------------------------------

  // Domain
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(cacheClient: getIt()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      httpClient: getIt(),
      checkConnection: getIt(),
      localDatabase: getIt(),
    ),
  );
  getIt.registerLazySingleton<SensorRepository>(
    () => SensorRepositoryImpl(
      httpClient: getIt(),
      checkConnection: getIt(),
      localDatabase: getIt(),
    ),
  );

  getIt.registerLazySingleton(
    () => GetLanguageSettingUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetThemeSettingUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => SaveLanguageSettingUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => SaveThemeSettingUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(GetSupportedLanguageUseCase.new);
  getIt.registerLazySingleton(
    () => GetProfileUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => UpdateProfileUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => SavePumpUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => SaveCgmUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetCgmUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetPumpUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => DisconnectCgmUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => SetAutoModeUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetAutoModeUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => SetAnnounceMealUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => GetAnnounceMealUseCase(
      getIt(),
    ),
  );
  getIt.registerLazySingleton(
    () => DisconnectPumpUseCase(
      getIt(),
    ),
  );

  // Presentation
  getIt.registerFactory(
    () => LanguageBloc(
      getLanguageSetting: getIt(),
      saveLanguageSetting: getIt(),
      getSupportedLanguage: getIt(),
    ),
  );
  getIt.registerFactory(
    () => ThemeBloc(
      getThemeSetting: getIt(),
      saveThemeSetting: getIt(),
    ),
  );
  getIt.registerFactory(
    () => ProfileBloc(
      getProfile: getIt(),
      updateProfile: getIt(),
    ),
  );
  getIt.registerFactory(
    () => SavePumpBloc(
      savePumpUsecase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => SaveCgmBloc(
      saveCgmUsecase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => GetPumpBloc(
      getPumpUseCase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => GetCgmBloc(
      getCgmUseCase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => DisconnectCgmBloc(
      disconnectCgmUseCase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => SetAutoModeBloc(
      setAutoModeUseCase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => GetAutoModeBloc(
      getAutoModeUseCase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => SetAnnounceMealBloc(
      setAnnounceMealUseCase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => GetAnnounceMealBloc(
      getAnnounceMealUseCase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => DisconnectPumpBloc(
      disconnectPumpUseCase: getIt(),
    ),
  );

  // ------------------------------ END SETTINGS -------------------------------

  // ---------------------------------- HOME -----------------------------------

  // Domain
  getIt.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(
      httpClient: getIt(),
      localDatabase: getIt(),
      checkConnection: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => GetGlucoseReportUseCase(getIt()));
  getIt.registerLazySingleton(() => GetInsulinReportUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCarbohydrateReportUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCarbohydrateFoodUseCase(getIt()));

  // Presentation

  getIt.registerFactory(() => GlucoseReportBloc(glucoseReport: getIt()));
  getIt.registerFactory(() => InsulinReportBloc(insulinReport: getIt()));
  getIt.registerFactory(
    () => CarbohydrateReportBloc(carbohydrateReport: getIt()),
  );
  getIt.registerFactory(
    () => CarbohydrateFoodBloc(carbohydrateFood: getIt()),
  );
  getIt
      .registerFactory(() => InputBloodGlucoseBloc(inputBloodGlucose: getIt()));
  getIt.registerFactory(() => InputInsulinBloc(inputInsulin: getIt()));
  getIt
      .registerFactory(() => InputCarbohydrateBloc(inputCarbohydrate: getIt()));

  // -------------------------------- END HOME ---------------------------------

  // --------------------------------- FAMILY ----------------------------------

  // Domain
  getIt.registerLazySingleton<FamilyRepository>(
    () => FamilyRepositoryImpl(
      httpClient: getIt(),
      localDatabase: getIt(),
      checkConnection: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => GetFamilyMemberUseCase(getIt()));
  getIt.registerLazySingleton(() => InviteFamilyUseCase(getIt()));
  getIt.registerLazySingleton(() => SearchFamilyUseCase(getIt()));
  getIt.registerLazySingleton(() => GetInvitationsUseCase(getIt()));
  getIt.registerLazySingleton(() => AcceptFamilyInvitationUsecase(getIt()));
  getIt.registerLazySingleton(() => LeaveFamilyUseCase(getIt()));
  getIt.registerLazySingleton(() => RejectFamilyInvitationUsecase(getIt()));
  getIt.registerLazySingleton(() => GetFamilyMemberByIdUseCase(getIt()));
  getIt.registerLazySingleton(() => RemoveFamilyMemberUsecase(getIt()));
  getIt.registerLazySingleton(() => UpdateFamilyUsecase(getIt()));
  getIt.registerLazySingleton(() => SyncAcceptFamilyInvitationUseCase(getIt()));
  getIt.registerLazySingleton(() => SyncLeaveFamilyUseCase(getIt()));
  getIt.registerLazySingleton(() => SyncRejectFamilyInvitationUseCase(getIt()));
  getIt.registerLazySingleton(() => SyncInviteFamilyUseCase(getIt()));
  getIt.registerLazySingleton(() => SyncRemoveFamilyMemberUseCase(getIt()));
  getIt.registerLazySingleton(() => SyncUpdateFamilyUseCase(getIt()));

  // Presentation
  // Presentation
  getIt.registerFactory(() => FamilyMemberBloc(familyMemberUseCase: getIt()));
  getIt.registerFactory(() => InviteFamilyBloc(inviteFamilyUsecase: getIt()));
  getIt.registerFactory(() => SearchFamilyBloc(searchFamilyUseCase: getIt()));
  getIt.registerFactory(
    () => InvitationsMemberBloc(invitationsMemberUseCase: getIt()),
  );
  getIt.registerFactory(
    () => AcceptFamilyInvitationBloc(acceptFamilyInvitationUsecase: getIt()),
  );
  getIt.registerFactory(
    () => LeaveFamilyBloc(leaveFamilyUseCase: getIt()),
  );
  getIt.registerFactory(
    () => RejectFamilyInvitationBloc(rejectFamilyInvitationUsecase: getIt()),
  );
  getIt.registerFactory(
    () => FamilyMemberDetailBloc(familyMemberDetail: getIt()),
  );
  getIt.registerFactory(
    () => RemoveFamilyMemberBloc(removeFamilyMemberUsecase: getIt()),
  );
  getIt.registerFactory(
    () => UpdateFamilyBloc(updateFamilyUsecase: getIt()),
  );
  getIt.registerFactory(
    () => SyncAcceptFamilyInvitationBloc(
      syncAcceptFamilyInvitationUsecase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => SyncRejectFamilyInvitationBloc(
      syncRejectFamilyInvitationUsecase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => SyncRemoveFamilyMemberBloc(
      syncRemoveFamilyMemberUsecase: getIt(),
    ),
  );
  getIt.registerFactory(
    () => SyncLeaveFamilyBloc(syncLeaveFamilyUsecase: getIt()),
  );
  getIt.registerFactory(
    () => SyncInviteFamilyBloc(syncInviteFamilyUsecase: getIt()),
  );
  getIt.registerFactory(
    () => SyncUpdateFamilyBloc(syncUpdateFamilyUsecase: getIt()),
  );
  // ------------------------------- END FAMILY --------------------------------

  // -------------------------------- SUMMARRY ---------------------------------

  // Domain
  getIt.registerLazySingleton<SummaryRepository>(
    () => SummaryRepositoryImpl(
      httpClient: getIt(),
      localDatabase: getIt(),
      checkConnection: getIt(),
    ),
  );

  getIt.registerLazySingleton(() => GetSummaryReportUseCase(getIt()));
  getIt.registerLazySingleton(() => GetAGPReportUseCase(getIt()));

  // Presentation
  getIt.registerFactory(() => SummaryReportBloc(summary: getIt()));
  getIt.registerFactory(() => AgpReportBloc(getAGPReportUseCase: getIt()));

  // ---------------------------- END SUMMARRY ---------------------------------

  // |+-----------------------------------------------------------------------+|
  // |+                             END FEATURES                              +|
  // |+-----------------------------------------------------------------------+|
}

Future<void> _setupCore() async {
  EquatableConfig.stringify = AppConfig.autoStringifyEquatable;

  // External
  getIt.registerLazySingleton(InternetConnectionCheckerPlus.new);
  getIt.registerLazySingleton(
    () => Dio()
      ..options = BaseOptions(
        baseUrl: AppConfig.baseUrl.value,
      )
      ..interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (v) {
            log(v.toString(), name: 'NETWORK');
          },
        ),
      ),
  );

  if (!kIsWeb) {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init('${appDocDir.path}/db');
  }

  getIt.registerLazySingleton<HiveInterface>(() => Hive);
  getIt.registerLazySingleton<DatabaseHelper>(DatabaseHelper.new);
  getIt.registerLazySingleton(() => DatabaseHelper().initDb());

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  getIt.registerLazySingleton(GoogleSignIn.new);
  getIt.registerLazySingleton(() => FirebaseAuth.instance);

  // Core
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<InternetConnectionCheckerPlus>()),
  );
}

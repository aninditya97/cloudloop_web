import 'dart:convert';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:hive/hive.dart';

/// {@template settings_repository}
/// A repository which manages about settings
/// {@endtemplate}
abstract class SettingsRepository {
  /// Request current theme settings, when successfully return [AppTheme]
  /// If there is an error throw an error [ErrorException]
  Future<AppTheme> getThemeSetting();

  /// Request current language settings, when successfully return [Language]
  /// If there is an error throw an error [ErrorException]
  Future<Language> getLanguageSetting();

  /// Save/update theme settings, when successfully return [bool]
  /// If there is an error throw an error [ErrorException]
  Future<bool> saveThemeSetting(AppTheme theme);

  /// Save/update language settings, when successfully return [bool]
  /// If there is an error throw an error [ErrorException]
  Future<bool> saveLanguageSetting(Language language);
}

class SettingsRepositoryImpl
    with ServiceCacheHandlerMixin
    implements SettingsRepository {
  const SettingsRepositoryImpl({required this.cacheClient});

  final HiveInterface cacheClient;

  @override
  Future<Language> getLanguageSetting() async {
    final result = await getCache<String>(
      cacheClient,
      boxKey: SettingsCacheKeys.languageCacheKey,
      dataKey: SettingsCacheKeys.languageCacheKey,
    );

    return Language.fromJson(jsonDecode(result) as Map<String, dynamic>);
  }

  @override
  Future<AppTheme> getThemeSetting() async {
    final result = await getCache<String>(
      cacheClient,
      boxKey: SettingsCacheKeys.themeCacheKey,
      dataKey: SettingsCacheKeys.themeCacheKey,
    );

    return result == AppTheme.dark.toText() ? AppTheme.dark : AppTheme.light;
  }

  @override
  Future<bool> saveLanguageSetting(Language language) async {
    await setCache<String>(
      cacheClient,
      boxKey: SettingsCacheKeys.languageCacheKey,
      dataKey: SettingsCacheKeys.languageCacheKey,
      value: jsonEncode(language.toJson()),
    );

    return true;
  }

  @override
  Future<bool> saveThemeSetting(AppTheme theme) async {
    await setCache<String>(
      cacheClient,
      boxKey: SettingsCacheKeys.languageCacheKey,
      dataKey: SettingsCacheKeys.languageCacheKey,
      value: theme.toText(),
    );

    return true;
  }
}

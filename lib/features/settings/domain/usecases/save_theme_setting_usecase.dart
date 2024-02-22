import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/domain.dart';
import 'package:dartz/dartz.dart';

class SaveThemeSettingUseCase
    implements UseCaseFuture<ErrorException, bool, AppTheme> {
  SaveThemeSettingUseCase(this.repository);
  final SettingsRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(AppTheme params) async {
    try {
      return Right(await repository.saveThemeSetting(params));
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

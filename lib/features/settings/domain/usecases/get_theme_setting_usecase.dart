import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:dartz/dartz.dart';

class GetThemeSettingUseCase
    implements UseCaseFuture<ErrorException, AppTheme, NoParams> {
  GetThemeSettingUseCase(this.repository);
  final SettingsRepository repository;

  @override
  FutureOr<Either<ErrorException, AppTheme>> call(NoParams params) async {
    try {
      return Right(await repository.getThemeSetting());
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

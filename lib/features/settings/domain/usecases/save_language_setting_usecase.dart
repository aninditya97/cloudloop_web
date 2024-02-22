import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/domain.dart';
import 'package:dartz/dartz.dart';

class SaveLanguageSettingUseCase
    implements UseCaseFuture<ErrorException, bool, Language> {
  SaveLanguageSettingUseCase(this.repository);
  final SettingsRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(Language params) async {
    try {
      return Right(await repository.saveLanguageSetting(params));
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

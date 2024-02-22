import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:dartz/dartz.dart';

class GetLanguageSettingUseCase
    implements UseCaseFuture<ErrorException, Language, NoParams> {
  GetLanguageSettingUseCase(this.repository);
  final SettingsRepository repository;

  @override
  FutureOr<Either<ErrorException, Language>> call(NoParams params) async {
    try {
      return Right(await repository.getLanguageSetting());
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

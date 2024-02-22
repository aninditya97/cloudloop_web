import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:dartz/dartz.dart';

class GetAnnounceMealUseCase
    implements UseCaseFuture<ErrorException, int, NoParams> {
  const GetAnnounceMealUseCase(this.repository);

  final SensorRepository repository;

  @override
  FutureOr<Either<ErrorException, int>> call(NoParams params) async {
    try {
      return Right(await repository.getAnnounceMealStatus());
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

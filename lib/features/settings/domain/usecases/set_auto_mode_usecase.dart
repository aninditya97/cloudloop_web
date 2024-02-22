import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/repositories/sensor_repository.dart';
import 'package:dartz/dartz.dart';

class SetAutoModeUseCase
    implements UseCaseFuture<ErrorException, bool, NoParams> {
  const SetAutoModeUseCase(this.repository);

  final SensorRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    NoParams params,
  ) async {
    try {
      return Right(
        await repository.setAutoMode(),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/domain.dart';
import 'package:dartz/dartz.dart';

class SavePumpUseCase implements UseCaseFuture<ErrorException, bool, PumpData> {
  const SavePumpUseCase(this.repository);

  final SensorRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    PumpData params,
  ) async {
    try {
      return Right(await repository.insertPump(params));
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

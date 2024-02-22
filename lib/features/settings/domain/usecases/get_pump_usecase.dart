import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/domain.dart';
import 'package:dartz/dartz.dart';

class GetPumpUseCase
    implements UseCaseFuture<ErrorException, PumpData?, NoParams> {
  const GetPumpUseCase(this.repository);

  final SensorRepository repository;

  @override
  FutureOr<Either<ErrorException, PumpData?>> call(NoParams params) async {
    try {
      return Right(await repository.getPump());
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

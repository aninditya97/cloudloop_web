import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:dartz/dartz.dart';

class GetCgmUseCase
    implements UseCaseFuture<ErrorException, CgmData?, NoParams> {
  const GetCgmUseCase(this.repository);

  final SensorRepository repository;

  @override
  FutureOr<Either<ErrorException, CgmData?>> call(NoParams params) async {
    try {
      return Right(await repository.getCgm());
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

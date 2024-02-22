import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/domain.dart';
import 'package:dartz/dartz.dart';

class SaveCgmUseCase
    implements UseCaseFuture<ErrorException, CgmData?, CgmData> {
  const SaveCgmUseCase(this.repository);

  final SensorRepository repository;

  @override
  FutureOr<Either<ErrorException, CgmData?>> call(
    CgmData params,
  ) async {
    try {
      return Right(
        await repository.insertCgm(params),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

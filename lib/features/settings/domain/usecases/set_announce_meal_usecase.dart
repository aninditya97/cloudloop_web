import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/repositories/sensor_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class SetAnnounceMealUseCase
    implements UseCaseFuture<ErrorException, bool, AnnounceMealParams> {
  const SetAnnounceMealUseCase(this.repository);

  final SensorRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    AnnounceMealParams params,
  ) async {
    try {
      return Right(
        await repository.setAnnounceMeal(params.type),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class AnnounceMealParams extends Equatable {
  const AnnounceMealParams({
    required this.type,
  });

  final int type;

  @override
  List<Object> get props {
    return [
      type,
    ];
  }
}

import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class InputCarbohydratesUsecase
    implements UseCaseFuture<ErrorException, bool, InputCarboParams> {
  const InputCarbohydratesUsecase(this.repository);

  final ReportRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    InputCarboParams params,
  ) async {
    try {
      return Right(
        await repository.sendCarbohydrate(params.toRequestBody()),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class InputCarboParams extends Equatable {
  const InputCarboParams({
    required this.value,
    required this.source,
    required this.foodType,
    this.time,
  });

  final double value;
  final ReportSource source;
  final DateTime? time;
  final FoodType foodType;

  Map<String, dynamic> toRequestBody() {
    final map = <String, dynamic>{
      'value': value,
      'foodType': foodType.id,
      'source': source.toCode(),
    };
    if (time != null) {
      map['time'] = time?.toIso8601String();
    }

    return map;
  }

  @override
  List<Object?> get props => [value, foodType, source, time];
}

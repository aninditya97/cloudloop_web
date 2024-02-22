import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetCarbohydrateFoodUseCase
    implements
        UseCaseFuture<ErrorException, CarbohydrateFoodData,
            CarbohydrateFoodDataParams> {
  const GetCarbohydrateFoodUseCase(this.repository);

  final ReportRepository repository;
  @override
  FutureOr<Either<ErrorException, CarbohydrateFoodData>> call(
    CarbohydrateFoodDataParams params,
  ) async {
    try {
      return Right(
        await repository.carbohydrateFoodData(
          page: params.page,
          perPage: params.perPage,
          search: params.search,
          source: params.source,
        ),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class CarbohydrateFoodDataParams extends Equatable {
  const CarbohydrateFoodDataParams({
    this.page,
    this.perPage,
    this.search,
    this.source,
  });

  final int? page;
  final int? perPage;
  final String? source;
  final String? search;

  @override
  List<Object?> get props => [page, perPage, source, search];
}

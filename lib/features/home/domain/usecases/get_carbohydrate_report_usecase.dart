import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetCarbohydrateReportUseCase
    implements
        UseCaseFuture<ErrorException, CarbohydrateReportData,
            CarbohydrateReportParams> {
  const GetCarbohydrateReportUseCase(this.repository);

  final ReportRepository repository;
  @override
  FutureOr<Either<ErrorException, CarbohydrateReportData>> call(
    CarbohydrateReportParams params,
  ) async {
    try {
      return Right(
        await repository.carbohydrateReports(
          startDate: params.startDate,
          endDate: params.endDate,
        ),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class CarbohydrateReportParams extends Equatable {
  const CarbohydrateReportParams({this.startDate, this.endDate});

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}

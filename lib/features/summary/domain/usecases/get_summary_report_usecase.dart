import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetSummaryReportUseCase
    implements
        UseCaseFuture<ErrorException, SummaryReport, SummaryReportParams> {
  const GetSummaryReportUseCase(this.repository);

  final SummaryRepository repository;

  @override
  FutureOr<Either<ErrorException, SummaryReport>> call(
    SummaryReportParams params,
  ) async {
    try {
      return Right(
        await repository.summary(
          startDate: params.startDate,
          endDate: params.endDate,
        ),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class SummaryReportParams extends Equatable {
  const SummaryReportParams({this.startDate, this.endDate});

  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [startDate, endDate];
}

import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetAGPReportUseCase
    implements UseCaseFuture<ErrorException, AGPReport, AgpReportParams> {
  const GetAGPReportUseCase(this.repository);

  final SummaryRepository repository;
  @override
  FutureOr<Either<ErrorException, AGPReport>> call(
    AgpReportParams params,
  ) async {
    try {
      return Right(
        await repository.agpReport(
          page: params.page,
          startDate: params.startDate,
          endDate: params.endDate,
          userId: params.userId,
        ),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class AgpReportParams extends Equatable {
  const AgpReportParams({
    this.page,
    this.startDate,
    this.endDate,
    this.userId,
  });

  final int? page;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? userId;

  @override
  List<Object?> get props => [
        page,
        startDate,
        endDate,
        userId,
      ];
}

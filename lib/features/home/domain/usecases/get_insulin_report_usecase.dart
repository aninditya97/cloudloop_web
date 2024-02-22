import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetInsulinReportUseCase
    implements
        UseCaseFuture<ErrorException, InsulinReportData, InsulinReportParams> {
  const GetInsulinReportUseCase(this.repository);

  final ReportRepository repository;
  @override
  FutureOr<Either<ErrorException, InsulinReportData>> call(
    InsulinReportParams params,
  ) async {
    try {
      return Right(
        await repository.insulinReports(
          startDate: params.startDate,
          endDate: params.endDate,
          filter: params.filter,
        ),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class InsulinReportParams extends Equatable {
  const InsulinReportParams({
    this.startDate,
    this.endDate,
    required this.filter,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final bool filter;

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        filter,
      ];
}

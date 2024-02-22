import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/domain/domain.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class InputInsulinUsecase
    implements UseCaseFuture<ErrorException, bool, SendInsulinDeliveryParams> {
  const InputInsulinUsecase(this.repository);

  final ReportRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    SendInsulinDeliveryParams params,
  ) async {
    try {
      return Right(
        await repository.sendInsulinDelivery(params),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class InputInsulinParams extends Equatable {
  const InputInsulinParams({
    required this.value,
    required this.source,
    this.announceMeal,
    this.autoMode,
    this.iob,
    this.hypoPrevention,
  });

  final double value;
  final ReportSource source;
  final bool? announceMeal;
  final bool? autoMode;
  final double? iob;
  final int? hypoPrevention;

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
        'value': value,
        'source': source.toCode(),
        'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        if (announceMeal != null) 'announceMeal': announceMeal,
        if (autoMode != null) 'autoMode': autoMode,
        if (iob != null) 'iob': iob,
        if (hypoPrevention != null) 'hypoPrevention': hypoPrevention
      };

  @override
  List<Object?> get props => [
        value,
        source,
        announceMeal,
        autoMode,
        iob,
        hypoPrevention,
      ];
}

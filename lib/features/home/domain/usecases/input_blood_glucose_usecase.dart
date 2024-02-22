import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/domain/domain.dart';
import 'package:dartz/dartz.dart';

class InputBloodGlucoseUsecase
    implements UseCaseFuture<ErrorException, bool, SendBloodGlucoseParams> {
  const InputBloodGlucoseUsecase(this.repository);

  final ReportRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    SendBloodGlucoseParams params,
  ) async {
    try {
      return Right(
        await repository.sendBloodGlucose(
          params,
        ),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

// class InputBloodGlucoseParams extends Equatable {
//   const InputBloodGlucoseParams({
//     required this.value,
//     required this.source,
//     this.time,
//   });

//   final double value;
//   final ReportSource source;
//   final DateTime? time;

//   Map<String, dynamic> toRequestBody() => <String, dynamic>{
//         'value': value,
//         'source': source.toCode(),
//         if (time != null)
//           'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(time!),
//       };

//   @override
//   List<Object?> get props => [
//         value,
//         source,
//         time,
//       ];
// }

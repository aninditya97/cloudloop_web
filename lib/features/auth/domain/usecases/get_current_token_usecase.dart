import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dartz/dartz.dart';

class GetCurrentTokenUsecase
    implements UseCaseFuture<ErrorException, String, NoParams> {
  const GetCurrentTokenUsecase(this.repository);

  final UserRepository repository;

  @override
  FutureOr<Either<ErrorException, String>> call(NoParams params) async {
    try {
      return Right(await repository.token());
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

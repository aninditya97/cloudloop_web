import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dartz/dartz.dart';

class GetCurrentUserUsecase
    implements UseCaseFuture<ErrorException, UserProfile, NoParams> {
  const GetCurrentUserUsecase(this.repository);

  final UserRepository repository;

  @override
  FutureOr<Either<ErrorException, UserProfile>> call(NoParams params) async {
    try {
      return Right(await repository.profile());
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

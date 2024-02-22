import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class LoginFirebaseUsecase
    implements UseCaseFuture<ErrorException, UserProfile, LoginFirebaseParams> {
  const LoginFirebaseUsecase(this.repository);

  final AuthRepository repository;

  @override
  FutureOr<Either<ErrorException, UserProfile>> call(
    LoginFirebaseParams params,
  ) async {
    try {
      return Right(await repository.loginWithFirebase(params.token));
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class LoginFirebaseParams extends Equatable {
  const LoginFirebaseParams({required this.token});

  final String token;

  @override
  List<Object?> get props => [token];
}

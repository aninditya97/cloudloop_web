import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class LoginEmailUsecase
    implements UseCaseFuture<ErrorException, UserProfile, LoginEmailParams> {
  const LoginEmailUsecase(this.repository);

  final AuthRepository repository;

  @override
  FutureOr<Either<ErrorException, UserProfile>> call(
    LoginEmailParams params,
  ) async {
    try {
      return Right(await repository.loginWithEmail(params.toRequestBody()));
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class LoginEmailParams extends Equatable {
  const LoginEmailParams({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
        'email': email,
        'password': password,
      };

  @override
  List<Object?> get props => [email, password];
}

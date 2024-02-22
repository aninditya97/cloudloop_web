import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateProfileCacheUseCase
    implements UseCaseFuture<ErrorException, bool, UpdateProfileCacheParams> {
  UpdateProfileCacheUseCase(this.repository);

  final AuthRepository repository;
  @override
  FutureOr<Either<ErrorException, bool>> call(
    UpdateProfileCacheParams params,
  ) async {
    try {
      return Right(await repository.saveProfileCache(params.user.toJson()));
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class UpdateProfileCacheParams extends Equatable {
  const UpdateProfileCacheParams({
    required this.user,
  });
  final UserProfile user;

  @override
  List<Object?> get props => [user];
}

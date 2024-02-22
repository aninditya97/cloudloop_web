import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:dartz/dartz.dart';

class SyncRejectFamilyInvitationUseCase
    implements UseCaseFuture<ErrorException, bool, NoParams> {
  const SyncRejectFamilyInvitationUseCase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    NoParams params,
  ) async {
    try {
      return Right(
        await repository.syncRejectFamilyInvitation(),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

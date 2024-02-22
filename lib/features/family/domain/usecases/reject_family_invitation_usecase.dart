import 'dart:async';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class RejectFamilyInvitationUsecase
    implements
        UseCaseFuture<ErrorException, bool, RejectFamilyInvitationParams> {
  const RejectFamilyInvitationUsecase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    RejectFamilyInvitationParams params,
  ) async {
    try {
      return Right(
        await repository.rejectFamilyInvitation(params.id),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class RejectFamilyInvitationParams extends Equatable {
  const RejectFamilyInvitationParams({
    required this.id,
  });

  final int id;

  @override
  List<Object?> get props => [id];
}

import 'dart:async';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class AcceptFamilyInvitationUsecase
    implements
        UseCaseFuture<ErrorException, bool, AcceptFamilyInvitationParams> {
  const AcceptFamilyInvitationUsecase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    AcceptFamilyInvitationParams params,
  ) async {
    try {
      return Right(
        await repository.acceptFamilyInvitation(
          params.id,
        ),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class AcceptFamilyInvitationParams extends Equatable {
  const AcceptFamilyInvitationParams({
    required this.id,
  });

  final int id;

  @override
  List<Object?> get props => [id];
}

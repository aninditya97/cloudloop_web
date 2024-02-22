import 'dart:async';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class LeaveFamilyUseCase
    implements UseCaseFuture<ErrorException, bool, LeaveFamilyMemberParams> {
  const LeaveFamilyUseCase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    LeaveFamilyMemberParams params,
  ) async {
    try {
      return Right(
        await repository.leaveFamily(params.id),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class LeaveFamilyMemberParams extends Equatable {
  const LeaveFamilyMemberParams({
    required this.id,
  });

  final int id;

  @override
  List<Object?> get props => [id];
}

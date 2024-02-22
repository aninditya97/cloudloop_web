import 'dart:async';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class RemoveFamilyMemberUsecase
    implements UseCaseFuture<ErrorException, bool, RemoveFamilyMemberParams> {
  const RemoveFamilyMemberUsecase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    RemoveFamilyMemberParams params,
  ) async {
    try {
      return Right(
        await repository.removeFamilyMember(
          params.id,
          params.toRequestBody(),
        ),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class RemoveFamilyMemberParams extends Equatable {
  const RemoveFamilyMemberParams({
    required this.id,
  });

  final int id;

  Map<String, dynamic> toRequestBody() => <String, dynamic>{'id': id};

  @override
  List<Object?> get props => [id];
}

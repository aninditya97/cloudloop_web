import 'dart:async';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class UpdateFamilyUsecase
    implements UseCaseFuture<ErrorException, bool, UpdateFamilyParams> {
  const UpdateFamilyUsecase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    UpdateFamilyParams params,
  ) async {
    try {
      return Right(
        await repository.updateFamily(params.id, params.toRequestBody()),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class UpdateFamilyParams extends Equatable {
  const UpdateFamilyParams({
    required this.id,
    required this.label,
  });

  final int id;
  final String label;

  Map<String, dynamic> toRequestBody() => <String, dynamic>{'label': label};

  @override
  List<Object?> get props => [id, label];
}

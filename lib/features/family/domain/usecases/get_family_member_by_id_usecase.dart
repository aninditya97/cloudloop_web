import 'dart:async';

import 'package:cloudloop_mobile/core/exceptions/exceptions.dart';
import 'package:cloudloop_mobile/core/usecases/usecases.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetFamilyMemberByIdUseCase
    implements
        UseCaseFuture<ErrorException, FamilyData, GetFamilyMemberByIdParams> {
  const GetFamilyMemberByIdUseCase(this.repository);

  final FamilyRepository repository;
  @override
  FutureOr<Either<ErrorException, FamilyData>> call(
    GetFamilyMemberByIdParams params,
  ) async {
    try {
      return Right(
        await repository.getFamilyMemberById(params.id),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class GetFamilyMemberByIdParams extends Equatable {
  const GetFamilyMemberByIdParams(this.id);

  final int id;

  @override
  List<Object> get props => [id];
}

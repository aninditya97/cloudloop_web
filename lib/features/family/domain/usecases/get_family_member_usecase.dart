import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/domain/entities/meta_data.dart';
import 'package:dartz/dartz.dart';

class GetFamilyMemberUseCase
    implements
        UseCaseFuture<ErrorException,
            PaginationData<List<FamilyData>, MetaData>, PaginateParams> {
  const GetFamilyMemberUseCase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, PaginationData<List<FamilyData>, MetaData>>>
      call(
    PaginateParams params,
  ) async {
    try {
      final result = await repository.getFamilyMember(
        params.page,
        params.perPage,
      );

      return Right(
        PaginationData(meta: result.meta, data: result.items ?? []),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

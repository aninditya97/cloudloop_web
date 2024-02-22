import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/domain/entities/meta_data.dart';
import 'package:dartz/dartz.dart';

class SearchFamilyUseCase
    implements
        UseCaseFuture<ErrorException, PaginationData<List<UserData>, MetaData>,
            SearchPaginateParams> {
  const SearchFamilyUseCase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, PaginationData<List<UserData>, MetaData>>>
      call(
    SearchPaginateParams params,
  ) async {
    try {
      final result = await repository.searchFamily(
        params.page,
        params.perPage,
        params.query,
      );

      return Right(
        PaginationData(meta: result.meta, data: result.items ?? []),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/domain/entities/meta_data.dart';
import 'package:dartz/dartz.dart';

class GetInvitationsUseCase
    implements
        UseCaseFuture<ErrorException,
            PaginationData<List<InvitationData>, MetaData>, PaginateParams> {
  const GetInvitationsUseCase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<
      Either<ErrorException,
          PaginationData<List<InvitationData>, MetaData>>> call(
    PaginateParams params,
  ) async {
    try {
      final result = await repository.getInvitations(
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

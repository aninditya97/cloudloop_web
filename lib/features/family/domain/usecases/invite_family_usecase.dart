import 'dart:async';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class InviteFamilyUseCase
    implements UseCaseFuture<ErrorException, bool, InviteFamilyParams> {
  const InviteFamilyUseCase(this.repository);

  final FamilyRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    InviteFamilyParams params,
  ) async {
    try {
      return Right(
        await repository.inviteFamily(params.toRequestBody()),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class InviteFamilyParams extends Equatable {
  const InviteFamilyParams({
    required this.email,
  });

  final String email;

  Map<String, dynamic> toRequestBody() {
    final emailList = [email];
    final map = <String, dynamic>{'targets': emailList};

    return map;
  }

  @override
  List<Object?> get props => [email];
}

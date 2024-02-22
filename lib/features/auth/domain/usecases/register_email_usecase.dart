import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class RegisterEmailUsecase
    implements UseCaseFuture<ErrorException, UserProfile, RegisterEmailParams> {
  const RegisterEmailUsecase(this.repository);

  final AuthRepository repository;

  @override
  FutureOr<Either<ErrorException, UserProfile>> call(
    RegisterEmailParams params,
  ) async {
    try {
      return Right(await repository.registerWithEmail(params.toRequestBody()));
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class RegisterEmailParams extends Equatable {
  const RegisterEmailParams({
    required this.name,
    required this.email,
    required this.birthDate,
    required this.gender,
    required this.diabetesType,
    required this.weight,
    required this.totalDailyDose,
  });

  final String name;
  final String email;
  final DateTime birthDate;
  final Gender gender;
  final String diabetesType;
  final double weight;
  final double totalDailyDose;

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
        'name': name,
        'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
        'gender': gender.toStringCode(),
        'diabetesType': diabetesType,
        'weight': weight,
        'totalDailyDose': totalDailyDose,
        'email': email,
      };

  @override
  List<Object?> get props => [
        name,
        email,
        birthDate,
        gender,
        diabetesType,
        weight,
        totalDailyDose,
      ];
}

import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class RegisterFirebaseUsecase
    implements
        UseCaseFuture<ErrorException, UserProfile, RegisterFirebaseParams> {
  const RegisterFirebaseUsecase(this.repository);

  final AuthRepository repository;

  @override
  FutureOr<Either<ErrorException, UserProfile>> call(
    RegisterFirebaseParams params,
  ) async {
    try {
      return Right(
        await repository.registerWithFirebase(params.toRequestBody()),
      );
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class RegisterFirebaseParams extends Equatable {
  const RegisterFirebaseParams({
    required this.name,
    required this.token,
    required this.birthDate,
    required this.gender,
    // required this.diabetesType,
    required this.weight,
    required this.totalDailyDose,
    required this.typicalBasalRate,
    required this.typicalICR,
    required this.typicalISF,
  });

  final String name;
  final String token;
  final DateTime birthDate;
  final Gender gender;
  // final DiabetesType diabetesType;
  final double weight;
  final double totalDailyDose;
  final double typicalBasalRate;
  final double typicalICR;
  final double typicalISF;

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
        'name': name,
        'birthDate': DateFormat('yyyy-MM-dd').format(birthDate),
        'gender': gender.toStringCode(),
        // 'diabetesType': diabetesType.toCode(),
        'weight': weight,
        'totalDailyDose': totalDailyDose,
        'token': token,
        'basalRate': typicalBasalRate,
        'insulinCarbRatio': typicalICR,
        'insulinSensitivityFactor': typicalISF,
      };

  @override
  List<Object?> get props => [
        name,
        token,
        birthDate,
        gender,
        // diabetesType,
        weight,
        totalDailyDose,
        typicalBasalRate,
        typicalICR,
        typicalISF,
      ];
}

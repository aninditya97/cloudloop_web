import 'dart:async';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class UpdateProfileUseCase
    implements UseCaseFuture<ErrorException, bool, UpdateProfileParams> {
  const UpdateProfileUseCase(this.repository);

  final ProfileRepository repository;

  @override
  FutureOr<Either<ErrorException, bool>> call(
    UpdateProfileParams params,
  ) async {
    try {
      return Right(await repository.updateProfile(params.toRequestBody()));
    } on ErrorException catch (error) {
      return Left(error);
    }
  }
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({
    required this.name,
    required this.birthDate,
    required this.gender,
    // required this.diabetesType,
    required this.weight,
    required this.totalDailyDose,
    required this.basalRate,
    required this.insulinCarbRatio,
    required this.insulinSensitivityFactor,
  });
  final String name;
  final DateTime? birthDate;
  final Gender gender;
  // final DiabetesType diabetesType;
  final double weight;
  final double totalDailyDose;
  final double basalRate;
  final double insulinCarbRatio;
  final double insulinSensitivityFactor;
  Map<String, dynamic> toRequestBody() {
    return <String, dynamic>{
      'name': name,
      'birthDate': birthDate != null
          ? DateFormat('yyyy-MM-dd').format(birthDate!)
          : null,
      'gender': gender.toStringCode(),
      // 'diabetesType': diabetesType.toCode(),
      'weight': weight,
      'totalDailyDose': totalDailyDose,
      'basalRate': basalRate,
      'insulinCarbRatio': insulinCarbRatio,
      'insulinSensitivityFactor': insulinSensitivityFactor,
    };
  }

  @override
  List<Object?> get props {
    return [
      name,
      birthDate,
      gender,
      // diabetesType,
      weight,
      totalDailyDose,
      basalRate,
      insulinCarbRatio,
      insulinSensitivityFactor,
    ];
  }
}

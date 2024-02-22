part of 'register_bloc.dart';

class RegisterState extends Equatable {
  const RegisterState({
    required this.googleAuth,
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    // required this.diabetesType,
    required this.weight,
    required this.totalDailyDose,
    required this.typicalBasalRate,
    required this.typicalICR,
    required this.typicalISF,
    required this.status,
    this.failure,
    this.user,
  });

  RegisterState.pure()
      : this(
          status: FormzStatus.pure,
          fullName: const MinLengthFormz.pure(4),
          gender: const NotNullFormz.pure(),
          dateOfBirth: const NotNullFormz.pure(),
          // diabetesType: const NotNullFormz.pure(),
          weight: CustomValidatorFormz.pure((value) => (value ?? 0) > 1),
          totalDailyDose:
              CustomValidatorFormz.pure((value) => (value ?? 0) > 0),
          typicalBasalRate:
              CustomValidatorFormz.pure((value) => (value ?? 0) > 0),
          typicalICR: CustomValidatorFormz.pure((value) => (value ?? 0) > 0),
          typicalISF: CustomValidatorFormz.pure((value) => (value ?? 0) > 0),
          googleAuth: const NotNullFormz.pure(),
        );

  final NotNullFormz<String> googleAuth;
  final MinLengthFormz fullName;
  final NotNullFormz<Gender> gender;
  final NotNullFormz<DateTime> dateOfBirth;
  // final NotNullFormz<DiabetesType> diabetesType;
  final CustomValidatorFormz<double> weight;
  final CustomValidatorFormz<double> totalDailyDose;
  final CustomValidatorFormz<double> typicalBasalRate;
  final CustomValidatorFormz<double> typicalICR;
  final CustomValidatorFormz<double> typicalISF;
  final FormzStatus status;
  final ErrorException? failure;
  final UserProfile? user;

  RegisterState copyWith({
    NotNullFormz<String>? googleAuth,
    MinLengthFormz? fullName,
    NotNullFormz<Gender>? gender,
    NotNullFormz<DateTime>? dateOfBirth,
    NotNullFormz<DiabetesType>? diabetesType,
    CustomValidatorFormz<double>? weight,
    CustomValidatorFormz<double>? totalDailyDose,
    CustomValidatorFormz<double>? typicalBasalRate,
    CustomValidatorFormz<double>? typicalICR,
    CustomValidatorFormz<double>? typicalISF,
    FormzStatus? status,
    ErrorException? failure,
    UserProfile? user,
  }) {
    return RegisterState(
      googleAuth: googleAuth ?? this.googleAuth,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      // diabetesType: diabetesType ?? this.diabetesType,
      weight: weight ?? this.weight,
      totalDailyDose: totalDailyDose ?? this.totalDailyDose,
      typicalBasalRate: typicalBasalRate ?? this.typicalBasalRate,
      typicalICR: typicalICR ?? this.typicalICR,
      typicalISF: typicalISF ?? this.typicalISF,
      status: status ?? this.status,
      failure: failure ?? this.failure,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        gender,
        dateOfBirth,
        // diabetesType,
        weight,
        totalDailyDose,
        typicalBasalRate,
        typicalICR,
        typicalISF,
        status,
        failure,
        user,
      ];
}

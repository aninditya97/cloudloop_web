part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object> get props => [];
}

class RegisterAuthTokenChanged extends RegisterEvent {
  const RegisterAuthTokenChanged(this.credential);

  final String credential;

  @override
  List<Object> get props => [credential];
}

class RegisterFullNameChanged extends RegisterEvent {
  const RegisterFullNameChanged(this.fullName);

  final String fullName;

  @override
  List<Object> get props => [fullName];
}

class RegisterGenderChanged extends RegisterEvent {
  const RegisterGenderChanged(this.gender);

  final Gender gender;

  @override
  List<Object> get props => [gender];
}

class RegisterDateOfBirthChanged extends RegisterEvent {
  const RegisterDateOfBirthChanged(this.dateOfBirth);

  final DateTime dateOfBirth;

  @override
  List<Object> get props => [dateOfBirth];
}

class RegisterDiabetesTypeChanged extends RegisterEvent {
  const RegisterDiabetesTypeChanged(this.diabetesType);

  final DiabetesType diabetesType;

  @override
  List<Object> get props => [diabetesType];
}

class RegisterWeightChanged extends RegisterEvent {
  const RegisterWeightChanged(this.weight);

  final double weight;

  @override
  List<Object> get props => [weight];
}

class RegisterDailyDoseChanged extends RegisterEvent {
  const RegisterDailyDoseChanged(this.dailyDose);

  final double dailyDose;

  @override
  List<Object> get props => [dailyDose];
}

class RegisterTypicalBasalRateChanged extends RegisterEvent {
  const RegisterTypicalBasalRateChanged(this.typicalBasalRate);

  final double typicalBasalRate;

  @override
  List<Object> get props => [typicalBasalRate];
}

class RegisterTypicalICRChanged extends RegisterEvent {
  const RegisterTypicalICRChanged(this.typicalICR);

  final double typicalICR;

  @override
  List<Object> get props => [typicalICR];
}

class RegisterTypicalISFChanged extends RegisterEvent {
  const RegisterTypicalISFChanged(this.typicalISF);

  final double typicalISF;

  @override
  List<Object> get props => [typicalISF];
}

class RegisterRequestSubmitted extends RegisterEvent {
  const RegisterRequestSubmitted();
}

class RegisterRequestResetted extends RegisterEvent {
  const RegisterRequestResetted();
}

part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileFetched extends ProfileEvent {
  const ProfileFetched();
}

class ProfileDailyDoseUpdated extends ProfileEvent {
  const ProfileDailyDoseUpdated(this.dailyDose);

  final double dailyDose;

  @override
  List<Object> get props => [dailyDose];
}

class ProfileWeightUpdated extends ProfileEvent {
  const ProfileWeightUpdated(this.weight);

  final double weight;

  @override
  List<Object> get props => [weight];
}

class ProfileTypicalBasalRateUpdated extends ProfileEvent {
  const ProfileTypicalBasalRateUpdated(this.basalRate);

  final double basalRate;

  @override
  List<Object> get props => [basalRate];
}

class ProfileTypicalICRUpdated extends ProfileEvent {
  const ProfileTypicalICRUpdated(this.icr);

  final double icr;

  @override
  List<Object> get props => [icr];
}

class ProfileTypicalISFUpdated extends ProfileEvent {
  const ProfileTypicalISFUpdated(this.isf);

  final double isf;

  @override
  List<Object> get props => [isf];
}

class ProfileDiabetesTypeUpdated extends ProfileEvent {
  const ProfileDiabetesTypeUpdated(this.type);

  final DiabetesType type;

  @override
  List<Object> get props => [type];
}

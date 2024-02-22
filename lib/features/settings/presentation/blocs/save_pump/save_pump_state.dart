part of 'save_pump_bloc.dart';

abstract class SavePumpState extends Equatable {
  const SavePumpState();

  @override
  List<Object> get props => [];
}

class PumpInitial extends SavePumpState {}

class SavePumpLoading extends SavePumpState {
  const SavePumpLoading();

  @override
  List<Object> get props => [];
}

class SavePumpSuccess extends SavePumpState {
  const SavePumpSuccess();

  @override
  List<Object> get props => [];
}

class SavePumpFailure extends SavePumpState {
  const SavePumpFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

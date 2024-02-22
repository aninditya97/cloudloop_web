part of 'disconnect_pump_bloc.dart';

abstract class DisconnectPumpState extends Equatable {
  const DisconnectPumpState();

  @override
  List<Object> get props => [];
}

class DisconnectPumpInitial extends DisconnectPumpState {}

class DisconnectPumpLoading extends DisconnectPumpState {
  const DisconnectPumpLoading();

  @override
  List<Object> get props => [];
}

class DisconnectPumpSuccess extends DisconnectPumpState {
  const DisconnectPumpSuccess();

  @override
  List<Object> get props => [];
}

class DisconnectPumpFailure extends DisconnectPumpState {
  const DisconnectPumpFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

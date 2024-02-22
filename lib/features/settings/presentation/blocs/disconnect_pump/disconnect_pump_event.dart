part of 'disconnect_pump_bloc.dart';

abstract class DisconnectPumpEvent extends Equatable {
  const DisconnectPumpEvent();

  @override
  List<Object> get props => [];
}

class DisconnectPumpFetched extends DisconnectPumpEvent {
  const DisconnectPumpFetched();

  @override
  List<Object> get props => [];
}

part of 'get_pump_bloc.dart';

abstract class GetPumpEvent extends Equatable {
  const GetPumpEvent();

  @override
  List<Object> get props => [];
}

class PumpFetched extends GetPumpEvent {
  const PumpFetched();

  @override
  List<Object> get props => [];
}

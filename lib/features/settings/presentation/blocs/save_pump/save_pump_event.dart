part of 'save_pump_bloc.dart';

abstract class SavePumpEvent extends Equatable {
  const SavePumpEvent();

  @override
  List<Object> get props => [];
}

class SavePump extends SavePumpEvent {
  const SavePump({
    required this.pump,
  });
  final PumpData pump;

  @override
  List<Object> get props => [pump];
}

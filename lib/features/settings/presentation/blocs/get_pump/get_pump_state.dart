part of 'get_pump_bloc.dart';

abstract class GetPumpState extends Equatable {
  const GetPumpState();

  @override
  List<Object?> get props => [];
}

class GetPumpLoading extends GetPumpState {
  const GetPumpLoading();
}

class GetPumpSuccess extends GetPumpState {
  const GetPumpSuccess(this.data);

  final PumpData? data;

  @override
  List<Object?> get props => [data];
}

class GetPumpFailure extends GetPumpState {
  const GetPumpFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}

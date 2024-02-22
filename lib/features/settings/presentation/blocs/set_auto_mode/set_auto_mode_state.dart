part of 'set_auto_mode_bloc.dart';

abstract class SetAutoModeState extends Equatable {
  const SetAutoModeState();

  @override
  List<Object> get props => [];
}

class SetAutoModeInitial extends SetAutoModeState {}

class SetAutoModeLoading extends SetAutoModeState {
  const SetAutoModeLoading();

  @override
  List<Object> get props => [];
}

class SetAutoModeSuccess extends SetAutoModeState {
  const SetAutoModeSuccess();

  @override
  List<Object> get props => [];
}

class SetAutoModeFailure extends SetAutoModeState {
  const SetAutoModeFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

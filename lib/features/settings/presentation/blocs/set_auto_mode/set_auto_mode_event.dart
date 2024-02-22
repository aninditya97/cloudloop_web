part of 'set_auto_mode_bloc.dart';

abstract class SetAutoModeEvent extends Equatable {
  const SetAutoModeEvent();

  @override
  List<Object> get props => [];
}

class AutoModeRequestSubmitted extends SetAutoModeEvent {
  const AutoModeRequestSubmitted();
}

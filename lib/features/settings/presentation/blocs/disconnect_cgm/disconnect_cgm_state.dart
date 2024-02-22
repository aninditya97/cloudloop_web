part of 'disconnect_cgm_bloc.dart';

abstract class DisconnectCgmState extends Equatable {
  const DisconnectCgmState();

  @override
  List<Object> get props => [];
}

class DisconnectCgmInitial extends DisconnectCgmState {}

class DisconnectCgmLoading extends DisconnectCgmState {
  const DisconnectCgmLoading();

  @override
  List<Object> get props => [];
}

class DisconnectCgmSuccess extends DisconnectCgmState {
  const DisconnectCgmSuccess();

  @override
  List<Object> get props => [];
}

class DisconnectCgmFailure extends DisconnectCgmState {
  const DisconnectCgmFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

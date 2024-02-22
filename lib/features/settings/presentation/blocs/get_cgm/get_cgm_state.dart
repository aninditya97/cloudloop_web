part of 'get_cgm_bloc.dart';

abstract class GetCgmState extends Equatable {
  const GetCgmState();

  @override
  List<Object?> get props => [];
}

class GetCgmLoading extends GetCgmState {
  const GetCgmLoading();
}

class GetCgmSuccess extends GetCgmState {
  const GetCgmSuccess(this.data);

  final CgmData? data;

  @override
  List<Object?> get props => [data];
}

class GetCgmFailure extends GetCgmState {
  const GetCgmFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}

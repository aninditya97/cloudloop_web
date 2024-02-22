part of 'get_auto_mode_bloc.dart';

abstract class GetAutoModeState extends Equatable {
  const GetAutoModeState();

  @override
  List<Object?> get props => [];
}

class GetAutoModeLoading extends GetAutoModeState {
  const GetAutoModeLoading();
}

class GetAutoModeSuccess extends GetAutoModeState {
  const GetAutoModeSuccess(this.success);

  final int success;

  @override
  List<Object?> get props => [success];
}

class GetAutoModeFailure extends GetAutoModeState {
  const GetAutoModeFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}

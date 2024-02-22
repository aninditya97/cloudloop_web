part of 'leave_family_bloc.dart';

abstract class LeaveFamilyState extends Equatable {
  const LeaveFamilyState();

  @override
  List<Object> get props => [];
}

class LeaveFamilyInitial extends LeaveFamilyState {}

class LeaveFamilyLoading extends LeaveFamilyState {
  const LeaveFamilyLoading();

  @override
  List<Object> get props => [];
}

class LeaveFamilySuccess extends LeaveFamilyState {
  const LeaveFamilySuccess();

  @override
  List<Object> get props => [];
}

class LeaveFamilyFailure extends LeaveFamilyState {
  const LeaveFamilyFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

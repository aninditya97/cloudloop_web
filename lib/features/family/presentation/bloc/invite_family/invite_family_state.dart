part of 'invite_family_bloc.dart';

abstract class InviteFamilyState extends Equatable {
  const InviteFamilyState();

  @override
  List<Object> get props => [];
}

class InviteFamilyInitial extends InviteFamilyState {}

class InviteFamilyLoading extends InviteFamilyState {
  const InviteFamilyLoading();

  @override
  List<Object> get props => [];
}

class InviteFamilySuccess extends InviteFamilyState {
  const InviteFamilySuccess();

  @override
  List<Object> get props => [];
}

class InviteFamilyFailure extends InviteFamilyState {
  const InviteFamilyFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

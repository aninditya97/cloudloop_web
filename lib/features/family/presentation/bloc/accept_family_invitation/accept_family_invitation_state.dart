part of 'accept_family_invitation_bloc.dart';

abstract class AcceptFamilyInvitationState extends Equatable {
  const AcceptFamilyInvitationState();

  @override
  List<Object> get props => [];
}

class AcceptFamilyInvitationInitial extends AcceptFamilyInvitationState {}

class AcceptFamilyInvitationLoading extends AcceptFamilyInvitationState {
  const AcceptFamilyInvitationLoading();

  @override
  List<Object> get props => [];
}

class AcceptFamilyInvitationSuccess extends AcceptFamilyInvitationState {
  const AcceptFamilyInvitationSuccess();

  @override
  List<Object> get props => [];
}

class AcceptFamilyInvitationFailure extends AcceptFamilyInvitationState {
  const AcceptFamilyInvitationFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

part of 'reject_family_invitation_bloc.dart';

abstract class RejectFamilyInvitationState extends Equatable {
  const RejectFamilyInvitationState();

  @override
  List<Object> get props => [];
}

class RejectFamilyInvitationInitial extends RejectFamilyInvitationState {}

class RejectFamilyInvitationLoading extends RejectFamilyInvitationState {
  const RejectFamilyInvitationLoading();

  @override
  List<Object> get props => [];
}

class RejectFamilyInvitationSuccess extends RejectFamilyInvitationState {
  const RejectFamilyInvitationSuccess();

  @override
  List<Object> get props => [];
}

class RejectFamilyInvitationFailure extends RejectFamilyInvitationState {
  const RejectFamilyInvitationFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

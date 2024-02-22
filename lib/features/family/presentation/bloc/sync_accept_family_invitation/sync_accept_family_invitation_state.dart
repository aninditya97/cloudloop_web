part of 'sync_accept_family_invitation_bloc.dart';

abstract class SyncAcceptFamilyInvitationState extends Equatable {
  const SyncAcceptFamilyInvitationState();

  @override
  List<Object> get props => [];
}

class SyncAcceptFamilyInvitationInitial
    extends SyncAcceptFamilyInvitationState {}

class SyncAcceptFamilyInvitationLoading
    extends SyncAcceptFamilyInvitationState {
  const SyncAcceptFamilyInvitationLoading();

  @override
  List<Object> get props => [];
}

class SyncAcceptFamilyInvitationSuccess
    extends SyncAcceptFamilyInvitationState {
  const SyncAcceptFamilyInvitationSuccess();

  @override
  List<Object> get props => [];
}

class SyncAcceptFamilyInvitationFailure
    extends SyncAcceptFamilyInvitationState {
  const SyncAcceptFamilyInvitationFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

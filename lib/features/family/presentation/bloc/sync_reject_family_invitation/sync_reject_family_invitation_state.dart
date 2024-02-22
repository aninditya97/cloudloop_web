part of 'sync_reject_family_invitation_bloc.dart';

abstract class SyncRejectFamilyInvitationState extends Equatable {
  const SyncRejectFamilyInvitationState();

  @override
  List<Object> get props => [];
}

class SyncRejectFamilyInvitationInitial
    extends SyncRejectFamilyInvitationState {}

class SyncRejectFamilyInvitationLoading
    extends SyncRejectFamilyInvitationState {
  const SyncRejectFamilyInvitationLoading();

  @override
  List<Object> get props => [];
}

class SyncRejectFamilyInvitationSuccess
    extends SyncRejectFamilyInvitationState {
  const SyncRejectFamilyInvitationSuccess();

  @override
  List<Object> get props => [];
}

class SyncRejectFamilyInvitationFailure
    extends SyncRejectFamilyInvitationState {
  const SyncRejectFamilyInvitationFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

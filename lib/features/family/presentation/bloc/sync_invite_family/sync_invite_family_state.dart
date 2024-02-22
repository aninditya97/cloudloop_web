part of 'sync_invite_family_bloc.dart';

abstract class SyncInviteFamilyState extends Equatable {
  const SyncInviteFamilyState();

  @override
  List<Object> get props => [];
}

class SyncInviteFamilyInitial extends SyncInviteFamilyState {}

class SyncInviteFamilyLoading extends SyncInviteFamilyState {
  const SyncInviteFamilyLoading();

  @override
  List<Object> get props => [];
}

class SyncInviteFamilySuccess extends SyncInviteFamilyState {
  const SyncInviteFamilySuccess();

  @override
  List<Object> get props => [];
}

class SyncInviteFamilyFailure extends SyncInviteFamilyState {
  const SyncInviteFamilyFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

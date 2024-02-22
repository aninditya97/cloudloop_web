part of 'sync_remove_family_member_bloc.dart';

abstract class SyncRemoveFamilyMemberState extends Equatable {
  const SyncRemoveFamilyMemberState();

  @override
  List<Object> get props => [];
}

class SyncRemoveFamilyMemberInitial extends SyncRemoveFamilyMemberState {}

class SyncRemoveFamilyMemberLoading extends SyncRemoveFamilyMemberState {
  const SyncRemoveFamilyMemberLoading();

  @override
  List<Object> get props => [];
}

class SyncRemoveFamilyMemberSuccess extends SyncRemoveFamilyMemberState {
  const SyncRemoveFamilyMemberSuccess();

  @override
  List<Object> get props => [];
}

class SyncRemoveFamilyMemberFailure extends SyncRemoveFamilyMemberState {
  const SyncRemoveFamilyMemberFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

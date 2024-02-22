part of 'sync_leave_family_bloc.dart';

abstract class SyncLeaveFamilyState extends Equatable {
  const SyncLeaveFamilyState();

  @override
  List<Object> get props => [];
}

class SyncLeaveFamilyInitial extends SyncLeaveFamilyState {}

class SyncLeaveFamilyLoading extends SyncLeaveFamilyState {
  const SyncLeaveFamilyLoading();

  @override
  List<Object> get props => [];
}

class SyncLeaveFamilySuccess extends SyncLeaveFamilyState {
  const SyncLeaveFamilySuccess();

  @override
  List<Object> get props => [];
}

class SyncLeaveFamilyFailure extends SyncLeaveFamilyState {
  const SyncLeaveFamilyFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

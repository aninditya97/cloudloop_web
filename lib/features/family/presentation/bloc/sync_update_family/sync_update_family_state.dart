part of 'sync_update_family_bloc.dart';

abstract class SyncUpdateFamilyState extends Equatable {
  const SyncUpdateFamilyState();

  @override
  List<Object> get props => [];
}

class SyncUpdateFamilyInitial extends SyncUpdateFamilyState {}

class SyncUpdateFamilyLoading extends SyncUpdateFamilyState {
  const SyncUpdateFamilyLoading();

  @override
  List<Object> get props => [];
}

class SyncUpdateFamilySuccess extends SyncUpdateFamilyState {
  const SyncUpdateFamilySuccess();

  @override
  List<Object> get props => [];
}

class SyncUpdateFamilyFailure extends SyncUpdateFamilyState {
  const SyncUpdateFamilyFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

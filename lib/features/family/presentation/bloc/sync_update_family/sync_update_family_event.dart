part of 'sync_update_family_bloc.dart';

abstract class SyncUpdateFamilyEvent extends Equatable {
  const SyncUpdateFamilyEvent();

  @override
  List<Object> get props => [];
}

class SyncUpdateFamilyFetched extends SyncUpdateFamilyEvent {
  const SyncUpdateFamilyFetched();

  @override
  List<Object> get props => [];
}

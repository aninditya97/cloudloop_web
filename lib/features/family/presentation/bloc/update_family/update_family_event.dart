part of 'update_family_bloc.dart';

abstract class UpdateFamilyEvent extends Equatable {
  const UpdateFamilyEvent();

  @override
  List<Object> get props => [];
}

class UpdateFamilyFetched extends UpdateFamilyEvent {
  const UpdateFamilyFetched({required this.id, required this.label});

  final int id;
  final String label;

  @override
  List<Object> get props => [id, label];
}

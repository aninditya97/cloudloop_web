part of 'update_family_bloc.dart';

abstract class UpdateFamilyState extends Equatable {
  const UpdateFamilyState();

  @override
  List<Object> get props => [];
}

class UpdateFamilyInitial extends UpdateFamilyState {}

class UpdateFamilyLoading extends UpdateFamilyState {
  const UpdateFamilyLoading();

  @override
  List<Object> get props => [];
}

class UpdateFamilySuccess extends UpdateFamilyState {
  const UpdateFamilySuccess();

  @override
  List<Object> get props => [];
}

class UpdateFamilyFailure extends UpdateFamilyState {
  const UpdateFamilyFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

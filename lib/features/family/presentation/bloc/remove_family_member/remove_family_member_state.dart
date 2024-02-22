part of 'remove_family_member_bloc.dart';

abstract class RemoveFamilyMemberState extends Equatable {
  const RemoveFamilyMemberState();

  @override
  List<Object> get props => [];
}

class RemoveFamilyMemberInitial extends RemoveFamilyMemberState {}

class RemoveFamilyMemberLoading extends RemoveFamilyMemberState {
  const RemoveFamilyMemberLoading();

  @override
  List<Object> get props => [];
}

class RemoveFamilyMemberSuccess extends RemoveFamilyMemberState {
  const RemoveFamilyMemberSuccess();

  @override
  List<Object> get props => [];
}

class RemoveFamilyMemberFailure extends RemoveFamilyMemberState {
  const RemoveFamilyMemberFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

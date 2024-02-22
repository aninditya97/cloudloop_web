part of 'family_member_bloc.dart';

abstract class FamilyMemberState extends Equatable {}

class FamilyMemberLoading extends FamilyMemberState {
  @override
  List<Object?> get props => [];
}

class FamilyMemberSuccess extends FamilyMemberState {
  FamilyMemberSuccess({
    required this.data,
    required this.hasReachedMax,
    required this.page,
  });
  final List<FamilyData> data;
  final bool hasReachedMax;
  final int page;

  @override
  List<Object> get props => [data, hasReachedMax, page];
}

class FamilyMemberFailure extends FamilyMemberState {
  FamilyMemberFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

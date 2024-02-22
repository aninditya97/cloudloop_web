part of 'family_member_detail_bloc.dart';

abstract class FamilyMemberDetailState extends Equatable {
  const FamilyMemberDetailState();

  @override
  List<Object> get props => [];
}

class FamilyMemberDetailLoading extends FamilyMemberDetailState {
  const FamilyMemberDetailLoading();
}

class FamilyMemberDetailSuccess extends FamilyMemberDetailState {
  const FamilyMemberDetailSuccess(this.data);

  final FamilyData data;

  @override
  List<Object> get props => [data];
}

class FamilyMemberDetailFailure extends FamilyMemberDetailState {
  const FamilyMemberDetailFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}

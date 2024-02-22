part of 'family_member_detail_bloc.dart';

abstract class FamilyMemberDetailEvent extends Equatable {
  const FamilyMemberDetailEvent();

  @override
  List<Object> get props => [];
}

class FamilyMemberDetailFetched extends FamilyMemberDetailEvent {
  const FamilyMemberDetailFetched({required this.id});
  final int id;

  @override
  List<Object> get props => [id];
}

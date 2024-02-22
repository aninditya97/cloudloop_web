part of 'remove_family_member_bloc.dart';

abstract class RemoveFamilyMemberEvent extends Equatable {
  const RemoveFamilyMemberEvent();

  @override
  List<Object> get props => [];
}

class RemoveFamilyMemberFetched extends RemoveFamilyMemberEvent {
  const RemoveFamilyMemberFetched({
    required this.id,
  });
  final int id;

  @override
  List<Object> get props => [id];
}

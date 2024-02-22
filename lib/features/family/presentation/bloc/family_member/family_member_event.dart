part of 'family_member_bloc.dart';

abstract class FamilyMemberEvent extends Equatable {}

class FetchFamilyMemberEvent extends FamilyMemberEvent {
  FetchFamilyMemberEvent({
    required this.page,
    required this.perPage,
  });

  final int page;
  final int perPage;

  @override
  List<Object?> get props => [page, perPage];
}

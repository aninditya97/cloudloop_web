part of 'invitations_member_bloc.dart';

abstract class InvitationsMemberEvent extends Equatable {}

class FetchInvitationsMemberEvent extends InvitationsMemberEvent {
  FetchInvitationsMemberEvent({
    required this.page,
    required this.perPage,
  });

  final int page;
  final int perPage;

  @override
  List<Object?> get props => [page, perPage];
}

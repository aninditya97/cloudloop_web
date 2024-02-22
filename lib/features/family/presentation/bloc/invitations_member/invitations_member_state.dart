part of 'invitations_member_bloc.dart';

abstract class InvitationsMemberState extends Equatable {}

class InvitationsMemberLoading extends InvitationsMemberState {
  @override
  List<Object?> get props => [];
}

class InvitationsMemberSuccess extends InvitationsMemberState {
  InvitationsMemberSuccess({
    required this.data,
    required this.hasReachedMax,
    required this.page,
  });
  final List<InvitationData> data;
  final bool hasReachedMax;
  final int page;

  @override
  List<Object> get props => [data, hasReachedMax, page];
}

class InvitationsMemberFailure extends InvitationsMemberState {
  InvitationsMemberFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

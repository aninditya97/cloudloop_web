part of 'reject_family_invitation_bloc.dart';

abstract class RejectFamilyInvitationEvent extends Equatable {
  const RejectFamilyInvitationEvent();

  @override
  List<Object> get props => [];
}

class RejectFamilyInvitationFetched extends RejectFamilyInvitationEvent {
  const RejectFamilyInvitationFetched({
    required this.id,
  });
  final int id;

  @override
  List<Object> get props => [id];
}

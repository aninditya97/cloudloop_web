part of 'accept_family_invitation_bloc.dart';

abstract class AcceptFamilyInvitationEvent extends Equatable {
  const AcceptFamilyInvitationEvent();

  @override
  List<Object> get props => [];
}

class AcceptFamilyInvitationFetched extends AcceptFamilyInvitationEvent {
  const AcceptFamilyInvitationFetched({
    required this.id,
  });
  final int id;

  @override
  List<Object> get props => [id];
}

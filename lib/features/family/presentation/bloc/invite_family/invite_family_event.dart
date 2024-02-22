part of 'invite_family_bloc.dart';

abstract class InviteFamilyEvent extends Equatable {
  const InviteFamilyEvent();

  @override
  List<Object?> get props => [];
}

class InviteFamilyFetched extends InviteFamilyEvent {
  const InviteFamilyFetched({
    required this.email,
  });
  final String email;

  @override
  List<Object?> get props => [email];
}

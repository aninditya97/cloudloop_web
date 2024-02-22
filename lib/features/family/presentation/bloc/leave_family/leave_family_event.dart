part of 'leave_family_bloc.dart';

abstract class LeaveFamilyEvent extends Equatable {
  const LeaveFamilyEvent();

  @override
  List<Object> get props => [];
}

class LeaveFamilyFetched extends LeaveFamilyEvent {
  const LeaveFamilyFetched({
    required this.id,
  });

  final int id;

  @override
  List<Object> get props => [id];
}

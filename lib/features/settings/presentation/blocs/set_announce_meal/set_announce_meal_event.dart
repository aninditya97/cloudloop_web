part of 'set_announce_meal_bloc.dart';

abstract class SetAnnounceMealEvent extends Equatable {
  const SetAnnounceMealEvent();

  @override
  List<Object> get props => [];
}

class AnnounceMealRequestSubmitted extends SetAnnounceMealEvent {
  const AnnounceMealRequestSubmitted({
    required this.type,
  });

  final int type;

  @override
  List<Object> get props => [type];
}

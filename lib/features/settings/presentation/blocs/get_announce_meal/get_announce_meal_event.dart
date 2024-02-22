part of 'get_announce_meal_bloc.dart';

abstract class GetAnnounceMealEvent extends Equatable {
  const GetAnnounceMealEvent();

  @override
  List<Object> get props => [];
}

class AnnounceMealFetched extends GetAnnounceMealEvent {
  const AnnounceMealFetched();

  @override
  List<Object> get props => [];
}

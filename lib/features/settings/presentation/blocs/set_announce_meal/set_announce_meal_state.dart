part of 'set_announce_meal_bloc.dart';

abstract class SetAnnounceMealState extends Equatable {
  const SetAnnounceMealState();

  @override
  List<Object> get props => [];
}

class SetAnnounceMealInitial extends SetAnnounceMealState {}

class SetAnnounceMealLoading extends SetAnnounceMealState {
  const SetAnnounceMealLoading();

  @override
  List<Object> get props => [];
}

class SetAnnounceMealSuccess extends SetAnnounceMealState {
  const SetAnnounceMealSuccess();

  @override
  List<Object> get props => [];
}

class SetAnnounceMealFailure extends SetAnnounceMealState {
  const SetAnnounceMealFailure(this.failure);
  final ErrorException failure;

  @override
  List<Object> get props => [failure];
}

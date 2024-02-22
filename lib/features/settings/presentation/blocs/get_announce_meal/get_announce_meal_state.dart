part of 'get_announce_meal_bloc.dart';

abstract class GetAnnounceMealState extends Equatable {
  const GetAnnounceMealState();

  @override
  List<Object?> get props => [];
}

class GetAnnounceMealLoading extends GetAnnounceMealState {
  const GetAnnounceMealLoading();
}

class GetAnnounceMealSuccess extends GetAnnounceMealState {
  const GetAnnounceMealSuccess(this.success);

  final int success;

  @override
  List<Object?> get props => [success];
}

class GetAnnounceMealFailure extends GetAnnounceMealState {
  const GetAnnounceMealFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}

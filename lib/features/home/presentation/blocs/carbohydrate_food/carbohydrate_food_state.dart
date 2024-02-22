part of 'carbohydrate_food_bloc.dart';

abstract class CarbohydrateFoodState extends Equatable {
  const CarbohydrateFoodState();

  @override
  List<Object> get props => [];
}

class CarbohydrateFoodLoading extends CarbohydrateFoodState {
  const CarbohydrateFoodLoading();
}

class CarbohydrateFoodSuccess extends CarbohydrateFoodState {
  const CarbohydrateFoodSuccess(this.data);

  final CarbohydrateFoodData data;

  @override
  List<Object> get props => [data];
}

class CarbohydrateFoodFailure extends CarbohydrateFoodState {
  const CarbohydrateFoodFailure(this.error);

  final ErrorException error;

  @override
  List<Object> get props => [error];
}

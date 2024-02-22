part of 'carbohydrate_food_bloc.dart';

abstract class CarbohydrateFoodEvent extends Equatable {
  const CarbohydrateFoodEvent();

  @override
  List<Object?> get props => [];
}

class CarbohydrateFoodFetched extends CarbohydrateFoodEvent {
  const CarbohydrateFoodFetched({
    this.page,
    this.perPage = 1000,
    this.search,
    this.source,
  });
  final int? page;
  final int? perPage;
  final String? search;
  final String? source;

  @override
  List<Object?> get props => [page, perPage, search, source];
}

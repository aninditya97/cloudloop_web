import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';

part 'carbohydrate_food_event.dart';
part 'carbohydrate_food_state.dart';

class CarbohydrateFoodBloc
    extends Bloc<CarbohydrateFoodEvent, CarbohydrateFoodState> {
  CarbohydrateFoodBloc({required this.carbohydrateFood})
      : super(const CarbohydrateFoodLoading()) {
    on<CarbohydrateFoodFetched>(_onDataFetched);
  }

  final GetCarbohydrateFoodUseCase carbohydrateFood;

  Future _onDataFetched(
    CarbohydrateFoodFetched event,
    Emitter<CarbohydrateFoodState> emit,
  ) async {
    try {
      emit(const CarbohydrateFoodLoading());
      final result = await carbohydrateFood(
        CarbohydrateFoodDataParams(
          page: event.page,
          perPage: event.perPage,
          search: event.search,
          source: event.source,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          CarbohydrateFoodFailure.new,
          CarbohydrateFoodSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        CarbohydrateFoodFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

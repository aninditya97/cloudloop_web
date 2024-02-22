import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:equatable/equatable.dart';

part 'get_announce_meal_event.dart';
part 'get_announce_meal_state.dart';

class GetAnnounceMealBloc
    extends Bloc<GetAnnounceMealEvent, GetAnnounceMealState> {
  GetAnnounceMealBloc({
    required this.getAnnounceMealUseCase,
  }) : super(const GetAnnounceMealLoading()) {
    on<AnnounceMealFetched>(_onDataFetched);
  }

  final GetAnnounceMealUseCase getAnnounceMealUseCase;

  Future _onDataFetched(
    AnnounceMealFetched event,
    Emitter<GetAnnounceMealState> emit,
  ) async {
    try {
      emit(const GetAnnounceMealLoading());
      final result = await getAnnounceMealUseCase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          GetAnnounceMealFailure.new,
          GetAnnounceMealSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        GetAnnounceMealFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

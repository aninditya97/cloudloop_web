import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:equatable/equatable.dart';

part 'set_announce_meal_event.dart';
part 'set_announce_meal_state.dart';

class SetAnnounceMealBloc
    extends Bloc<SetAnnounceMealEvent, SetAnnounceMealState> {
  SetAnnounceMealBloc({required this.setAnnounceMealUseCase})
      : super(SetAnnounceMealInitial()) {
    on<AnnounceMealRequestSubmitted>(_onDataFetched);
  }

  final SetAnnounceMealUseCase setAnnounceMealUseCase;

  Future _onDataFetched(
    AnnounceMealRequestSubmitted event,
    Emitter<SetAnnounceMealState> emit,
  ) async {
    try {
      emit(const SetAnnounceMealLoading());
      final result = await setAnnounceMealUseCase(
        AnnounceMealParams(type: event.type),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          SetAnnounceMealFailure.new,
          (r) => const SetAnnounceMealSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SetAnnounceMealFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

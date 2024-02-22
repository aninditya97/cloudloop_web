import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:equatable/equatable.dart';

part 'set_auto_mode_event.dart';
part 'set_auto_mode_state.dart';

class SetAutoModeBloc extends Bloc<SetAutoModeEvent, SetAutoModeState> {
  SetAutoModeBloc({required this.setAutoModeUseCase})
      : super(SetAutoModeInitial()) {
    on<AutoModeRequestSubmitted>(_onDataFetched);
  }

  final SetAutoModeUseCase setAutoModeUseCase;

  Future _onDataFetched(
    AutoModeRequestSubmitted event,
    Emitter<SetAutoModeState> emit,
  ) async {
    try {
      emit(const SetAutoModeLoading());
      final result = await setAutoModeUseCase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          SetAutoModeFailure.new,
          (r) => const SetAutoModeSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SetAutoModeFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

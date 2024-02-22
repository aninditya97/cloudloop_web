import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:equatable/equatable.dart';

part 'save_pump_event.dart';
part 'save_pump_state.dart';

class SavePumpBloc extends Bloc<SavePumpEvent, SavePumpState> {
  SavePumpBloc({
    required this.savePumpUsecase,
  }) : super(PumpInitial()) {
    on<SavePump>(_onSaveData);
  }

  final SavePumpUseCase savePumpUsecase;

  Future _onSaveData(
    SavePump event,
    Emitter<SavePumpState> emit,
  ) async {
    try {
      emit(const SavePumpLoading());
      final result = await savePumpUsecase(event.pump);

      if (emit.isDone) return;

      emit(
        result.fold(
          SavePumpFailure.new,
          (r) => const SavePumpSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SavePumpFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

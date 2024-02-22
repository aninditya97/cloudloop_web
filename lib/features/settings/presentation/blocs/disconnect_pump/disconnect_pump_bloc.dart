import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/usecases/disconnect_pump_usecase.dart';
import 'package:equatable/equatable.dart';

part 'disconnect_pump_event.dart';
part 'disconnect_pump_state.dart';

class DisconnectPumpBloc
    extends Bloc<DisconnectPumpEvent, DisconnectPumpState> {
  DisconnectPumpBloc({required this.disconnectPumpUseCase})
      : super(DisconnectPumpInitial()) {
    on<DisconnectPumpFetched>(_onDataFetched);
  }

  final DisconnectPumpUseCase disconnectPumpUseCase;

  Future _onDataFetched(
    DisconnectPumpFetched event,
    Emitter<DisconnectPumpState> emit,
  ) async {
    try {
      emit(const DisconnectPumpLoading());
      final result = await disconnectPumpUseCase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          DisconnectPumpFailure.new,
          (r) => const DisconnectPumpSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        DisconnectPumpFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

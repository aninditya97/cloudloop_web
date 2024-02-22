import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/domain.dart';
import 'package:equatable/equatable.dart';

part 'get_pump_event.dart';
part 'get_pump_state.dart';

class GetPumpBloc extends Bloc<GetPumpEvent, GetPumpState> {
  GetPumpBloc({
    required this.getPumpUseCase,
  }) : super(const GetPumpLoading()) {
    on<PumpFetched>(_onDataFetched);
  }

  final GetPumpUseCase getPumpUseCase;

  Future _onDataFetched(
    PumpFetched event,
    Emitter<GetPumpState> emit,
  ) async {
    try {
      emit(const GetPumpLoading());
      final result = await getPumpUseCase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          GetPumpFailure.new,
          GetPumpSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        GetPumpFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

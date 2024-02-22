import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/usecases/disconnect_cgm_usecase.dart';
import 'package:equatable/equatable.dart';

part 'disconnect_cgm_event.dart';
part 'disconnect_cgm_state.dart';

class DisconnectCgmBloc extends Bloc<DisconnectCgmEvent, DisconnectCgmState> {
  DisconnectCgmBloc({required this.disconnectCgmUseCase})
      : super(DisconnectCgmInitial()) {
    on<DisconnectCgmFetched>(_onDataFetched);
  }

  final DisconnectCgmUseCase disconnectCgmUseCase;

  Future _onDataFetched(
    DisconnectCgmFetched event,
    Emitter<DisconnectCgmState> emit,
  ) async {
    try {
      emit(const DisconnectCgmLoading());
      final result = await disconnectCgmUseCase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          DisconnectCgmFailure.new,
          (r) => const DisconnectCgmSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        DisconnectCgmFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

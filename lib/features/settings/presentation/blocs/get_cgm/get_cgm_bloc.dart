import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:equatable/equatable.dart';

part 'get_cgm_event.dart';
part 'get_cgm_state.dart';

class GetCgmBloc extends Bloc<GetCgmEvent, GetCgmState> {
  GetCgmBloc({
    required this.getCgmUseCase,
  }) : super(const GetCgmLoading()) {
    on<CgmFetched>(_onDataFetched);
  }

  final GetCgmUseCase getCgmUseCase;

  Future _onDataFetched(
    CgmFetched event,
    Emitter<GetCgmState> emit,
  ) async {
    try {
      emit(const GetCgmLoading());
      final result = await getCgmUseCase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          GetCgmFailure.new,
          GetCgmSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        GetCgmFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

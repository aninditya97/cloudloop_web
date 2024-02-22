import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:equatable/equatable.dart';

part 'get_auto_mode_event.dart';
part 'get_auto_mode_state.dart';

class GetAutoModeBloc extends Bloc<GetAutoModeEvent, GetAutoModeState> {
  GetAutoModeBloc({
    required this.getAutoModeUseCase,
  }) : super(const GetAutoModeLoading()) {
    on<AutoModeFetched>(_onDataFetched);
  }

  final GetAutoModeUseCase getAutoModeUseCase;

  Future _onDataFetched(
    AutoModeFetched event,
    Emitter<GetAutoModeState> emit,
  ) async {
    try {
      emit(const GetAutoModeLoading());
      final result = await getAutoModeUseCase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          GetAutoModeFailure.new,
          GetAutoModeSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        GetAutoModeFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/usecases/leave_family_usecase.dart';
import 'package:equatable/equatable.dart';

part 'leave_family_event.dart';
part 'leave_family_state.dart';

class LeaveFamilyBloc extends Bloc<LeaveFamilyEvent, LeaveFamilyState> {
  LeaveFamilyBloc({required this.leaveFamilyUseCase})
      : super(LeaveFamilyInitial()) {
    on<LeaveFamilyFetched>(_onDataFetched);
  }

  final LeaveFamilyUseCase leaveFamilyUseCase;

  Future _onDataFetched(
    LeaveFamilyFetched event,
    Emitter<LeaveFamilyState> emit,
  ) async {
    try {
      emit(const LeaveFamilyLoading());
      final result = await leaveFamilyUseCase(
        LeaveFamilyMemberParams(
          id: event.id,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          LeaveFamilyFailure.new,
          (r) => const LeaveFamilySuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        LeaveFamilyFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

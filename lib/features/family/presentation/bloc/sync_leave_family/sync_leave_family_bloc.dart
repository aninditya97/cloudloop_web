import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'sync_leave_family_event.dart';
part 'sync_leave_family_state.dart';

class SyncLeaveFamilyBloc
    extends Bloc<SyncLeaveFamilyEvent, SyncLeaveFamilyState> {
  SyncLeaveFamilyBloc({required this.syncLeaveFamilyUsecase})
      : super(SyncLeaveFamilyInitial()) {
    on<SyncLeaveFamilyFetched>(_onDataFetched);
  }

  final SyncLeaveFamilyUseCase syncLeaveFamilyUsecase;

  Future _onDataFetched(
    SyncLeaveFamilyFetched event,
    Emitter<SyncLeaveFamilyState> emit,
  ) async {
    try {
      emit(const SyncLeaveFamilyLoading());
      final result = await syncLeaveFamilyUsecase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          SyncLeaveFamilyFailure.new,
          (r) => const SyncLeaveFamilySuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SyncLeaveFamilyFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

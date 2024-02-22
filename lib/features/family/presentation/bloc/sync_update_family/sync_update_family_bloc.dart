import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'sync_update_family_event.dart';
part 'sync_update_family_state.dart';

class SyncUpdateFamilyBloc
    extends Bloc<SyncUpdateFamilyEvent, SyncUpdateFamilyState> {
  SyncUpdateFamilyBloc({required this.syncUpdateFamilyUsecase})
      : super(SyncUpdateFamilyInitial()) {
    on<SyncUpdateFamilyFetched>(_onDataFetched);
  }

  final SyncUpdateFamilyUseCase syncUpdateFamilyUsecase;

  Future _onDataFetched(
    SyncUpdateFamilyFetched event,
    Emitter<SyncUpdateFamilyState> emit,
  ) async {
    try {
      emit(const SyncUpdateFamilyLoading());
      final result = await syncUpdateFamilyUsecase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          SyncUpdateFamilyFailure.new,
          (r) => const SyncUpdateFamilySuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SyncUpdateFamilyFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

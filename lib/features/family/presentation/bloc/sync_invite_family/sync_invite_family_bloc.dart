import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'sync_invite_family_event.dart';
part 'sync_invite_family_state.dart';

class SyncInviteFamilyBloc
    extends Bloc<SyncInviteFamilyEvent, SyncInviteFamilyState> {
  SyncInviteFamilyBloc({required this.syncInviteFamilyUsecase})
      : super(SyncInviteFamilyInitial()) {
    on<SyncInviteFamilyFetched>(_onDataFetched);
  }

  final SyncInviteFamilyUseCase syncInviteFamilyUsecase;

  Future _onDataFetched(
    SyncInviteFamilyFetched event,
    Emitter<SyncInviteFamilyState> emit,
  ) async {
    try {
      emit(const SyncInviteFamilyLoading());
      final result = await syncInviteFamilyUsecase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          SyncInviteFamilyFailure.new,
          (r) => const SyncInviteFamilySuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SyncInviteFamilyFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

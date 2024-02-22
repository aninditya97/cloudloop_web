import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'sync_reject_family_invitation_event.dart';
part 'sync_reject_family_invitation_state.dart';

class SyncRejectFamilyInvitationBloc extends Bloc<
    SyncRejectFamilyInvitationEvent, SyncRejectFamilyInvitationState> {
  SyncRejectFamilyInvitationBloc({
    required this.syncRejectFamilyInvitationUsecase,
  }) : super(SyncRejectFamilyInvitationInitial()) {
    on<SyncRejectFamilyInvitationFetched>(_onDataFetched);
  }

  final SyncRejectFamilyInvitationUseCase syncRejectFamilyInvitationUsecase;

  Future _onDataFetched(
    SyncRejectFamilyInvitationFetched event,
    Emitter<SyncRejectFamilyInvitationState> emit,
  ) async {
    try {
      emit(const SyncRejectFamilyInvitationLoading());
      final result = await syncRejectFamilyInvitationUsecase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          SyncRejectFamilyInvitationFailure.new,
          (r) => const SyncRejectFamilyInvitationSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SyncRejectFamilyInvitationFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'sync_accept_family_invitation_event.dart';
part 'sync_accept_family_invitation_state.dart';

class SyncAcceptFamilyInvitationBloc extends Bloc<
    SyncAcceptFamilyInvitationEvent, SyncAcceptFamilyInvitationState> {
  SyncAcceptFamilyInvitationBloc({
    required this.syncAcceptFamilyInvitationUsecase,
  }) : super(SyncAcceptFamilyInvitationInitial()) {
    on<SyncAcceptFamilyInvitationFetched>(_onDataFetched);
  }

  final SyncAcceptFamilyInvitationUseCase syncAcceptFamilyInvitationUsecase;

  Future _onDataFetched(
    SyncAcceptFamilyInvitationFetched event,
    Emitter<SyncAcceptFamilyInvitationState> emit,
  ) async {
    try {
      emit(const SyncAcceptFamilyInvitationLoading());
      final result = await syncAcceptFamilyInvitationUsecase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          SyncAcceptFamilyInvitationFailure.new,
          (r) => const SyncAcceptFamilyInvitationSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SyncAcceptFamilyInvitationFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

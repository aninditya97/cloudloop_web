import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/usecases/reject_family_invitation_usecase.dart';
import 'package:equatable/equatable.dart';

part 'reject_family_invitation_event.dart';
part 'reject_family_invitation_state.dart';

class RejectFamilyInvitationBloc
    extends Bloc<RejectFamilyInvitationEvent, RejectFamilyInvitationState> {
  RejectFamilyInvitationBloc({required this.rejectFamilyInvitationUsecase})
      : super(RejectFamilyInvitationInitial()) {
    on<RejectFamilyInvitationFetched>(_onDataFetched);
  }

  final RejectFamilyInvitationUsecase rejectFamilyInvitationUsecase;

  Future _onDataFetched(
    RejectFamilyInvitationFetched event,
    Emitter<RejectFamilyInvitationState> emit,
  ) async {
    try {
      emit(const RejectFamilyInvitationLoading());
      final result = await rejectFamilyInvitationUsecase(
        RejectFamilyInvitationParams(
          id: event.id,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          RejectFamilyInvitationFailure.new,
          (r) => const RejectFamilyInvitationSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        RejectFamilyInvitationFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

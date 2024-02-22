import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/usecases/accept_family_invitation_usecase.dart';
import 'package:equatable/equatable.dart';

part 'accept_family_invitation_event.dart';
part 'accept_family_invitation_state.dart';

class AcceptFamilyInvitationBloc
    extends Bloc<AcceptFamilyInvitationEvent, AcceptFamilyInvitationState> {
  AcceptFamilyInvitationBloc({required this.acceptFamilyInvitationUsecase})
      : super(AcceptFamilyInvitationInitial()) {
    on<AcceptFamilyInvitationFetched>(_onDataFetched);
  }

  final AcceptFamilyInvitationUsecase acceptFamilyInvitationUsecase;

  Future _onDataFetched(
    AcceptFamilyInvitationFetched event,
    Emitter<AcceptFamilyInvitationState> emit,
  ) async {
    try {
      emit(const AcceptFamilyInvitationLoading());
      final result = await acceptFamilyInvitationUsecase(
        AcceptFamilyInvitationParams(
          id: event.id,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          AcceptFamilyInvitationFailure.new,
          (r) => const AcceptFamilyInvitationSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        AcceptFamilyInvitationFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

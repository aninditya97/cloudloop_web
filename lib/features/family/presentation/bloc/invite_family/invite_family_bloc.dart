import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'invite_family_event.dart';
part 'invite_family_state.dart';

class InviteFamilyBloc extends Bloc<InviteFamilyEvent, InviteFamilyState> {
  InviteFamilyBloc({required this.inviteFamilyUsecase})
      : super(InviteFamilyInitial()) {
    on<InviteFamilyFetched>(_onDataFetched);
  }

  final InviteFamilyUseCase inviteFamilyUsecase;

  Future _onDataFetched(
    InviteFamilyFetched event,
    Emitter<InviteFamilyState> emit,
  ) async {
    try {
      emit(const InviteFamilyLoading());
      final result = await inviteFamilyUsecase(
        InviteFamilyParams(
          email: event.email,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          InviteFamilyFailure.new,
          (r) => const InviteFamilySuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        InviteFamilyFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

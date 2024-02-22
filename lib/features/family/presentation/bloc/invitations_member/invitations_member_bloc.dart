import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/domain/entities/entities.dart';
import 'package:cloudloop_mobile/features/family/domain/usecases/get_invitations_usecase.dart';
import 'package:equatable/equatable.dart';

part 'invitations_member_event.dart';
part 'invitations_member_state.dart';

class InvitationsMemberBloc
    extends Bloc<InvitationsMemberEvent, InvitationsMemberState> {
  InvitationsMemberBloc({required this.invitationsMemberUseCase})
      : super(InvitationsMemberLoading()) {
    on<FetchInvitationsMemberEvent>(_onFetchInvitationsMember);
  }

  final GetInvitationsUseCase invitationsMemberUseCase;

  Future _onFetchInvitationsMember(
    FetchInvitationsMemberEvent event,
    Emitter<InvitationsMemberState> emit,
  ) async {
    if (!_isAllow(event)) return;

    final currentState = state;

    if (event.page == 1) {
      emit(InvitationsMemberLoading());
    }
    try {
      final _result = await invitationsMemberUseCase(
        PaginateParams(
          page: event.page,
          perPage: event.perPage,
        ),
      );

      _result.fold((l) {
        if (event.page == 1) {
          emit(InvitationsMemberFailure(l));
        }
      }, (r) {
        if (currentState is InvitationsMemberLoading || event.page == 1) {
          emit(
            InvitationsMemberSuccess(
              data: r.data,
              hasReachedMax: r.data.length < event.perPage,
              page: r.meta.page,
            ),
          );
        } else if (currentState is InvitationsMemberSuccess &&
            currentState.page < (r.meta.page)) {
          emit(
            InvitationsMemberSuccess(
              data: currentState.data + r.data,
              hasReachedMax: r.data.length < event.perPage,
              page: r.meta.page,
            ),
          );
        }
      });
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        InvitationsMemberFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }

  bool _isAllow(FetchInvitationsMemberEvent event) {
    if (!_hasReachedMax(state) || event.page == 1) {
      if (state is InvitationsMemberSuccess) {
        final currentState = state as InvitationsMemberSuccess;
        if (event.page == 1 || event.page > currentState.page) {
          return true;
        }
      } else if (event.page == 1) {
        return true;
      }
    }
    return false;
  }

  bool _hasReachedMax(InvitationsMemberState state) =>
      state is InvitationsMemberSuccess && state.hasReachedMax;
}

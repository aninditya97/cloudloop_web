import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'family_member_event.dart';
part 'family_member_state.dart';

class FamilyMemberBloc extends Bloc<FamilyMemberEvent, FamilyMemberState> {
  FamilyMemberBloc({required this.familyMemberUseCase})
      : super(FamilyMemberLoading()) {
    on<FetchFamilyMemberEvent>(
      _onFetchFamilyMember,
      transformer: throttleDroppable(
        const Duration(milliseconds: 500),
      ),
    );
  }
  final GetFamilyMemberUseCase familyMemberUseCase;

  Future _onFetchFamilyMember(
    FetchFamilyMemberEvent event,
    Emitter<FamilyMemberState> emit,
  ) async {
    if (!_isAllow(event)) return;

    final currentState = state;

    if (event.page == 1) {
      emit(FamilyMemberLoading());
    }
    try {
      final _result = await familyMemberUseCase(
        PaginateParams(
          page: event.page,
          perPage: event.perPage,
        ),
      );

      _result.fold((l) {
        if (event.page == 1) {
          emit(FamilyMemberFailure(l));
        }
      }, (r) {
        if (currentState is FamilyMemberLoading || event.page == 1) {
          emit(
            FamilyMemberSuccess(
              data: r.data,
              hasReachedMax: r.data.length < event.perPage,
              page: r.meta.page,
            ),
          );
        } else if (currentState is FamilyMemberSuccess &&
            currentState.page < (r.meta.page)) {
          emit(
            FamilyMemberSuccess(
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
        FamilyMemberFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }

  bool _isAllow(FetchFamilyMemberEvent event) {
    if (!_hasReachedMax(state) || event.page == 1) {
      if (state is FamilyMemberSuccess) {
        final currentState = state as FamilyMemberSuccess;
        if (event.page == 1 || event.page > currentState.page) {
          return true;
        }
      } else if (event.page == 1) {
        return true;
      }
    }
    return false;
  }

  bool _hasReachedMax(FamilyMemberState state) =>
      state is FamilyMemberSuccess && state.hasReachedMax;
}

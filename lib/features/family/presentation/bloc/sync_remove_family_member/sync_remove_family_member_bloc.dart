import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'sync_remove_family_member_event.dart';
part 'sync_remove_family_member_state.dart';

class SyncRemoveFamilyMemberBloc
    extends Bloc<SyncRemoveFamilyMemberEvent, SyncRemoveFamilyMemberState> {
  SyncRemoveFamilyMemberBloc({required this.syncRemoveFamilyMemberUsecase})
      : super(SyncRemoveFamilyMemberInitial()) {
    on<SyncRemoveFamilyMemberFetched>(_onDataFetched);
  }

  final SyncRemoveFamilyMemberUseCase syncRemoveFamilyMemberUsecase;

  Future _onDataFetched(
    SyncRemoveFamilyMemberFetched event,
    Emitter<SyncRemoveFamilyMemberState> emit,
  ) async {
    try {
      emit(const SyncRemoveFamilyMemberLoading());
      final result = await syncRemoveFamilyMemberUsecase(const NoParams());

      if (emit.isDone) return;

      emit(
        result.fold(
          SyncRemoveFamilyMemberFailure.new,
          (r) => const SyncRemoveFamilyMemberSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        SyncRemoveFamilyMemberFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/exceptions/exceptions.dart';
import 'package:cloudloop_mobile/core/extensions/extensions.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'remove_family_member_event.dart';
part 'remove_family_member_state.dart';

class RemoveFamilyMemberBloc
    extends Bloc<RemoveFamilyMemberEvent, RemoveFamilyMemberState> {
  RemoveFamilyMemberBloc({required this.removeFamilyMemberUsecase})
      : super(RemoveFamilyMemberInitial()) {
    on<RemoveFamilyMemberFetched>(_onDataFetched);
  }

  final RemoveFamilyMemberUsecase removeFamilyMemberUsecase;

  Future _onDataFetched(
    RemoveFamilyMemberFetched event,
    Emitter<RemoveFamilyMemberState> emit,
  ) async {
    try {
      emit(const RemoveFamilyMemberLoading());
      final result = await removeFamilyMemberUsecase(
        RemoveFamilyMemberParams(
          id: event.id,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          RemoveFamilyMemberFailure.new,
          (r) => const RemoveFamilyMemberSuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        RemoveFamilyMemberFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

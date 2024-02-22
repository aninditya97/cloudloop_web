import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'update_family_event.dart';
part 'update_family_state.dart';

class UpdateFamilyBloc extends Bloc<UpdateFamilyEvent, UpdateFamilyState> {
  UpdateFamilyBloc({required this.updateFamilyUsecase})
      : super(UpdateFamilyInitial()) {
    on<UpdateFamilyFetched>(_onDataFetched);
  }

  final UpdateFamilyUsecase updateFamilyUsecase;

  Future _onDataFetched(
    UpdateFamilyFetched event,
    Emitter<UpdateFamilyState> emit,
  ) async {
    try {
      emit(const UpdateFamilyLoading());
      final result = await updateFamilyUsecase(
        UpdateFamilyParams(
          id: event.id,
          label: event.label,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          UpdateFamilyFailure.new,
          (r) => const UpdateFamilySuccess(),
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        UpdateFamilyFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

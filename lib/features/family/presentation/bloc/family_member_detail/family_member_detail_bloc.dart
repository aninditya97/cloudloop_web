import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';

part 'family_member_detail_event.dart';
part 'family_member_detail_state.dart';

class FamilyMemberDetailBloc
    extends Bloc<FamilyMemberDetailEvent, FamilyMemberDetailState> {
  FamilyMemberDetailBloc({required this.familyMemberDetail})
      : super(const FamilyMemberDetailLoading()) {
    on<FamilyMemberDetailFetched>(_onDataFetched);
  }

  final GetFamilyMemberByIdUseCase familyMemberDetail;

  Future _onDataFetched(
    FamilyMemberDetailFetched event,
    Emitter<FamilyMemberDetailState> emit,
  ) async {
    try {
      emit(const FamilyMemberDetailLoading());
      final result = await familyMemberDetail(
        GetFamilyMemberByIdParams(
          event.id,
        ),
      );

      if (emit.isDone) return;

      emit(
        result.fold(
          FamilyMemberDetailFailure.new,
          FamilyMemberDetailSuccess.new,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        FamilyMemberDetailFailure(
          ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

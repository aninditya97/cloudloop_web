import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:intl/intl.dart';

part 'input_insulin_event.dart';
part 'input_insulin_state.dart';

class InputInsulinBloc extends Bloc<InputInsulinEvent, InputInsulinState> {
  InputInsulinBloc({
    required this.inputInsulin,
  }) : super(const InputInsulinState.pure()) {
    on<InputInsulinValueChanged>(_onValueChanged);
    on<InputInsulinSubmitted>(_onSubmited);
  }

  final InputInsulinUsecase inputInsulin;

  void _onValueChanged(
    InputInsulinValueChanged event,
    Emitter<InputInsulinState> emit,
  ) {
    _validateState(
      emit,
      state: state.copyWith(insulin: state.insulin.dirty(event.value)),
    );
  }

  // Method to validate all fields
  void _validateState(
    Emitter<InputInsulinState> emit, {
    required InputInsulinState state,
  }) {
    emit(
      state.copyWith(
        insulin: state.insulin,
        status: Formz.validate([state.insulin]),
      ),
    );
  }

  Future _onSubmited(
    InputInsulinSubmitted event,
    Emitter<InputInsulinState> emit,
  ) async {
    try {
      if (!state.status.isValidated) return;
      emit(
        state.copyWith(
          status: FormzStatus.submissionInProgress,
        ),
      );

      final result = await inputInsulin(
        SendInsulinDeliveryParams(
          value: state.insulin.value ?? 0,
          source: event.source.toCode(),
          time: DateFormat('yyyy-MM-dd HH:mm:ss').format(
            DateTime.now(),
          ),
          announceMealEnabled: event.announceMeal,
          autoModeEnabled: event.autoMode,
          iob: event.iob,
          hypoPrevention: event.hypoPrevention,
        ),
      );

      emit(
        result.fold(
          (failure) => state.copyWith(
            status: FormzStatus.submissionFailure,
            failure: failure,
          ),
          (data) => state.copyWith(
            status: FormzStatus.submissionSuccess,
          ),
        ),
      );
    } on ErrorException catch (e) {
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          failure: e,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          failure: ErrorCodeException(message: error.toString()),
        ),
      );
    }
  }
}

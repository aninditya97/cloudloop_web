import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:intl/intl.dart';

part 'input_bg_event.dart';
part 'input_bg_state.dart';

class InputBloodGlucoseBloc
    extends Bloc<InputBloodGlucoseEvent, InputBloodGlucoseState> {
  InputBloodGlucoseBloc({
    required this.inputBloodGlucose,
  }) : super(const InputBloodGlucoseState.pure()) {
    on<InputBloodGlucoseValueChanged>(_onValueChanged);
    on<InputBloodGlucoseSubmitted>(_onSubmited);
  }

  final InputBloodGlucoseUsecase inputBloodGlucose;

  void _onValueChanged(
    InputBloodGlucoseValueChanged event,
    Emitter<InputBloodGlucoseState> emit,
  ) {
    _validateState(
      emit,
      state: state.copyWith(glucose: state.glucose.dirty(event.value)),
    );
  }

  // Method to validate all fields
  void _validateState(
    Emitter<InputBloodGlucoseState> emit, {
    required InputBloodGlucoseState state,
  }) {
    emit(
      state.copyWith(
        glucose: state.glucose,
        status: Formz.validate([state.glucose]),
      ),
    );
  }

  Future _onSubmited(
    InputBloodGlucoseSubmitted event,
    Emitter<InputBloodGlucoseState> emit,
  ) async {
    try {
      if (!state.status.isValidated) return;
      emit(state.copyWith(status: FormzStatus.submissionInProgress));

      final result = await inputBloodGlucose(
        SendBloodGlucoseParams(
          value: state.glucose.value ?? 0,
          source: event.source.toCode(),
          time: event.time != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(event.time!)
              : null,
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

import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:formz/formz.dart';

part 'input_carbo_event.dart';
part 'input_carbo_state.dart';

class InputCarbohydrateBloc
    extends Bloc<InputCarbohydrateEvent, InputCarbohydrateState> {
  InputCarbohydrateBloc({
    required this.inputCarbohydrate,
  }) : super(const InputCarbohydrateState.pure()) {
    on<InputCarbohydrateValueChanged>(_onValueChanged);
    on<InputCarbohydrateDateChanged>(_onDateChanged);
    on<InputCarbohydrateFoodTypeChanged>(_onFoodTypeChanged);
    on<InputCarbohydrateTimeChanged>(_onTimeChanged);
    on<InputCarbohydrateSubmitted>(_onSubmited);
  }

  final InputCarbohydratesUsecase inputCarbohydrate;

  void _onValueChanged(
    InputCarbohydrateValueChanged event,
    Emitter<InputCarbohydrateState> emit,
  ) {
    _validateState(
      emit,
      state:
          state.copyWith(carbohydrate: state.carbohydrate.dirty(event.value)),
    );
  }

  void _onDateChanged(
    InputCarbohydrateDateChanged event,
    Emitter<InputCarbohydrateState> emit,
  ) {
    _validateState(
      emit,
      state: state.copyWith(
        date: state.date.dirty(event.date),
        time: state.time.value == null
            ? state.time.dirty(TimeOfDay.fromDateTime(event.date))
            : null,
      ),
    );
  }

  void _onTimeChanged(
    InputCarbohydrateTimeChanged event,
    Emitter<InputCarbohydrateState> emit,
  ) {
    _validateState(
      emit,
      state: state.copyWith(time: state.time.dirty(event.time)),
    );
  }

  void _onFoodTypeChanged(
    InputCarbohydrateFoodTypeChanged event,
    Emitter<InputCarbohydrateState> emit,
  ) {
    _validateState(
      emit,
      state: state.copyWith(foodType: state.foodType.dirty(event.foodType)),
    );
  }

  // Method to validate all fields
  void _validateState(
    Emitter<InputCarbohydrateState> emit, {
    required InputCarbohydrateState state,
  }) {
    emit(
      state.copyWith(
        carbohydrate: state.carbohydrate,
        foodType: state.foodType,
        time: state.time,
        date: state.date,
        status: Formz.validate([
          state.carbohydrate,
          state.foodType,
          state.time,
          state.date,
        ]),
      ),
    );
  }

  Future _onSubmited(
    InputCarbohydrateSubmitted event,
    Emitter<InputCarbohydrateState> emit,
  ) async {
    try {
      if (!state.status.isValidated) return;
      emit(state.copyWith(status: FormzStatus.submissionInProgress));

      var dateTime = state.date.value;
      if (dateTime != null) {
        final time = state.time.value;
        if (time != null) {
          dateTime = DateTime(
            dateTime.year,
            dateTime.month,
            dateTime.day,
            time.hour,
            time.minute,
          );
        }
      }

      final result = await inputCarbohydrate(
        InputCarboParams(
          value: state.carbohydrate.value ?? 0,
          source: event.source,
          time: dateTime,
          foodType: state.foodType.value!,
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

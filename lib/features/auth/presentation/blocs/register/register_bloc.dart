import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required this.registerFirebase}) : super(RegisterState.pure()) {
    on<RegisterAuthTokenChanged>(_onGoogleAuthChanged);
    on<RegisterFullNameChanged>(_onFullNameChanged);
    on<RegisterGenderChanged>(_onGenderChanged);
    on<RegisterDateOfBirthChanged>(_onDateOfBirthChanged);
    // on<RegisterDiabetesTypeChanged>(_onDiabetesTypeChanged);
    on<RegisterWeightChanged>(_onWeightChanged);
    on<RegisterDailyDoseChanged>(_onDailyDoseChanged);
    on<RegisterTypicalBasalRateChanged>(_onTypicalBasalRateChanged);
    on<RegisterTypicalICRChanged>(_onTypicalICRChanged);
    on<RegisterTypicalISFChanged>(_onTypicalISFChanged);
    on<RegisterRequestSubmitted>(_onSubmitted);
    on<RegisterRequestResetted>(_onResetted);
  }

  final RegisterFirebaseUsecase registerFirebase;

  Future _onGoogleAuthChanged(
    RegisterAuthTokenChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final googleAuth = state.googleAuth.dirty(event.credential);
      _validateState(emit, state: state.copyWith(googleAuth: googleAuth));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onFullNameChanged(
    RegisterFullNameChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final fullName = state.fullName.dirty(event.fullName);
      _validateState(emit, state: state.copyWith(fullName: fullName));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onGenderChanged(
    RegisterGenderChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final gender = state.gender.dirty(event.gender);
      _validateState(emit, state: state.copyWith(gender: gender));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onDateOfBirthChanged(
    RegisterDateOfBirthChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final dateOfBirth = state.dateOfBirth.dirty(event.dateOfBirth);
      _validateState(emit, state: state.copyWith(dateOfBirth: dateOfBirth));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  // Future _onDiabetesTypeChanged(
  //   RegisterDiabetesTypeChanged event,
  //   Emitter<RegisterState> emit,
  // ) async {
  //   try {
  //     final diabetesType = state.diabetesType.dirty(event.diabetesType);
  //     _validateState(emit, state:
  //state.copyWith(diabetesType: diabetesType));
  //   } catch (error, stackTrace) {
  //     error.recordError(stackTrace: stackTrace);
  //   }
  // }

  Future _onWeightChanged(
    RegisterWeightChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final weight = state.weight.dirty(event.weight);
      _validateState(emit, state: state.copyWith(weight: weight));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onDailyDoseChanged(
    RegisterDailyDoseChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final dailyDose = state.totalDailyDose.dirty(event.dailyDose);
      _validateState(emit, state: state.copyWith(totalDailyDose: dailyDose));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onTypicalBasalRateChanged(
    RegisterTypicalBasalRateChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final typicalBasalRate = state.typicalBasalRate.dirty(
        event.typicalBasalRate,
      );
      _validateState(
        emit,
        state: state.copyWith(
          typicalBasalRate: typicalBasalRate,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onTypicalICRChanged(
    RegisterTypicalICRChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final typicalICR = state.typicalICR.dirty(event.typicalICR);
      _validateState(
        emit,
        state: state.copyWith(typicalICR: typicalICR),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onTypicalISFChanged(
    RegisterTypicalISFChanged event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      final typicalISF = state.typicalISF.dirty(event.typicalISF);
      _validateState(
        emit,
        state: state.copyWith(typicalISF: typicalISF),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  // Method to validate all fields

  void _validateState(
    Emitter<RegisterState> emit, {
    required RegisterState state,
  }) {
    emit(
      state.copyWith(
        googleAuth: state.googleAuth,
        fullName: state.fullName,
        gender: state.gender,
        dateOfBirth: state.dateOfBirth,
        // diabetesType: state.diabetesType,
        weight: state.weight,
        totalDailyDose: state.totalDailyDose,
        typicalBasalRate: state.typicalBasalRate,
        typicalICR: state.typicalICR,
        typicalISF: state.typicalISF,
        status: Formz.validate([
          state.googleAuth,
          state.fullName,
          state.gender,
          state.dateOfBirth,
          // state.diabetesType,
          state.weight,
          state.totalDailyDose,
          state.typicalBasalRate,
          state.typicalICR,
          state.typicalISF,
        ]),
      ),
    );
  }

  Future _onResetted(
    RegisterRequestResetted event,
    Emitter<RegisterState> emit,
  ) async {
    _validateState(
      emit,
      state: state.copyWith(
        weight: state.weight.dirty(0),
        totalDailyDose: state.totalDailyDose.dirty(0),
        typicalBasalRate: state.typicalBasalRate.dirty(0),
        typicalICR: state.typicalICR.dirty(0),
        typicalISF: state.typicalISF.dirty(0),
        fullName: state.fullName.dirty(''),
      ),
    );
  }

  Future _onSubmitted(
    RegisterRequestSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      if (!state.status.isValidated) return;
      emit(state.copyWith(status: FormzStatus.submissionInProgress));

      final result = await registerFirebase(
        RegisterFirebaseParams(
          name: state.fullName.value ?? '',
          token: state.googleAuth.value ?? '',
          birthDate: state.dateOfBirth.value!,
          gender: state.gender.value ?? Gender.male,
          // diabetesType: state.diabetesType.value ?? DiabetesType.type1,
          weight: state.weight.value ?? 0,
          totalDailyDose: state.totalDailyDose.value ?? 0,
          typicalBasalRate: state.typicalBasalRate.value ?? 0,
          typicalICR: state.typicalICR.value ?? 0,
          typicalISF: state.typicalISF.value ?? 0,
        ),
      );

      emit(
        result.fold(
          (failure) => state.copyWith(
            status: FormzStatus.submissionFailure,
            failure: failure,
          ),
          (user) => state.copyWith(
            status: FormzStatus.submissionSuccess,
            user: user,
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
      if (error is ErrorException) {
        emit(
          state.copyWith(failure: error, status: FormzStatus.submissionFailure),
        );
      } else {
        emit(
          state.copyWith(
            failure: ErrorCodeException(message: error.toString()),
            status: FormzStatus.submissionFailure,
          ),
        );
      }
    }
  }
}

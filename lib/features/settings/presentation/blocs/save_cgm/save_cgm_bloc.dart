import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

part 'save_cgm_event.dart';
part 'save_cgm_state.dart';

class SaveCgmBloc extends Bloc<SaveCgmEvent, SaveCgmState> {
  SaveCgmBloc({
    required this.saveCgmUsecase,
  }) : super(const SaveCgmState.pure()) {
    on<CgmIdChanged>(_onIdChanged);
    on<CgmDeviceIdChanged>(_onDeviceIdChanged);
    on<CgmRequestSubmitted>(_onSubmitted);
  }

  final SaveCgmUseCase saveCgmUsecase;

  Future _onIdChanged(
    CgmIdChanged event,
    Emitter<SaveCgmState> emit,
  ) async {
    try {
      final id = state.id.dirty(event.id);
      _validateState(emit, state: state.copyWith(id: id));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onDeviceIdChanged(
    CgmDeviceIdChanged event,
    Emitter<SaveCgmState> emit,
  ) async {
    try {
      final deviceId = state.deviceId.dirty(event.deviceId);
      _validateState(
        emit,
        state: state.copyWith(
          deviceId: deviceId,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onTransmitterIdChanged(
    CgmTransmitterIdChanged event,
    Emitter<SaveCgmState> emit,
  ) async {
    try {
      final transmitterId = state.transmitterId.dirty(event.transmitterId);
      _validateState(
        emit,
        state: state.copyWith(
          transmitterId: transmitterId,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  Future _onTransmitterCodeChanged(
    CgmDeviceIdChanged event,
    Emitter<SaveCgmState> emit,
  ) async {
    try {
      final transmitterCode = state.transmitterCode.dirty(event.deviceId);
      _validateState(
        emit,
        state: state.copyWith(
          transmitterCode: transmitterCode,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }

  void _validateState(
    Emitter<SaveCgmState> emit, {
    required SaveCgmState state,
  }) {
    emit(
      state.copyWith(
        id: state.id,
        transmitterId: state.transmitterId,
        transmitterCode: state.transmitterCode,
        deviceId: state.deviceId,
        status: Formz.validate([
          state.id,
          state.deviceId,
          state.transmitterId,
          state.transmitterCode,
        ]),
      ),
    );
  }

  Future _onSubmitted(
    CgmRequestSubmitted event,
    Emitter<SaveCgmState> emit,
  ) async {
    try {
      if (!state.status.isValidated) return;
      emit(state.copyWith(status: FormzStatus.submissionInProgress));

      final result = await saveCgmUsecase(
        CgmData(
          id: state.id.value ?? '',
          deviceId: state.deviceId.value ?? '',
          transmitterId: state.transmitterId.value ?? '',
          transmitterCode: state.transmitterCode.value ?? '',
          status: true,
          connectAt: DateTime.now(),
        ),
      );

      emit(
        result.fold(
          (failure) => state.copyWith(
            status: FormzStatus.submissionFailure,
            failure: failure,
          ),
          (cgm) => state.copyWith(
            status: FormzStatus.submissionSuccess,
            cgm: cgm,
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

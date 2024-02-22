import 'package:bloc/bloc.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:equatable/equatable.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
  }) : super(const ProfileState.loading()) {
    on<ProfileFetched>(_onDataFetched);
    on<ProfileDailyDoseUpdated>(_onDailyDoseUpdated);
    // on<ProfileDiabetesTypeUpdated>(_onDiabetesTypeUpdated);
    on<ProfileTypicalBasalRateUpdated>(_onTypicalBasalRateUpdated);
    on<ProfileTypicalICRUpdated>(_onTypicalICRUpdated);
    on<ProfileTypicalISFUpdated>(_onTypicalISFUpdated);
    on<ProfileWeightUpdated>(_onWeightUpdated);
  }

  final GetProfileUseCase getProfile;
  final UpdateProfileUseCase updateProfile;

  Future _onDataFetched(
    ProfileFetched event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      emit(const ProfileState.loading());

      final result = await getProfile(const NoParams());
      if (emit.isDone) return;

      emit(result.fold(ProfileState.failure, ProfileState.success));
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);

      emit(ProfileState.failure(ErrorCodeException(message: error.toString())));
    }
  }

  void _onDailyDoseUpdated(
    ProfileDailyDoseUpdated event,
    Emitter<ProfileState> emit,
  ) {
    if (state.status == ProfileBlocStatus.success) {
      final newProfile = state.user!.copyWith(totalDailyDose: event.dailyDose);
      emit(ProfileState.success(newProfile));
      _onUpdate(newProfile);
    }
  }

  void _onTypicalBasalRateUpdated(
    ProfileTypicalBasalRateUpdated event,
    Emitter<ProfileState> emit,
  ) {
    if (state.status == ProfileBlocStatus.success) {
      final newProfile = state.user!.copyWith(basalRate: event.basalRate);
      emit(ProfileState.success(newProfile));
      _onUpdate(newProfile);
    }
  }

  void _onTypicalICRUpdated(
    ProfileTypicalICRUpdated event,
    Emitter<ProfileState> emit,
  ) {
    if (state.status == ProfileBlocStatus.success) {
      final newProfile = state.user!.copyWith(insulinCarbRatio: event.icr);
      emit(ProfileState.success(newProfile));
      _onUpdate(newProfile);
    }
  }

  void _onTypicalISFUpdated(
    ProfileTypicalISFUpdated event,
    Emitter<ProfileState> emit,
  ) {
    if (state.status == ProfileBlocStatus.success) {
      final newProfile =
          state.user!.copyWith(insulinSensitivityFactor: event.isf);
      emit(ProfileState.success(newProfile));
      _onUpdate(newProfile);
    }
  }

  void _onWeightUpdated(
    ProfileWeightUpdated event,
    Emitter<ProfileState> emit,
  ) {
    if (state.status == ProfileBlocStatus.success) {
      final newProfile = state.user!.copyWith(weight: event.weight);
      emit(ProfileState.success(newProfile));
      _onUpdate(newProfile);
    }
  }

  // void _onDiabetesTypeUpdated(
  //   ProfileDiabetesTypeUpdated event,
  //   Emitter<ProfileState> emit,
  // ) {
  //   if (state.status == ProfileBlocStatus.success) {
  //     final newProfile = state.user!.copyWith(diabetesType: event.type);
  //     emit(ProfileState.success(newProfile));
  //     _onUpdate(newProfile);
  //   }
  // }

  Future _onUpdate(UserProfile profile) async {
    try {
      updateProfile(
        UpdateProfileParams(
          birthDate: profile.birthDate,
          // diabetesType: profile.diabetesType,
          gender: profile.gender,
          name: profile.name,
          totalDailyDose: profile.totalDailyDose,
          weight: profile.weight,
          basalRate: profile.basalRate ?? 0,
          insulinCarbRatio: profile.insulinCarbRatio ?? 0,
          insulinSensitivityFactor: profile.insulinSensitivityFactor ?? 0,
        ),
      );
    } catch (error, stackTrace) {
      error.recordError(stackTrace: stackTrace);
    }
  }
}

import 'dart:async';
import 'dart:developer';
import 'package:cloudloop_mobile/core/data/models/alarm_profile.dart';
import 'package:cloudloop_mobile/features/auth/domain/entities/enums/alarmprofile_type.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/audioplay/csaudioplayer.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/StateMgr.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'input_alarm_event.dart';

part 'input_alarm_state.dart';

class InputAlarmProfileBloc
    extends Bloc<InputAlarmProfileEvent, InputAlarmProfileState> {
  // Your constructor and other logic here
  final StateMgr stateMgr;

  // stateMgr = Provider.of<StateMgr>(context, listen: false);
  String? selectedSound; // Initialize with an empty string
  final AlarmProfile? newProfile;
  final bool showCheckboxes;
  final List<AlarmProfile> alarmProfiles;
  final StreamController<void> profileSavedController =
      StreamController<void>.broadcast();
  DateTime? selectedDate = DateTime.now(); // Initialize with a default value
  final CsaudioPlayer mCsaudioPlayer = CsaudioPlayer();

  Stream<void> get onProfileSaved => profileSavedController.stream;

  // Define soundOptions as a static constant list
  static final List<String> soundOptions = CsaudioPlayer.getSoundOptions()
      .map((sound) => CsaudioPlayer.mapSoundToDisplayName(sound))
      .toList();

  static String mapSoundToDisplayName(String sound) {
    switch (sound) {
      case 'low_battery_sound.mp3':
        return 'Sound 1';
      case 'bleep_sound.mp3':
        return 'Sound 2';
      default:
        return sound; // Return the original if not found in mapping
    }
  }

  static String mapDisplayNameToSound(String displayName) {
    switch (displayName) {
      case 'Sound 1':
        return 'low_battery_sound.mp3';
      case 'Sound 2':
        return 'bleep_sound.mp3';
      default:
        return displayName; // Return the original if not found in mapping
    }
  }

  late List<AlarmProfile> selectedProfilesForDeletion;

  static List<String> getSnoozeOptions() {
    return ['Snooze'] +
        List<String>.generate(12, (index) => '${(index + 1) * 10}');
  }

  static String mapSnoozeToDisplayName(String duration) {
    return duration + (duration != 'Snooze' ? ' Minutes' : '');
  }

  @override
  Stream<InputAlarmProfileState> mapEventToState(
    InputAlarmProfileEvent event,
  ) async* {
    if (event is UpdateSelectedProfilesForDeletion) {
      // Assuming selectedProfilesForDeletion is a property in your state class
      final updatedProfilesForDeletion =
          List<AlarmProfile>.from(state.selectedProfilesForDeletion)
            ..remove(event.profileToDelete);

      yield state.copyWith(
          selectedProfilesForDeletion: updatedProfilesForDeletion,
          isUrgentAlarm: true,
          isUrgentSoon: state.isUrgentSoon,
          isLowAlert: state.isLowAlert,
          isHighAlert: state.isHighAlert,
          isSensorSignalLoss: state.isSensorSignalLoss,
          isPumpRefill: state.isPumpRefill,
          profileName: state.profileName,
          selectedTime: state.selectedTime,
          isRepeatEnabled: state.isRepeatEnabled,
          selectedDays: state.selectedDays,
          selectedSound: state.selectedSound,
          showCheckboxes: state.showCheckboxes,
          light: state.light,
          isProfileSaved: state.isProfileSaved,
          selectedDate: state.selectedDate,
          alarmDuration: state.alarmDuration,
          alarmThreshold: state.alarmThreshold,
          isSnoozeEnabled: state.isSnoozeEnabled,
          snoozeDuration: state.snoozeDuration);
    } else if (event is UpdateEditedProfileEvent) {
      updateEditedProfile(event.editedProfile);
    } else if (event is ResetEditingStateEvent) {
      resetEditingState();
    } else if (event is EditProfileEvent) {
      editProfile(event.profileToEdit);
    } else if (event is InputAlarmProfileRepeatChanged) {
      final updatedState = state.copyWith(
        isRepeatEnabled: event.isRepeatEnabled,
        selectedDays: event.selectedDays,
      );
      emit(updatedState);
    } else if (event is DeleteProfileEvent) {
      final updatedProfiles =
          List<AlarmProfile>.from(state.selectedProfilesForDeletion);
      log('ANNISA112423:mapEventToState ->>> DeleteProfileEvent');
      updatedProfiles.remove(event.profileToDelete);
      log('ANNISA1124723:mapEventToState ->>> updatedProfiles.remove');

      stateMgr.alarmProfiles = updatedProfiles;
      log('ANNISA1124723:mapEventToState ->>>updatedProfiles $updatedProfiles');
      yield state.copyWith(selectedProfilesForDeletion: updatedProfiles);
    } else if (event is ResetAlarmProfileForm) {
      log('ANNISA112423:mapEventToState ->>>ResetAlarmProfileForm $_mapResetFormToState');
      yield* _mapResetFormToState();
    } else if (event is ToggleProfileSelectionEvent) {
      final selectedProfiles =
          List<AlarmProfile>.from(state.selectedProfilesForDeletion);
      if (selectedProfiles.contains(event.profile)) {
        selectedProfiles.remove(event.profile);
      } else {
        selectedProfiles.add(event.profile);
      }

      yield state.copyWith(selectedProfilesForDeletion: selectedProfiles);
    } else if (event is ToggleAlarmProfileSwitch) {
      log("ToggleAlarmProfileSwitch come here!");
      final switchType = event.alarmProfileType;
      final newValue = event.value;

      try {
        // Handle the switch type and new value, and update the state accordingly
        if (switchType == AlarmProfileType.urgentAlarm) {
          // Update the state for this switch type to always be true
          final updatedState = state.copyWith(isUrgentAlarm: true);
          yield updatedState;

          // Log the state change
          log("UrgentLowSoon switch state changed to true");
        } else if (switchType == AlarmProfileType.urgentSoon) {
          // Update the state for the urgentAlertSoon switch
          if (newValue == true) {
            // Handle the error by throwing an exception
            throw Exception(
                "An error occurred while updating the urgentAlertSoon state.");
          } else {
            // Update the state for this switch type
            final updatedState = state.copyWith(isUrgentSoon: newValue);
            yield updatedState;

            // Log the state change
            log("isUrgentSoon switch state changed to $newValue");
          }
        } else if (switchType == AlarmProfileType.lowAlert) {
          // Update the state for the low alert switch
          if (newValue == true) {
            // Handle the error by throwing an exception
            throw Exception(
                "An error occurred while updating the lowAlert state.");
          } else {
            // Update the state for this switch type
            final updatedState = state.copyWith(isLowAlert: newValue);
            yield updatedState;

            // Log the state change
            log("lowAlert switch state changed to $newValue");
          }
        } else if (switchType == AlarmProfileType.highAlert) {
          // Update the state for the low alert switch
          if (newValue == true) {
            // Handle the error by throwing an exception
            throw Exception(
                "An error occurred while updating the highAlert state.");
          } else {
            // Update the state for this switch type
            final updatedState = state.copyWith(isHighAlert: newValue);
            yield updatedState;

            // Log the state change
            log("highAlert switch state changed to $newValue");
          }
        } else if (switchType == AlarmProfileType.sensorSignalLoss) {
          // Update the state for the low alert switch
          if (newValue == true) {
            // Handle the error by throwing an exception
            throw Exception(
                "An error occurred while updating the sensorSignalLoss state.");
          } else {
            // Update the state for this switch type
            final updatedState = state.copyWith(isSensorSignalLoss: newValue);
            yield updatedState;

            // Log the state change
            log("isSensorSignalLoss switch state changed to $newValue");
          }
        } else if (switchType == AlarmProfileType.pumpRefill) {
          // Update the state for the low alert switch
          if (newValue == true) {
            // Handle the error by throwing an exception
            throw Exception(
                "An error occurred while updating the pumpRefill state.");
          } else {
            // Update the state for this switch type
            final updatedState = state.copyWith(isPumpRefill: newValue);
            yield updatedState;

            // Log the state change
            log("isPumpRefill switch state changed to $newValue");
          }
        } else if (switchType == AlarmProfileType.isSnoozeEnabled) {
          // Update the state for the isSnoozeEnabled switch
          if (newValue == true) {
            // Handle the error by throwing an exception
            throw Exception(
                "An error occurred while updating the isSnoozeEnabled state.");
          } else {
            // Update the state for this switch type
            final updatedState = state.copyWith(isSnoozeEnabled: newValue);
            yield updatedState;
            // Log the state change
            log("isSnoozeEnabled switch state changed to $newValue");
          }
        }
      } on Exception catch (e) {
        // Handle exceptions
        yield ErrorState("An error occurred: ${e.toString()}");
      }
    } else if (event is SoundSelectedEvent) {
      // Handle the sound selection event
      final selectedSound = event.selectedSound;
      selectSound(selectedSound); // Call your method to handle sound selection
    } else if (event is InputAlarmProfileSnoozeDurationChanged) {
      // Handle the sound selection event
      final snoozeDuration = event.snoozeDuration;
      snoozeDurationChanged(
          snoozeDuration); // Call your method to handle snoze selection
    } else if (event is InputAlarmProfileSnoozeEnabledChanged) {
      log('Bloc: InputAlarmProfileSnoozeEnabledChanged: ${event.isSnoozeEnabled}');
      final isSnoozeEnabled = event.isSnoozeEnabled;
      savedSnoozeSwitch(isSnoozeEnabled);
    } else if (event is InputAlarmProfileDateChanged) {
      final selectedDate = event.selectedDate;
      updateSelectedDate(selectedDate);
    } else if (event is InputAlarmProfileTimeChanged) {
      final selectedTime = event.selectedTime;
      updateSelectedTime(selectedTime);
    } else if (event is InputAlarmProfileDaysChanged) {
      final selectedDays = event.selectedDays;
      updateSelectedDays(selectedDays);
    } else if (event is InputAlarmProfileThresholdChanged) {
      final alarmThreshold = event.alarmThreshold;
      updateAlarmThreshold(alarmThreshold);
    } else if (event is InputAlarmProfileDurationChanged) {
      final alarmDuration = event.alarmDuration;
      updateAlarmDuration(alarmDuration);
    } else if (event is InputAlarmProfileRepeatChanged) {
      final isRepeatEnabled = event.isRepeatEnabled;
      final selectedDays = event.selectedDays;
      // Update the state for this switch type
      final updatedState = state.copyWith(
          isRepeatEnabled: isRepeatEnabled, selectedDays: selectedDays ?? []);
      yield updatedState;
    }
  }

  Stream<InputAlarmProfileState> _mapResetFormToState() async* {
    TextEditingController profileNameController = TextEditingController();
    profileNameController.clear();
    TextEditingController thresholdController = TextEditingController();
    thresholdController.clear();
    TextEditingController durationController = TextEditingController();
    durationController.clear();
    yield InputAlarmProfileInitial(
      // Set default values for form fields here
      isUrgentAlarm: true,
      isUrgentSoon: false,
      isLowAlert: false,
      isHighAlert: false,
      isSensorSignalLoss: false,
      isPumpRefill: false,
      profileNameController: profileNameController,
      thresholdController: thresholdController,
      durationController: durationController,
      selectedTime: TimeOfDay.now(),
      isRepeatEnabled: false,
      selectedDays: [],
      selectedSound: InputAlarmProfileBloc.soundOptions[0],
      // Set the default sound
      selectedProfilesForDeletion: [],
      light: false,
      selectedDate: DateTime.now(),
      alarmDuration: 0,
      alarmThreshold: 0,
      snoozeDuration: InputAlarmProfileBloc.getSnoozeOptions()[0],
      isSnoozeEnabled: false,
    );
  }

  InputAlarmProfileBloc(
      this.stateMgr, this.newProfile, this.showCheckboxes, this.alarmProfiles)
      : super(InputAlarmProfileInitial(
          isUrgentAlarm: true,
          isUrgentSoon: false,
          isLowAlert: false,
          isHighAlert: false,
          isSensorSignalLoss: false,
          isPumpRefill: false,
          profileName: '',
          selectedTime: TimeOfDay.now(),
          isRepeatEnabled: false,
          selectedDays: [],
          selectedSound: soundOptions[0],
          showCheckboxes: false,
          // Set the default sound
          selectedProfilesForDeletion: [],
          light: false,
          selectedDate: DateTime.now(),
          profileNameController: TextEditingController(),
          thresholdController: TextEditingController(),
          durationController: TextEditingController(),
          isSnoozeEnabled: false,
          snoozeDuration: getSnoozeOptions()[0],
        )) {
    {
      on<EditProfileEvent>((event, emit) {
        // Extract the profile to edit from the event
        final profileToEdit = event.profileToEdit;

        // Create an InputAlarmProfileEditing state with the data from the profile
        final editingState = InputAlarmProfileEditing(
          // Set other properties based on the profileToEdit
          isEditing: true,
          profileToEdit: profileToEdit,
          // Set default values for form fields using the profileToEdit data
          isUrgentAlarm: true,
          isUrgentSoon: profileToEdit.isUrgentSoon,
          isLowAlert: profileToEdit.isLowAlert,
          isHighAlert: profileToEdit.isHighAlert,
          isSensorSignalLoss: profileToEdit.isSensorSignalLoss,
          isPumpRefill: profileToEdit.isPumpRefill,
          profileName: profileToEdit.profileName,
          selectedTime: profileToEdit.selectedTime,
          isRepeatEnabled: profileToEdit.isRepeatEnabled,
          selectedDays: profileToEdit.selectedDays ?? [],
          selectedSound: profileToEdit.selectedSound,
          snoozeDuration: profileToEdit.snoozeDuration,
          selectedProfilesForDeletion: [],
          // You can set this if needed
          selectedDate: profileToEdit.selectedDate ?? DateTime.now(),
          profileNameController:
              TextEditingController(text: profileToEdit.profileName),
          thresholdController: TextEditingController(
              text: profileToEdit.alarmThreshold?.toString()),
          durationController: TextEditingController(
              text: profileToEdit.alarmDuration?.toString()),
          isSnoozeEnabled: profileToEdit.isSnoozeEnabled,
        );

        // Emit the editing state to the Bloc
        emit(editingState);
      });

      on<UpdateEditedProfileEvent>((event, emit) {
        // Update the state with the edited profile information
        final updatedState = state.copyWith(
          profileName: event.editedProfile.profileName,
          isUrgentAlarm: true,
          isUrgentSoon: event.editedProfile.isUrgentSoon,
          isLowAlert: event.editedProfile.isLowAlert,
          isHighAlert: event.editedProfile.isHighAlert,
          isSensorSignalLoss: event.editedProfile.isSensorSignalLoss,
          isPumpRefill: event.editedProfile.isPumpRefill,
          selectedTime: event.editedProfile.selectedTime,
          isRepeatEnabled: event.editedProfile.isRepeatEnabled,
          selectedDays: event.editedProfile.selectedDays,
          selectedSound: event.editedProfile.selectedSound,
          isProfileSaved: event.editedProfile.isProfileSaved,
          selectedDate: event.editedProfile.selectedDate,
          alarmThreshold: event.editedProfile.alarmThreshold,
          alarmDuration: event.editedProfile.alarmDuration,
          snoozeDuration: event.editedProfile.snoozeDuration,
          isSnoozeEnabled: event.editedProfile.isSnoozeEnabled,
          profileNameController:
              TextEditingController(text: event.editedProfile.profileName),
          thresholdController: TextEditingController(
              text: event.editedProfile.alarmThreshold?.toString()),
          durationController: TextEditingController(
              text: event.editedProfile.alarmDuration?.toString()),
        );
        emit(updatedState);
      });

      on<DeleteProfileEvent>((event, emit) {
        final updatedProfiles =
            List<AlarmProfile>.from(state.selectedProfilesForDeletion);
        updatedProfiles.remove(event.profileToDelete);

        // Update the profiles list in the state
        emit(state.copyWith(selectedProfilesForDeletion: updatedProfiles));

        // Directly remove the profile from StateMgr upon deletion
        final stateMgr = StateMgr();
        final allProfiles = stateMgr.callProfiles;
        allProfiles.remove(event.profileToDelete);
        stateMgr.alarmProfiles = allProfiles;
        stateMgr.notifyListeners();
      });
      on<ToggleAlarmProfileSwitch>((event, emit) {
        log("ToggleAlarmProfileSwitch come here !!!");
        // Handle the ToggleAlarmProfileSwitch event here
        if (event.alarmProfileType == AlarmProfileType.urgentAlarm) {
          // Always set "isUrgentAlarm" to true regardless of the event value
          final updatedState = state.copyWith(isUrgentAlarm: true);
          emit(updatedState);
        } else if (event.alarmProfileType == AlarmProfileType.urgentSoon) {
          // Handle the "isUrgentSoon" case
          final updatedState = state.copyWith(isUrgentSoon: event.value);
          emit(updatedState);
        } else if (event.alarmProfileType == AlarmProfileType.lowAlert) {
          // Handle the "lowAlert" case
          final updatedState = state.copyWith(isLowAlert: event.value);
          emit(updatedState);
        } else if (event.alarmProfileType == AlarmProfileType.highAlert) {
          // Handle the "highAlert" case
          final updatedState = state.copyWith(isHighAlert: event.value);
          emit(updatedState);
        } else if (event.alarmProfileType ==
            AlarmProfileType.sensorSignalLoss) {
          // Handle the "sensorSignalLoss" case
          final updatedState = state.copyWith(isSensorSignalLoss: event.value);
          emit(updatedState);
        } else if (event.alarmProfileType == AlarmProfileType.pumpRefill) {
          // Handle the "pumpRefill" case
          final updatedState = state.copyWith(isPumpRefill: event.value);
          emit(updatedState);
        } else if (event.alarmProfileType == AlarmProfileType.repeatAlarm) {
          // Handle the repeat alarm switch
          final updatedState = state.copyWith(isRepeatEnabled: event.value);
          emit(updatedState);
        } else if (event.alarmProfileType == AlarmProfileType.isSnoozeEnabled) {
          // Handle the "isSnoozeEnabled" case
          final updatedState = state.copyWith(isSnoozeEnabled: event.value);
          emit(updatedState);
        }
        // Add more cases as needed
      });

      on<ResetAlarmProfileForm>((event, emit) {
        emit(InputAlarmProfileInitial(
          // Set default values for form fields here
          isUrgentAlarm: true,
          isUrgentSoon: false,
          isLowAlert: false,
          isHighAlert: false,
          isSensorSignalLoss: false,
          isPumpRefill: false,
          profileName: '',
          selectedTime: TimeOfDay.now(),
          isRepeatEnabled: false,
          selectedDays: [],
          selectedSound: InputAlarmProfileBloc.soundOptions[0],
          // Set the default sound
          selectedProfilesForDeletion: [],
          light: false,
          selectedDate: DateTime.now(),
          alarmDuration: 0,
          alarmThreshold: 0,
          snoozeDuration: InputAlarmProfileBloc.getSnoozeOptions()[0],
          profileNameController: TextEditingController(),
          thresholdController: TextEditingController(),
          durationController: TextEditingController(),
          isSnoozeEnabled: false,
        ));
      });

      on<InputAlarmProfileRepeatChanged>((event, emit) {
        // Handle the InputAlarmProfileRepeatChanged event here
        emit(state.copyWith(
            isRepeatEnabled: event.isRepeatEnabled,
            selectedDays: event.selectedDays));
      });

      on<InputAlarmProfileName>((event, emit) {
        // Handle the InputAlarmProfileRepeatChanged event here
        emit(state.copyWith(profileName: event.profileName));
      });

      on<InputAlarmProfileThresholdChanged>((event, emit) {
        // Handle the InputAlarmProfileThresholdChanged event here
        emit(state.copyWith(alarmThreshold: event.alarmThreshold));
      });

      on<InputAlarmProfileDurationChanged>((event, emit) {
        // Handle the InputAlarmProfileDurationChanged event here
        emit(state.copyWith(alarmDuration: event.alarmDuration));
      });

      on<InputAlarmProfileDateChanged>((event, emit) {
        // Handle the InputAlarmProfileDateChanged event here
        emit(state.copyWith(selectedDate: event.selectedDate));
      });

      on<InputAlarmProfileTimeChanged>((event, emit) {
        // Handle the InputAlarmProfileTimeChanged event here
        emit(state.copyWith(selectedTime: event.selectedTime));
      });

      on<InputAlarmProfileDaysChanged>((event, emit) {
        // Handle the InputAlarmProfileDaysChanged event here
        emit(state.copyWith(selectedDays: event.selectedDays));
      });

      on<SoundSelectedEvent>((event, emit) {
        // Handle the SoundSelectedEvent event here
        emit(state.copyWith(selectedSound: event.selectedSound));
      });

      on<InputAlarmProfileSnoozeDurationChanged>((event, emit) {
        // Handle the InputAlarmProfileSnoozeDurationChanged  event here
        emit(state.copyWith(snoozeDuration: event.snoozeDuration));
      });
      on<InputAlarmProfileSnoozeEnabledChanged>((event, emit) {
        // Create an SnoozeState state with the data from the isSnoozeEnabled
        final editingState = SnoozeState(
          isSnoozeEnabled: event.isSnoozeEnabled,
        );
        // Emit the editing state to the Bloc
        emit(editingState);
      });
    }
  }

  void dispatch(InputAlarmProfileEvent event) {
    if (event is InputAlarmProfileDaysChanged) {
      updateSelectedDays(event.selectedDays);
    } else if (event is InputAlarmProfileUrgentAlertChanged) {
      updateUrgentAlarm(event.isUrgentAlarm);
    } else if (event is InputAlarmProfileSnoozeEnabledChanged) {
      savedSnoozeSwitch(event.isSnoozeEnabled);
    } else if (event is InputAlarmProfileName) {
      updateProfileName(event.profileName);
    } else if (event is InputAlarmProfileThresholdChanged) {
      updateAlarmThreshold(event.alarmThreshold);
    } else if (event is InputAlarmProfileDurationChanged) {
      updateAlarmDuration(event.alarmDuration);
    } else if (event is InputAlarmProfileLowAlertChanged) {
      updateLowAlert(event.isLowAlert);
    } else if (event is InputAlarmProfileHighAlertChanged) {
      updateHighAlert(event.isHighAlert);
    } else if (event is InputAlarmProfileSensorSignalLossChanged) {
      updateSensorSignalLoss(event.isSensorSignalLoss);
    } else if (event is InputAlarmProfilePumpRefillChanged) {
      updatePumpRefill(event.isPumpRefill);
    } else if (event is InputAlarmProfileRepeatChanged) {
      updateRepeatSetting(event.isRepeatEnabled, event.selectedDays);
    } else if (event is InputAlarmProfileDateChanged) {
      updateSelectedDate(event.selectedDate);
    } else if (event is InputAlarmProfileTimeChanged) {
      updateSelectedTime(event.selectedTime);
    } else if (event is SoundSelectedEvent) {
      selectSound(event.selectedSound); // Handle sound selection
    } else if (event is InputAlarmProfileSnoozeDurationChanged) {
      snoozeDurationChanged(event.snoozeDuration); // Handle SNOOZE selection
    }
  }

  void updateEditedProfile(AlarmProfile editedProfile) {
    final profileNameController =
        TextEditingController(text: editedProfile.profileName);
    final durationController =
        TextEditingController(text: editedProfile.alarmDuration?.toString());
    final thresholdController =
        TextEditingController(text: editedProfile.alarmThreshold?.toString());
    emit(InputAlarmProfileEditing(
      isEditing: true,
      profileToEdit: editedProfile,
      isUrgentAlarm: true,
      isUrgentSoon: editedProfile.isUrgentSoon,
      isLowAlert: editedProfile.isLowAlert,
      isHighAlert: editedProfile.isHighAlert,
      isSensorSignalLoss: editedProfile.isSensorSignalLoss,
      isPumpRefill: editedProfile.isPumpRefill,
      profileName: editedProfile.profileName,
      selectedTime: editedProfile.selectedTime,
      isRepeatEnabled: editedProfile.isRepeatEnabled,
      selectedDays: editedProfile.selectedDays ?? [],
      selectedSound: editedProfile.selectedSound,
      selectedProfilesForDeletion: [],
      // Update as needed
      selectedDate: editedProfile.selectedDate ?? DateTime.now(),
      alarmDuration: editedProfile.alarmDuration,
      alarmThreshold: editedProfile.alarmThreshold,
      snoozeDuration: editedProfile.snoozeDuration,
      profileNameController: profileNameController,
      durationController: durationController,
      thresholdController: thresholdController,
      isSnoozeEnabled: editedProfile.isSnoozeEnabled,
    ));
  }

  void onSelectedDaysChanged(List<int>? newSelectedDays) {
    log('ANNISA111523: #1 onSelectedDaysChanged: Day $newSelectedDays selected');
    // For example, you might want to format the selected days using the formatSelectedDays method
    String? formattedDays = StateMgr.formatSelectedDays(newSelectedDays);
    log('ANNISA111523: #2  onSelectedDaysChanged.formattedDays: Day $formattedDays selected');
    // Dispatch an event or update the state as needed
    dispatch(InputAlarmProfileDaysChanged(newSelectedDays ?? []));
  }

// Define the state transition to reset editing state
  void resetEditingState() {
    emit(InputAlarmProfileInitial(
      // Set default values for form fields here
      isUrgentAlarm: true,
      isUrgentSoon: false,
      isLowAlert: false,
      isHighAlert: false,
      isSensorSignalLoss: false,
      isPumpRefill: false,
      profileName: '',
      selectedTime: TimeOfDay.now(),
      isRepeatEnabled: false,
      selectedDays: [],
      selectedSound: InputAlarmProfileBloc.soundOptions[0],
      // Set the default sound
      selectedProfilesForDeletion: [],
      selectedDate: DateTime.now(),
      light: false,
      alarmThreshold: 0,
      alarmDuration: 0,
      snoozeDuration: InputAlarmProfileBloc.getSnoozeOptions()[0],
      profileNameController: TextEditingController(),
      thresholdController: TextEditingController(),
      durationController: TextEditingController(),
      isSnoozeEnabled: false,
    ));
  }

  void editProfile(AlarmProfile profileToEdit) {
    final profileNameController =
        TextEditingController(text: profileToEdit.profileName);
    final durationController =
        TextEditingController(text: profileToEdit.alarmDuration?.toString());
    final thresholdController =
        TextEditingController(text: profileToEdit.alarmThreshold?.toString());
    emit(InputAlarmProfileEditing(
      isEditing: true,
      profileToEdit: profileToEdit,
      // Set default values for form fields using the profileToEdit data
      isUrgentAlarm: true,
      isUrgentSoon: profileToEdit.isUrgentSoon,
      isLowAlert: profileToEdit.isLowAlert,
      isHighAlert: profileToEdit.isHighAlert,
      isSensorSignalLoss: profileToEdit.isSensorSignalLoss,
      isPumpRefill: profileToEdit.isPumpRefill,
      profileName: profileToEdit.profileName,
      selectedTime: profileToEdit.selectedTime,
      isRepeatEnabled: profileToEdit.isRepeatEnabled,
      selectedDays: profileToEdit.selectedDays ?? [],
      selectedSound: profileToEdit.selectedSound,
      selectedDate: profileToEdit.selectedDate ?? DateTime.now(),
      selectedProfilesForDeletion: [],
      // You can set this if needed
      profileNameController: profileNameController,
      thresholdController: thresholdController,
      durationController: durationController,
      alarmDuration: profileToEdit.alarmDuration,
      alarmThreshold: profileToEdit.alarmThreshold,
      snoozeDuration: profileToEdit.snoozeDuration,
      isSnoozeEnabled: profileToEdit.isSnoozeEnabled,
    ));
  }

  void savedSnooze(bool isSnoozeEnabled) {
    log('value of is snoozeEnabled on savedSnooze = ${isSnoozeEnabled}');
    emit(SnoozeState(
      isSnoozeEnabled: isSnoozeEnabled,
    ));
  }

  Future<bool> checkProfile(
      BuildContext context, AlarmProfile newProfile) async {
    AlarmProfile? existingProfile;

    int getCustomDayOfWeek(DateTime? date) {
      if (date != null && date.weekday != null) {
        int dartDayOfWeek = date.weekday;
        log('Checking date.weekday: $dartDayOfWeek');

        // Adjust the index so that it's within the range 2..8
        int adjustedIndex = ((dartDayOfWeek - 1) % 7 + 7) % 7 + 3;
        log('Checking adjustedIndex: $adjustedIndex');

        // Ensure the adjusted index is not greater than 8
        return adjustedIndex <= 8 ? adjustedIndex : adjustedIndex - 7;
      }
      return -1; // Return an invalid value if the date is null
    }

    try {
      existingProfile = StateMgr().callProfiles.firstWhere((profile) {
        // Check if there's any common day between profile and newProfile\
        bool hasCommonSelectedDays(
            List<int> profileSelectedDays, List<int> newProfileSelectedDays) {
          final commonValuesProfile = profileSelectedDays
              .asMap()
              .entries
              .where((entry) => entry.value == 1)
              .map((entry) => entry.key + 2)
              .toSet();

          final commonValuesNewProfile = newProfileSelectedDays
              .asMap()
              .entries
              .where((entry) => entry.value == 1)
              .map((entry) => entry.key + 2)
              .toSet();

          // Check if there's at least one common value between profile and newProfile
          return commonValuesProfile
              .intersection(commonValuesNewProfile)
              .isNotEmpty;
        }

        bool hasCommon = hasCommonSelectedDays(
            newProfile.selectedDays!, profile.selectedDays!);
        log('Do the profiles have common selected days? $hasCommon');

        bool adjustedDays(List<int>? selectedDays, DateTime? selectedDate) {
          for (int i = 0; i < selectedDays!.length; i++) {
            int adjustedIndex = i + 2;
            if (selectedDays[i] == 1) {
              int dayOfWeekForProfile = getCustomDayOfWeek(selectedDate!);
              log('dayOfWeekForProfile value for selectedDate? $dayOfWeekForProfile');
              log('dayOfWeekForProfile value for adjustedIndex? $adjustedIndex');
              return adjustedIndex == dayOfWeekForProfile;
            }
          }
          // If no match is found, return false
          return false;
        }

        bool hasCommonAdjustedDays =
            adjustedDays(newProfile.selectedDays!, profile.selectedDate!);
        bool hasCommonAdjustedDays2 =
            adjustedDays(profile.selectedDays!, newProfile.selectedDate!);
        log('Do the newProfile have common hasCommonAdjustedDays? $hasCommonAdjustedDays');
        log('Do the profiles have common hasCommonAdjustedDays? $hasCommonAdjustedDays2');

        bool hasCommonDay = (profile.selectedDays!.isNotEmpty &&
            newProfile.selectedDays!.isNotEmpty &&
            profile.selectedDays!
                .any((day) => newProfile.selectedDays!.contains(day)));

        log('Checking hasCommonDay: $hasCommonDay');

        log('Checking hasCommonCheck profile selectedDays: ${profile.selectedDays}');
        log('Checking hasCommonCheck newProfile selectedDays: ${newProfile.selectedDays}');

        log('::ANNISA Checking profile.selectedDays : ${profile.selectedDays}');
        log('::ANNISA Checking newProfile.selectedDays : ${newProfile.selectedDays}');
        log('::ANNISA Checking profile');
        log('::ANNISA Checking profile.selectedDate : ${profile.selectedDate}');
        log('::ANNISA Checking newProfile.selectedDate : ${newProfile.selectedDate}');

        if (newProfile.selectedDate != null) {
          log('Checking !getCustomDayOfWeek newProfile.selectedDate?.day : ${getCustomDayOfWeek(newProfile.selectedDate)}');
        }

        bool hasCommonTime = profile.selectedTime == newProfile.selectedTime;
        log('>>> Checking log for !getCustomDayOfWeek profile.selectedDate != DateTime(0) : ${profile.selectedDate != DateTime(0)}');
        log('>>> Checking log for !getCustomDayOfWeek newProfile.selectedDays != null  : ${newProfile.selectedDays!.isNotEmpty}');
        log('>>> Checking log for !getCustomDayOfWeek  adjustedIndex1 == dayOfWeekForProfile1  : ${newProfile.selectedDays!.any((int day) {
          int adjustedIndex = day + 2; // Adjust the index here
          int dayOfWeekForProfile = getCustomDayOfWeek(profile.selectedDate!);
          log('log for Day $dayOfWeekForProfile is profile.selectedDate!');
          return adjustedIndex == dayOfWeekForProfile;
        })}');
        log('#ANNISA Checking log for !getCustomDayOfWeek newProfile.selectedDate != DateTime(0) : ${(newProfile.selectedDate != DateTime(0))}');
        log('#ANNISA Checking log for !getCustomDayOfWeek profile.selectedDays != null  : ${profile.selectedDays!.isNotEmpty}');
        log('#ANNISA Checking log for !getCustomDayOfWeek profile.selectedDays != null  : ${profile.selectedDays!.any((int day) {
          int adjustedIndex2 = day + 2; // Adjust the index here
          log('> log for Day ${adjustedIndex2} is profile.selectedDays!');
          int dayOfWeekForProfile2 =
              getCustomDayOfWeek(newProfile.selectedDate!);
          log('> log for Day $dayOfWeekForProfile2 is newProfile.selectedDate!');
          return adjustedIndex2 == dayOfWeekForProfile2;
        })}');
        // Check if it's a repeat alarm with common days or a one-time alarm with the same date and time
        return hasCommonTime &&
            hasCommon &&
            (profile.selectedDate?.day == newProfile.selectedDate?.day) &&
            (profile.selectedDate?.month == newProfile.selectedDate?.month) &&
            (profile.selectedDate?.year == newProfile.selectedDate?.year);
      });
    } catch (e) {
      log('Error finding existing profile: $e');
    }

    log('Checking existingProfile : ${existingProfile}');

    if (existingProfile != null) {
      bool? userConfirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text(
                'There is already an alarm profile set for the same time. Do you want to proceed and override it?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
            ],
          );
        },
      );

      if (userConfirmed == null) {
        // User didn't interact with the dialog
        // Handle this case based on your application's logic
      } else if (userConfirmed) {
        saveProfile(newProfile);
      }

      return userConfirmed ?? false; // Return whether the user confirmed or not
    } else {
      log('No matching profile found. Creating a new one.');
      final profileNameController =
          TextEditingController(text: newProfile.profileName);
      final durationController =
          TextEditingController(text: newProfile.alarmDuration?.toString());
      final thresholdController =
          TextEditingController(text: newProfile.alarmThreshold?.toString());

      existingProfile = AlarmProfile(
        profileName: newProfile.profileName,
        isUrgentAlarm: true,
        isUrgentSoon: newProfile.isUrgentSoon,
        isLowAlert: newProfile.isLowAlert,
        isHighAlert: newProfile.isHighAlert,
        isSensorSignalLoss: newProfile.isSensorSignalLoss,
        isPumpRefill: newProfile.isPumpRefill,
        selectedTime: newProfile.selectedTime,
        selectedDays: newProfile.selectedDays,
        selectedSound: newProfile.selectedSound,
        isProfileSaved: newProfile.isProfileSaved,
        selectedProfilesForDeletion: newProfile.selectedProfilesForDeletion,
        selectedDate: newProfile.selectedDate,
        alarmThreshold: newProfile.alarmThreshold,
        alarmDuration: newProfile.alarmDuration,
        isRepeatEnabled: newProfile.isRepeatEnabled,
        profileNameController: profileNameController,
        thresholdController: thresholdController,
        durationController: durationController,
        snoozeDuration: newProfile.snoozeDuration,
        isSnoozeEnabled: newProfile.isSnoozeEnabled,
      );
      saveProfile(newProfile);
      return true;
    }
  }

  static bool isDaySelected(
      List<int>? selectedDays, TimeOfDay selectedTime, DateTime? selectedDate) {
    final currentTime = TimeOfDay.now();
    log('ANNISA111723:InputAlarmProfileBloc isDaySelected currentTime = $currentTime');
    log('ANNISA111723:InputAlarmProfileBloc isDaySelected selectedTime = $selectedTime');

    if (selectedDays != null && selectedDays.isNotEmpty) {
      int adjustIndex(int originalIndex) {
        // Adjust the index so that it's within the range 2..8
        return ((originalIndex - 1) % 7) + 2;
      }

      final currentDay = [2, 3, 4, 5, 6, 7, 8];
      log('ANNISA112723:InputAlarmProfileBloc DateTime.now().weekday = ${DateTime.now().weekday}');

      // Adjust the calculation for a custom mapping
      final todayIndex = adjustIndex(DateTime.now().weekday); // Adjusted index

      log('ANNISA112723:InputAlarmProfileBloc isDaySelected weekday = $todayIndex');

      // Use todayIndex to get the custom-mapped current day
      final currentDayOfWeek =
          currentDay[todayIndex - 1]; // Adjusted to zero-based index
      log('ANNISA111723:InputAlarmProfileBloc isDaySelected currentDayOfWeek = $currentDayOfWeek');
      // Now, currentDayOfWeek will have the custom-mapped value for the current day

      log('ANNISA111723:InputAlarmProfileBloc isDaySelected selectedDays = $selectedDays');

      final dayAbbreviation = _getDayAbbreviation(currentDayOfWeek);
      log('ANNISA111723:InputAlarmProfileBloc isDaySelected dayAbbreviation = $dayAbbreviation');
      final dayIndex = _dayAbbreviationToIndex(dayAbbreviation);
      log('ANNISA111723:InputAlarmProfileBloc isDaySelected dayIndex = $dayIndex');

      final selectedIndices = <int>[];
      for (int i = 0; i < selectedDays.length; i++) {
        if (selectedDays[i] == 1) {
          selectedIndices.add(i + 2); // Adjust index to match currentDay values
        }
      }
      log('ANNISA111723:InputAlarmProfileBloc isDaySelected selectedIndices = $selectedIndices');
      log('ANNISA111723:InputAlarmProfileBloc isDaySelected selectedIndices.contains(dayIndex) = ${selectedIndices.contains(dayIndex)}');
      // Check if todayIndex is in the list of selected indices
      if (selectedIndices.contains(dayIndex)) {
        // Check if the current time matches the selected time
        if (currentTime.hour == selectedTime.hour &&
            currentTime.minute == selectedTime.minute) {
          log('ANNISA111723:InputAlarmProfileBloc cUrrentTime.hour == selectedTime.hour && currentTime.minute == selectedTime.minute = true!!!!');
          // Trigger alarm/notification here
          return true;
        }
      }
    } else if (selectedDate != DateTime(0)) {
      log('ANNISA111723:InputAlarmProfileBloc isDaySelected selectedDate != null is TRUEE');
      // Get the current date
      final currentDate = DateTime.now();
      log('ANNISA111723:InputAlarmProfileBloc isDaySelected currentDate = $currentDate');
      log('ANNISA111723:InputAlarmProfileBloc isDaySelected selectedDate = $selectedDate');
      // Check if the selected date is not null and is the same as the current date
      if (selectedDate != null &&
          selectedDate.year == currentDate.year &&
          selectedDate.month == currentDate.month &&
          selectedDate.day == currentDate.day) {
        // Check if the current time matches the selected time
        if (currentTime.hour == selectedTime.hour &&
            currentTime.minute == selectedTime.minute) {
          log('ANNISA111723: InputAlarmProfileBloc currentTime.hour == selectedTime.hour && currentTime.minute == selectedTime.minute = true!!!!');
          // Trigger alarm/notification here
          return true;
        }
      }
    }
    return false;
  }

  static String _getDayAbbreviation(int index) {
    switch (index) {
      case 2:
        return 'S';
      case 3:
        return 'M';
      case 4:
        return 'T';
      case 5:
        return 'W';
      case 6:
        return 'Th';
      case 7:
        return 'F';
      case 8:
        return 'Sa';
      default:
        return '';
    }
  }

  static int _dayAbbreviationToIndex(String dayAbbreviation) {
    switch (dayAbbreviation) {
      case 'S':
        return 2;
      case 'M':
        return 3;
      case 'T':
        return 4;
      case 'W':
        return 5;
      case 'Th':
        return 6;
      case 'F':
        return 7;
      case 'Sa':
        return 8;
      default:
        return -1; // Invalid day abbreviation
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      updateSelectedDate(picked);
    }
  }

  void handleAlarmNotification(AlarmProfile newProfile, BuildContext context) {
    log('ANNISA112423:InputAlarmProfileBloc come inside handleAlarmNotification');
    log('ANNISA112423:InputAlarmProfileBloc.handleAlarmNotification >> $newProfile');

    // Extract relevant information
    final selectedDays = newProfile.selectedDays;
    final selectedDate = newProfile.selectedDate;
    // Check each switch in the profile along with the new factors
    if (newProfile.isUrgentAlarm) {
      // Trigger notification for isUrgentAlarm
      // Trigger notification for isUrgentAlarm
      AlertPage.handleNotificationState('light', context, newProfile, stateMgr);
    }

    if (newProfile.isUrgentSoon) {
      // Trigger notification for isUrgentSoon
      AlertPage.handleNotificationState(
          'light2', context, newProfile, stateMgr);
    }

    if (newProfile.isLowAlert) {
      // Trigger notification for isLowAlert
      AlertPage.handleNotificationState(
          'light3', context, newProfile, stateMgr);
    }

    if (newProfile.isHighAlert) {
      // Trigger notification for isHighAlert
      AlertPage.handleNotificationState(
          'light4', context, newProfile, stateMgr);
    }

    if (newProfile.isSensorSignalLoss) {
      // Trigger notification for isSensorSignalLoss
      AlertPage.handleNotificationState(
          'light5', context, newProfile, stateMgr);
    }

    if (newProfile.isPumpRefill) {
      // Trigger notification for isPumpRefill
      AlertPage.handleNotificationState(
          'light6', context, newProfile, stateMgr);
    }

    if (newProfile.isSnoozeEnabled) {
      // Trigger notification for isPumpRefill
      AlertPage.handleNotificationState(
          'isSnoozeEnabled', context, newProfile, stateMgr);
    }
  }

  void clearProfileNameText() {
    log('ANNISA112423:clearProfileNameText inside');
    // Dispatch an event to notify the UI to clear the text field
    add(InputAlarmProfileNameTextCleared());
  }

  void updateAlarmDuration(int duration) {
    log('ANNISA112423:updateAlarmDuration inside');
    final currentState = state;
    if (currentState is InputAlarmProfileState) {
      emit(currentState.copyWith(alarmDuration: duration));
    }
  }

  void updateAlarmThreshold(int alarmThreshold) {
    log('updateAlarmThreshold come inside >>> ${alarmThreshold}');
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      emit(currentStateAsInitial.copyWith(alarmThreshold: alarmThreshold));
    }
  }

  void saveProfile(AlarmProfile newProfile) {
    stateMgr.saveAlarmProfile(newProfile);
    profileSavedController.add(null); // Notify listeners about the profile save
  }

  void selectSound(String selectedSound) {
    // Update the selectedSound in the state
    final currentState = state;
    if (currentState is InputAlarmProfileState) {
      emit(currentState.copyWith(selectedSound: selectedSound));
    }
  }

  void snoozeDurationChanged(String snoozeDuration) {
    // Update the selectedSound in the state
    final currentState = state;
    if (currentState is InputAlarmProfileState) {
      emit(currentState.copyWith(snoozeDuration: snoozeDuration));
    }
  }

  void savedSnoozeSwitch(bool isSnoozeEnabled) async {
    log('ANNISA12623: #1 InputAlarmProfileBloc: savedSnoozeSwitch $isSnoozeEnabled');
    final currentState = SnoozeState;
    if (currentState is SnoozeState) {
      final currentStateAsInitial = currentState as SnoozeState;
      final updatedState =
          currentStateAsInitial.copyWith(isSnoozeEnabled: isSnoozeEnabled);
      emit(updatedState);
      log('ANNISA12623: #3 InputAlarmProfileBloc: Updated state for isSnoozeEnabled: $updatedState');
    }
  }

  void snoozeEvent(String? snoozeDuration) {
    log('ANNISA12623: #1 InputAlarmProfileBloc: snoozeEvent $snoozeDuration');
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      final updatedState =
          currentStateAsInitial.copyWith(snoozeDuration: snoozeDuration);
      emit(updatedState);
      log('ANNISA12623: #3 InputAlarmProfileBloc: Updated state for snoozeEvent: $updatedState');
    }
  }

  void updateSelectedSound(String sound) {
    selectedSound = sound;
  }

  void updateSnoozeEnabledAlarm(bool isSnoozeEnabled) {
    log('Bloc: updateSnoozeEnabledAlarm: ${isSnoozeEnabled}');
    // Update the selectedSound in the state
    final currentState = state;
    if (currentState is InputAlarmProfileState) {
      emit(currentState.copyWith(isSnoozeEnabled: isSnoozeEnabled));
    }
  }

  void updateUrgentAlarm(bool isUrgentAlarm) {
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      // Always set "isUrgentAlarm" to true regardless of the passed argument
      emit(currentStateAsInitial.copyWith(isUrgentAlarm: true));
    }
  }

  void updateProfileName(String profileName) {
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      emit(currentStateAsInitial.copyWith(profileName: profileName));
    }
  }

  void updateLowAlert(bool isLowAlert) {
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      emit(currentStateAsInitial.copyWith(isLowAlert: isLowAlert));
    }
  }

  void updateHighAlert(bool isHighAlert) {
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      emit(currentStateAsInitial.copyWith(isHighAlert: isHighAlert));
    }
  }

  void updateSensorSignalLoss(bool isSensorSignalLoss) {
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      emit(currentStateAsInitial.copyWith(
          isSensorSignalLoss: isSensorSignalLoss));
    }
  }

  void updatePumpRefill(bool isPumpRefill) {
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      emit(currentStateAsInitial.copyWith(isPumpRefill: isPumpRefill));
    }
  }

  void updateTime(TimeOfDay newSelectedTime) {
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      final updatedState =
          currentStateAsInitial.updateSelectedTime(newSelectedTime);
      emit(updatedState);
    }
  }

  void updateSelectedTime(TimeOfDay selectedTime) {
    log('ANNISA112423: #1 InputAlarmProfileBloc: updateSelectedTime $selectedTime');
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      final updatedState =
          currentStateAsInitial.copyWith(selectedTime: selectedTime);
      emit(updatedState);
    }
  }

// In your bloc class

  void showMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void updateSelectedDays(List<int>? newSelectedDays) {
    log('ANNISA111723: #1 updateSelectedDays: Day $newSelectedDays selected');
    final currentState = state;
    if (currentState is InputAlarmProfileState) {
      final currentStateAsState = currentState as InputAlarmProfileState;
      final updatedState =
          currentStateAsState.copyWith(selectedDays: newSelectedDays);
      emit(updatedState);

      final selectedDaysText = formatSelectedDaysText(state.selectedDays);
      log('ANNISA111523: Selected days text: $selectedDaysText');
    }
  }

  void updateSelectedDate(DateTime? selectedDate) {
    log('ANNISA111523: #1 InputAlarmProfileBloc: updateSelectedDate $selectedDate');
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      final updatedState =
          currentStateAsInitial.copyWith(selectedDate: selectedDate);
      emit(updatedState);
      log('ANNISA111523: #3 InputAlarmProfileBloc: Updated state: $updatedState');
    }
  }

  static String formatSelectedDaysText(List<int>? selectedDays) {
    log('ANNISA111523: #1 formatSelectedDaysText: $selectedDays');
    if (selectedDays == null) {
      return ''; // Handle the case when selectedDays is null
    } else if (selectedDays.every((day) => day == 1)) {
      log('ANNISA111523: formatSelectedDaysText Every day!!');
      return 'Every day'; // Display 'Every day' when all days are selected
    } else if (selectedDays.any((day) => day == 1)) {
      log('ANNISA111523: formatSelectedDaysText Some days!!');
      final shortDayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final selectedDayNames = selectedDays
          .asMap()
          .entries
          .where((entry) => entry.value == 1)
          .map((entry) => shortDayNames[entry.key])
          .toList();
      log('ANNISA111523: formatSelectedDaysText =  ${selectedDayNames.join(', ')}');
      return 'Every ${selectedDayNames.join(', ')}';
    } else if (selectedDays.isEmpty) {
      return '';
    } else {
      log('ANNISA111523: formatSelectedDaysText No days!!');
      return 'Today'; // Display 'Today' when no day is selected
    }
  }

  void updateRepeatSetting(bool isRepeatEnabled, List<int>? selectedDays) {
    final currentState = state;
    if (currentState is InputAlarmProfileInitial) {
      final currentStateAsInitial = currentState as InputAlarmProfileInitial;
      emit(currentStateAsInitial.copyWith(
        isRepeatEnabled: isRepeatEnabled,
        selectedDays: selectedDays,
      ));
    }
  }

  void toggleProfileSelectionForDeletion(AlarmProfile profile) {
    if (selectedProfilesForDeletion.contains(profile)) {
      selectedProfilesForDeletion.remove(profile);
    } else {
      selectedProfilesForDeletion.add(profile);
    }
  }

  Future<void> editedAlarmProfile(AlarmProfile profileToEdit) async {
    final profileNameController =
        TextEditingController(text: state.profileName);
    final durationController =
        TextEditingController(text: state.alarmDuration?.toString());
    final thresholdController =
        TextEditingController(text: state.alarmThreshold?.toString());
    emit(InputAlarmProfileEditing(
      isEditing: true,
      profileToEdit: profileToEdit,
      isUrgentAlarm: true,
      isUrgentSoon: state.isUrgentSoon,
      isLowAlert: state.isLowAlert,
      isHighAlert: state.isHighAlert,
      isSensorSignalLoss: state.isSensorSignalLoss,
      isPumpRefill: state.isPumpRefill,
      profileName: state.profileName,
      selectedTime: state.selectedTime,
      isRepeatEnabled: state.isRepeatEnabled,
      selectedDays: state.selectedDays,
      selectedSound: state.selectedSound,
      showCheckboxes: state.showCheckboxes,
      light: state.light,
      isProfileSaved: state.isProfileSaved,
      selectedDate: state.selectedDate,
      alarmDuration: state.alarmDuration,
      alarmThreshold: state.alarmThreshold,
      snoozeDuration: state.snoozeDuration,
      profileNameController: profileNameController,
      thresholdController: thresholdController,
      durationController: durationController,
      isSnoozeEnabled: state.isSnoozeEnabled,
    ));
    try {
      // Save the profile to StateMgr's savedProfiles
      log('ANNISA111423:profileToEdit: saveAlarmProfile');
      stateMgr.saveAlarmProfile(profileToEdit);
      log('ANNISA111423:profileToEdit: after saveAlarmProfile');

      log('ANNISA111423:profileToEdit.InputAlarmProfileSuccess: success!!');
      emit(InputAlarmProfileSuccess(
        isUrgentAlarm: true,
        isUrgentSoon: state.isUrgentSoon,
        isLowAlert: state.isLowAlert,
        isHighAlert: state.isHighAlert,
        isSensorSignalLoss: state.isSensorSignalLoss,
        isPumpRefill: state.isPumpRefill,
        profileName: state.profileName,
        selectedTime: state.selectedTime,
        isRepeatEnabled: state.isRepeatEnabled,
        selectedDays: state.selectedDays,
        selectedSound: state.selectedSound,
        showCheckboxes: state.showCheckboxes,
        light: state.light,
        isProfileSaved: state.isProfileSaved,
        selectedDate: state.selectedDate,
        savedProfile: profileToEdit,
        alarmDuration: state.alarmDuration,
        alarmThreshold: state.alarmThreshold,
        snoozeDuration: state.snoozeDuration,
        profileNameController: profileNameController,
        thresholdController: thresholdController,
        durationController: durationController,
        isSnoozeEnabled: state.isSnoozeEnabled,
      ));
    } catch (e) {
      // Handle the failure case and emit the failure state
      emit(InputAlarmProfileFailure(
        error: "Failed to edit the Alarm profile: $e",
        isUrgentAlarm: true,
        isUrgentSoon: state.isUrgentSoon,
        isLowAlert: state.isLowAlert,
        isHighAlert: state.isHighAlert,
        isSensorSignalLoss: state.isSensorSignalLoss,
        isPumpRefill: state.isPumpRefill,
        profileName: state.profileName,
        selectedTime: state.selectedTime,
        isRepeatEnabled: state.isRepeatEnabled,
        selectedDays: state.selectedDays,
        selectedSound: state.selectedSound,
        // Maintain the selected sound
        showCheckboxes: state.showCheckboxes,
        light: state.light,
        isProfileSaved: state.isProfileSaved,
        selectedDate: state.selectedDate,
        alarmDuration: state.alarmDuration,
        alarmThreshold: state.alarmThreshold,
        snoozeDuration: state.snoozeDuration,
        profileNameController: profileNameController,
        thresholdController: thresholdController,
        durationController: durationController,
        isSnoozeEnabled: state.isSnoozeEnabled,
      ));
    }
  }

  Future<void> submitAlarmProfile(AlarmProfile profile) async {
    final profileNameController =
        TextEditingController(text: state.profileName);
    final durationController =
        TextEditingController(text: state.alarmDuration?.toString());
    final thresholdController =
        TextEditingController(text: state.alarmThreshold?.toString());
    emit(InputAlarmProfileSubmitting(
      isUrgentAlarm: true,
      isUrgentSoon: state.isUrgentSoon,
      isLowAlert: state.isLowAlert,
      isHighAlert: state.isHighAlert,
      isSensorSignalLoss: state.isSensorSignalLoss,
      isPumpRefill: state.isPumpRefill,
      profileName: state.profileName,
      selectedTime: state.selectedTime,
      isRepeatEnabled: state.isRepeatEnabled,
      selectedDays: state.selectedDays,
      selectedSound: state.selectedSound,
      showCheckboxes: state.showCheckboxes,
      light: state.light,
      isProfileSaved: state.isProfileSaved,
      selectedDate: state.selectedDate,
      alarmDuration: state.alarmDuration,
      alarmThreshold: state.alarmThreshold,
      snoozeDuration: state.snoozeDuration,
      profileNameController: profileNameController,
      thresholdController: thresholdController,
      durationController: durationController,
      isSnoozeEnabled: state.isSnoozeEnabled,
    ));
    try {
      // Save the profile to StateMgr's savedProfiles
      log('ANNISA112423:InputAlarmProfileBloc: saveAlarmProfile');
      stateMgr.saveAlarmProfile(profile);
      log('ANNISA112423:InputAlarmProfileBloc: after saveAlarmProfile');
      // Notify listeners that a profile is saved
      profileSavedController.add(null);

      log('ANNISA112423:submitAlarmProfile.InputAlarmProfileSuccess: success!!');
      emit(InputAlarmProfileSuccess(
        isUrgentAlarm: true,
        isUrgentSoon: state.isUrgentSoon,
        isLowAlert: state.isLowAlert,
        isHighAlert: state.isHighAlert,
        isSensorSignalLoss: state.isSensorSignalLoss,
        isPumpRefill: state.isPumpRefill,
        profileName: state.profileName,
        selectedTime: state.selectedTime,
        isRepeatEnabled: state.isRepeatEnabled,
        selectedDays: state.selectedDays,
        selectedSound: state.selectedSound,
        showCheckboxes: state.showCheckboxes,
        light: state.light,
        isProfileSaved: state.isProfileSaved,
        savedProfile: profile,
        selectedDate: state.selectedDate,
        alarmDuration: state.alarmDuration,
        alarmThreshold: state.alarmThreshold,
        snoozeDuration: state.snoozeDuration,
        profileNameController: profileNameController,
        thresholdController: thresholdController,
        durationController: durationController,
        isSnoozeEnabled: state.isSnoozeEnabled,
      ));
    } catch (e) {
      // Handle the failure case and emit the failure state
      emit(InputAlarmProfileFailure(
        error: "Failed to submit the Alarm profile: $e",
        isUrgentAlarm: true,
        isUrgentSoon: state.isUrgentSoon,
        isLowAlert: state.isLowAlert,
        isHighAlert: state.isHighAlert,
        isSensorSignalLoss: state.isSensorSignalLoss,
        isPumpRefill: state.isPumpRefill,
        profileName: state.profileName,
        selectedTime: state.selectedTime,
        isRepeatEnabled: state.isRepeatEnabled,
        selectedDays: state.selectedDays,
        selectedSound: state.selectedSound,
        // Maintain the selected sound
        selectedProfilesForDeletion: state.selectedProfilesForDeletion,
        showCheckboxes: state.showCheckboxes,
        light: state.light,
        isProfileSaved: state.isProfileSaved,
        selectedDate: state.selectedDate,
        alarmDuration: state.alarmDuration,
        alarmThreshold: state.alarmThreshold,
        snoozeDuration: state.snoozeDuration,
        profileNameController: profileNameController,
        thresholdController: thresholdController,
        durationController: durationController,
        isSnoozeEnabled: state.isSnoozeEnabled,
      ));
    }
  }
}

Future<bool?> showSnoozeEditDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Edit Profile with Snooze Enabled"),
        content: Text(
            "The profile is currently in snooze mode. Do you want to proceed with the edit?"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Do not proceed with the edit
            },
            child: Text("Cancel Edit"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Proceed with the edit
            },
            child: Text("Edit Anyway"),
          ),
        ],
      );
    },
  );
}

bool shouldRepeatOnDay(List<int> selectedDays, int currentDay) {
  return selectedDays[currentDay] == 1;
}

class DaysOfWeekSelector extends StatelessWidget {
  final List<bool>? selectedDays;
  final Function(int)? onDaySelected;
  final EdgeInsets dayPadding;
  final TextStyle dayTextStyle;

  DaysOfWeekSelector({
    required this.selectedDays,
    required this.onDaySelected,
    this.dayPadding = const EdgeInsets.all(8.0),
    this.dayTextStyle = const TextStyle(),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 2; i <= 8; i++) // Adjust the loop to start from 2
              GestureDetector(
                onTap: () {
                  onDaySelected!(i);
                },
                child: Container(
                  padding: dayPadding,
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: selectedDays![i - 2] ? Colors.blue : Colors.white,
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getDayAbbreviation(i),
                      style: TextStyle(
                        color: selectedDays![i - 2] ? Colors.blue : Colors.grey,
                        fontSize: 14.0,
                        fontWeight: selectedDays![i - 2]
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _getDayAbbreviation(int index) {
    switch (index) {
      case 2:
        return 'S';
      case 3:
        return 'M';
      case 4:
        return 'T';
      case 5:
        return 'W';
      case 6:
        return 'T';
      case 7:
        return 'F';
      case 8:
        return 'S';
      default:
        return '';
    }
  }
}

// Use CustomTimePicker as a function to show the time picker
Future<TimeOfDay?> showCustomTimePicker(
    BuildContext context, TimeOfDay initialTime) async {
  TimeOfDay? selectedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
    builder: (BuildContext context, Widget? child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      );
    },
  );

  return selectedTime;
}

Future<DateTime?> showCustomDatePicker(
    BuildContext context, DateTime? initialDate) async {
  DateTime now = DateTime.now();
  DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: now,
    lastDate: DateTime(2100),
    selectableDayPredicate: (DateTime day) =>
        !day.isBefore(now.subtract(const Duration(days: 1))),
    // Allow selection of today and future dates
    builder: (BuildContext context, Widget? child) {
      // You can customize the appearance of the date picker here
      return Theme(
        data: ThemeData.light(), // Customize the theme as needed
        child: child!,
      );
    },
  );

  return selectedDate;
}

class errorMessage implements Exception {
  final String message;

  errorMessage(this.message);

  @override
  String toString() {
    return 'Error: $message';
  }
}

Future<bool?> showDeleteConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this profile?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop(
                  false); // returning false, indicating deletion is not confirmed
            },
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              Navigator.of(context)
                  .pop(true); // returning true, confirming deletion
            },
          ),
        ],
      );
    },
  );
}

void showConfirmationDialog(
  BuildContext context,
  String message, {
  VoidCallback? onConfirmed,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              onConfirmed?.call(); // Call the confirmed callback
            },
            child: const Text('Proceed'),
          ),
        ],
      );
    },
  );
}

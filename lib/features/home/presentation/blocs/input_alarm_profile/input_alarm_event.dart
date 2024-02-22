part of 'input_alarm_bloc.dart';

abstract class InputAlarmProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InputAlarmProfileEnableSnooze extends InputAlarmProfileEvent {}

class InputAlarmProfileDisableSnooze extends InputAlarmProfileEvent {}

class SoundSelectedEvent extends InputAlarmProfileEvent {
  SoundSelectedEvent(this.selectedSound);
  final String selectedSound;
}

class InputAlarmProfileDateChanged extends InputAlarmProfileEvent {
  InputAlarmProfileDateChanged(this.selectedDate);
  final DateTime? selectedDate;

  @override
  List<Object> get props => [selectedDate ?? DateTime.now()];
}

class UpdateSelectedProfilesForDeletion extends InputAlarmProfileEvent {
  UpdateSelectedProfilesForDeletion(this.profileToDelete);
  final AlarmProfile profileToDelete;

  @override
  List<Object?> get props => [profileToDelete];
}

class SubmitAlarmProfileEvent extends InputAlarmProfileEvent {
  SubmitAlarmProfileEvent(this.profile);
  final AlarmProfile profile;
}

class EditProfileEvent extends InputAlarmProfileEvent {
  EditProfileEvent(this.profileToEdit);
  final AlarmProfile profileToEdit;
}

class InputAlarmProfileSnoozeDurationChanged extends InputAlarmProfileEvent {
  InputAlarmProfileSnoozeDurationChanged(this.snoozeDuration);
  final String snoozeDuration;
}

class InputAlarmProfileDaysChanged extends InputAlarmProfileEvent {
  InputAlarmProfileDaysChanged(this.selectedDays);
  final List<int>? selectedDays;
}

class InputAlarmProfileName extends InputAlarmProfileEvent {
  InputAlarmProfileName(this.profileName);
  final String profileName;
}

// Define the event
class UpdateEditedProfileEvent extends InputAlarmProfileEvent {
  UpdateEditedProfileEvent(this.editedProfile);
  final AlarmProfile editedProfile;

  @override
  List<Object?> get props => [editedProfile];
}

class ResetEditingStateEvent extends InputAlarmProfileEvent {
  @override
  List<Object?> get props => [];
}

class InputAlarmProfileUrgentAlertChanged extends InputAlarmProfileEvent {
  InputAlarmProfileUrgentAlertChanged(this.isUrgentAlarm);
  final bool isUrgentAlarm;
}

class InputAlarmProfileLightChanged extends InputAlarmProfileEvent {
  InputAlarmProfileLightChanged(this.lightValue);
  final bool lightValue;
  @override
  List<Object?> get props => [lightValue];
}

class InputAlarmProfileSnoozeEnabledChanged extends InputAlarmProfileEvent {
  InputAlarmProfileSnoozeEnabledChanged(this.isSnoozeEnabled);
  final bool isSnoozeEnabled;
}

class InputAlarmProfileLowAlertChanged extends InputAlarmProfileEvent {
  InputAlarmProfileLowAlertChanged(this.isLowAlert);
  final bool isLowAlert;
}

class InputAlarmProfileHighAlertChanged extends InputAlarmProfileEvent {
  InputAlarmProfileHighAlertChanged(this.isHighAlert);
  final bool isHighAlert;
}

class InputAlarmProfileSensorSignalLossChanged extends InputAlarmProfileEvent {
  InputAlarmProfileSensorSignalLossChanged(this.isSensorSignalLoss);
  final bool isSensorSignalLoss;
}

class InputAlarmProfilePumpRefillChanged extends InputAlarmProfileEvent {
  InputAlarmProfilePumpRefillChanged(this.isPumpRefill);
  final bool isPumpRefill;
}

class InputAlarmProfileTimeChanged extends InputAlarmProfileEvent {
  InputAlarmProfileTimeChanged(this.selectedTime);
  final TimeOfDay selectedTime;

  @override
  List<Object?> get props => [selectedTime];
}

class InputAlarmProfileRepeatChanged extends InputAlarmProfileEvent {
  InputAlarmProfileRepeatChanged({
    required this.isRepeatEnabled,
    this.selectedDays,
  });
  final bool isRepeatEnabled;
  final List<int>? selectedDays;
}

class InputAlarmProfileEdited extends InputAlarmProfileEvent {
  InputAlarmProfileEdited(this.editedProfile);
  final AlarmProfile editedProfile;

  @override
  List<Object?> get props => [editedProfile];
}

class DeleteProfileEvent extends InputAlarmProfileEvent {
  DeleteProfileEvent(this.profileToDelete);

  final AlarmProfile profileToDelete;
}

class ResetAlarmProfileForm extends InputAlarmProfileEvent {}

class InputAlarmProfileNameTextCleared extends InputAlarmProfileEvent {}

class InputAlarmProfileThresholdChanged extends InputAlarmProfileEvent {
  InputAlarmProfileThresholdChanged(this.alarmThreshold);
  final int alarmThreshold;
}

class InputAlarmProfileDurationChanged extends InputAlarmProfileEvent {
  InputAlarmProfileDurationChanged(this.alarmDuration);
  final int alarmDuration;
}

// Define the ToggleProfileSelectionEvent class
class ToggleProfileSelectionEvent extends InputAlarmProfileEvent {
  ToggleProfileSelectionEvent(this.profile);
  final AlarmProfile profile;

  @override
  List<Object> get props => [profile];
}

class ToggleAlarmProfileSwitch extends InputAlarmProfileEvent {
  ToggleAlarmProfileSwitch({
    required this.alarmProfileType,
    required this.value,
  });
  final AlarmProfileType alarmProfileType;
  final bool value;

  @override
  List<Object> get props => [alarmProfileType, value];
}

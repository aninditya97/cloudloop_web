part of 'input_alarm_bloc.dart';

abstract class InputAlarmProfileState extends Equatable {
  final bool isUrgentAlarm;
  final bool isUrgentSoon;
  final bool isLowAlert;
  final bool isHighAlert;
  final bool isSensorSignalLoss;
  final bool isPumpRefill;
  final String profileName;
  final TimeOfDay selectedTime;
  final bool isRepeatEnabled;
  final List<int>? selectedDays;
  final String selectedSound;
  final bool showCheckboxes;
  final bool light;
  final bool isProfileSaved;
  final List<AlarmProfile> selectedProfilesForDeletion;
  final DateTime? selectedDate;
  final int? alarmThreshold;
  final int? alarmDuration;
  final String? snoozeDuration;
  final TextEditingController profileNameController;
  final TextEditingController thresholdController;
  final TextEditingController durationController;
  final bool isSnoozeEnabled;

  InputAlarmProfileState({
    required this.isUrgentAlarm,
    required this.isUrgentSoon,
    required this.isLowAlert,
    required this.isHighAlert,
    required this.isSensorSignalLoss,
    required this.isPumpRefill,
    required this.profileName,
    required this.selectedTime,
    required this.isRepeatEnabled,
    required this.selectedDays,
    required this.selectedSound,
    required this.selectedProfilesForDeletion, // Initialize the property
    required this.showCheckboxes,
    required this.light,
    required this.isProfileSaved,
    required this.selectedDate,
    required this.alarmThreshold, // Add this line
    required this.alarmDuration,
    required this.snoozeDuration,
    required this.profileNameController,
    required this.thresholdController,
    required this.durationController,
    required this.isSnoozeEnabled,
  });

  @override
  InputAlarmProfileState copyWith({
    bool? isUrgentAlarm,
    bool? isUrgentSoon,
    bool? isLowAlert,
    bool? isHighAlert,
    bool? isSensorSignalLoss,
    bool? isPumpRefill,
    String? profileName,
    TimeOfDay? selectedTime,
    bool? isRepeatEnabled,
    List<int>? selectedDays,
    String? selectedSound,
    List<AlarmProfile>? selectedProfilesForDeletion,
    bool? showCheckboxes,
    bool? light,
    bool? isProfileSaved,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? durationController,
    TextEditingController? thresholdController,
    bool? isSnoozeEnabled,
  }) {
    return InputAlarmProfileInitial(
      isUrgentAlarm: isUrgentAlarm ?? this.isUrgentAlarm,
      isUrgentSoon: isUrgentSoon ?? this.isUrgentSoon,
      isLowAlert: isLowAlert ?? this.isLowAlert,
      isHighAlert: isHighAlert ?? this.isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss ?? this.isSensorSignalLoss,
      isPumpRefill: isPumpRefill ?? this.isPumpRefill,
      profileName: profileName ?? this.profileName,
      selectedTime: selectedTime ?? this.selectedTime,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSound: selectedSound ?? this.selectedSound,
      selectedProfilesForDeletion:
      selectedProfilesForDeletion ?? this.selectedProfilesForDeletion,
      showCheckboxes: showCheckboxes ?? this.showCheckboxes,
      light: light ?? this.light,
      isProfileSaved: isProfileSaved ?? this.isProfileSaved,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      profileNameController:
      profileNameController ?? this.profileNameController,
      durationController: durationController ?? this.durationController,
      thresholdController: thresholdController ?? this.thresholdController,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
    );
  }

  InputAlarmProfileState updateSelectedTime(TimeOfDay newSelectedTime);
}

class InputAlarmProfileInitial extends InputAlarmProfileState {
  InputAlarmProfileInitial({
    bool isUrgentAlarm = false,
    bool isUrgentSoon = false,
    bool isLowAlert = false,
    bool isHighAlert = false,
    bool isSensorSignalLoss = false,
    bool isPumpRefill = false,
    String profileName = '',
    TimeOfDay selectedTime = const TimeOfDay(hour: 0, minute: 0),
    bool isRepeatEnabled = false,
    List<int>? selectedDays = const [],
    String selectedSound = '',
    List<AlarmProfile> selectedProfilesForDeletion = const [],
    bool showCheckboxes = false,
    bool light = false,
    bool isProfileSaved = false,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    required TextEditingController profileNameController,
    required TextEditingController thresholdController,
    required TextEditingController durationController,
    bool isSnoozeEnabled = false,
  }) : super(
    isUrgentAlarm: isUrgentAlarm,
    isUrgentSoon: isUrgentSoon,
    isLowAlert: isLowAlert,
    isHighAlert: isHighAlert,
    isSensorSignalLoss: isSensorSignalLoss,
    isPumpRefill: isPumpRefill,
    profileName: profileName,
    selectedTime: selectedTime,
    isRepeatEnabled: isRepeatEnabled,
    selectedDays: selectedDays,
    selectedSound: selectedSound,
    selectedProfilesForDeletion: selectedProfilesForDeletion,
    showCheckboxes: showCheckboxes,
    light: light,
    isProfileSaved: isProfileSaved,
    selectedDate: selectedDate,
    alarmThreshold: alarmThreshold,
    alarmDuration: alarmDuration,
    snoozeDuration: snoozeDuration,
    profileNameController: profileNameController,
    thresholdController: thresholdController,
    durationController: durationController,
    isSnoozeEnabled: isSnoozeEnabled,
  );

  @override
  List<Object?> get props => [
    isUrgentAlarm,
    isUrgentSoon,
    isLowAlert,
    isHighAlert,
    isSensorSignalLoss,
    isPumpRefill,
    profileName,
    selectedTime,
    isRepeatEnabled,
    selectedDays,
    selectedSound,
    selectedProfilesForDeletion,
    showCheckboxes,
    light,
    isProfileSaved,
    selectedDate,
    alarmThreshold,
    alarmDuration,
    snoozeDuration,
    profileNameController,
    thresholdController,
    durationController,
    isSnoozeEnabled,
  ];

  @override
  InputAlarmProfileInitial copyWith({
    bool? isUrgentAlarm,
    bool? isUrgentSoon,
    bool? isLowAlert,
    bool? isHighAlert,
    bool? isSensorSignalLoss,
    bool? isPumpRefill,
    String? profileName,
    TimeOfDay? selectedTime,
    bool? isRepeatEnabled,
    List<int>? selectedDays,
    String? selectedSound,
    List<AlarmProfile>? selectedProfilesForDeletion,
    bool? showCheckboxes,
    bool? light,
    bool? isProfileSaved,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? thresholdController,
    TextEditingController? durationController,
    bool? isSnoozeEnabled,
  }) {
    return InputAlarmProfileInitial(
      isUrgentAlarm: isUrgentAlarm ?? this.isUrgentAlarm,
      isUrgentSoon: isUrgentSoon ?? this.isUrgentSoon,
      isLowAlert: isLowAlert ?? this.isLowAlert,
      isHighAlert: isHighAlert ?? this.isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss ?? this.isSensorSignalLoss,
      isPumpRefill: isPumpRefill ?? this.isPumpRefill,
      profileName: profileName ?? this.profileName,
      selectedTime: selectedTime ?? this.selectedTime,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSound: selectedSound ?? this.selectedSound,
      selectedProfilesForDeletion:
      selectedProfilesForDeletion ?? this.selectedProfilesForDeletion,
      showCheckboxes: showCheckboxes ?? this.showCheckboxes,
      light: light ?? this.light,
      isProfileSaved: isProfileSaved ?? this.isProfileSaved,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      profileNameController:
      profileNameController ?? this.profileNameController,
      thresholdController: thresholdController ?? this.thresholdController,
      durationController: durationController ?? this.durationController,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
    );
  }

  @override
  InputAlarmProfileState updateSelectedTime(TimeOfDay newSelectedTime) {
    return copyWith(selectedTime: newSelectedTime);
  }
}

class InputAlarmProfileSuccess extends InputAlarmProfileState {
  final AlarmProfile savedProfile; // Add this property
  InputAlarmProfileSuccess({
    required DateTime? selectedDate,
    required bool isUrgentAlarm,
    required bool isUrgentSoon,
    required bool isLowAlert,
    required bool isHighAlert,
    required bool isSensorSignalLoss,
    required bool isPumpRefill,
    required String profileName,
    required TimeOfDay selectedTime,
    required bool isRepeatEnabled,
    required List<int>? selectedDays,
    required String selectedSound,
    List<AlarmProfile>? selectedProfilesForDeletion, // Make it optional
    required bool showCheckboxes,
    required bool light,
    required bool isProfileSaved,
    required this.savedProfile,
    required int? alarmThreshold,
    required int? alarmDuration,
    required String? snoozeDuration,
    required TextEditingController profileNameController,
    required TextEditingController thresholdController,
    required TextEditingController durationController,
    required bool isSnoozeEnabled,
  }) : super(
    isUrgentAlarm: isUrgentAlarm,
    isUrgentSoon: isUrgentSoon,
    isLowAlert: isLowAlert,
    isHighAlert: isHighAlert,
    isSensorSignalLoss: isSensorSignalLoss,
    isPumpRefill: isPumpRefill,
    profileName: profileName,
    selectedTime: selectedTime,
    isRepeatEnabled: isRepeatEnabled,
    selectedDays: selectedDays ?? [],
    selectedSound: selectedSound,
    selectedProfilesForDeletion: selectedProfilesForDeletion ?? [],
    // Initialize it to an empty list
    showCheckboxes: showCheckboxes,
    light: light,
    isProfileSaved: isProfileSaved,
    selectedDate: selectedDate ?? DateTime.now(),
    alarmThreshold: alarmThreshold,
    alarmDuration: alarmDuration,
    snoozeDuration: snoozeDuration,
    profileNameController: profileNameController,
    thresholdController: thresholdController,
    durationController: durationController,
    isSnoozeEnabled: isSnoozeEnabled,
  );

  @override
  List<Object> get props => [savedProfile];

  @override
  InputAlarmProfileSuccess copyWith({
    bool? isUrgentAlarm,
    bool? isUrgentSoon,
    bool? isLowAlert,
    bool? isHighAlert,
    bool? isSensorSignalLoss,
    bool? isPumpRefill,
    String? profileName,
    TimeOfDay? selectedTime,
    bool? isRepeatEnabled,
    List<int>? selectedDays,
    String? selectedSound,
    bool? showCheckboxes,
    List<AlarmProfile>? selectedProfilesForDeletion,
    bool? light,
    bool? isProfileSaved,
    AlarmProfile? savedProfile,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? thresholdController,
    TextEditingController? durationController,
    bool? isSnoozeEnabled,
  }) {
    return InputAlarmProfileSuccess(
      isUrgentAlarm: isUrgentAlarm ?? this.isUrgentAlarm,
      isUrgentSoon: isUrgentSoon ?? this.isUrgentSoon,
      isLowAlert: isLowAlert ?? this.isLowAlert,
      isHighAlert: isHighAlert ?? this.isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss ?? this.isSensorSignalLoss,
      isPumpRefill: isPumpRefill ?? this.isPumpRefill,
      profileName: profileName ?? this.profileName,
      selectedTime: selectedTime ?? this.selectedTime,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSound: selectedSound ?? this.selectedSound,
      selectedProfilesForDeletion:
      selectedProfilesForDeletion ?? this.selectedProfilesForDeletion,
      showCheckboxes: showCheckboxes ?? this.showCheckboxes,
      light: light ?? this.light,
      isProfileSaved: isProfileSaved ?? this.isProfileSaved,
      savedProfile: savedProfile ?? this.savedProfile,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      profileNameController:
      profileNameController ?? this.profileNameController,
      thresholdController: thresholdController ?? this.thresholdController,
      durationController: durationController ?? this.durationController,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
    );
  }

  @override
  InputAlarmProfileState updateSelectedTime(TimeOfDay newSelectedTime) {
    return copyWith(selectedTime: newSelectedTime);
  }
}

class InputAlarmProfileFailure extends InputAlarmProfileState {
  final String error;
  final bool isUrgentAlarm;
  final bool isUrgentSoon;
  final bool isLowAlert;
  final bool isHighAlert;
  final bool isSensorSignalLoss;
  final bool isPumpRefill;
  final String profileName;
  final TimeOfDay selectedTime;
  final bool isRepeatEnabled;
  final List<int>? selectedDays;
  final String selectedSound; // Include selectedSound property
  final bool showCheckboxes;
  final bool light;
  final bool isProfileSaved;
  final DateTime? selectedDate;
  final int? alarmThreshold;
  final int? alarmDuration;
  final String? snoozeDuration;
  final TextEditingController profileNameController;
  final TextEditingController thresholdController;
  final TextEditingController durationController;
  final bool isSnoozeEnabled;

  InputAlarmProfileFailure({
    required this.error,
    required this.isUrgentAlarm,
    required this.isUrgentSoon,
    required this.isLowAlert,
    required this.isHighAlert,
    required this.isSensorSignalLoss,
    required this.isPumpRefill,
    required this.profileName,
    required this.selectedTime,
    required this.isRepeatEnabled,
    required this.selectedDays,
    required this.selectedSound,
    required this.showCheckboxes,
    required this.light,
    required this.isProfileSaved,
    required this.selectedDate,
    required this.alarmThreshold,
    required this.alarmDuration,
    List<AlarmProfile> selectedProfilesForDeletion = const [],
    required this.snoozeDuration, // Initialize it here
    required this.profileNameController,
    required this.thresholdController,
    required this.durationController,
    required this.isSnoozeEnabled,
  }) : super(
    isUrgentAlarm: isUrgentAlarm,
    isUrgentSoon: isUrgentSoon,
    isLowAlert: isLowAlert,
    isHighAlert: isHighAlert,
    isSensorSignalLoss: isSensorSignalLoss,
    isPumpRefill: isPumpRefill,
    profileName: profileName,
    selectedTime: selectedTime,
    isRepeatEnabled: isRepeatEnabled,
    selectedDays: selectedDays,
    selectedSound: selectedSound,
    selectedProfilesForDeletion: selectedProfilesForDeletion,
    showCheckboxes: showCheckboxes,
    light: light,
    isProfileSaved: isProfileSaved,
    selectedDate: selectedDate,
    alarmThreshold: alarmThreshold,
    alarmDuration: alarmDuration,
    snoozeDuration: snoozeDuration,
    profileNameController: profileNameController,
    thresholdController: thresholdController,
    durationController: durationController,
    isSnoozeEnabled: isSnoozeEnabled,
  );

  factory InputAlarmProfileFailure.newProfileFailure({
    required String error,
    required String profileName,
    required bool isUrgentAlarm,
    required bool isUrgentSoon,
    required bool isLowAlert,
    required bool isHighAlert,
    required bool isSensorSignalLoss,
    required bool isPumpRefill,
    required TimeOfDay selectedTime,
    required bool isRepeatEnabled,
    required List<int>? selectedDays,
    required String selectedSound,
    required bool showCheckboxes,
    required bool light,
    required bool isProfileSaved,
    required DateTime? selectedDate,
    required int? alarmThreshold,
    required int? alarmDuration,
    required String? snoozeDuration,
    required TextEditingController profileNameController,
    required TextEditingController thresholdController,
    required TextEditingController durationController,
    required bool isSnoozeEnabled,
  }) {
    return InputAlarmProfileFailure(
      error: error,
      isUrgentAlarm: isUrgentAlarm,
      isUrgentSoon: isUrgentSoon,
      isLowAlert: isLowAlert,
      isHighAlert: isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss,
      isPumpRefill: isPumpRefill,
      profileName: profileName,
      selectedTime: selectedTime,
      isRepeatEnabled: isRepeatEnabled,
      selectedDays: selectedDays,
      selectedSound: selectedSound,
      showCheckboxes: showCheckboxes,
      light: light,
      isProfileSaved: isProfileSaved,
      alarmThreshold: alarmThreshold,
      alarmDuration: alarmDuration,
      selectedDate: selectedDate,
      selectedProfilesForDeletion: [],
      // Initialize selectedProfilesForDeletion
      snoozeDuration: snoozeDuration,
      profileNameController: profileNameController,
      thresholdController: thresholdController,
      durationController: durationController,
      isSnoozeEnabled: isSnoozeEnabled,
    );
  }

  @override
  List<Object?> get props => [error];

  @override
  InputAlarmProfileFailure copyWith({
    String? error,
    bool? isUrgentAlarm,
    bool? isUrgentSoon,
    bool? isLowAlert,
    bool? isHighAlert,
    bool? isSensorSignalLoss,
    bool? isPumpRefill,
    String? profileName,
    TimeOfDay? selectedTime,
    bool? isRepeatEnabled,
    List<int>? selectedDays,
    String? selectedSound,
    bool? showCheckboxes,
    bool? light,
    bool? isProfileSaved,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    List<AlarmProfile>? selectedProfilesForDeletion,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? thresholdController,
    TextEditingController? durationController,
    bool? isSnoozeEnabled,
  }) {
    return InputAlarmProfileFailure(
      error: error ?? this.error,
      isUrgentAlarm: isUrgentAlarm ?? this.isUrgentAlarm,
      isUrgentSoon: isUrgentSoon ?? this.isUrgentSoon,
      isLowAlert: isLowAlert ?? this.isLowAlert,
      isHighAlert: isHighAlert ?? this.isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss ?? this.isSensorSignalLoss,
      isPumpRefill: isPumpRefill ?? this.isPumpRefill,
      profileName: profileName ?? this.profileName,
      selectedTime: selectedTime ?? this.selectedTime,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSound: selectedSound ?? this.selectedSound,
      showCheckboxes: showCheckboxes ?? this.showCheckboxes,
      light: light ?? this.light,
      isProfileSaved: isProfileSaved ?? this.isProfileSaved,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      selectedProfilesForDeletion:
      selectedProfilesForDeletion ?? this.selectedProfilesForDeletion,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      profileNameController:
      profileNameController ?? this.profileNameController,
      durationController: durationController ?? this.durationController,
      thresholdController: thresholdController ?? this.thresholdController,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
    );
  }

  @override
  InputAlarmProfileState updateSelectedTime(TimeOfDay newSelectedTime) {
    return copyWith(selectedTime: newSelectedTime);
  }
}

class InputAlarmProfileSubmitting extends InputAlarmProfileState {
  InputAlarmProfileSubmitting({
    required bool isUrgentAlarm,
    required bool isUrgentSoon,
    required bool isLowAlert,
    required bool isHighAlert,
    required bool isSensorSignalLoss,
    required bool isPumpRefill,
    required String profileName,
    required TimeOfDay selectedTime,
    required bool isRepeatEnabled,
    required List<int>? selectedDays,
    required String selectedSound,
    List<AlarmProfile>? selectedProfilesForDeletion, // Make it optional
    required bool showCheckboxes,
    required bool light,
    required bool isProfileSaved,
    required DateTime? selectedDate,
    required int? alarmDuration,
    required int? alarmThreshold,
    required String? snoozeDuration,
    required TextEditingController profileNameController,
    required TextEditingController thresholdController,
    required TextEditingController durationController,
    required bool isSnoozeEnabled,
  }) : super(
    isUrgentAlarm: isUrgentAlarm,
    isUrgentSoon: isUrgentSoon,
    isLowAlert: isLowAlert,
    isHighAlert: isHighAlert,
    isSensorSignalLoss: isSensorSignalLoss,
    isPumpRefill: isPumpRefill,
    profileName: profileName,
    selectedTime: selectedTime,
    isRepeatEnabled: isRepeatEnabled,
    selectedDays: selectedDays,
    selectedSound: selectedSound,
    selectedProfilesForDeletion: selectedProfilesForDeletion ?? [],
    // Initialize it to an empty list
    showCheckboxes: showCheckboxes,
    selectedDate: selectedDate,
    light: light,
    isProfileSaved: isProfileSaved,
    alarmThreshold: alarmThreshold,
    alarmDuration: alarmDuration,
    snoozeDuration: snoozeDuration,
    profileNameController: profileNameController,
    thresholdController: thresholdController,
    durationController: durationController,
    isSnoozeEnabled: isSnoozeEnabled,
  );

  factory InputAlarmProfileSubmitting.newProfileSubmitting({
    required bool isUrgentAlarm,
    required bool isUrgentSoon,
    required bool isLowAlert,
    required bool isHighAlert,
    required bool isSensorSignalLoss,
    required bool isPumpRefill,
    required String profileName,
    required TimeOfDay selectedTime,
    required bool isRepeatEnabled,
    required List<int> selectedDays,
    required String selectedSound,
    required bool light,
    required bool isProfileSaved,
    required DateTime selectedDate,
    required int? alarmThreshold,
    required int? alarmDuration,
    required String? snoozeDuration,
    required TextEditingController profileNameController,
    required TextEditingController thresholdController,
    required TextEditingController durationController,
    required bool isSnoozeEnabled,
  }) {
    return InputAlarmProfileSubmitting(
      isUrgentAlarm: isUrgentAlarm,
      isUrgentSoon: isUrgentSoon,
      isLowAlert: isLowAlert,
      isHighAlert: isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss,
      isPumpRefill: isPumpRefill,
      profileName: profileName,
      selectedTime: selectedTime,
      isRepeatEnabled: isRepeatEnabled,
      selectedDays: selectedDays,
      selectedSound: selectedSound,
      selectedProfilesForDeletion: [],
      showCheckboxes: false,
      light: light,
      isProfileSaved: isProfileSaved,
      selectedDate: selectedDate,
      alarmThreshold: alarmThreshold,
      alarmDuration: alarmDuration,
      snoozeDuration: snoozeDuration,
      profileNameController: profileNameController,
      thresholdController: thresholdController,
      durationController: durationController,
      isSnoozeEnabled: isSnoozeEnabled,
    );
  }

  @override
  List<Object?> get props => [
    isUrgentAlarm,
    isUrgentSoon,
    isLowAlert,
    isHighAlert,
    isSensorSignalLoss,
    isPumpRefill,
    profileName,
    selectedTime,
    isRepeatEnabled,
    selectedDays,
    selectedSound, // Include selectedSound property in props
    selectedProfilesForDeletion,
    showCheckboxes,
    light,
    isProfileSaved,
    selectedDate,
    alarmThreshold,
    alarmDuration,
    snoozeDuration,
    profileNameController,
    thresholdController,
    durationController,
    isSnoozeEnabled,
  ];

  @override
  InputAlarmProfileSubmitting copyWith({
    bool? isUrgentAlarm,
    bool? isUrgentSoon,
    bool? isLowAlert,
    bool? isHighAlert,
    bool? isSensorSignalLoss,
    bool? isPumpRefill,
    String? profileName,
    TimeOfDay? selectedTime,
    bool? isRepeatEnabled,
    List<int>? selectedDays,
    String? selectedSound,
    List<AlarmProfile>? selectedProfilesForDeletion,
    bool? showCheckboxes,
    bool? light,
    bool? isProfileSaved,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? thresholdController,
    TextEditingController? durationController,
    bool? isSnoozeEnabled,
  }) {
    return InputAlarmProfileSubmitting(
      isUrgentAlarm: isUrgentAlarm ?? this.isUrgentAlarm,
      isUrgentSoon: isUrgentSoon ?? this.isUrgentSoon,
      isLowAlert: isLowAlert ?? this.isLowAlert,
      isHighAlert: isHighAlert ?? this.isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss ?? this.isSensorSignalLoss,
      isPumpRefill: isPumpRefill ?? this.isPumpRefill,
      profileName: profileName ?? this.profileName,
      selectedTime: selectedTime ?? this.selectedTime,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSound: selectedSound ?? this.selectedSound,
      selectedProfilesForDeletion:
      selectedProfilesForDeletion ?? this.selectedProfilesForDeletion,
      showCheckboxes: showCheckboxes ?? this.showCheckboxes,
      light: light ?? this.light,
      isProfileSaved: isProfileSaved ?? this.isProfileSaved,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      profileNameController:
      profileNameController ?? this.profileNameController,
      thresholdController: thresholdController ?? this.thresholdController,
      durationController: durationController ?? this.durationController,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
    );
  }

  @override
  InputAlarmProfileState updateSelectedTime(TimeOfDay newSelectedTime) {
    return copyWith(selectedTime: newSelectedTime);
  }
}

class InputAlarmProfileEditing extends InputAlarmProfileState {
  // Properties specific to editing state
  final bool
  isEditing; // You can use this to differentiate between adding and editing
  final AlarmProfile profileToEdit;
  final DateTime? selectedDate; // Add this property
  InputAlarmProfileEditing({
    required this.isEditing,
    required this.profileToEdit,
    this.selectedDate,
    // Include other properties as needed for the editing state
    bool isUrgentAlarm = false,
    bool isUrgentSoon = false,
    bool isLowAlert = false,
    bool isHighAlert = false,
    bool isSensorSignalLoss = false,
    bool isPumpRefill = false,
    String profileName = '',
    TimeOfDay selectedTime = const TimeOfDay(hour: 0, minute: 0),
    bool isRepeatEnabled = false,
    List<int>? selectedDays = const [],
    String selectedSound = '',
    List<AlarmProfile> selectedProfilesForDeletion = const [],
    bool light = false,
    bool showCheckboxes = false,
    bool isProfileSaved = false,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    required TextEditingController profileNameController,
    required TextEditingController thresholdController,
    required TextEditingController durationController,
    bool isSnoozeEnabled = false,
  }) : super(
    isUrgentAlarm: isUrgentAlarm,
    isUrgentSoon: isUrgentSoon,
    isLowAlert: isLowAlert,
    isHighAlert: isHighAlert,
    isSensorSignalLoss: isSensorSignalLoss,
    isPumpRefill: isPumpRefill,
    profileName: profileName,
    selectedTime: selectedTime,
    isRepeatEnabled: isRepeatEnabled,
    selectedDays: selectedDays,
    selectedSound: selectedSound,
    selectedProfilesForDeletion: selectedProfilesForDeletion,
    light: light,
    isProfileSaved: isProfileSaved,
    showCheckboxes: showCheckboxes,
    selectedDate: selectedDate,
    alarmThreshold: alarmThreshold,
    alarmDuration: alarmDuration,
    snoozeDuration: snoozeDuration,
    profileNameController: profileNameController,
    thresholdController: thresholdController,
    durationController: durationController,
    isSnoozeEnabled: isSnoozeEnabled,
  );

  @override
  List<Object?> get props => [
    isUrgentAlarm,
    isUrgentSoon,
    isLowAlert,
    isHighAlert,
    isSensorSignalLoss,
    isPumpRefill,
    profileName,
    selectedTime,
    isRepeatEnabled,
    selectedDays,
    selectedSound,
    selectedProfilesForDeletion,
    showCheckboxes,
    light,
    isProfileSaved,
    selectedDate,
    alarmThreshold,
    alarmDuration,
    snoozeDuration,
    profileNameController,
    thresholdController,
    durationController,
    isSnoozeEnabled,
  ];

  @override
  InputAlarmProfileEditing copyWith({
    bool? isUrgentAlarm,
    bool? isUrgentSoon,
    bool? isLowAlert,
    bool? isHighAlert,
    bool? isSensorSignalLoss,
    bool? isPumpRefill,
    String? profileName,
    TimeOfDay? selectedTime,
    bool? isRepeatEnabled,
    List<int>? selectedDays,
    String? selectedSound,
    List<AlarmProfile>? selectedProfilesForDeletion,
    bool? light,
    bool? showCheckboxes,
    bool? isProfileSaved,
    bool? isEditing,
    AlarmProfile? profileToEdit,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? thresholdController,
    TextEditingController? durationController,
    bool? isSnoozeEnabled,
  }) {
    return InputAlarmProfileEditing(
      isEditing: isEditing ?? this.isEditing,
      profileToEdit: profileToEdit ?? this.profileToEdit,
      profileName: profileName ?? this.profileName,
      // Include other properties as needed for the editing state
      isUrgentAlarm: isUrgentAlarm ?? this.isUrgentAlarm,
      isUrgentSoon: isUrgentSoon ?? this.isUrgentSoon,
      isLowAlert: isLowAlert ?? this.isLowAlert,
      isHighAlert: isHighAlert ?? this.isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss ?? this.isSensorSignalLoss,
      isPumpRefill: isPumpRefill ?? this.isPumpRefill,
      selectedTime: selectedTime ?? this.selectedTime,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSound: selectedSound ?? this.selectedSound,
      selectedProfilesForDeletion:
      selectedProfilesForDeletion ?? this.selectedProfilesForDeletion,
      light: light ?? this.light,
      isProfileSaved: isProfileSaved ?? this.isProfileSaved,
      showCheckboxes: showCheckboxes ?? this.showCheckboxes,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      profileNameController:
      profileNameController ?? this.profileNameController,
      thresholdController: thresholdController ?? this.thresholdController,
      durationController: durationController ?? this.durationController,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
    );
  }

  @override
  InputAlarmProfileState updateSelectedTime(TimeOfDay newSelectedTime) {
    return copyWith(selectedTime: newSelectedTime);
  }
}

class ErrorState extends InputAlarmProfileState {
  final String errorMessage;

  ErrorState(
      this.errorMessage, {
        bool isUrgentAlarm = false,
        bool isUrgentSoon = false,
        bool isLowAlert = false,
        bool isHighAlert = false,
        bool isSensorSignalLoss = false,
        bool isPumpRefill = false,
        String profileName = '',
        TimeOfDay selectedTime = const TimeOfDay(hour: 0, minute: 0),
        bool isRepeatEnabled = false,
        List<int>? selectedDays = const [],
        List<AlarmProfile> selectedProfilesForDeletion = const [],
        bool showCheckboxes = false,
        String selectedSound = '',
        bool light = false,
        bool isProfileSaved = false,
        DateTime? selectedDate, // Change the default value to null
        int? alarmThreshold,
        int? alarmDuration,
        String? snoozeDuration,
        TextEditingController? profileNameController,
        TextEditingController? thresholdController,
        TextEditingController? durationController,
        bool isSnoozeEnabled = false,
      }) : super(
    isUrgentAlarm: isUrgentAlarm,
    isUrgentSoon: isUrgentSoon,
    isLowAlert: isLowAlert,
    isHighAlert: isHighAlert,
    isSensorSignalLoss: isSensorSignalLoss,
    isPumpRefill: isPumpRefill,
    profileName: profileName,
    selectedTime: selectedTime,
    isRepeatEnabled: isRepeatEnabled,
    selectedDays: selectedDays ?? [],
    selectedSound: selectedSound,
    selectedProfilesForDeletion: selectedProfilesForDeletion,
    showCheckboxes: showCheckboxes,
    light: light,
    isProfileSaved: isProfileSaved,
    selectedDate: selectedDate ?? DateTime.now(),
    // Use DateTime.now() if selectedDate is null
    alarmThreshold: alarmThreshold,
    alarmDuration: alarmDuration,
    snoozeDuration: snoozeDuration,
    profileNameController:
    profileNameController ?? TextEditingController(),
    thresholdController: thresholdController ?? TextEditingController(),
    durationController: durationController ?? TextEditingController(),
    isSnoozeEnabled: isSnoozeEnabled,
  );

  @override
  List<Object> get props => [errorMessage];

  @override
  ErrorState copyWith({
    bool? isUrgentAlarm,
    bool? isUrgentSoon,
    bool? isLowAlert,
    bool? isHighAlert,
    bool? isSensorSignalLoss,
    bool? isPumpRefill,
    String? profileName,
    TimeOfDay? selectedTime,
    bool? isRepeatEnabled,
    List<int>? selectedDays,
    String? selectedSound,
    List<AlarmProfile>? selectedProfilesForDeletion,
    bool? showCheckboxes,
    bool? light,
    bool? isProfileSaved,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? thresholdController,
    TextEditingController? durationController,
    bool? isSnoozeEnabled,
  }) {
    return ErrorState(
      errorMessage,
      isUrgentAlarm: isUrgentAlarm ?? this.isUrgentAlarm,
      isUrgentSoon: isUrgentSoon ?? this.isUrgentSoon,
      isLowAlert: isLowAlert ?? this.isLowAlert,
      isHighAlert: isHighAlert ?? this.isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss ?? this.isSensorSignalLoss,
      isPumpRefill: isPumpRefill ?? this.isPumpRefill,
      profileName: profileName ?? this.profileName,
      selectedTime: selectedTime ?? this.selectedTime,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSound: selectedSound ?? this.selectedSound,
      selectedProfilesForDeletion:
      selectedProfilesForDeletion ?? this.selectedProfilesForDeletion,
      showCheckboxes: showCheckboxes ?? this.showCheckboxes,
      light: light ?? this.light,
      isProfileSaved: isProfileSaved ?? this.isProfileSaved,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      profileNameController:
      profileNameController ?? this.profileNameController,
      durationController: durationController ?? this.durationController,
      thresholdController: thresholdController ?? this.thresholdController,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
    );
  }

  @override
  InputAlarmProfileState updateSelectedTime(TimeOfDay newSelectedTime) {
    return copyWith(selectedTime: newSelectedTime);
  }
}

class SnoozeState extends InputAlarmProfileState {
  final bool isSnoozeEnabled;

  SnoozeState({
    bool isUrgentAlarm = false,
    bool isUrgentSoon = false,
    bool isLowAlert = false,
    bool isHighAlert = false,
    bool isSensorSignalLoss = false,
    bool isPumpRefill = false,
    String profileName = '',
    TimeOfDay selectedTime = const TimeOfDay(hour: 0, minute: 0),
    bool isRepeatEnabled = false,
    List<int>? selectedDays = const [],
    List<AlarmProfile> selectedProfilesForDeletion = const [],
    bool showCheckboxes = false,
    String selectedSound = '',
    bool light = false,
    bool isProfileSaved = false,
    DateTime? selectedDate, // Change the default value to null
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? thresholdController,
    TextEditingController? durationController,
    required this.isSnoozeEnabled,
  }) : super(
    isUrgentAlarm: isUrgentAlarm,
    isUrgentSoon: isUrgentSoon,
    isLowAlert: isLowAlert,
    isHighAlert: isHighAlert,
    isSensorSignalLoss: isSensorSignalLoss,
    isPumpRefill: isPumpRefill,
    profileName: profileName,
    selectedTime: selectedTime,
    isRepeatEnabled: isRepeatEnabled,
    selectedDays: selectedDays ?? [],
    selectedSound: selectedSound,
    selectedProfilesForDeletion: selectedProfilesForDeletion,
    showCheckboxes: showCheckboxes,
    light: light,
    isProfileSaved: isProfileSaved,
    selectedDate: selectedDate ?? DateTime.now(),
    // Use DateTime.now() if selectedDate is null
    alarmThreshold: alarmThreshold,
    alarmDuration: alarmDuration,
    snoozeDuration: snoozeDuration,
    profileNameController:
    profileNameController ?? TextEditingController(),
    thresholdController: thresholdController ?? TextEditingController(),
    durationController: durationController ?? TextEditingController(),
    isSnoozeEnabled: isSnoozeEnabled,
  );

  @override
  List<Object> get props => [isSnoozeEnabled];

  @override
  SnoozeState copyWith({
    bool? isUrgentAlarm,
    bool? isUrgentSoon,
    bool? isLowAlert,
    bool? isHighAlert,
    bool? isSensorSignalLoss,
    bool? isPumpRefill,
    String? profileName,
    TimeOfDay? selectedTime,
    bool? isRepeatEnabled,
    List<int>? selectedDays,
    String? selectedSound,
    List<AlarmProfile>? selectedProfilesForDeletion,
    bool? showCheckboxes,
    bool? light,
    bool? isProfileSaved,
    DateTime? selectedDate,
    int? alarmThreshold,
    int? alarmDuration,
    String? snoozeDuration,
    TextEditingController? profileNameController,
    TextEditingController? thresholdController,
    TextEditingController? durationController,
    bool? isSnoozeEnabled,
  }) {
    return SnoozeState(
      isUrgentAlarm: isUrgentAlarm ?? this.isUrgentAlarm,
      isUrgentSoon: isUrgentSoon ?? this.isUrgentSoon,
      isLowAlert: isLowAlert ?? this.isLowAlert,
      isHighAlert: isHighAlert ?? this.isHighAlert,
      isSensorSignalLoss: isSensorSignalLoss ?? this.isSensorSignalLoss,
      isPumpRefill: isPumpRefill ?? this.isPumpRefill,
      profileName: profileName ?? this.profileName,
      selectedTime: selectedTime ?? this.selectedTime,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSound: selectedSound ?? this.selectedSound,
      selectedProfilesForDeletion:
      selectedProfilesForDeletion ?? this.selectedProfilesForDeletion,
      showCheckboxes: showCheckboxes ?? this.showCheckboxes,
      light: light ?? this.light,
      isProfileSaved: isProfileSaved ?? this.isProfileSaved,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmThreshold: alarmThreshold ?? this.alarmThreshold,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      profileNameController:
      profileNameController ?? this.profileNameController,
      durationController: durationController ?? this.durationController,
      thresholdController: thresholdController ?? this.thresholdController,
      isSnoozeEnabled: isSnoozeEnabled ?? this.isSnoozeEnabled,
    );
  }

  @override
  InputAlarmProfileState updateSelectedTime(TimeOfDay newSelectedTime) {
    return copyWith(selectedTime: newSelectedTime);
  }
}

import 'package:flutter/material.dart';

class AlarmProfile {
  String profileName;
  bool isUrgentAlarm;
  bool isUrgentSoon;
  bool isLowAlert;
  bool isHighAlert;
  bool isSensorSignalLoss;
  bool isPumpRefill;
  TimeOfDay selectedTime; // Make it nullable
  bool isRepeatEnabled;
  List<int>? selectedDays;
  String selectedSound;
  DateTime? selectedDate; // Make it nullable
  bool isSelectedForDeletion;
  bool isProfileSaved;
  final List<AlarmProfile> selectedProfilesForDeletion;
  int? alarmThreshold;
  int? alarmDuration;
  String? snoozeDuration;
  bool isSnoozeEnabled;
  final TextEditingController profileNameController;
  final TextEditingController thresholdController;
  final TextEditingController durationController;

  AlarmProfile({
    required this.isUrgentAlarm,
    required this.isUrgentSoon,
    required this.isLowAlert,
    required this.isHighAlert,
    required this.isSensorSignalLoss,
    required this.isPumpRefill,
    required this.profileName,
    required this.isRepeatEnabled,
    this.selectedDays,
    required this.selectedSound,
    required this.isProfileSaved,
    required this.selectedProfilesForDeletion,
    required this.profileNameController,
    required this.thresholdController,
    required this.durationController,
    required this.selectedTime, // Allow it to be null
    this.selectedDate, // Allow it to be null
    this.alarmThreshold,
    this.alarmDuration,
    this.snoozeDuration,
    required this.isSnoozeEnabled,
  }) : isSelectedForDeletion = false;
}

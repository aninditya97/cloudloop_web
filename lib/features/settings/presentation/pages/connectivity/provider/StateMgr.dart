import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloudloop_mobile/core/data/models/alarm_profile.dart';

import 'package:flutter/foundation.dart';

class StateMgr extends ChangeNotifier {
  static final StateMgr _singleton = StateMgr._internal();

  factory StateMgr() {
    return _singleton;
  }

  StateMgr._internal();
  bool _isSnoozeActive = false;

  List<AlarmProfile> alarmProfiles = [];
  List<AlarmProfile> savedProfiles = [];
  List<AlarmProfile> newProfiles = [];
  List<AlarmProfile> _callProfiles = [];
  List<AlarmProfile> _alertProfiles = [];

  List<AlarmProfile> get alertProfiles => _alertProfiles;

  List<AlarmProfile> get callProfiles => _callProfiles;
  TextEditingController? profileNameController;

  Map<String, DateTime> _profileSnoozeEndTimes = {};

  // Sets the snooze end time for a specific profile
  void setSnoozeEndTimeForProfile(DateTime snoozeEndTime, AlarmProfile callProfiles) {
    _profileSnoozeEndTimes[callProfiles.profileName] = snoozeEndTime;
  }

  // Checks if snooze is active for a specific profile
  bool isSnoozeActiveForProfile(AlarmProfile callProfiles) {
    log('ANNISA121123 check on StateMgr go inside isSnoozeActiveForProfile');
    log('ANNISA121123 check on StateMgr -> isSnoozeActiveForProfile -> _profileSnoozeEndTimes.containsKey(callProfiles.profileName) value is >> ${_profileSnoozeEndTimes.containsKey(callProfiles.profileName)}');
    if (_profileSnoozeEndTimes.containsKey(callProfiles.profileName)) {
      var snoozeEndTime = _profileSnoozeEndTimes[callProfiles.profileName];
      return DateTime.now().isBefore(snoozeEndTime!);
    }
    return false;
  }

  // Gets the snooze end time for a specific profile
  DateTime? getSnoozeEndTimeForProfile(AlarmProfile callProfiles) {
    log('ANNISA121123 check on StateMgr go inside getSnoozeEndTimeForProfile');
    log('ANNISA121123 check on StateMgr -> getSnoozeEndTimeForProfile -> _profileSnoozeEndTimes[callProfiles.profileName] value is >> ${_profileSnoozeEndTimes[callProfiles.profileName]}');
    return _profileSnoozeEndTimes[callProfiles.profileName];
  }

  // Resets the snooze state for a specific profile
  void resetSnoozeForProfile(AlarmProfile callProfiles) {
    _profileSnoozeEndTimes.remove(callProfiles.profileName);
  }

  // Sets the snooze state
  void setSnoozeActive(bool value) {
    _isSnoozeActive = value;
  }

  // Returns the current snooze state
  bool get isSnoozeActive {
    return _isSnoozeActive;
  }


  int countSavedProfiles() {
    return _callProfiles.length;
  }

  Future<void> saveAlertProfiles(AlarmProfile profile) async {
    try {
      StateMgr().addProfileMe(profile);

      log('Profile saved: $profile');
    } catch (e) {
      log('Failed to save profile: $e');
    }
  }

  List<AlarmProfile> getAlarmProfiles() {
    return callProfiles;
  }

  AlarmProfile? _alarmProfile;

  void updateProfile(AlarmProfile oldProfile, AlarmProfile updatedProfile) {
    try {
      final index = _callProfiles.indexOf(oldProfile);
      if (index != -1) {
        _callProfiles[index] = updatedProfile;
        notifyListeners();
      }
    } catch (e) {
      log('Exception in updateProfile._callProfiles: $e');
    }
  }

  static String formatSelectedDays(List<int>? selectedDays,
      {Function(List<int>)? onSelectedDaysChanged}) {
    if (selectedDays == null) {
      return '';
    } else if (selectedDays.isEmpty) {
      return 'Today'; // Default value when no days are selected
    } else if (selectedDays.length == 7) {
      return 'Every day'; // Display 'Every day' when all days are selected
    } else {
      final shortDayNames = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun'
      ]; // Adjust day names accordingly
      final selectedDayNames = selectedDays
          .map((day) => shortDayNames[day - 2])
          .toList(); // Subtract 2 to map to the range 2 to 8

      // Call the callback function to inform about the selected days change
      onSelectedDaysChanged?.call(selectedDays);

      return 'Every ${selectedDayNames.join(', ')}';
    }
  }

  void addProfile(AlarmProfile profile) {
    try {
      log('ANNISA111723:StateMgr: addProfile._callProfiles');
      _callProfiles.add(profile);
      log('ANNISA111723:StateMgr: addProfile._callProfiles = $_callProfiles');
      notifyListeners(); // Notify listeners to update the UI
    } catch (e) {
      log('Exception in addProfile._callProfiles: $e');
    }
  }

  void addProfileMe(AlarmProfile profile) {
    try {
      log('ANNISA111723:StateMgr: addProfile._alertProfiles');
      _alertProfiles.add(profile);
      log('ANNISA111723:StateMgr: addProfile._alertProfiles = $_alertProfiles');
      notifyListeners(); // Notify listeners to update the UI
    } catch (e) {
      log('Exception in addProfile._callProfiles: $e');
    }
  }

  Future<void> addAlarmProfile(AlarmProfile profile) async {
    // Your existing code to add the profile
    alarmProfiles.add(profile);
    savedProfiles.add(profile);
    notifyListeners();
  }

  void updateAlarmProfile(int index, AlarmProfile updatedProfile) {
    if (index >= 0 && index < alarmProfiles.length) {
      alarmProfiles[index] = updatedProfile;
      notifyListeners();
    }
  }

// Update the selectedSound for an AlarmProfile at a given index
  void updateSelectedSound(int index, String newSelectedSound) {
    if (index >= 0 && index < alarmProfiles.length) {
      alarmProfiles[index].selectedSound = newSelectedSound;
      notifyListeners();
    }
  }

  void saveAlarmProfile(AlarmProfile profile) {
    try {
      log('!!!ANNISA111723:StateMgr: saveAlarmProfile');
      newProfiles.add(profile);
      // Notify listeners only when the profile is successfully saved.
      notifyListeners();
    } catch (e) {
      log('Exception in saveAlarmProfile: $e');
    }
  }

// List to store the listeners
  List<void Function()> _updateListeners = [];

// Add a saved profile to the list
  void addSavedProfile(AlarmProfile profile) {
    log('ANNISA111723:StateMGR.addSavedProfile: COME IN!!');
    try {
      log('ANNISA111723:StateMGR.addSavedProfile try catch >>>');
      alarmProfiles.add(profile);
      log('ANNISA111723:StateMGR.addSavedProfile >> $alarmProfiles');
      notifyListeners(); // Notify the main listeners
    } catch (e) {
      log('Exception in addSavedProfile: $e');
    }
    // Notify the listeners registered for updates in AlarmPageForm
    for (final listener in _updateListeners) {
      listener();
    }
  }

// Method to register a listener
  void registerUpdateListener(void Function() listener) {
    _updateListeners.add(listener);
  }

  void notifyListeners() {
    super.notifyListeners(); // Call the super method from ChangeNotifier
  }

  void deleteAlarmProfile(AlarmProfile profile) {
    log('ANNISA111723:StateMgr ->>> deleteAlarmProfile');
    alarmProfiles.remove(profile);
    callProfiles.remove(profile); // Remove from _callProfiles as well
    log('ANNISA111723:StateMgr >> deleteAlarmProfile callProfiles.remove(profile) ->>> {$callProfiles}');
    log('ANNISA111723:StateMgr >> deleteAlarmProfile alarmProfiles.remove(profile) ->>> {$alarmProfiles}');
    countSavedProfiles();
    log('ANNISA111723:StateMgr >> deleteAlarmProfile countSavedProfiles ->>> {$countSavedProfiles}');
    notifyListeners(); // Notify after deletion
  }

  // Method to set the AlarmProfile
  void setAlarmProfile(AlarmProfile profile) {
    _alarmProfile = profile;
  }

  // Method to get the AlarmProfile
  AlarmProfile? getAlarmProfile() {
    return _alarmProfile;
  }

  AlarmProfile? getProfileByDateTime(
      DateTime selectedDate, TimeOfDay selectedTime) {
    for (final profile in _callProfiles) {
      if (profile.selectedDate == selectedDate &&
          profile.selectedTime == selectedTime) {
        return profile;
      }
    }
    return null; // Return null if no profile matches the given date and time
  }

  bool hasProfileWithDateTime(DateTime dateTime) {
    return _callProfiles.any((AlarmProfile existingProfile) {
      final selectedDate = existingProfile.selectedDate;
      final selectedTime = existingProfile.selectedTime;

      return selectedDate != null &&
          selectedTime != null &&
          selectedDate.isAtSameMomentAs(dateTime) &&
          selectedTime.hour == dateTime.hour &&
          selectedTime.minute == dateTime.minute;
    });
  }
}

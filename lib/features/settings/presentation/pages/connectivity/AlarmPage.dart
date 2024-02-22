import 'dart:developer';

import 'package:cloudloop_mobile/core/data/models/alarm_profile.dart';
import 'package:cloudloop_mobile/features/auth/domain/entities/enums/alarmprofile_type.dart';
import 'package:cloudloop_mobile/features/home/presentation/blocs/input_alarm_profile/input_alarm_bloc.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/StateMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/sections/sections.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AlarmPage extends StatefulWidget {
  AlarmPage({Key? key}) : super(key: key);

  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  late InputAlarmProfileBloc
      _alarmProfileBloc; // Declare without initialization
  late StateMgr? stateMgr;
  late SwitchState switchMgr;
  List<AlarmProfile> selectedProfiles = [];
  bool showCheckboxes = false;
  AlarmProfile? newProfile; // Store the newly created profile

  @override
  void dispose() {
    _alarmProfileBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    switchMgr = Provider.of<SwitchState>(context, listen: false);
    if (switchMgr == null) {
      log('ANNISA112423:_AlarmProfileState_switchMgr is null!!');
      switchMgr = Provider.of<SwitchState>(context, listen: false);
      log('ANNISA112423:_AlarmProfileState_switchMgr Provider.of<SwitchState>(context, listen: false)');
    } else {
      log('ANNISA112423:_AlarmProfileState_switchMgr not null');
    }

    stateMgr = Provider.of<StateMgr>(context, listen: false);
    if (stateMgr == null) {
      log('ANNISA112423:_AlarmProfileState_stateMgr is null!!');
      stateMgr = Provider.of<StateMgr>(context, listen: false);
      log('ANNISA112423:_AlarmProfileState_stateMgr Provider.of<StateMgr>(context, listen: false)');
    } else {
      log('ANNISA112423:_AlarmProfileState_stateMgr not null');
    }

    // Create an instance of InputAlarmProfileBloc and pass the StateMgr
    _alarmProfileBloc = InputAlarmProfileBloc(
      stateMgr!,
      newProfile,
      showCheckboxes,
      selectedProfiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _alarmProfileBloc,
      child: AlarmPageContent(
        alarmProfileBloc: _alarmProfileBloc,
        switchMgr: switchMgr,
      ), // Pass the created _alarmProfileBloc
    );
  }
}

class AlarmPageContent extends StatelessWidget {
  final InputAlarmProfileBloc alarmProfileBloc;
  final SwitchState switchMgr;

  const AlarmPageContent({
    Key? key,
    required this.alarmProfileBloc,
    required this.switchMgr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: alarmProfileBloc,
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            if (state is InputAlarmProfileEditing) {
              alarmProfileBloc.resetEditingState();
              return false;
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                state is InputAlarmProfileEditing
                    ? 'Edit Alarm Profile'
                    : 'Create Alarm Profile',
              ),
            ),
            body: AlarmPageForm(
              alarmProfileBloc: alarmProfileBloc,
              switchMgr: switchMgr,
            ),
          ),
        );
      },
    );
  }
}

class AlarmPageForm extends StatelessWidget {
  final InputAlarmProfileBloc alarmProfileBloc;
  final TextEditingController _dateController = TextEditingController();
  final SwitchState switchMgr;
  AlarmProfile? profileToEdit;
  int maxProfileCount = 10; // Maximum allowed profiles
  int submittedProfileCount = 0; // Counter for submitted profiles
  AlarmPageForm({
    Key? key,
    required this.alarmProfileBloc,
    required this.switchMgr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InputAlarmProfileBloc, InputAlarmProfileState>(
      listener: (context, state) {
        if (state is InputAlarmProfileSuccess) {
          // The profile is saved successfully, capture the saved profile
          final savedProfile = state.savedProfile;
          log('ANNISA112423InputAlarmProfileSuccess: Checking getAlarmProfiles '
              '${StateMgr().callProfiles}');
          // Check if the profile is saved and trigger the notification
          alarmProfileBloc.handleAlarmNotification(savedProfile, context);
          StateMgr().addProfileMe(savedProfile);
          log('ANNISA112423:InputAlarmProfileSuccess come inside ResetAlarmProfileForm');
          alarmProfileBloc.add(ResetAlarmProfileForm());
        } else if (state is InputAlarmProfileFailure) {
          final failureState = state as InputAlarmProfileFailure;
          final errorMessage = failureState.error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is InputAlarmProfileEditing) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Profile Name'),
                      controller: state.profileNameController,
                      onChanged: (value) {
                        alarmProfileBloc.add(InputAlarmProfileName(value));
                        log('ANNISA112423: #1 AlarmPageForm: Profile Name >> ${state.profileName}');
                      },
                    ),
                    // Urgent Low Alarm
                    AlarmMenuTile(
                      title: Text(
                        '${context.l10n.urgent} ${context.l10n.low} ${context.l10n.alert}',
                      ),
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.urgentAlarm,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Urgent Low Alert Soon
                    AlarmMenuTile(
                      title: Text(
                        '${context.l10n.urgent} ${context.l10n.low} ${context.l10n.alert} ${context.l10n.soon}',
                      ),
                      trailing: Switch(
                        value: state.isUrgentSoon,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.urgentSoon,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Low Alert
                    AlarmMenuTile(
                      title: Text('${context.l10n.low} ${context.l10n.alert}'),
                      trailing: Switch(
                        value: state.isLowAlert,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.lowAlert,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // High Alert
                    AlarmMenuTile(
                      title: Text('${context.l10n.high} ${context.l10n.alert}'),
                      trailing: Switch(
                        value: state.isHighAlert,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.highAlert,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Sensor Signal Loss
                    AlarmMenuTile(
                      title: Text(context.l10n.sensorSignalLoss),
                      trailing: Switch(
                        value: state.isSensorSignalLoss,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType:
                                  AlarmProfileType.sensorSignalLoss,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Pump Refill
                    AlarmMenuTile(
                      title: Text(context.l10n.pumpRefill),
                      trailing: Switch(
                        value: state.isPumpRefill,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.pumpRefill,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Dropdown for Sound Selection

                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Alarm Threshold'),
                      onChanged: (value) {
                        log('ANNISA112423: #2 AlarmPageForm: Alarm Threshold ${int.tryParse(value)}');
                        final int? alarmThreshold = int.tryParse(value);
                        alarmProfileBloc.add(
                          InputAlarmProfileThresholdChanged(alarmThreshold!),
                        );
                      },
                      controller: state.thresholdController,
                      // Use the controller here
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 4),

                    DropdownButton<String>(
                      value: state.selectedSound,
                      items: InputAlarmProfileBloc.soundOptions.map((sound) {
                        final displayName =
                            InputAlarmProfileBloc.mapSoundToDisplayName(sound);
                        return DropdownMenuItem<String>(
                          value: sound,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        alarmProfileBloc.add(SoundSelectedEvent(selected!));
                      },
                    ),

                    const SizedBox(height: 4),

                    DropdownButton<String>(
                      value: state.snoozeDuration,
                      // Ensure this matches one of the dropdown items
                      items: InputAlarmProfileBloc.getSnoozeOptions()
                          .map((duration) {
                        final displayName =
                            InputAlarmProfileBloc.mapSnoozeToDisplayName(
                          duration,
                        );
                        return DropdownMenuItem<String>(
                          value: duration,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        if (selected != null) {
                          alarmProfileBloc.add(
                            InputAlarmProfileSnoozeDurationChanged(selected),
                          );
                        }
                      },
                    ),

                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Alarm Duration'),
                      onChanged: (value) {
                        log('ANNISA112423: #2 AlarmPageForm: Alarm Duration ${int.tryParse(value)}');
                        final int? alarmDuration = int.tryParse(value);
                        alarmProfileBloc.add(
                          InputAlarmProfileDurationChanged(alarmDuration!),
                        );
                      },
                      controller: state.durationController,
                      // Use the controller here
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 4),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Set Alarm Time'),
                      subtitle: Text(state.selectedTime.format(context)),
                      onTap: () async {
                        final selectedTime = await showCustomTimePicker(
                          context,
                          state.selectedTime,
                        );
                        if (selectedTime != null) {
                          alarmProfileBloc
                              .add(InputAlarmProfileTimeChanged(selectedTime));
                          log('ANNISA112423: #2 AlarmPageForm: selectedTime $selectedTime');
                        }
                      },
                    ),
                    const SizedBox(height: 4),
// Display the selected date or days
                    AlarmConfigurationInfo(
                      isRepeatEnabled: state.isRepeatEnabled,
                      selectedDate: state.selectedDate,
                      selectedDays: state.selectedDays,
                    ),

                    const SizedBox(height: 4),

                    ListTile(
                      leading: const Icon(Icons.calendar_month_rounded),
                      title: const Text('Set Date Time'),
                      subtitle: Text(
                        state.isRepeatEnabled
                            ? 'No date selected'
                            : state.selectedDate != null
                                ? DateFormat('EEE, MMM d')
                                    .format(state.selectedDate!)
                                : 'No date selected',
                      ),
                      onTap: () async {
                        if (state.isRepeatEnabled) {
                          // If Repeat Alarm switch is turned on, turn it off when selecting a date
                          alarmProfileBloc
                            ..add(
                              InputAlarmProfileRepeatChanged(
                                isRepeatEnabled: false,
                                selectedDays: const [],
                              ),
                            )
                            ..add(
                              InputAlarmProfileDateChanged(DateTime.now()),
                            );
                        }
                        final selectedDate = await showCustomDatePicker(
                          context,
                          state.selectedDate,
                        );
                        if (selectedDate != null) {
                          alarmProfileBloc
                              .add(InputAlarmProfileDateChanged(selectedDate));
                          log('ANNISA111723: #2 AlarmPageForm: selectedDate $selectedDate');
                        }
                      },
                    ),

                    const SizedBox(height: 4),
                    // Repeat Alarm SwitchListTile
                    SwitchListTile(
                      title: const Text('Repeat Alarm'),
                      value: state.isRepeatEnabled,
                      onChanged: (value) {
                        if (value) {
                          log('ANNISA:112423 >> edited state Repeat Alarm Switch value is $value is true? ');
                          // If Repeat Alarm switch is turned on, set selectedDate to null and selectedDays to default
                          alarmProfileBloc
                            ..dispatch(InputAlarmProfileDateChanged(null))
                            ..add(
                              InputAlarmProfileRepeatChanged(
                                isRepeatEnabled: true,
                                selectedDays: const [2, 3, 4, 5, 6, 7, 8],
                              ),
                            );
                        } else {
                          log('ANNISA:112423 >> edited state Repeat Alarm Switch value is $value is false?');
                          // If Repeat Alarm switch is turned off, ensure that selectedDays is empty
                          alarmProfileBloc
                            ..add(
                              InputAlarmProfileRepeatChanged(
                                isRepeatEnabled: false,
                                selectedDays: const [],
                              ),
                            )
                            ..add(
                              InputAlarmProfileDateChanged(DateTime.now()),
                            );
                        }
                      },
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.isRepeatEnabled &&
                                state.selectedDays != null ||
                            state.selectedDays!
                                .isNotEmpty) // Show only if Repeat Alarm switch is on
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // DaysOfWeekSelector
                              if (state.selectedDays != null)
                                DaysOfWeekSelector(
                                  selectedDays: state.selectedDays
                                      ?.map((day) => day == 1)
                                      .toList(),
                                  onDaySelected: (int index) {
                                    final adjustedIndex = index - 2;
                                    log('ANNISA112423: #0 AlarmPageForm: Day $adjustedIndex selected');
                                    final newSelectedDays =
                                        List<int>.from(state.selectedDays!);
                                    newSelectedDays[adjustedIndex] =
                                        (newSelectedDays[adjustedIndex] == 1)
                                            ? 0
                                            : 1;
                                    log('ANNISA124423: #1 AlarmPageForm: Day $adjustedIndex selected');
                                    log('ANNISA124423: #2 AlarmPageForm: newSelectedDays = $newSelectedDays');
                                    alarmProfileBloc.add(
                                      InputAlarmProfileDaysChanged(
                                        newSelectedDays,
                                      ),
                                    );
                                    alarmProfileBloc
                                        .onSelectedDaysChanged(newSelectedDays);
                                  },
                                  // Use the provided dayPadding
                                  dayTextStyle: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Reduce space between form elements
                    Align(
                      alignment: Alignment.topRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (alarmProfileBloc.state
                              is! InputAlarmProfileSubmitting) {
                            final profileNameController =
                                TextEditingController(text: state.profileName);
                            final durationController = TextEditingController(
                              text: state.alarmDuration?.toString(),
                            );
                            final thresholdController = TextEditingController(
                              text: state.alarmThreshold?.toString(),
                            );
                            profileToEdit = state.profileToEdit;
                            log('ANNISA112423: AlarmPageForm edited state >> profileName value is:  ${alarmProfileBloc.state.profileName}');
                            log('ANNISA112423: AlarmPageForm edited state >> selectedTime value is:  ${alarmProfileBloc.state.selectedTime}');
                            log('ANNISA112423: AlarmPageForm edited state >> selectedDays value is:  ${alarmProfileBloc.state.selectedDays}');
                            log('ANNISA112423: AlarmPageForm edited state >> selectedDate value is:  ${alarmProfileBloc.state.selectedDate}');
                            log('ANNISA112423: AlarmPageForm edited state >> alarmDuration value is:  ${alarmProfileBloc.state.alarmDuration}');
                            log('ANNISA112423: AlarmPageForm edited state >> alarmThreshold value is:  ${alarmProfileBloc.state.alarmThreshold}');
                            log('ANNISA112423: AlarmPageForm edited state >> snoozeDuration value is:  ${alarmProfileBloc.state.snoozeDuration}');
                            // Create a new profile based on the edited values
                            if (alarmProfileBloc.state.isSnoozeEnabled) {
                              final shouldProceedWithEdit =
                                  await showSnoozeEditDialog(context);
                              if (shouldProceedWithEdit != null &&
                                  shouldProceedWithEdit) {
                                final editedProfile = AlarmProfile(
                                  profileName:
                                      alarmProfileBloc.state.profileName,
                                  isUrgentAlarm:
                                      alarmProfileBloc.state.isUrgentAlarm,
                                  isUrgentSoon:
                                      alarmProfileBloc.state.isUrgentSoon,
                                  isLowAlert: alarmProfileBloc.state.isLowAlert,
                                  isHighAlert:
                                      alarmProfileBloc.state.isHighAlert,
                                  isSensorSignalLoss:
                                      alarmProfileBloc.state.isSensorSignalLoss,
                                  isPumpRefill:
                                      alarmProfileBloc.state.isPumpRefill,
                                  selectedTime:
                                      alarmProfileBloc.state.selectedTime,
                                  isRepeatEnabled:
                                      alarmProfileBloc.state.isRepeatEnabled,
                                  selectedDays:
                                      alarmProfileBloc.state.selectedDays,
                                  selectedSound:
                                      alarmProfileBloc.state.selectedSound,
                                  isProfileSaved: true,
                                  selectedProfilesForDeletion: alarmProfileBloc
                                      .state.selectedProfilesForDeletion,
                                  selectedDate:
                                      alarmProfileBloc.state.selectedDate,
                                  snoozeDuration:
                                      alarmProfileBloc.state.snoozeDuration,
                                  alarmDuration:
                                      alarmProfileBloc.state.alarmDuration,
                                  alarmThreshold:
                                      alarmProfileBloc.state.alarmThreshold,
                                  isSnoozeEnabled:
                                      alarmProfileBloc.state.isSnoozeEnabled,
                                  profileNameController: profileNameController,
                                  durationController: durationController,
                                  thresholdController: thresholdController,
                                );

                                StateMgr().updateProfile(
                                  state.profileToEdit,
                                  editedProfile,
                                );
                                // Dispatch an action to update the existing profile with the new values
                                alarmProfileBloc
                                    .editedAlarmProfile(editedProfile);
                              } else {
                                // User canceled the edit, do nothing
                              }
                            } else {
                              final editedProfile = AlarmProfile(
                                profileName: alarmProfileBloc.state.profileName,
                                isUrgentAlarm:
                                    alarmProfileBloc.state.isUrgentAlarm,
                                isUrgentSoon:
                                    alarmProfileBloc.state.isUrgentSoon,
                                isLowAlert: alarmProfileBloc.state.isLowAlert,
                                isHighAlert: alarmProfileBloc.state.isHighAlert,
                                isSensorSignalLoss:
                                    alarmProfileBloc.state.isSensorSignalLoss,
                                isPumpRefill:
                                    alarmProfileBloc.state.isPumpRefill,
                                selectedTime:
                                    alarmProfileBloc.state.selectedTime,
                                isRepeatEnabled:
                                    alarmProfileBloc.state.isRepeatEnabled,
                                selectedDays:
                                    alarmProfileBloc.state.selectedDays,
                                selectedSound:
                                    alarmProfileBloc.state.selectedSound,
                                isProfileSaved: true,
                                selectedProfilesForDeletion: alarmProfileBloc
                                    .state.selectedProfilesForDeletion,
                                selectedDate:
                                    alarmProfileBloc.state.selectedDate,
                                snoozeDuration:
                                    alarmProfileBloc.state.snoozeDuration,
                                alarmDuration:
                                    alarmProfileBloc.state.alarmDuration,
                                alarmThreshold:
                                    alarmProfileBloc.state.alarmThreshold,
                                isSnoozeEnabled:
                                    alarmProfileBloc.state.isSnoozeEnabled,
                                profileNameController: profileNameController,
                                durationController: durationController,
                                thresholdController: thresholdController,
                              );

                              StateMgr().updateProfile(
                                state.profileToEdit,
                                editedProfile,
                              );
                              // Dispatch an action to update the existing profile with the new values
                              alarmProfileBloc
                                  .editedAlarmProfile(editedProfile);
                            }
                            // Reset editing state
                            alarmProfileBloc.resetEditingState();
                          }
                        },
                        child: const Text('Update Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (state is InputAlarmProfileSubmitting) {
          return const CircularProgressIndicator(); // Show loading indicator
        } else {
          // Display the form fields
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Profile Name'),
                      controller: state.profileNameController,
                      onChanged: (value) {
                        alarmProfileBloc.dispatch(InputAlarmProfileName(value));
                      },
                    ),

                    // Urgent Low Alarm
                    AlarmMenuTile(
                      title: Text(
                        '${context.l10n.urgent} ${context.l10n.low} ${context.l10n.alert}',
                      ),
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.urgentAlarm,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Urgent Low Alert Soon
                    AlarmMenuTile(
                      title: Text(
                        '${context.l10n.urgent} ${context.l10n.low} ${context.l10n.alert} ${context.l10n.soon}',
                      ),
                      trailing: Switch(
                        value: state.isUrgentSoon,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.urgentSoon,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Low Alert
                    AlarmMenuTile(
                      title: Text('${context.l10n.low} ${context.l10n.alert}'),
                      trailing: Switch(
                        value: state.isLowAlert,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.lowAlert,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // High Alert
                    AlarmMenuTile(
                      title: Text('${context.l10n.high} ${context.l10n.alert}'),
                      trailing: Switch(
                        value: state.isHighAlert,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.highAlert,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Sensor Signal Loss
                    AlarmMenuTile(
                      title: Text(context.l10n.sensorSignalLoss),
                      trailing: Switch(
                        value: state.isSensorSignalLoss,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType:
                                  AlarmProfileType.sensorSignalLoss,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Pump Refill
                    AlarmMenuTile(
                      title: Text(context.l10n.pumpRefill),
                      trailing: Switch(
                        value: state.isPumpRefill,
                        onChanged: (value) {
                          alarmProfileBloc.add(
                            ToggleAlarmProfileSwitch(
                              alarmProfileType: AlarmProfileType.pumpRefill,
                              value: value,
                            ),
                          );
                        },
                      ),
                    ),
                    // Reduce space between form elements

                    const SizedBox(height: 4),
                    // Reduced spacing
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Alarm Threshold'),
                      onChanged: (value) {
                        final int? alarmThreshold = int.tryParse(value);
                        alarmProfileBloc.dispatch(
                          InputAlarmProfileThresholdChanged(alarmThreshold!),
                        );
                      },
                      controller: state.thresholdController,
                      // Use the controller here
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 4),
                    // Dropdown for Sound Selection
                    DropdownButton<String>(
                      value: state.selectedSound,
                      items: InputAlarmProfileBloc.soundOptions.map((sound) {
                        final displayName =
                            InputAlarmProfileBloc.mapSoundToDisplayName(sound);
                        return DropdownMenuItem<String>(
                          value: sound,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        alarmProfileBloc.add(SoundSelectedEvent(selected!));
                      },
                    ),

                    const SizedBox(height: 4),

                    DropdownButton<String>(
                      value: state.snoozeDuration,
                      // Ensure this matches one of the dropdown items
                      items: InputAlarmProfileBloc.getSnoozeOptions()
                          .map((duration) {
                        final displayName =
                            InputAlarmProfileBloc.mapSnoozeToDisplayName(
                          duration,
                        );
                        return DropdownMenuItem<String>(
                          value: duration,
                          child: Text(displayName),
                        );
                      }).toList(),
                      onChanged: (selected) {
                        if (selected != null) {
                          alarmProfileBloc.add(
                            InputAlarmProfileSnoozeDurationChanged(selected),
                          );
                        }
                      },
                    ),

                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Alarm Duration'),
                      onChanged: (value) {
                        log('ANNISA112423: #2 AlarmPageForm: Alarm Duration ${int.tryParse(value)}');
                        final int? alarmDuration = int.tryParse(value);
                        alarmProfileBloc.dispatch(
                          InputAlarmProfileDurationChanged(alarmDuration!),
                        );
                      },
                      controller: state.durationController,
                      // Use the controller here
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 4),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Set Alarm Time'),
                      subtitle: Text(state.selectedTime.format(context)),
                      onTap: () async {
                        final selectedTime = await showCustomTimePicker(
                          context,
                          state.selectedTime,
                        );
                        if (selectedTime != null) {
                          alarmProfileBloc.updateSelectedTime(selectedTime);
                          log('ANNISA112423: #2 AlarmPageForm: selectedTime $selectedTime');
                        }
                      },
                    ),
                    const SizedBox(height: 4),
// Display the selected date or days
                    AlarmConfigurationInfo(
                      isRepeatEnabled: state.isRepeatEnabled,
                      selectedDate: state.selectedDate,
                      selectedDays: state.selectedDays,
                    ),

                    const SizedBox(height: 4),

                    ListTile(
                      leading: const Icon(Icons.calendar_month_rounded),
                      title: const Text('Set Date Time'),
                      subtitle: Text(
                        state.isRepeatEnabled
                            ? 'No date selected'
                            : state.selectedDate != null
                                ? DateFormat('EEE, MMM d')
                                    .format(state.selectedDate!)
                                : 'No date selected',
                      ),
                      onTap: () async {
                        if (state.isRepeatEnabled) {
                          // If Repeat Alarm switch is turned on, turn it off when selecting a date
                          alarmProfileBloc.dispatch(
                            InputAlarmProfileDateChanged(DateTime.now()),
                          );
                          alarmProfileBloc.dispatch(
                            InputAlarmProfileRepeatChanged(
                              isRepeatEnabled: false,
                              selectedDays: const [],
                            ),
                          );
                        }
                        final selectedDate = await showCustomDatePicker(
                          context,
                          state.selectedDate,
                        );
                        if (selectedDate != null) {
                          alarmProfileBloc.updateSelectedDate(selectedDate);
                          log('ANNISA111723: #2 AlarmPageForm: selectedDate $selectedDate');
                        }
                      },
                    ),

                    const SizedBox(height: 4),
                    // Repeat Alarm SwitchListTile
                    SwitchListTile(
                      title: const Text('Repeat Alarm'),
                      value: state.isRepeatEnabled,
                      onChanged: (value) {
                        log('ANNISA:112423 >> Repeat Alarm Switch value is $value');
                        if (value) {
                          // If Repeat Alarm switch is turned on, set selectedDate to null and selectedDays to default
                          alarmProfileBloc.dispatch(
                            InputAlarmProfileDateChanged(DateTime(0)),
                          );
                          log(' If Repeat Alarm switch is turned on, set selectedDate to null and selectedDays to default == ${alarmProfileBloc.state.selectedDate}');
                          alarmProfileBloc.dispatch(
                            InputAlarmProfileRepeatChanged(
                              isRepeatEnabled: true,
                              selectedDays: const [
                                2,
                                3,
                                4,
                                5,
                                6,
                                7,
                                8
                              ], // Default selectedDays when switch is turned on
                            ),
                          );
                        } else {
                          // If Repeat Alarm switch is turned off, ensure that selectedDays is empty
                          alarmProfileBloc.dispatch(
                            InputAlarmProfileRepeatChanged(
                              isRepeatEnabled: false,
                              selectedDays: const [],
                            ),
                          );
                          alarmProfileBloc.dispatch(
                            InputAlarmProfileDateChanged(DateTime.now()),
                          );
                        }
                      },
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.isRepeatEnabled &&
                                state.selectedDays != null ||
                            state.selectedDays!
                                .isNotEmpty) // Show only if Repeat Alarm switch is on
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // DaysOfWeekSelector
                              if (state.selectedDays != null)
                                DaysOfWeekSelector(
                                  selectedDays: state.selectedDays
                                      ?.map((day) => day == 1)
                                      .toList(),
                                  onDaySelected: (int index) {
                                    final adjustedIndex = index - 2;
                                    log('ANNISA112423: #0 AlarmPageForm: Day $adjustedIndex selected');
                                    final newSelectedDays =
                                        List<int>.from(state.selectedDays!);
                                    newSelectedDays[adjustedIndex] =
                                        (newSelectedDays[adjustedIndex] == 1)
                                            ? 0
                                            : 1;
                                    log('ANNISA124423: #1 AlarmPageForm: Day $adjustedIndex selected');
                                    log('ANNISA124423: #2 AlarmPageForm: newSelectedDays = $newSelectedDays');
                                    alarmProfileBloc
                                      ..dispatch(
                                        InputAlarmProfileDaysChanged(
                                          newSelectedDays,
                                        ),
                                      )
                                      ..onSelectedDaysChanged(newSelectedDays);
                                  },
                                  // Use the provided dayPadding
                                  dayTextStyle: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Reduced spacing
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        width: 48, // Adjust the size as needed
                        height: 48, // Adjust the size as needed
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle, // Make it a circular shape
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white, // Set the icon color to white
                          ),
                          onPressed: () async {
                            if (alarmProfileBloc.state
                                is! InputAlarmProfileSubmitting) {
                              log('ANNISA112423:InputAlarmProfileSubmitting: inside AlarmProfileForm');
                              log('ANNISA112423:AlarmProfileForm.alarmProfileBloc.state = ${alarmProfileBloc.state}');
                              int savedProfileCount =
                                  StateMgr().countSavedProfiles();

                              if (savedProfileCount < maxProfileCount) {
                                final profileName =
                                    alarmProfileBloc.state.profileName;
                                final profileNameController =
                                    TextEditingController(
                                  text: state.profileName,
                                );
                                final durationController =
                                    TextEditingController(
                                  text: state.alarmDuration?.toString(),
                                );
                                final thresholdController =
                                    TextEditingController(
                                  text: state.alarmThreshold?.toString(),
                                );
                                if (alarmProfileBloc.state.selectedDays !=
                                        null &&
                                    alarmProfileBloc
                                        .state.selectedDays!.isNotEmpty) {
                                  log('ANNISA12423: AlarmPageForm submit state >> selectedDays not null and not empty ==  ${alarmProfileBloc.state.selectedDays}');
                                } else {
                                  log('ANNISA12423: AlarmPageForm submit state >> selectedDays is empty == ${alarmProfileBloc.state.selectedDays}');
                                }
                                log('ANNISA112423: AlarmPageForm submit state >> profileName value is:  ${alarmProfileBloc.state.profileName}');
                                log('ANNISA112423: AlarmPageForm submit state >> selectedTime value is:  ${alarmProfileBloc.state.selectedTime}');
                                log('ANNISA112423: AlarmPageForm submit state >> selectedDays value is:  ${alarmProfileBloc.state.selectedDays}');
                                log('ANNISA112423: AlarmPageForm submit state >> selectedDate value is:  ${alarmProfileBloc.state.selectedDate}');
                                log('ANNISA112423: AlarmPageForm submit state >> alarmThreshold value is:  ${alarmProfileBloc.state.alarmThreshold}');
                                log('ANNISA112423: AlarmPageForm submit state >> alarmDuration value is:  ${alarmProfileBloc.state.alarmDuration}');
                                final newProfile = AlarmProfile(
                                  profileName: profileName,
                                  isUrgentAlarm:
                                      alarmProfileBloc.state.isUrgentAlarm,
                                  isUrgentSoon:
                                      alarmProfileBloc.state.isUrgentSoon,
                                  isLowAlert: alarmProfileBloc.state.isLowAlert,
                                  isHighAlert:
                                      alarmProfileBloc.state.isHighAlert,
                                  isSensorSignalLoss:
                                      alarmProfileBloc.state.isSensorSignalLoss,
                                  isPumpRefill:
                                      alarmProfileBloc.state.isPumpRefill,
                                  selectedTime:
                                      alarmProfileBloc.state.selectedTime,
                                  isRepeatEnabled:
                                      alarmProfileBloc.state.isRepeatEnabled,
                                  selectedDays:
                                      alarmProfileBloc.state.selectedDays,
                                  selectedSound:
                                      alarmProfileBloc.state.selectedSound,
                                  isProfileSaved:
                                      alarmProfileBloc.state.isProfileSaved,
                                  selectedProfilesForDeletion: alarmProfileBloc
                                      .state.selectedProfilesForDeletion,
                                  selectedDate:
                                      alarmProfileBloc.state.selectedDate,
                                  alarmThreshold:
                                      alarmProfileBloc.state.alarmThreshold,
                                  alarmDuration:
                                      alarmProfileBloc.state.alarmDuration,
                                  profileNameController: profileNameController,
                                  durationController: durationController,
                                  thresholdController: thresholdController,
                                  isSnoozeEnabled:
                                      alarmProfileBloc.state.isSnoozeEnabled,
                                  snoozeDuration:
                                      alarmProfileBloc.state.snoozeDuration,
                                );
                                log('ANNISA111223:AlarmProfileForm >> newProfile.alarmDuration = ${newProfile.alarmDuration}');
                                log('ANNISA112723:AlarmProfileForm >> newProfile.alarmThreshold = ${newProfile.alarmThreshold}');
                                log('ANNISA124223:AlarmProfileForm >> newProfile.selectedDate = ${newProfile.selectedDate}');
                                log('ANNISA124223:AlarmProfileForm >> newProfile.selectedTime = ${newProfile.selectedTime}');
                                log('ANNISA124223:AlarmProfileForm >> newProfile.selectedDays = ${newProfile.selectedDays}');

                                if (StateMgr().callProfiles.isEmpty) {
                                  alarmProfileBloc
                                      .submitAlarmProfile(newProfile);
                                  StateMgr().addProfile(newProfile);
                                  savedProfileCount =
                                      StateMgr().countSavedProfiles();
                                  log('PROFILE COUNTING after = $savedProfileCount');
                                } else {
                                  if (await alarmProfileBloc.checkProfile(
                                    context,
                                    newProfile,
                                  )) {
                                    log('log call profiles! = ${StateMgr().callProfiles}');
                                    await alarmProfileBloc
                                        .submitAlarmProfile(newProfile);
                                    StateMgr().addProfile(newProfile);
                                    savedProfileCount =
                                        StateMgr().countSavedProfiles();
                                    log('PROFILE COUNTING after = $savedProfileCount');
                                  } else {
                                    // Show a message or take other actions based on your requirements
                                    alarmProfileBloc.showMessage(
                                      context,
                                      'Profile cannot be submitted due to conflicting data.',
                                    );
                                  }
                                }
                              } else {
                                // Display a message when the maximum profile count is reached
                                alarmProfileBloc.showMessage(
                                  context,
                                  'Maximum profile count reached. Unable to add more profiles.',
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(
                      thickness: 2,
                      height: 5,
                      color: Colors.grey,
                    ),
                    Consumer<StateMgr>(
                      builder: (context, stateMgr, child) {
                        final savedProfiles = stateMgr.callProfiles;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: savedProfiles.length,
                          itemBuilder: (context, index) {
                            final profile = savedProfiles[index];
                            final selectedDays = profile.selectedDays;
                            final snoozeDuration = profile.snoozeDuration;
                            final selectedDate = profile.selectedDate;
                            if (profile.alarmThreshold == null) {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> alarmThreshold value is null >>  ${profile.alarmThreshold}');
                            } else {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> alarmThreshold value is not null >> ${profile.alarmThreshold}');
                            }
                            if (profile.selectedSound == null) {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> selectedSound value is null >>  ${profile.selectedSound}');
                            } else {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> selectedSound value is not null >> ${profile.selectedSound}');
                            }
                            if (profile.alarmDuration == null) {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> alarmDuration value is null >>  ${profile.alarmDuration}');
                            } else {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> alarmDuration value is not null >> ${profile.alarmDuration}');
                            }
                            if (selectedDate == null) {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> selectedDate value is null >>  ${selectedDate}');
                            } else {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> selectedDate value is not null >> ${selectedDate}');
                            }

                            if (selectedDays == null || selectedDays.isEmpty) {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> selectedDays value is null >>  ${selectedDays}');
                            } else {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> selectedDays value is not null >> ${selectedDays}');
                            }
                            if (snoozeDuration == null) {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> snoozeDuration value is null >>  ${snoozeDuration}');
                            } else {
                              log('ALARM PROFILE CHECKING for profile : ${profile.profileName} >> snoozeDuration value is not null >> ${snoozeDuration}');
                            }
                            return GestureDetector(
                              onTap: () {
                                // Dispatch the editing event
                                final profileToEdit = profile;
                                alarmProfileBloc
                                    .add(EditProfileEvent(profileToEdit));
                              },
                              child: ListTile(
                                title: Text(profile.profileName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AlarmConfigurationInfo(
                                      isRepeatEnabled: profile.isRepeatEnabled,
                                      selectedDate: profile.selectedDate,
                                      selectedDays: profile.selectedDays,
                                    ),
                                    Text(
                                      profile.selectedTime.format(context),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirmed =
                                            await showDeleteConfirmationDialog(
                                          context,
                                        );
                                        if (confirmed == true) {
                                          final profileToDelete = profile;
                                          alarmProfileBloc.add(
                                            DeleteProfileEvent(
                                              profileToDelete,
                                            ),
                                          );
                                          StateMgr().deleteAlarmProfile(
                                            profileToDelete,
                                          );
                                          alarmProfileBloc.dispatch(
                                            UpdateSelectedProfilesForDeletion(
                                              profileToDelete,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

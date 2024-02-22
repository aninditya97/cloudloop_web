import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/domain/entities/enums/alarmprofile_type.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/StateMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/setting_menu_tile.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:cloudloop_mobile/features/home/presentation/blocs/input_alarm_profile/input_alarm_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'alarm_menu_tile.dart';

class AlarmSwitchTile extends StatefulWidget {
  final bool isSnoozeEnabled;
  final ValueChanged<bool> onChanged;

  const AlarmSwitchTile({
    Key? key,
    required this.isSnoozeEnabled,
    required this.onChanged,
  }) : super(key: key);

  @override
  _AlarmSwitchTileState createState() => _AlarmSwitchTileState();
}

class _AlarmSwitchTileState extends State<AlarmSwitchTile> {
  late bool isSnoozeEnabled;

  @override
  void initState() {
    super.initState();
    isSnoozeEnabled = widget.isSnoozeEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        '${isSnoozeEnabled ? context.l10n.on : context.l10n.off}',
      ),
      value: isSnoozeEnabled,
      onChanged: (bool value) {
        widget.onChanged(value);
        setState(() {
          isSnoozeEnabled = value;
        });
      },
    );
  }
}

class AlarmSettingTile extends StatefulWidget {
  final InputAlarmProfileBloc alarmProfileBloc;
  final SwitchState switchMgr;

  const AlarmSettingTile({
    Key? key,
    required this.alarmProfileBloc,
    required this.switchMgr,
  }) : super(key: key);

  @override
  _AlarmSettingTileState createState() => _AlarmSettingTileState();
}

class _AlarmSettingTileState extends State<AlarmSettingTile> {
  late InputAlarmProfileBloc alarmProfileBloc;
  late StateMgr? stateMgr;
  late SwitchState switchMgr;
  List<AlarmProfile> selectedProfiles = [];
  bool showCheckboxes = false;
  AlarmProfile? newProfile;
  int selectedInterval = 5;
  @override
  void initState() {
    super.initState();
    switchMgr = Provider.of<SwitchState>(context, listen: false);
    stateMgr = Provider.of<StateMgr>(context, listen: false);
    alarmProfileBloc = InputAlarmProfileBloc(
      stateMgr!,
      newProfile,
      showCheckboxes,
      selectedProfiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snooze Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AlarmSwitchTile(
              isSnoozeEnabled: switchMgr.isSnoozeEnabled,
              onChanged: (bool value) {
                log('AlarmSwitchTile Switch snooze onChanged: $value');
                alarmProfileBloc.add(ToggleAlarmProfileSwitch(
                  alarmProfileType: AlarmProfileType.isSnoozeEnabled,
                  value: value,
                ));
                log('AlarmSwitchTile: annisa value is $value');
                switchMgr.setSnoozeEnabledValue(value);
              },
            ),
            SizedBox(height: 16),
            // Add a vertical list of selectable intervals
            Text('Snooze Interval (minutes):'),
            Container(
              height: 150,
              child: ListView.builder(
                itemCount: presetSnoozeDurations.length,
                itemBuilder: (context, index) {
                  final snoozeDuration = presetSnoozeDurations[index];
                  return ListTile(
                    leading: IconButton(
                      icon: Icon(Icons.access_alarm), // Replace with your desired icon
                      onPressed: () {
                        // Handle the button press on the left side
                        log('Button pressed for ${snoozeDuration.label}');
                      },
                    ),
                    title: Text(snoozeDuration.label),
                    onTap: () {
                      // Handle the selection of this snooze duration
                      log('Selected snooze duration: ${snoozeDuration.label}');
                    },
                  );
                },
              ),

            ),
          ],
        ),
      ),
    );
  }
}

class SnoozeDuration {
  final String label;
  final Duration duration;

  SnoozeDuration(this.label, this.duration);
}

List<SnoozeDuration> presetSnoozeDurations = [
  SnoozeDuration('5 minutes', Duration(minutes: 5)),
  SnoozeDuration('10 minutes', Duration(minutes: 10)),
  SnoozeDuration('15 minutes', Duration(minutes: 15)),
  // Add more durations as needed
];

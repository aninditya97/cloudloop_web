import 'dart:developer';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/sections/sections.dart';
import 'package:cloudloop_mobile/features/auth/domain/entities/enums/alarmprofile_type.dart';
import 'package:cloudloop_mobile/features/home/presentation/blocs/input_alarm_profile/input_alarm_bloc.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/StateMgr.dart';
import 'package:cloudloop_mobile/core/data/models/alarm_profile.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AlarmSnoozePage extends StatefulWidget {
  final InputAlarmProfileBloc alarmProfileBloc;
  final bool isSnoozeEnabled;

  const AlarmSnoozePage({
    Key? key,
    required this.alarmProfileBloc,
    required this.isSnoozeEnabled,
  }) : super(key: key);

  @override
  _AlarmSnoozePageState createState() => _AlarmSnoozePageState();
}

class _AlarmSnoozePageState extends State<AlarmSnoozePage> {
  late bool isSnoozeEnabled;
  late InputAlarmProfileBloc _alarmProfileBloc;
  StateMgr? stateMgr;
  late SwitchState switchMgr;
  List<AlarmProfile> selectedProfiles = [];
  bool showCheckboxes = false;
  AlarmProfile? newProfile;

  @override
  void initState() {
    super.initState();
    stateMgr = Provider.of<StateMgr>(context, listen: false);
    switchMgr = Provider.of<SwitchState>(context, listen: false);
    if (switchMgr == null) {
      log('ANNISA112423:_AlarmSnoozePageState_switchMgr is null!!');
      switchMgr = Provider.of<SwitchState>(context, listen: false);
      log('ANNISA12823:_AlarmSnoozePageState_switchMgr Provider.of<SwitchState>(context, listen: false)');
    } else {
      log('ANNISA12823:_AlarmSnoozePageState_switchMgr not null');
    }
    log('ANNISA12823:_AlarmSnoozePageState_switchMgr.isSnoozeEnabled = ${switchMgr.isSnoozeEnabled}');
    isSnoozeEnabled = widget.isSnoozeEnabled;
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
      child: AlarmSnoozeContent(
        alarmProfileBloc: _alarmProfileBloc,
        switchMgr: switchMgr,
        isSnoozeEnabled: isSnoozeEnabled,
      ),
    );
  }
}

class AlarmSnoozeContent extends StatelessWidget {
  final InputAlarmProfileBloc alarmProfileBloc;
  final SwitchState switchMgr;
  final bool isSnoozeEnabled;

  const AlarmSnoozeContent({
    Key? key,
    required this.alarmProfileBloc,
    required this.switchMgr,
    required this.isSnoozeEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: alarmProfileBloc,
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            if (state is SnoozeState) {
              alarmProfileBloc.resetEditingState();
              return false;
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Snooze'),
            ),
            body: AlarmSnoozeForm(
              alarmProfileBloc: alarmProfileBloc,
              switchMgr: switchMgr,
              isSnoozeEnabled: isSnoozeEnabled,
            ),
          ),
        );
      },
    );
  }
}

class AlarmSnoozeForm extends StatelessWidget {
  final InputAlarmProfileBloc alarmProfileBloc;
  final SwitchState switchMgr;
  final bool isSnoozeEnabled;

  AlarmSnoozeForm({
    Key? key,
    required this.alarmProfileBloc,
    required this.switchMgr,
    required this.isSnoozeEnabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InputAlarmProfileBloc, InputAlarmProfileState>(
      builder: (context, state) {
        log('AlarmSnoozeForm BlocBuilder: Rebuilding with state: $state');
        if (state is InputAlarmProfileSubmitting) {
          return CircularProgressIndicator();
        } else {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text('Snooze'),
                      trailing: Switch(
                        value: switchMgr.isSnoozeEnabled,
                        onChanged: (value) {
                          log('AlarmSnoozeComponent Switch snooze onChanged: $value');
                          alarmProfileBloc.add(ToggleAlarmProfileSwitch(
                            alarmProfileType: AlarmProfileType.isSnoozeEnabled,
                            value: value,
                          ));
                          log('AlarmSnoozeComponent():annisa value is ${value}');
                          switchMgr.setSnoozeEnabledValue(value);
                        },
                      ),
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

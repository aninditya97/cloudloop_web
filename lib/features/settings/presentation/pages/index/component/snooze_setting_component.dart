import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SnoozeSettingComponent extends StatefulWidget {
  const SnoozeSettingComponent({Key? key}) : super(key: key);

  @override
  State<SnoozeSettingComponent> createState() => _SnoozeSettingComponentState();
}

class _SnoozeSettingComponentState extends State<SnoozeSettingComponent> {
  List<String> snoozeTime = [
    //kai_20231023  SRS Reqs
    /*
    '1 Minutes',
    '2 Minutes',
    '5 Minutes',
   */
    '10 Minutes',
    '15 Minutes',
    '20 Minutes',
    '30 Minutes',
    '60 Minutes',
    '90 Minutes',
    '120 Minutes',
  ];
  var _switchValue = false;
  String _snoozeTime = '10 Minutes';

  @override
  void initState() {
    super.initState();

    _switchValue =
        CspPreference.getBool('snoozeSwitch' /*CspPreference.snoozeSwitchKey*/);
    _snoozeTime = CspPreference.getString(
      'snoozeTimeValue', /*CspPreference.snoozeTimeValueKey*/
    );
    debugPrint(
      'kai:_SnoozeSettingComponentState.initState() is called::_switchValue(${_switchValue},_snoozeTime(${_snoozeTime})',
    );
  }

  @override
  void dispose() {
    debugPrint(
      'kai:_SnoozeSettingComponentState.dispose() is called::_switchValue(${_switchValue},_snoozeTime(${_snoozeTime})',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingMenuTile(
      title: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: _showSnoozeOptionsSheet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.snooze),
            Text(
              _snoozeTime,
              style: TextStyle(
                color: context.theme.primaryColor,
                fontSize: Dimens.dp12,
              ),
            ),
          ],
        ),
      ),
      trailing: SizedBox(
        height: Dimens.dp24,
        child: Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            activeColor: CupertinoColors.activeBlue,
            value: _switchValue,
            onChanged: (value) {
              debugPrint(
                'kai:_SnoozeSettingComponentState.CupertinoSwitch.onChanged() is called::mounted(${mounted},_switchValue(${_switchValue},_snoozeTime(${_snoozeTime})',
              );
              if (mounted) {
                setState(() {
                  _switchValue = value;
                });
              } else {
                _switchValue = value;
              }
              //kai_20231022  added
              CspPreference.setBool(
                'snoozeSwitch' /*CspPreference.snoozeSwitchKey*/,
                value,
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSnoozeOptionsSheet() {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return ActionableContentSheet(
          header: HeadingText2(text: context.l10n.snoozeTime),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: snoozeTime
                .map(
                  (e) => ListTile(
                    minLeadingWidth: 0,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      debugPrint(
                        'kai:_SnoozeSettingComponentState._showSnoozeOptionsSheet.onTap() is called::mounted(${mounted},_switchValue(${_switchValue},_snoozeTime(${_snoozeTime})',
                      );
                      if (mounted) {
                        setState(() {
                          _snoozeTime = e;
                          //kai_20231022  added
                          CspPreference.setString(
                            'snoozeTimeValue' /*CspPreference.snoozeTimeValueKey*/,
                            e,
                          );
                          Navigator.pop(context);
                        });
                      } else {
                        _snoozeTime = e;
                        //kai_20231022  added
                        CspPreference.setString(
                          'snoozeTimeValue' /*CspPreference.snoozeTimeValueKey*/,
                          e,
                        );
                        Navigator.pop(context);
                      }
                    },
                    title: HeadingText4(
                      text: e,
                      textColor: const Color(0xff333333),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

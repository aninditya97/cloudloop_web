import 'dart:async';
import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/helpers/date_time_helper.dart';
import 'package:cloudloop_mobile/features/auth/domain/entities/enums/alarmprofile_type.dart';

import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/blocs/input_alarm_profile/input_alarm_bloc.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/audioplay/csaudioplayer.dart';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/StateMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// sound
const bool _USE_TTS_PLAYBACK = false;
const bool _USE_AUDIO_PLAYBACK = true;
const bool _USE_AUDIOCACHE = true;
const bool _USE_GLOBAL_KEY = true;

class AlertPage extends StatefulWidget {
  const AlertPage({Key? key}) : super(key: key);

  @override
  State<AlertPage> createState() => _AlertPageState();

  void checkAlertNotificationCondition(BuildContext context) {
    _AlertPageState state = _AlertPageState();
    state.checkHandleNotificationCondition(context);
  }

  void updateLight(bool value) async {
    _AlertPageState state = _AlertPageState();
    state._updateLight(value);
  }

  void updateLight2(bool value) async {
    _AlertPageState state = _AlertPageState();
    state._updateLight2(value);
  }

  void updateLight3(bool value) async {
    _AlertPageState state = _AlertPageState();
    state._updateLight3(value);
  }

  void updateLight4(bool value) async {
    _AlertPageState state = _AlertPageState();
    state._updateLight4(value);
  }

  void updateLight5(bool value) async {
    _AlertPageState state = _AlertPageState();
    state._updateLight5(value);
  }

  void updateLight6(bool value) async {
    _AlertPageState state = _AlertPageState();
    state._updateLight6(value);
  }

  void updateLight7(bool value) async {
    _AlertPageState state = _AlertPageState();
    state._updateLight7(value);
  }

  void updateOnOff(String value) {
    _AlertPageState state = _AlertPageState();
    state._updateOnOff(value);
  }

  void updateswitchValue(bool value) {
    _AlertPageState state = _AlertPageState();
    state._updateswitchValue(value);
  }

  void updatesnoozeEnabledValue(bool value) {
    _AlertPageState state = _AlertPageState();
    state._updatesnoozeEnabledValue(value);
  }

  void checkNewBGIncomingTimer(BuildContext context) {
    _AlertPageState state = _AlertPageState();
    state.startSignalLossMonitoring(context);
  }

  void showAlertDialog(
      BuildContext context, String message, AlarmProfile savedProfile) {
    _AlertPageState state = _AlertPageState();
    state.showAlertDialogOnEvent(context, message, savedProfile);
  }

  static void handleNotificationState(String preferenceKey,
      BuildContext context, AlarmProfile savedProfile, StateMgr stateMgr) {
    log('ANNISA12423:_AlertPageState.handleNotificationState >> $preferenceKey');
    _AlertPageState state = _AlertPageState();
    state.handleNotification(preferenceKey, context, savedProfile, stateMgr);
  }
}

class SwitchState extends ChangeNotifier {
  static bool showConfirmationDialog = false;
  static bool _switchValue = false;

  ///< alerts switch on/off status top section
  static bool _light = false;

  ///< urgent low alarm
  static bool _light2 = false;

  ///< urgent low soon
  static bool _light3 = false;

  ///< low
  static bool _light4 = false;

  ///< high
  static bool _light5 = false;

  ///< sensor signal loss
  static bool _light6 = false;

  ///< Pump refill
  static bool _light7 = false;

  static bool _isSnoozeEnabled = false;

  ///< not used at this time
  static int _selectedInterval = 10;
  static bool _isConditionMet = false; // Flag to track if condition is met
  static bool _hasConfirmedAction = false;

  int get selectedInterval => _selectedInterval;

  bool get light => _light;

  bool get switchValue => _switchValue;

  bool get light2 => _light2;

  bool get light3 => _light3;

  bool get light4 => _light4;

  bool get light5 => _light5;

  bool get light6 => _light6;

  bool get light7 => _light7;

  bool get isSnoozeEnabled => _isSnoozeEnabled;

  bool get hasConfirmedAction => _hasConfirmedAction;

  bool get isConditionMet => _isConditionMet;
  static Timer? _signalLossTimer;

  Timer? get signalLossTimer => _signalLossTimer;

  set signalLossTimer(Timer? value) {
    _signalLossTimer = value;
  }

  static Timer? _NewBGIncomingTimer;

  Timer? get NewBGIncomingTimer => _NewBGIncomingTimer;

  set NewBGIncomingTimer(Timer? value) {
    _NewBGIncomingTimer = value;
  }

  Timer? _AutoModeStatusTimer;

  Timer? get AutoModeStatusTimer => _AutoModeStatusTimer;

  set AutoModeStatusTimer(Timer? value) {
    _AutoModeStatusTimer = value;
  }

  String _popupMessage = '';

  String get popupMessage => _popupMessage;

  static BuildContext? _appContext;

  static void setAppContext(BuildContext context) {
    _appContext = context;
  }

  BuildContext? get appContext => _appContext;

  static AlertPage? _mAlertPage = null;

  AlertPage? get mAlertPage => _mAlertPage;

  static void setmAlertPage(AlertPage page) {
    _mAlertPage = page;
  }

  void setPopupMessage(String message) {
    _popupMessage = message;
    notifyListeners();
  }

  void resetSwitches() {
    _switchValue = false;
    _light = false;
    _light2 = false;
    _light3 = false;
    _light4 = false;
    _light5 = false;
    _light6 = false;
    _light7 = false;
    _isSnoozeEnabled = false;

    if (_mAlertPage != null) {
      _mAlertPage!.updateLight(_light);

      ///< urgent low
      _mAlertPage!.updateLight2(_light2);

      ///< urgent low soon
      _mAlertPage!.updateLight3(_light3);

      ///< low alert
      _mAlertPage!.updateLight4(_light4);

      ///< high
      _mAlertPage!.updateLight5(_light5);

      ///< sensor signal loss
      _mAlertPage!.updateLight6(_light6);

      ///< pump refill
      _mAlertPage!.updateLight7(_light7);

      ///<
      _mAlertPage!.updateswitchValue(_switchValue);

      _mAlertPage!.updatesnoozeEnabledValue(_isSnoozeEnabled);

      ///< Main alerts switch
    } else {
      debugPrint('resetSwitches():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }

  void setSelectedInterval(int value) {
    log('Selected interval: $value');
    _selectedInterval = value;
    notifyListeners();
  }

  void setHasConfirmedAction(bool value) {
    _hasConfirmedAction = value;
    notifyListeners();
  }

  /*
  *@brief alert switch
  */
  void setSwitchValue(bool value) {
    _switchValue = value;
    if (_mAlertPage != null) {
      _mAlertPage!.updateswitchValue(value);
    } else {
      debugPrint('setSwitchValue():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }

  void setSnoozeEnabledValue(bool value) {
    _isSnoozeEnabled = value;
    log('isSnoozeEnabled():annisa value is ${_isSnoozeEnabled}');
    if (_mAlertPage != null) {
      _mAlertPage!.updatesnoozeEnabledValue(value);
    } else {
      debugPrint('isSnoozeEnabled():annisa :_mAlertPage is null!!');
    }
    notifyListeners();
  }

/*
*@brief urgent low
 */
  void setLightValue(bool value) {
    _light = value;

    if (_mAlertPage != null) {
      _mAlertPage!.updateLight(value);
    } else {
      debugPrint('setLightValue():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }

  /*
  *@brief urgent low soon
  */
  void setLight2Value(bool value) {
    _light2 = value;

    if (_mAlertPage != null) {
      _mAlertPage!.updateLight2(value);
    } else {
      debugPrint('setLight2Value():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }

  /*
  *@brief Low alert
  */
  void setLight3Value(bool value) {
    _light3 = value;

    if (_mAlertPage != null) {
      _mAlertPage!.updateLight3(value);
    } else {
      debugPrint('setLight3Value():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }

  /*
  *@brief High alert
  */
  void setLight4Value(bool value) {
    _light4 = value;

    if (_mAlertPage != null) {
      _mAlertPage!.updateLight4(value);
    } else {
      debugPrint('setLight4Value():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }

  /*
  *@brief sensor signal loss
  */
  void setLight5Value(bool value) {
    _light5 = value;

    if (_mAlertPage != null) {
      _mAlertPage!.updateLight5(value);
    } else {
      debugPrint('setLight5Value():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }

  /*
  *@brief Pump refill
  */
  void setLight6Value(bool value) {
    _light6 = value;

    if (_mAlertPage != null) {
      _mAlertPage!.updateLight6(value);
    } else {
      debugPrint('setLight6Value():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }

  /*
  *@brief Pump refill
  */
  void setLight7Value(bool value) {
    _light7 = value;
    if (_mAlertPage != null) {
      _mAlertPage!.updateLight7(value);
    } else {
      debugPrint('setLight6Value():kai :_mAlertPage is null!!');
    }
    notifyListeners();
  }
}

final Map<AlarmProfileType, SwitchState> alertTypeStateMap = {
  AlarmProfileType.urgentAlarm: SwitchState(),
  AlarmProfileType.urgentSoon: SwitchState(),
  AlarmProfileType.lowAlert: SwitchState(),
  AlarmProfileType.highAlert: SwitchState(),
  AlarmProfileType.sensorSignalLoss: SwitchState(),
  AlarmProfileType.pumpRefill: SwitchState(),
  AlarmProfileType.isSnoozeEnabled: SwitchState(),
};

class _AlertPageState extends State<AlertPage> {
  SwitchState switchState = SwitchState();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static SharedPreferences? _preferences;

  InputAlarmProfileBloc? mInputAlarmProfileBloc;
  late ConnectivityMgr? mCMgr = null;
  late BuildContext mContext;
  CsaudioPlayer? mAudioPlayer;
  StateMgr? mStateMgr;
  static bool _switchValue = false;
  static String _onOff = 'Off';
  static bool _light = false;
  static bool _light2 = false;
  static bool _light3 = false;
  static bool _light4 = false;
  static bool _light5 = false;
  static bool _light6 = false;
  static bool _light7 = false;
  static bool _isSnoozeEnabled = false;

  static bool _setDose = false;
  static int _selectedInterval = 10;

  static double defaultGlucoseValue = 90;

  final GlobalKey<State> _key = GlobalKey();
  CgmInfoData? _cgmInfoData;

  static String tag = '_CgmPageState:';
  String _alertmessage = '';

  static double _lastBloodGlucoseValue = 0.0;
  static double rateOfChange = 0.0;

  Future<int> _getStoredInterval() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selectedInterval') ?? 10; // Default to 10 if not found
  }

  Future<void> _saveSelectedInterval(int interval) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedInterval', interval);
  }

  Future<bool> getLowSwitchEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('lowSwitchEnabled') ??
        true; // Default to true if not set
  }

  Future<bool> getAlertsScheduleSwitchValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('alertsScheduleSwitchValue') ??
        false; // Default to false if not set
  }

  Future<bool?> showAlertDialogAlarm(
      BuildContext context, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User chose not to proceed
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User chose to proceed
              },
              child: Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConfirmationDialog(String message, bool value) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.confirmation}'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                // User confirmed to turn off all alerts
                Navigator.of(context).pop(true);
              },
              child: Text('${context.l10n.turnOffAllAlerts}'),
            ),
            TextButton(
              onPressed: () {
                // User chose to turn off manually
                bool allowManualTurnOn = _lastBloodGlucoseValue == null ||
                    _lastBloodGlucoseValue >= defaultGlucoseValue * 0.07;
                Navigator.of(context).pop(allowManualTurnOn);
              },
              child: Text('${context.l10n.turnOffManually}'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null) {
        if (confirmed) {
          // User confirmed to turn off all alerts
          if (mounted) {
            setState(() {
              _switchValue =
                  false; // Assuming the action is to turn off the Main Alert

              // Turn off all other switches
              switchState.setLightValue(false);
              switchState.setLight2Value(false);
              switchState.setLight3Value(false);
              switchState.setLight4Value(false);
              switchState.setLight5Value(false);
              switchState.setLight6Value(false);
              switchState.setLight7Value(false);
            });
          } else {
            _switchValue =
                false; // Assuming the action is to turn off the Main Alert

            // Turn off all other switches
            switchState.setLightValue(false);
            switchState.setLight2Value(false);
            switchState.setLight3Value(false);
            switchState.setLight4Value(false);
            switchState.setLight5Value(false);
            switchState.setLight6Value(false);
            switchState.setLight7Value(false);
          }

          // Check if Urgent Low Alert Switch can be turned off manually
          if (_lastBloodGlucoseValue == null ||
              _lastBloodGlucoseValue >= defaultGlucoseValue * 0.07) {
            if (mounted) {
              setState(() {
                switchState
                    .setLightValue(false); // Turn off Urgent Low Alert Switch
              });
            } else {
              switchState
                  .setLightValue(false); // Turn off Urgent Low Alert Switch
            }
          }

          // Check if High Alert Switch can be turned off manually
          if (_lastBloodGlucoseValue == null ||
              _lastBloodGlucoseValue <= defaultGlucoseValue) {
            if (mounted) {
              setState(() {
                switchState.setLight2Value(false); // Turn off High Alert Switch
              });
            } else {
              switchState.setLight2Value(false); // Turn off High Alert Switch
            }
          }
        } else {
          // Allow manual turn-on for Urgent Low Alert Switch and High Alert Switch
          // and set their respective switch state
          if (mounted) {
            setState(() {
              if (value) {
                switchState.setLightValue(true); // Urgent Low Alert Switch
                switchState.setLight2Value(true); // High Alert Switch
              }
            });
          } else {
            if (value) {
              switchState.setLightValue(true); // Urgent Low Alert Switch
              switchState.setLight2Value(true); // High Alert Switch
            }
          }
        }
      }
    });
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            'cloudloop_mobile'); // Replace with your app's icon name

    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // Handle the received local notification here
  }

  @override
  void initState() {
    _fetchAllData();
    super.initState();
    // Initialize your switch values to false (Off) here
    _switchValue = false;
    _light = false;
    _light2 = false;
    _light3 = false;
    _light4 = false;
    _light5 = false;
    _light6 = false;
    _light7 = false;
    _isSnoozeEnabled = false;
    _initPreferences();
    _initNotifications();

// Add this code to your main Dart file or wherever you initialize your notifications.
    flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('app_icon'),
      ),
    );

    _getStoredInterval().then((value) {
      if (mounted) {
        setState(() {
          _selectedInterval = value;
        });
      } else {
        _selectedInterval = value;
      }
    });
    log('>> initState checking value for _USE_AUDIO_PLAYBACK : ${_USE_AUDIO_PLAYBACK}!');
    if (_USE_AUDIO_PLAYBACK == true) {
      log('>> initState checking value for _USE_AUDIOCACHE : ${_USE_AUDIOCACHE}!');
      if (_USE_AUDIOCACHE == true) {
        //maudioCacheplayer = AudioCache();

        mAudioPlayer = CsaudioPlayer();
        log('>> initState checking value for mAudioPlayer  if _USE_AUDIOCACHE true : ${mAudioPlayer}!');
      } else {
        // maudioPlayer = AudioPlayer();
        mAudioPlayer = CsaudioPlayer();
        log('>> initState checking value for mAudioPlayer() if _USE_AUDIOCACHE not true : ${mAudioPlayer}!');
      }
    }
    if (mInputAlarmProfileBloc == null) {
      mInputAlarmProfileBloc =
          Provider.of<InputAlarmProfileBloc>(context, listen: false);
    } else {
      debugPrint(
          'ANNISA112423:AlertPage.initState: mInputAlarmProfileBloc is ready now');
    }

    if (mStateMgr == null) {
      mStateMgr = Provider.of<StateMgr>(context, listen: false);
    } else {
      debugPrint('ANNISA112423:AlertPage.initState: mStateMgr is ready now');
    }

    if (mCMgr == null) {
      mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
    } else {
      debugPrint('kai:AlertPage.initState: mCMgr is ready now');
    }
  }

  @override
  void dispose() {
    // blocked due to below error
    // Error stopping scan: Looking up a deactivated widget's ancestor is unsafe.
    // I/flutter (12065): At this point the state of the widget's element tree is no longer stable.
    // I/flutter (12065): To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.
    // _stopScan();

    debugPrint('kai:AlertPage.dispose() is called');
    if (_USE_AUDIO_PLAYBACK) {
      // maudioPlayer.dispose();
      if (mAudioPlayer != null) {
        mAudioPlayer!.release();
        mAudioPlayer = null;
      }
    }

    super.dispose();
  }

  Future<void> initializeNotifications() async {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _initPreferences() async {
    debugPrint('kai:_initPreferences() is called!!');
    _preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _switchValue = _preferences?.getBool('switchValue') ?? false;
        _onOff = _preferences?.getString('onOff') ?? 'Off';
        _light = _preferences?.getBool('light') ?? false;
        _light2 = _preferences?.getBool('light2') ?? false;
        _light3 = _preferences?.getBool('light3') ?? false;
        _light4 = _preferences?.getBool('light4') ?? false;
        _light5 = _preferences?.getBool('light5') ?? false;
        _light6 = _preferences?.getBool('light6') ?? false;
        _light7 = _preferences?.getBool('light7') ?? false;
        _isSnoozeEnabled = _preferences?.getBool('isSnoozeEnabled') ?? false;
      });
    } else {
      _switchValue = _preferences?.getBool('switchValue') ?? false;
      _onOff = _preferences?.getString('onOff') ?? 'Off';
      _light = _preferences?.getBool('light') ?? false;
      _light2 = _preferences?.getBool('light2') ?? false;
      _light3 = _preferences?.getBool('light3') ?? false;
      _light4 = _preferences?.getBool('light4') ?? false;
      _light5 = _preferences?.getBool('light5') ?? false;
      _light6 = _preferences?.getBool('light6') ?? false;
      _light7 = _preferences?.getBool('light7') ?? false;
      _isSnoozeEnabled = _preferences?.getBool('isSnoozeEnabled') ?? false;
    }

    //kai_20231022
    if (switchState == null) {
      switchState = SwitchState();
    }

    if (switchState != null) {
      switchState.setLightValue(_light);
      switchState.setLight2Value(_light2);
      switchState.setLight3Value(_light3);
      switchState.setLight4Value(_light4);
      switchState.setLight5Value(_light5);
      switchState.setLight6Value(_light6);
      switchState.setLight7Value(_light7);
      switchState.setSwitchValue(_switchValue);
      switchState.setSnoozeEnabledValue(_isSnoozeEnabled);
    }
  }

  Future<void> _updatesnoozeEnabledValue(bool value) async {
    if (mounted) {
      setState(() {
        _isSnoozeEnabled = value;
      });
    } else {
      _isSnoozeEnabled = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('isSnoozeEnabled', value);
    } else {
      debugPrint(
          'ANNISA:_isSnoozeEnabled:mounted(${mounted}):_preferences is null!!');
    }
  }

  Future<void> _updateswitchValue(bool value) async {
    if (mounted) {
      setState(() {
        _switchValue = value;
      });
    } else {
      _switchValue = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('switchValue', value);
    } else {
      debugPrint(
          'kai:_updateswitchValue:mounted(${mounted}):_preferences is null!!');
    }
  }

  Future<void> _updateOnOff(String value) async {
    if (mounted) {
      setState(() {
        _onOff = value;
      });
    } else {
      _onOff = value;
    }

    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setString('onOff', value);
    }
  }

  Future<void> _updateLight(bool value) async {
    if (mounted) {
      setState(() {
        _light = value;
      });
    } else {
      _light = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('light', value);
    } else {
      debugPrint('kai:_updateLight:mounted(${mounted}):_preferences is null!!');
    }
  }

  Future<void> _updateLight2(bool value) async {
    if (mounted) {
      setState(() {
        _light2 = value;
      });
    } else {
      _light2 = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('light2', value);
    } else {
      debugPrint(
          'kai:_updateLight2:mounted(${mounted}):_preferences is null!!');
    }
  }

  Future<void> _updateLight3(bool value) async {
    if (mounted) {
      setState(() {
        _light3 = value;
      });
    } else {
      _light3 = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('light3', value);
    } else {
      debugPrint(
          'kai:_updateLight3:mounted(${mounted}):_preferences is null!!');
    }
  }

  Future<void> _updateLight4(bool value) async {
    if (mounted) {
      setState(() {
        _light4 = value;
      });
    } else {
      _light4 = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('light4', value);
    } else {
      debugPrint(
          'kai:_updateLight4:mounted(${mounted}):_preferences is null!!');
    }
  }

  Future<void> _updateLight5(bool value) async {
    if (mounted) {
      setState(() {
        _light5 = value;
      });
    } else {
      _light5 = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('light5', value);
    } else {
      debugPrint(
          'kai:_updateLight5:mounted(${mounted}):_preferences is null!!');
    }
  }

  Future<void> _updateLight6(bool value) async {
    if (mounted) {
      setState(() {
        _light6 = value;
      });
    } else {
      _light6 = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('light6', value);
    } else {
      debugPrint(
          'kai:_updateLight6:mounted(${mounted}):_preferences is null!!');
    }
  }

  Future<void> _updateLight7(bool value) async {
    if (mounted) {
      setState(() {
        _light7 = value;
      });
    } else {
      _light7 = value;
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }

    if (_preferences != null) {
      await _preferences?.setBool('light7', value);
    } else {
      debugPrint(
          'kai:_updateLight7:mounted(${mounted}):_preferences is null!!');
    }
  }

  final _date = (TEST_FEATCH_DATA_TWO_DAYS == true)
      ? DateTimeRange(
          start: DateTimeHelper.minifyFormatDate(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
          end: DateTimeHelper.minifyFormatDate(DateTime.now()),
        )
      : DateTimeRange(
          start: DateTimeHelper.minifyFormatDate(DateTime.now()),
          end: DateTimeHelper.minifyFormatDate(DateTime.now()),
        );

  Future<void> _fetchAllData() async {
    await _fetchBloodGlucose();
  }

  Future<void> _fetchBloodGlucose() async {
    context.read<GlucoseReportBloc>().add(
          GlucoseReportFetched(
            startDate: _date.start,
            endDate: _date.end,
            filter: false,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        foregroundColor: AppColors.primarySolidColor,
        centerTitle: true,
        title: HeadingText2(
          text: '${context.l10n.alerts}',
          textColor: Colors.black,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(Dimens.appPadding),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HeadingText4(
                          text: '${context.l10n.alerts}',
                          textColor: AppColors.blueGray[600],
                        ),
                        Switch(
                          value: SwitchState._switchValue,
                          onChanged: (bool value) {
                            if (value) {
                              _showSwitchDialog(
                                  '${context.l10n.allAlertOn}', value);
                              switchState.setSwitchValue(value);
                            } else {
                              _showSwitchDialog(
                                  '${context.l10n.allAlertOff}', value);
                              switchState.setSwitchValue(value);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimens.dp8),
                  ],
                ),
              ),
              const LargeDivider(),
              Padding(
                  padding: const EdgeInsets.all(Dimens.appPadding),
                  child: Row()),
              SettingMenuTile(
                title: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //kai_20231024  Text('${context.l10n.urgent} ${context.l10n.low} ${context.l10n.alert}'),
                      Text(
                          '${context.l10n.urgent} ${context.l10n.low} ${context.l10n.alarm}'),
                      Text(
                        '${SwitchState._light ? context.l10n.on : context.l10n.off}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Switch(
                  value: SwitchState._light,
                  onChanged: (bool value) {
                    if (value) {
                      _showMyDialog('${context.l10n.urgentLowOn}', value);
                      switchState.setLightValue(value);
                    } else {
                      _showMyDialog('${context.l10n.urgentLowOff}', value);
                      switchState.setLightValue(value);
                    }
                  },
                ),
              ),
              SettingMenuTile(
                title: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${context.l10n.urgent} ${context.l10n.low} ${context.l10n.soon}'),
                      Text(
                        '${SwitchState._light2 ? context.l10n.on : context.l10n.off}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Switch(
                  value: SwitchState._light2,
                  onChanged: (bool value) {
                    if (value) {
                      _showMyDialog2('${context.l10n.urgentLowSoonOn}', value);
                      switchState.setLight2Value(value);
                    } else {
                      _showMyDialog2('${context.l10n.urgentLowSoonOff}', value);
                      switchState.setLight2Value(value);
                    }
                  },
                ),
              ),
              SettingMenuTile(
                title: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //kai_20231024 Text(' ${context.l10n.low} ${context.l10n.alert}'),
                      Text(' ${context.l10n.low}'),
                      Text(
                        '${SwitchState._light3 ? context.l10n.on : context.l10n.off}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Switch(
                  value: SwitchState._light3,
                  onChanged: (bool value) {
                    if (value) {
                      _showMyDialog3('${context.l10n.lowAlertOn}', value);
                      switchState.setLight3Value(value);
                    } else {
                      _showMyDialog3('${context.l10n.lowAlertOff}', value);
                      switchState.setLight3Value(value);
                    }
                  },
                ),
              ),
              SettingMenuTile(
                title: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${context.l10n.high}'),
                      Text(
                        '${SwitchState._light4 ? context.l10n.on : context.l10n.off}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Switch(
                  value: SwitchState._light4,
                  onChanged: (bool value) {
                    if (value) {
                      _showMyDialog4('${context.l10n.highAlertOn}', value);
                      switchState.setLight4Value(value);
                    } else {
                      _showMyDialog4('${context.l10n.highAlertOff}', value);
                      switchState.setLight4Value(value);
                    }

                    /* // Handle switch change for High Alert
                    _handleHighAlert(value); */
                  },
                ),
              ),
              SettingMenuTile(
                title: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${context.l10n.sensorSignalLoss}'),
                      Text(
                        '${SwitchState._light5 ? context.l10n.on : context.l10n.off}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Switch(
                  value: SwitchState._light5,
                  onChanged: (bool value) {
                    if (value) {
                      _showMyDialog5(
                          '${context.l10n.sensorSignalLossOn}', value);
                      switchState.setLight5Value(value);
                    } else {
                      _showMyDialog5(
                          '${context.l10n.sensorSignalLossOff}', value);
                      switchState.setLight5Value(value);
                    }
                  },
                ),
              ),
              SettingMenuTile(
                title: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${context.l10n.pumpRefill}'),
                      Text(
                        '${SwitchState._light6 ? context.l10n.on : context.l10n.off}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Switch(
                  value: SwitchState._light6,
                  onChanged: (bool value) {
                    if (value) {
                      _showMyDialog6('${context.l10n.pumprefillOn}', value);
                      switchState.setLight6Value(value);
                    } else {
                      _showMyDialog6('${context.l10n.pumpRefillOff}', value);
                      switchState.setLight6Value(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(Dimens.appPadding),
        child: ElevatedButton(
          onPressed: () {
            // Call the function to show reset confirmation dialog
            _showResetConfirmationDialog();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.whiteColor,
            side: BorderSide(
              color: AppColors.blueGray[200]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_rounded,
              ),
              SizedBox(width: Dimens.dp8),
              HeadingText4(
                text: '${context.l10n.resetAlertSetting}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveResetAlertsState(bool reset) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('resetAlerts', reset);
  }

  // Function to show a dialog for reset confirmation
  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.resetAlerts}'),
          content: Text('${context.l10n.resetAll}'),
          actions: [
            TextButton(
              child: Text('${context.l10n.cancel}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('${context.l10n.reset}'),
              onPressed: () {
                // Reset switch values and save the reset state
                switchState.resetSwitches();
                _saveResetAlertsState(true);

                // Close the dialog
                Navigator.of(context).pop();

                // Rebuild the UI to reflect the reset switch values
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSwitchDialog(String question, bool mode) async {
    SwitchState._hasConfirmedAction =
        false; // Reset the flag before showing the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.alert}'),
          content: Text(question),
          actions: [
            TextButton(
              child: Text('${context.l10n.confirm}'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _switchValue = mode;
                    SwitchState._hasConfirmedAction =
                        true; // Set the flag to true when confirmed
                  });
                } else {
                  _switchValue = mode;
                  SwitchState._hasConfirmedAction =
                      true; // Set the flag to true when confirmed
                }

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('${context.l10n.cancel}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This will execute after the dialog is closed
      if (SwitchState._hasConfirmedAction) {
        // Call _handleNotification here after the user confirms
        if (mode) {
          _handleNotification('switchValue');
        }
      }
    });
  }

  Future<void> _showMyDialog(String question, bool mode) async {
    SwitchState._hasConfirmedAction =
        false; // Reset the flag before showing the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.alert}'),
          content: Text(question),
          actions: [
            TextButton(
              child: Text('${context.l10n.confirm}'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _light = mode;
                    SwitchState._hasConfirmedAction =
                        true; // Set the flag to true when confirmed
                  });
                } else {
                  _light = mode;
                  SwitchState._hasConfirmedAction =
                      true; // Set the flag to true when confirmed
                }

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('${context.l10n.cancel}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This will execute after the dialog is closed
      if (SwitchState._hasConfirmedAction) {
        // Call _handleNotification here after the user confirms
        if (mode) {
          _handleNotification('light');
        }
      }
    });
  }

  Future<void> _showMyDialog2(String question, bool mode) async {
    SwitchState._hasConfirmedAction =
        false; // Reset the flag before showing the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.alert}'),
          content: Text(question),
          actions: [
            TextButton(
              child: Text('${context.l10n.confirm}'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _light2 = mode;
                    SwitchState._hasConfirmedAction =
                        true; // Set the flag to true when confirmed
                  });
                } else {
                  _light2 = mode;
                  SwitchState._hasConfirmedAction =
                      true; // Set the flag to true when confirmed
                }

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('${context.l10n.cancel}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This will execute after the dialog is closed
      if (SwitchState._hasConfirmedAction) {
        // Call _handleNotification here after the user confirms
        if (mode) {
          _handleNotification('light2');
        }
      }
    });
  }

  Future<void> _showMyDialog3(String question, bool mode) async {
    SwitchState._hasConfirmedAction =
        false; // Reset the flag before showing the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.alert}'),
          content: Text(question),
          actions: [
            TextButton(
              child: Text('${context.l10n.confirm}'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _light3 = mode;
                    SwitchState._hasConfirmedAction =
                        true; // Set the flag to true when confirmed
                  });
                } else {
                  _light3 = mode;
                  SwitchState._hasConfirmedAction =
                      true; // Set the flag to true when confirmed
                }

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('${context.l10n.cancel}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This will execute after the dialog is closed
      if (SwitchState._hasConfirmedAction) {
        // Call _handleNotification here after the user confirms
        if (mode) {
          _handleNotification('light3');
        }
      }
    });
  }

  Future<void> _showMyDialog4(String question, bool mode) async {
    SwitchState._hasConfirmedAction =
        false; // Reset the flag before showing the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.alert}'),
          content: Text(question),
          actions: [
            TextButton(
              child: Text('${context.l10n.confirm}'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _light4 = mode;
                    SwitchState._hasConfirmedAction =
                        true; // Set the flag to true when confirmed
                  });
                } else {
                  _light4 = mode;
                  SwitchState._hasConfirmedAction =
                      true; // Set the flag to true when confirmed
                }

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('${context.l10n.cancel}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This will execute after the dialog is closed
      if (SwitchState._hasConfirmedAction) {
        // Call _handleNotification here after the user confirms
        if (mode) {
          _handleNotification('light4');
        }
      }
    });
  }

  Future<void> _showMyDialog5(String question, bool mode) async {
    SwitchState._hasConfirmedAction =
        false; // Reset the flag before showing the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.alert}'),
          content: Text(question),
          actions: [
            TextButton(
              child: Text('${context.l10n.confirm}'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _light5 = mode;
                    SwitchState._hasConfirmedAction =
                        true; // Set the flag to true when confirmed
                  });
                } else {
                  _light5 = mode;
                  SwitchState._hasConfirmedAction =
                      true; // Set the flag to true when confirmed
                }

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('${context.l10n.cancel}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This will execute after the dialog is closed
      if (SwitchState._hasConfirmedAction) {
        // Call _handleNotification here after the user confirms
        if (mode) {
          _handleNotification('light5');
        }
      }
    });
  }

  Future<void> _showMyDialog6(String question, bool mode) async {
    SwitchState._hasConfirmedAction =
        false; // Reset the flag before showing the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${context.l10n.alert}'),
          content: Text(question),
          actions: [
            TextButton(
              child: Text('${context.l10n.confirm}'),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _light6 = mode;
                    SwitchState._hasConfirmedAction =
                        true; // Set the flag to true when confirmed
                  });
                } else {
                  _light6 = mode;
                  SwitchState._hasConfirmedAction =
                      true; // Set the flag to true when confirmed
                }

                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('${context.l10n.cancel}'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // This will execute after the dialog is closed
      if (SwitchState._hasConfirmedAction) {
        // Call _handleNotification here after the user confirms
        if (mode) {
          _handleNotification('light6');
        }
      }
    });
  }

  void showMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Future<void> checkHandleNotificationCondition(BuildContext context) async {
    final String TAG = 'checkHandleNotificationCondition:';
    DateTime now = DateTime.now();
    String format = "MMddyy";
    var DATE = DateFormat(format).format(now);
    log('${TAG}ANNISA[$DATE] CHECKING');
    String key = 'light';

    // Access StateMgr using Provider
    var stateMgr = Provider.of<StateMgr>(context, listen: false);
    var profiles = stateMgr.callProfiles;

    log('${TAG}ANNISA[$DATE]: Checking StateMgr.callProfiles $profiles');

    if (profiles != null && profiles.isNotEmpty) {
      for (int index = 0; index < profiles.length; index++) {
        final profile = profiles[index];
        log('${TAG}ANNISA[$DATE]: Checking profile ${profile.profileName}');
        log('${TAG}ANNISA[$DATE]: Checking profile Low Alert  ${profile.isLowAlert}');
        log('${TAG}ANNISA[$DATE]: Checking profile snoozeDuration ${profile.snoozeDuration}');
        log('${TAG}ANNISA[$DATE]: Checking profile Urgent Alert ${profile.isUrgentAlarm}');
        log('${TAG}ANNISA[$DATE]: Checking profile SnoozeEnabled ${profile.isSnoozeEnabled}');
        // Call your handleNotification method for each profile
        String key = 'light';
        handleNotification(key, context, profile, stateMgr);
        log('${TAG}ANNISA[$DATE]: Checking profile for stateMgr.isSnoozeActiveForProfile(profile) >> ${stateMgr.isSnoozeActiveForProfile(profile)}');
        log('${TAG}ANNISA[$DATE]: Checking profile for stateMgr.getSnoozeEndTimeForProfile(profile) >> ${stateMgr.getSnoozeEndTimeForProfile(profile)}');
        DateTime? snoozeEndTime = stateMgr.getSnoozeEndTimeForProfile(profile);
        if (_preferences == null) {
          _preferences = await SharedPreferences.getInstance();
        }
        // Set the value of light2 based on the value of profile.isLowAlert
        bool light2Value = profile.isUrgentSoon;
        _preferences!.setBool('light2', light2Value);
        log('${TAG}ANNISA[$DATE]:light2: $light2Value');

        bool light3Value = profile.isLowAlert;
        _preferences!.setBool('light3', light3Value);
        log('${TAG}ANNISA[$DATE]:light3: $light3Value');

        bool light4Value = profile.isHighAlert;
        _preferences!.setBool('light4', light4Value);
        log('${TAG}ANNISA[$DATE]:light4: $light4Value');

        bool light5Value = profile.isSensorSignalLoss;
        _preferences!.setBool('light5', light5Value);
        log('${TAG}ANNISA[$DATE]:light5: $light5Value');

        bool isSnoozeEnabledValue = profile.isSnoozeEnabled;
        _preferences!.setBool('isSnoozeEnabled', isSnoozeEnabledValue);
        log('${TAG}ANNISA[$DATE]:isSnoozeEnabledValue: $isSnoozeEnabledValue');

        String? snoozeDuration = profile.snoozeDuration;
        _preferences!.setString('snoozeDuration', snoozeDuration!);
        log('${TAG}ANNISA[$DATE]:snoozeDuration: $snoozeDuration');

        bool light6Value = profile.isPumpRefill;
        _preferences!.setBool('light6', light6Value);
        log('${TAG}ANNISA[$DATE]:light6: $light6Value');

        log('${TAG}ANNISA[$DATE]:Preferences: $_preferences');
        log('${TAG}ANNISA[$DATE]:light2: ${_preferences?.getBool('light2')}');
        // Check if snooze is active and snooze end time is not yet reached
        if (stateMgr.isSnoozeActiveForProfile(profile) &&
            snoozeEndTime != null &&
            DateTime.now().isBefore(snoozeEndTime)) {
          log('${TAG}ANNISA[$DATE]: Snooze is active for profile ${profile.profileName}, skipping notification check.');
          continue; // Skip to next profile
        }

        if (snoozeEndTime != null && DateTime.now().isAfter(snoozeEndTime)) {
          log('${TAG}ANNISA[$DATE]:Snooze period ended for profile ${profile.profileName}, checking conditions.');
          log('${TAG}ANNISA[$DATE]: come inside here isSnoozeActive!');
          if (_preferences != null) {
            for (int i = 2; i < 7; i++) {
              String innerKey = 'light${i}';
              log('${TAG}ANNISA[$DATE]:Loop iteration: $i, Inner Key: $innerKey');
              // Check if the preference key exists
              if (_preferences!.containsKey(innerKey)) {
                bool preferenceValue = _preferences!.getBool(innerKey) ?? false;
                log('${TAG}ANNISA[$DATE]: Preference Value for $innerKey: $preferenceValue');

                // Check if the preference value is true
                if (_preferences!.getBool(innerKey) ?? false) {
                  log('${TAG}ANNISA[$DATE]: Entering handleNotification for $innerKey');
                  handleNotificationForSnooze(
                      innerKey, context, profile, stateMgr);
                  stateMgr.resetSnoozeForProfile(
                      profile); // Reset snooze state for this profile
                }
              } else {
                log('${TAG}ANNISA[$DATE]: Preference key $innerKey not found');
              }
            }
          } else {
            debugPrint('Cannot proceed: _preferences is null');
          }
        } else {
          log('${TAG}ANNISA[$DATE]: come inside here because isSnoozeActive is false!');
          if (_preferences == null) {
            _preferences = await SharedPreferences.getInstance();
          }
          log('${TAG}ANNISA[$DATE]: Preferences: $_preferences');
          log('${TAG}ANNISA[$DATE]: light2: ${_preferences?.getBool('light2')}');
          if (_preferences != null) {
            for (int i = 2; i < 7; i++) {
              String innerKey = 'light${i}';
              log('${TAG}ANNISA[$DATE]: Loop iteration: $i, Inner Key: $innerKey');

              // Check if the preference key exists
              if (_preferences!.containsKey(innerKey)) {
                bool preferenceValue = _preferences!.getBool(innerKey) ?? false;
                log('Preference Value for $innerKey: $preferenceValue');

                // Check if the preference value is true
                if (_preferences!.getBool(innerKey) ?? false) {
                  log('Entering handleNotification for $innerKey');
                  handleNotification(innerKey, context, profile, stateMgr);
                }
              } else {
                log('Preference key $innerKey not found');
              }
            }
          } else {
            debugPrint('Cannot proceed: _preferences is null');
          }
        }
      }
    } else {
      log('ANNISA112423checkHandleNotificationCondition: No saved profiles found');
    }
  }

  void handleNotification(String preferenceKey, BuildContext context,
      AlarmProfile savedProfile, StateMgr stateMgr) {
    final String TAG = 'handleNotification:';
    DateTime now = DateTime.now();
    String format = "MMddyy";
    var DATE = DateFormat(format).format(now);

    log('${TAG}ANNISA[$DATE]:  >> $preferenceKey');
    if (mCMgr == null) {
      log('${TAG}ANNISA[$DATE]: mCMgr is null !!');
      if (context != null) {
        log('${TAG}ANNISA[$DATE]: checking mCMgr for context not null!!!');

        mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
        log('${TAG}ANNISA[$DATE]: checking mCMgr!!! $mCMgr');
      } else {
        log('${TAG}ANNISA[$DATE]: context is null !!');
      }

      if (mCMgr == null) {
        log('${TAG}ANNISA[$DATE]: mCMgr is null !!. can not proceed !!');
        return;
      }
    } else if (mCMgr!.mCgm == null) {
      log('${TAG}ANNISA[$DATE]: mCMgr.mCgm is null !!. can not proceed !!');
      return;
    }

    if (mAudioPlayer == null) {
      log('${TAG}ANNISA[$DATE]: checking value for _USE_AUDIO_PLAYBACK : ${_USE_AUDIO_PLAYBACK}!');
      if (_USE_AUDIO_PLAYBACK == true) {
        log('${TAG}ANNISA[$DATE]: checking value for _USE_AUDIOCACHE : ${_USE_AUDIOCACHE}!');
        if (_USE_AUDIOCACHE == true) {
          //maudioCacheplayer = AudioCache();

          mAudioPlayer = CsaudioPlayer();
          log('${TAG}ANNISA[$DATE]: checking value for mAudioPlayer  if _USE_AUDIOCACHE true : ${mAudioPlayer}!');
        } else {
          mAudioPlayer = CsaudioPlayer();
          log('${TAG}ANNISA[$DATE]: checking value for mAudioPlayer() if _USE_AUDIOCACHE not true : ${mAudioPlayer}!');
        }
      }
    } else if (mAudioPlayer == null) {
      log('${TAG}ANNISA[$DATE]: mCMgr.mAudioPlayer is null !!. can not proceed !!');
      return;
    }
    final bloodGlucoseHistoryList =
        mCMgr?.mCgm?.getBloodGlucoseHistoryList().take(2).toList() ?? [];

// If the length is less than 2, fill the remaining slots with null or 0
    if (bloodGlucoseHistoryList.length < 2) {
      bloodGlucoseHistoryList.addAll(
        List<int?>.filled(2 - bloodGlucoseHistoryList.length, null).cast<int>(),
      );
    }

    log('${TAG}ANNISA[$DATE]: bloodGlucoseHistoryList(${bloodGlucoseHistoryList}');
    final intValue = mCMgr!.mCgm!.getBloodGlucoseValue();
    final lastValue = mCMgr!.mCgm!.getLastBloodGlucose() > 0
        ? mCMgr!.mCgm!.getLastBloodGlucose()
        : intValue;
    final currentValueGlucose =
        mCMgr?.mCgm!.getBloodGlucoseHistoryList().getRange(0, 1) ?? [0];
    final lastValueGlucose =
        mCMgr?.mCgm!.getBloodGlucoseHistoryList().getRange(1, 2) ?? [0];
    log('${TAG}ANNISA[$DATE]: intValue(${intValue}');
    log('${TAG}ANNISA[$DATE]: lastValue(${lastValue}');
    log('${TAG}ANNISA[$DATE]: currentValueGlucose(${currentValueGlucose}');
    log('${TAG}ANNISA[$DATE]: lastValueGlucose(${lastValueGlucose}');

    int rateOfChange = intValue - lastValue;

    int glucoseDifference =
        (currentValueGlucose.isNotEmpty && lastValueGlucose.isNotEmpty)
            ? currentValueGlucose.first - lastValueGlucose.first
            : 0;
    int timeInterval = 10 * 60 * 1000; // 10 minutes in milliseconds
    double rateOfChange2 = glucoseDifference / timeInterval;
    log('${TAG}ANNISA[$DATE]: glucoseDifference(${glucoseDifference}');
    int? glucoseValueThreshold = savedProfile.alarmThreshold;
    double rapidFallThreshold = -0.5;
    log('${TAG}ANNISA[$DATE]: mounted(${mounted}):glucoseValueThreshold:= $glucoseValueThreshold, intValue(${intValue}),lastValue(${lastValue}),rateOfChange(${rateOfChange})');
    // Fetch the received time history list
    final receivedTimeHistoryList = mCMgr!.mCgm!.getRecievedTimeHistoryList();
    final lastTime = mCMgr!.mCgm!.getLastTimeBGReceived();
    final LastInsulin = mCMgr!.mPump!.getBolusDeliveryValue();
    if (mCMgr!.mCgm != null) {
      log('${TAG}ANNISA[$DATE]: savedProfile.snoozeDuration(${savedProfile.snoozeDuration})');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedSound(${savedProfile.selectedSound})');
      log('${TAG}ANNISA[$DATE]: savedProfile.alarmDuration(${savedProfile.alarmDuration})');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedDays(${savedProfile.selectedDays})');
      log('${TAG}ANNISA[$DATE]: savedProfile.alarmThreshold(${savedProfile.alarmThreshold})');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedDate.year(${savedProfile.selectedDate?.year}');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedDate.month(${savedProfile.selectedDate?.month}');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedDate.day(${savedProfile.selectedDate?.day}');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedTimes(${savedProfile.selectedTime})');
      log('${TAG}ANNISA[$DATE]: savedProfile.isSnoozeEnabled(${savedProfile.isSnoozeEnabled})');
      log('${TAG}ANNISA[$DATE]: preference key = $preferenceKey');
      final num thresholdAsNum = glucoseValueThreshold ?? 90;
      bool now = InputAlarmProfileBloc.isDaySelected(savedProfile.selectedDays,
          savedProfile.selectedTime, savedProfile.selectedDate);
      if (now) {
        log('${TAG}ANNISA[$DATE]: checking time! date! and days! is true!!');
      } else {
        log('${TAG}ANNISA[$DATE]: checking time! date! and days! is not true!!');
      }
      if (preferenceKey == 'light2') {
        log('${TAG}ANNISA[$DATE]: light key2 is true!');
        if (rateOfChange2 < rapidFallThreshold) {
          log('${TAG}ANNISA[$DATE]: light key2 bloodGlucoseFallFast condition is true!');
        } else {
          log('${TAG}ANNISA[$DATE]: light key2 bloodGlucoseFallFast condition is false!');
        }
      } else {
        log('${TAG}ANNISA[$DATE]: light key2 is not true!');
      }

      if (preferenceKey == 'light3') {
        log('${TAG}ANNISA[$DATE]: light key3 is true!');
        if (lastValue < thresholdAsNum) {
          log('${TAG}ANNISA[$DATE]: light key3 low value condition is true!');
        } else {
          log('${TAG}ANNISA[$DATE]: light key3 low value  condition is false!');
        }
      } else {
        log('${TAG}ANNISA[$DATE]: light key3 is not true!');
      }

      if (preferenceKey == 'light4') {
        log('${TAG}ANNISA[$DATE]: light key4 is true!');
        if (lastValue > 130) {
          log('${TAG}ANNISA[$DATE]: light4 High Value condition  is true!');
        } else {
          log('${TAG}ANNISA[$DATE]: light4 High Value condition is false!');
        }
      } else {
        log('${TAG}ANNISA[$DATE]: light key4 is not true!');
      }

      if (preferenceKey == 'light6') {
        log('${TAG}ANNISA[$DATE]: light6 key is true!');
        if (checkForPumpRefill(receivedTimeHistoryList)) {
          log('${TAG}ANNISA[$DATE]: light condition is true!');
        } else {
          log('${TAG}ANNISA[$DATE]: light condition is false!');
        }
      } else {
        log('${TAG}ANNISA[$DATE]: light condition is not true!');
      }

      if (lastValue > 90) {
        log('${TAG}ANNISA[$DATE]: #CGM IS high TRUE!');
      } else {
        log('${TAG}ANNISA[$DATE]: #CGM IS high FALSE!');
      }

      if (lastValue < thresholdAsNum) {
        log('${TAG}ANNISA[$DATE]: #CGM IS LOW VALUE TRUE!');
      } else {
        log('${TAG}ANNISA[$DATE]: #CGM IS LOW VALUE FALSE!');
      }

      if (lastValue < thresholdAsNum) {
        log('${TAG}ANNISA[$DATE]: light: cgmIsLow condition is true!');
        showCGMLowAlertDialogOnEvent(context,
            '${context.l10n.cgmIsLow} ${context.l10n.value}: $lastValue');
      } else if (preferenceKey == 'light2' &&
          rateOfChange2 < rapidFallThreshold &&
          InputAlarmProfileBloc.isDaySelected(savedProfile.selectedDays,
              savedProfile.selectedTime, savedProfile.selectedDate)) {
        log('${TAG}ANNISA[$DATE]: light2: bloodGlucoseFallFast condition is true!');
        showAlertDialog(
            context,
            '${context.l10n.bloodGlucoseFallFast} $lastValue',
            savedProfile,
            stateMgr);
        /**
            showAlertDialogSnoozeOnEvent(
            context,
            '${context.l10n.bloodGlucoseFallFast} $lastValue',
            savedProfile,
            stateMgr,
            preferenceKey);
         **/
      } else if (preferenceKey == 'light3' &&
          lastValue < thresholdAsNum &&
          InputAlarmProfileBloc.isDaySelected(savedProfile.selectedDays,
              savedProfile.selectedTime, savedProfile.selectedDate)) {
        log('${TAG}ANNISA[$DATE]: light3: bloodGlucoseLow condition is true!');
        showAlertDialog(
            context,
            '${context.l10n.bloodGlucoseLow} ${context.l10n.value}: $lastValue',
            savedProfile,
            stateMgr);
        /**
            showAlertDialogSnoozeOnEvent(
            context,
            '${context.l10n.bloodGlucoseLow} ${context.l10n.value}: $lastValue',
            savedProfile,
            stateMgr,
            preferenceKey);
         **/
      } else if (preferenceKey == 'light4' &&
          lastValue > 130 &&
          InputAlarmProfileBloc.isDaySelected(savedProfile.selectedDays,
              savedProfile.selectedTime, savedProfile.selectedDate)) {
        log('${TAG}ANNISA[$DATE]: light4: bloodGlucoseHigh condition is true!');
        showAlertDialog(
            context,
            '${context.l10n.bloodGlucoseHigh} ${context.l10n.value}: $lastValue',
            savedProfile,
            stateMgr);
        /**
            showAlertDialogSnoozeOnEvent(
            context,
            '${context.l10n.bloodGlucoseHigh} ${context.l10n.value}: $lastValue',
            savedProfile,
            stateMgr,
            preferenceKey);
         **/
      } else if (preferenceKey == 'light5' &&
          checkForSignalLoss() &&
          InputAlarmProfileBloc.isDaySelected(savedProfile.selectedDays,
              savedProfile.selectedTime, savedProfile.selectedDate)) {
        log('${TAG}ANNISA[$DATE]: light5: signalLossOnly condition is true!');
        showAlertDialog(
            context, '${context.l10n.signalLossOnly}', savedProfile, stateMgr);
      } else if (preferenceKey == 'light6' &&
          checkForPumpRefill(receivedTimeHistoryList) &&
          InputAlarmProfileBloc.isDaySelected(savedProfile.selectedDays,
              savedProfile.selectedTime, savedProfile.selectedDate)) {
        showAlertDialog(context, '${context.l10n.pumpRefillNeeded}',
            savedProfile, stateMgr);
      }
    }
  }

  void handleNotificationForSnooze(String preferenceKey, BuildContext context,
      AlarmProfile savedProfile, StateMgr stateMgr) {
    final String TAG = 'handleNotificationForSnooze:';
    DateTime now = DateTime.now();
    String format = "MMddyy";
    var DATE = DateFormat(format).format(now);
    log('${TAG}ANNISA[$DATE]: $preferenceKey');
    if (mCMgr == null) {
      log('${TAG}ANNISA[$DATE]: mCMgr is null !!');
      if (context != null) {
        log('${TAG}ANNISA[$DATE]: checking mCMgr for context not null!!!');

        mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
        log('${TAG}ANNISA[$DATE]: checking mCMgr!!! $mCMgr');
      } else {
        log('${TAG}ANNISA[$DATE]: context is null !!');
      }

      if (mCMgr == null) {
        log('${TAG}ANNISA[$DATE]: mCMgr is null !!. can not proceed !!');
        return;
      }
    } else if (mCMgr!.mCgm == null) {
      log('${TAG}ANNISA[$DATE]: mCMgr.mCgm is null !!. can not proceed !!');
      return;
    }

    if (mAudioPlayer == null) {
      log('${TAG}ANNISA[$DATE]: mAudioPlayer is null !!');
      if (context != null) {
        log('${TAG}ANNISA[$DATE]: checking mAudioPlayer for context not null!!!');

        mAudioPlayer = Provider.of<CsaudioPlayer>(context, listen: false);
        log('${TAG}ANNISA[$DATE]: checking mAudioPlayer!!! $mAudioPlayer');
      } else {
        log('${TAG}ANNISA[$DATE]: mAudioPlayer is null !!');
      }

      if (mAudioPlayer == null) {
        log('${TAG}ANNISA[$DATE]: mAudioPlayer is null !!. can not proceed !!');
        return;
      }
    } else if (mAudioPlayer == null) {
      log('${TAG}ANNISA[$DATE]: mAudioPlayeris null !!. can not proceed !!');
      return;
    }
    final bloodGlucoseHistoryList =
        mCMgr?.mCgm?.getBloodGlucoseHistoryList().take(2).toList() ?? [];

// If the length is less than 2, fill the remaining slots with null or 0
    if (bloodGlucoseHistoryList.length < 2) {
      bloodGlucoseHistoryList.addAll(
        List<int?>.filled(2 - bloodGlucoseHistoryList.length, null).cast<int>(),
      );
    }

    log('${TAG}ANNISA[$DATE]: bloodGlucoseHistoryList(${bloodGlucoseHistoryList}');
    final intValue = mCMgr!.mCgm!.getBloodGlucoseValue();
    final lastValue = mCMgr!.mCgm!.getLastBloodGlucose() > 0
        ? mCMgr!.mCgm!.getLastBloodGlucose()
        : intValue;
    final currentValueGlucose =
        mCMgr?.mCgm!.getBloodGlucoseHistoryList().getRange(0, 1) ?? [0];
    final lastValueGlucose =
        mCMgr?.mCgm!.getBloodGlucoseHistoryList().getRange(1, 2) ?? [0];
    log('${TAG}ANNISA[$DATE]: intValue(${intValue}');
    log('${TAG}ANNISA[$DATE]: lastValue(${lastValue}');
    log('${TAG}ANNISA[$DATE]: currentValueGlucose(${currentValueGlucose}');
    log('${TAG}ANNISA[$DATE]: lastValueGlucose(${lastValueGlucose}');

    int rateOfChange = intValue - lastValue;

    int glucoseDifference =
        (currentValueGlucose.isNotEmpty && lastValueGlucose.isNotEmpty)
            ? currentValueGlucose.first - lastValueGlucose.first
            : 0;
    int timeInterval = 10 * 60 * 1000; // 10 minutes in milliseconds
    double rateOfChange2 = glucoseDifference / timeInterval;
    log('${TAG}ANNISA[$DATE]: glucoseDifference(${glucoseDifference}');
    int? glucoseValueThreshold = savedProfile.alarmThreshold;
    double rapidFallThreshold = -0.5;
    log('${TAG}ANNISA[$DATE]: mounted(${mounted}):glucoseValueThreshold:= $glucoseValueThreshold, intValue(${intValue}),lastValue(${lastValue}),rateOfChange(${rateOfChange})');
    // Fetch the received time history list
    final receivedTimeHistoryList = mCMgr!.mCgm!.getRecievedTimeHistoryList();
    final lastTime = mCMgr!.mCgm!.getLastTimeBGReceived();
    final LastInsulin = mCMgr!.mPump!.getBolusDeliveryValue();
    if (mCMgr!.mCgm != null) {
      log('${TAG}ANNISA[$DATE]: savedProfile.snoozeDuration(${savedProfile.snoozeDuration})');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedSound(${savedProfile.selectedSound})');
      log('${TAG}ANNISA[$DATE]: savedProfile.alarmDuration(${savedProfile.alarmDuration})');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedDays(${savedProfile.selectedDays})');
      log('${TAG}ANNISA[$DATE]: savedProfile.alarmThreshold(${savedProfile.alarmThreshold})');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedDate.year(${savedProfile.selectedDate?.year}');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedDate.month(${savedProfile.selectedDate?.month}');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedDate.day(${savedProfile.selectedDate?.day}');
      log('${TAG}ANNISA[$DATE]: savedProfile.selectedTimes(${savedProfile.selectedTime})');
      log('${TAG}ANNISA[$DATE]: savedProfile.isSnoozeEnabled(${savedProfile.isSnoozeEnabled})');
      log('${TAG}ANNISA[$DATE]: preference key = $preferenceKey');
      final num thresholdAsNum = glucoseValueThreshold ?? 90;
      bool now = InputAlarmProfileBloc.isDaySelected(savedProfile.selectedDays,
          savedProfile.selectedTime, savedProfile.selectedDate);
      if (now) {
        log('${TAG}ANNISA[$DATE]:checking time! date! and days! is true!!');
      } else {
        log('${TAG}ANNISA[$DATE]:checking time! date! and days! is not true!!');
      }
      if (preferenceKey == 'light2') {
        log('${TAG}ANNISA[$DATE]:light key2 is true!');
        if (rateOfChange2 < rapidFallThreshold) {
          log('${TAG}ANNISA[$DATE]:light key2 bloodGlucoseFallFast condition is true!');
        } else {
          log('${TAG}ANNISA[$DATE]:light key2 bloodGlucoseFallFast condition is false!');
        }
      } else {
        log('${TAG}ANNISA[$DATE]:light key2 is not true!');
      }

      if (preferenceKey == 'light3') {
        log('${TAG}ANNISA[$DATE]:light key3 is true!');
        if (lastValue < thresholdAsNum) {
          log('${TAG}ANNISA[$DATE]:light key3 low value condition is true!');
        } else {
          log('${TAG}ANNISA[$DATE]:light key3 low value  condition is false!');
        }
      } else {
        log('${TAG}ANNISA[$DATE]:light key3 is not true!');
      }

      if (preferenceKey == 'light4') {
        log('${TAG}ANNISA[$DATE]:light key4 is true!');
        if (lastValue > 130) {
          log('${TAG}ANNISA[$DATE]:light4 High Value condition  is true!');
        } else {
          log('${TAG}ANNISA[$DATE]:light4 High Value condition is false!');
        }
      } else {
        log('${TAG}ANNISA[$DATE]:light key4 is not true!');
      }

      if (preferenceKey == 'light6') {
        log('${TAG}ANNISA[$DATE]:light6 key is true!');
        if (checkForPumpRefill(receivedTimeHistoryList)) {
          log('${TAG}ANNISA[$DATE]:light condition is true!');
        } else {
          log('${TAG}ANNISA[$DATE]:light condition is false!');
        }
      } else {
        log('${TAG}ANNISA[$DATE]:light condition is not true!');
      }

      if (lastValue > 90) {
        log('${TAG}ANNISA[$DATE]:#CGM IS high TRUE!');
      } else {
        log('${TAG}ANNISA[$DATE]:#CGM IS high FALSE!');
      }

      if (lastValue < thresholdAsNum) {
        log('${TAG}ANNISA[$DATE]:#CGM IS LOW VALUE TRUE!');
      } else {
        log('${TAG}ANNISA[$DATE]:#CGM IS LOW VALUE FALSE!');
      }

      if (lastValue < thresholdAsNum) {
        log('${TAG}ANNISA[$DATE]:light: cgmIsLow condition is true!');
        showCGMLowAlertDialogOnEvent(context,
            '${context.l10n.cgmIsLow} ${context.l10n.value}: $lastValue');
      } else if (preferenceKey == 'light2' &&
          rateOfChange2 < rapidFallThreshold) {
        log('${TAG}ANNISA[$DATE]:light2: bloodGlucoseFallFast condition is true!');
        showAlertDialog(
            context,
            '${context.l10n.bloodGlucoseFallFast} $lastValue',
            savedProfile,
            stateMgr);
      } else if (preferenceKey == 'light3' && lastValue < thresholdAsNum) {
        log('${TAG}ANNISA[$DATE]:light3: bloodGlucoseLow condition is true!');
        showAlertDialog(
            context,
            '${context.l10n.bloodGlucoseLow} ${context.l10n.value}: $lastValue',
            savedProfile,
            stateMgr);
      } else if (preferenceKey == 'light4' && lastValue > 130) {
        log('${TAG}ANNISA[$DATE]:light4: bloodGlucoseHigh condition is true!');
        showAlertDialog(
            context,
            '${context.l10n.bloodGlucoseHigh} ${context.l10n.value}: $lastValue',
            savedProfile,
            stateMgr);
      } else if (preferenceKey == 'light5' && checkForSignalLoss()) {
        log('${TAG}ANNISA[$DATE]:light5: signalLossOnly condition is true!');
        showAlertDialog(
            context, '${context.l10n.signalLossOnly}', savedProfile, stateMgr);
      } else if (preferenceKey == 'light6' &&
          checkForPumpRefill(receivedTimeHistoryList)) {
        log('${TAG}ANNISA[$DATE]:light6: pumpRefillNeeded condition is true!');
        showAlertDialog(context, '${context.l10n.pumpRefillNeeded}',
            savedProfile, stateMgr);
      }
    }
  }

  void _handleNotification(String preferenceKey) {}

  DateTime getLastPumpRefillTime(List<String> receivedTimeHistoryList) {
    if (receivedTimeHistoryList.isNotEmpty) {
      return DateTime.parse(receivedTimeHistoryList.first);
    } else {
      return DateTime.now();
    }
  }

  bool checkForPumpRefill(List<String> receivedTimeHistoryList) {
    DateTime lastRefillTime = getLastPumpRefillTime(receivedTimeHistoryList);

    final maxRefillDuration = Duration(days: 30);

    bool isRefillNeeded =
        DateTime.now().difference(lastRefillTime) >= maxRefillDuration;

    return isRefillNeeded;
  }

// Function to check for signal loss
  /*
  *@brief let's check new bloodglucose is incoming during 30 minutes
  * 	Loss of communication for more than 30 minutes to the CGM/ pump
  */
  bool checkForSignalLoss() {
    // Get the current timestamp
    DateTime currentTime = DateTime.now();

    // Assume your CGM provides the last timestamp when glucose data was received
    // Replace this with the actual timestamp you have in your application
    DateTime lastGlucoseTimestamp;
    if (mCMgr != null &&
        mCMgr!.mCgm != null &&
        mCMgr!.mCgm!.getLastTimeBGReceived() != 0) {
      lastGlucoseTimestamp = DateTime.fromMillisecondsSinceEpoch(
          mCMgr!.mCgm!.getLastTimeBGReceived());
    } else {
      lastGlucoseTimestamp = DateTime.now(); // Use the current date and time
    }
    // Define the maximum allowed time difference to consider the signal valid (e.g., 10 minutes) auto mode off
    final maxAllowedTimeDifference = Duration(minutes: 30).inMilliseconds;
    // Check if the time difference between the current time and the last received data is within the allowed threshold
    bool isSignalLost = currentTime.millisecondsSinceEpoch -
            lastGlucoseTimestamp.millisecondsSinceEpoch >
        maxAllowedTimeDifference;

    return isSignalLost;
  }

  /*
  *@brief let's check new bloodglucose is incoming during 10 minutes
  *      	CGM value is not received for more than 10 minutes
  */
  bool checkNewGlucoseIncomingFor10Minutes() {
    // Get the current timestamp
    DateTime currentTime = DateTime.now();

    // Assume your CGM provides the last timestamp when glucose data was received
    // Replace this with the actual timestamp you have in your application
    DateTime lastGlucoseTimestamp;
    if (mCMgr != null &&
        mCMgr!.mCgm != null &&
        mCMgr!.mCgm!.getLastTimeBGReceived() != 0) {
      lastGlucoseTimestamp = DateTime.fromMillisecondsSinceEpoch(
          mCMgr!.mCgm!.getLastTimeBGReceived());
    } else {
      lastGlucoseTimestamp = DateTime.now(); // Use the current date and time
    }
    // Define the maximum allowed time difference to consider the signal valid (e.g., 10 minutes)
    final maxAllowedTimeDifference = Duration(minutes: 10).inMilliseconds;
    // Check if the time difference between the current time and the last received data is within the allowed threshold
    bool isNoIncomingNewBG = ((currentTime.millisecondsSinceEpoch -
            lastGlucoseTimestamp.millisecondsSinceEpoch) >=
        maxAllowedTimeDifference);

    debugPrint(
        'kai:currentTime.millisecondsSinceEpoch(${currentTime.millisecondsSinceEpoch}),'
        'lastGlucoseTimestamp.millisecondsSinceEpoch(${lastGlucoseTimestamp.millisecondsSinceEpoch},'
        'DiffTime(${currentTime.millisecondsSinceEpoch - lastGlucoseTimestamp.millisecondsSinceEpoch}) > maxAllowedTimeDifference(${maxAllowedTimeDifference})'
        'isNoIncomingNewBG(${isNoIncomingNewBG})');
    return isNoIncomingNewBG;
  }

// Function to start monitoring glucose data
  /*
  *@brief  let's alert "CGM value is not received for more than 10 minutes"
  * in case that Auto mode is off && CGM value is not received for more than 10 minutes after receive New Glood glucose from CGM
  */
  void startNewGlucoseMonitoring(BuildContext context) {
    //kai_20231024 let's check below
    if (switchState == null) {
      switchState = SwitchState();
    }

    if (switchState != null) {
      if (switchState.NewBGIncomingTimer == null) {
        // Start a timer to check for signal loss every 10 minutes
        switchState.NewBGIncomingTimer = Timer(Duration(minutes: 10), () {
          // Check if you have received new glucose data within the last 10 minutes
          bool isSignalLost = checkNewGlucoseIncomingFor10Minutes();
          debugPrint(
              'kai:AlertPage: witchState!._NewBGIncomingTimer callback is called after 10 minutes:isSignalLost(${isSignalLost})');
          if (isSignalLost) {
            // Trigger an alert for signal loss
            // showAlertDialogOnEvent(context, '${context.l10n.noNewBGIncoming}');
            showAlertToastMessage(
                context, '${context.l10n.noNewBGIncoming}', 'yellow', 3);
          }
        });
      } else {
        if (switchState.NewBGIncomingTimer!.isActive) {
          switchState.NewBGIncomingTimer!.cancel();
        }

        // Start a timer to check for signal loss every 10 minutes
        switchState.NewBGIncomingTimer = Timer(Duration(minutes: 10), () {
          // Check if you have received new glucose data within the last 10 minutes
          bool isSignalLost = checkNewGlucoseIncomingFor10Minutes();
          debugPrint(
              'kai:AlertPage: witchState!._NewBGIncomingTimer callback is called after 10 minutes:isSignalLost(${isSignalLost})');
          // 2. Auto mode is off && CGM value is not received for more than 10 minutes after receive New Glood glucose from CGM
          if (isSignalLost) {
            // Trigger an alert for signal loss
            // showAlertDialogOnEvent(context,  '${context.l10n.noNewBGIncoming}');
            showAlertToastMessage(
                context, '${context.l10n.noNewBGIncoming}', 'yellow', 3);
          }
        });
      }
    }
  }

  Future<void> startSignalLossMonitoring(BuildContext context) async {
    //kai_20231024 let's check below
    debugPrint('kai:AlertPage:startSignalLossMonitoring() is called');
    if (switchState == null) {
      switchState = SwitchState();
    }

    if (switchState != null) {
      if (switchState.signalLossTimer == null) {
        debugPrint(
            'kai:AlertPage:create switchState!._signalLossTimer instance first');
        final autoMode = (await GetIt.I<GetAutoModeUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          0,
          (r, previous) => r,
        );

        // Start a timer to check for signal loss every 10 minutes
        switchState.signalLossTimer = Timer.periodic(
            (autoMode > 0) ? Duration(minutes: 30) : Duration(minutes: 10),
            (timer) {
          // Check if you have received new glucose data within the last 10 minutes
          bool isSignalLost = (autoMode > 0)
              ? checkForSignalLoss()
              : checkNewGlucoseIncomingFor10Minutes();
          debugPrint(
              'kai:AlertPage: switchState!._signalLossTimer callback is called after ${(autoMode > 0) ? 30 : 10} minutes: isSignalLost(${isSignalLost})');
          if (isSignalLost) {
            // Trigger an alert for signal loss
            // showAlertDialogOnEvent(context, (autoMode > 0) ? '${context.l10n.signalLoss}' : '${context.l10n.noNewBGIncoming}');
            showAlertToastMessage(
                context,
                (autoMode > 0)
                    ? '${context.l10n.signalLoss}'
                    : '${context.l10n.noNewBGIncoming}',
                'yellow',
                3);
          }
        });
      } else {
        if (switchState.signalLossTimer!.isActive) {
          debugPrint(
              'kai:AlertPage:call switchState!._signalLossTimer!.cancel() first and create it again');
          switchState.signalLossTimer!.cancel();
        }

        final autoMode = (await GetIt.I<GetAutoModeUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          0,
          (r, previous) => r,
        );

        // Start a timer to check for signal loss every 10 minutes
        switchState.signalLossTimer = Timer.periodic(
            (autoMode > 0) ? Duration(minutes: 30) : Duration(minutes: 10),
            (timer) {
          // Check if you have received new glucose data within the last 10 minutes
          debugPrint(
              'kai:AlertPage: switchState!._signalLossTimer callback is called after ${(autoMode > 0) ? 30 : 10} minutes');
          bool isSignalLost = (autoMode > 0)
              ? checkForSignalLoss()
              : checkNewGlucoseIncomingFor10Minutes();
          // 2. Auto mode is off && CGM value is not received for more than 10 minutes after receive New Glood glucose from CGM
          if (isSignalLost) {
            // Trigger an alert for signal loss
            //  showAlertDialogOnEvent(context, (autoMode > 0) ? '${context.l10n.signalLoss}' : '${context.l10n.noNewBGIncoming}');
            showAlertToastMessage(
                context,
                (autoMode > 0)
                    ? '${context.l10n.signalLoss}'
                    : '${context.l10n.noNewBGIncoming}',
                'yellow',
                3);
          }
        });
      }
    } else {
      debugPrint(
          'kai:AlertPage:can not statrt startSignalLossMonitoring() due to switchState is null!!');
    }
  }

  /*
  *@brief if one of the following criteria is meet, Auto mode will revert to  ‘Attempting’:
  * •	Loss of communication for more than 30 minutes to the CGM/ pump
  * •	Pump insulin delivery was suspended (manually setted from the pump)
  * •	Bluetooth of the pump is turned off
  * •	Extended bolus disallowed on the pump
  * •	Pump reservoir is less than 1U
  * •	Pump need to refill, pump unreachable, pump is almost expired (e.g. < 1 hour)
  * •	CGM expired time less than 1 hour
  *
  * The ‘attempting’ mode continues until the condition preventing the start of Auto mode is resolved.
  * When in ‘attempting’ mode, insulin infusion will revert to the pre-programmed basal rate after approximately 30 minutes
   */
  void startAutoModeOnStatusMonitoring(BuildContext context) {
    //kai_20231024
    //let's check	below
    if (switchState == null) {
      switchState = SwitchState();
    }

    if (switchState != null) {
      if (switchState.AutoModeStatusTimer == null) {
        switchState.AutoModeStatusTimer =
            Timer.periodic(Duration(minutes: 5), (timer) {
          // Check if you have received new glucose data within the last 5 seconds
          bool isSignalLost = checkForSignalLoss();
          debugPrint(
              'kai:AlertPage: switchState!._AutoModeStatusTimer callback is called:isSignalLost{${isSignalLost})');
          if (isSignalLost) {
            // Trigger an alert for signal loss
            // showAlertDialogOnEvent(context,'${context.l10n.signalLoss}');
            showAlertToastMessage(
                context, '${context.l10n.signalLoss}', 'yellow', 3);
          }
        });
      }
    }
  }

  void updateAlertMessage(String message) {
    if (mounted) {
      setState(() {
        this._alertmessage = message;
      });
    } else {
      this._alertmessage = message;
    }
  }

  bool isAlertDisplayed = false;
  late Completer<void> dialogCompleter; // Add this line

  Future<void> playAlertAndShowDialog(
      BuildContext context, String message, AlarmProfile savedProfile) async {
    log('>> Checking value on playAlertAndShowDialog = _USE_AUDIO_PLAYBACK: ${_USE_AUDIO_PLAYBACK}');
    log('>> Checking value on playAlertAndShowDialog = mAudioPlayer: ${mAudioPlayer}');
    log('>> Checking value on playAlertAndShowDialog = (mAudioPlayer!.isPlaying: ${(mAudioPlayer!.isPlaying)}');

    if (_USE_AUDIO_PLAYBACK) {
      if (mAudioPlayer == null) {
        mAudioPlayer = CsaudioPlayer(); // Initialize if null
      }

      if (mAudioPlayer!.isPlaying) {
        log('>> Checking value on playAlertAndShowDialog = before mAudioPlayer!.stop(): ${(mAudioPlayer!.isPlaying)}');
        await mAudioPlayer!.stop();
        mAudioPlayer!.isPlaying = false;
        log('>> Checking value on playAlertAndShowDialog = after mAudioPlayer!.stop(): ${(mAudioPlayer!.isPlaying)}');
      }

      log('>> Checking value on playAlertAndShowDialog = selectedSound: ${(savedProfile.selectedSound)}');
      await mAudioPlayer!
          .playAlertNotification(message, savedProfile.selectedSound);
    }

    int alarmDuration = savedProfile.alarmDuration ?? 15;

    if (dialogCompleter == null || dialogCompleter.isCompleted) {
      dialogCompleter = Completer<void>();
    }

    Future.delayed(Duration(minutes: alarmDuration), () {
      if (!dialogCompleter.isCompleted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          log('>>showAlertDialogOnEvent off!');
        }

        if (_USE_AUDIO_PLAYBACK && mAudioPlayer != null) {
          mAudioPlayer!.stopAlert();
          log('>>_USE_AUDIO_PLAYBACK off too!');
        }

        dialogCompleter.complete();
      }
    });

    dialogCompleter.complete();
  }

  Future<void> showAlertDialogSnoozeOnEvent(
      BuildContext context,
      String message,
      AlarmProfile savedProfile,
      StateMgr stateMgr,
      String preferenceKey) async {
    log('>> calling showAlertDialogSnoozeOnEvent method!');
    log('>> calling savedProfile on showAlertDialogSnoozeOnEvent >> ${savedProfile}');

    // If a dialog is already displayed, dismiss it
    if (isAlertDisplayed) {
      Navigator.of(context).pop();
      isAlertDisplayed = false;
    }

    isAlertDisplayed = true;
    _alertmessage = message; // Simplify the setState logic

    if (mounted) {
      setState(() {
        _alertmessage = message;
      });
    } else {
      _alertmessage = message;
    }

    log('AlertPage:showAlertDialogSnoozeOnEvent(). CHECKING _USE_GLOBAL_KEY VALUE IS ${_USE_GLOBAL_KEY}');
    log('AlertPage:showAlertDialogSnoozeOnEvent(). CHECKING _USE_AUDIO_PLAYBACK VALUE IS ${_USE_AUDIO_PLAYBACK}');
    log('AlertPage:showAlertDialogSnoozeOnEvent(). CHECKING CsaudioPlayer VALUE IS ${CsaudioPlayer()}');
    if (_USE_GLOBAL_KEY == true) {
      if (_USE_AUDIO_PLAYBACK == true) {
        log('>> calling _USE_AUDIO_PLAYBACK true!');
        //playAlert() ;
        if (mAudioPlayer == null) {
          mAudioPlayer = CsaudioPlayer();
        }

        if (mAudioPlayer != null) {
          if (mAudioPlayer!.isPlaying == true) {
            mAudioPlayer!.stop();
            mAudioPlayer!.isPlaying = false;
          }
          log('>> Checking value on showAlertDialogSnoozeOnEvent = selectedSound: ${savedProfile.selectedSound}');
          mAudioPlayer!
              .playAlertNotification(message, savedProfile.selectedSound);
        } else {
          log('AlertPage:showAlertDialogSnoozeOnEvent():kai:can not mAudioPlayer.playAlert, mAudioPlayer is null');
        }
      }
      dialogCompleter = Completer<void>();
      showDialog<BuildContext>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return FutureBuilder<void>(
            future: playAlertAndShowDialog(context, message, savedProfile),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              return AlertDialog(
                title: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '${context.l10n.alert}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.all(0),
                content: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (_USE_AUDIO_PLAYBACK) {
                        if (mAudioPlayer != null) {
                          mAudioPlayer!.stopAlert();
                          log('>>showAlertDialogSnoozeOnEvent _USE_AUDIO_PLAYBACK off too: ${_USE_AUDIO_PLAYBACK}!');
                        } else {
                          log('AlertPage:showAlertDialogSnoozeOnEvent().dismiss:kai:can not mAudioPlayer.stopAlert, mAudioPlayer is null');
                        }
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text('${context.l10n.stop}'),
                  ),
                  // Inside showAlertDialogSnoozeOnEvent function, find the snooze button logic
                  TextButton(
                    onPressed: () {
                      log('AlertPage:showAlertDialogSnoozeOnEvent(). CHECKING AUDIO PLAYBACK  _USE_AUDIO_PLAYBACK VALUE IS ${_USE_AUDIO_PLAYBACK}');
                      if (_USE_AUDIO_PLAYBACK && mAudioPlayer != null) {
                        log('AlertPage:showAlertDialogSnoozeOnEvent(). CHECKING AUDIO PLAYBACK  mAudioPlayer != null VALUE IS TRUE');
                        mAudioPlayer!.stopAlert();
                      } else {
                        log('AlertPage:showAlertDialogSnoozeOnEvent().dismiss:ANNISA:can not mAudioPlayer.stopAlert, mAudioPlayer is null');
                      }

                      log('check the snoozeDuration: ${savedProfile.snoozeDuration}');
                      snoozeAlarm(savedProfile.snoozeDuration, savedProfile,
                          context, stateMgr);
                      Navigator.of(context).pop();
                    },
                    child: Text('${context.l10n.snooze}'),
                  ),
                ],
              );
            },
          );
        },
      ).then((_) {
        // Reset the alert display flag when dialog is closed
        isAlertDisplayed = false;
      });
      switchState.setPopupMessage(message);
    }
  }

  /// Shows a notification with the specified message using Flutter Local Notification
  Future<void> showNotification(BuildContext context, String message,
      AlarmProfile savedProfile, DateTime scheduledTime) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'alert_channel_id', // Unique ID for your notification channel
      'Alert Channel', // Name of the notification channel
      'Alert Notification Description', // Description of the notification channel
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
          savedProfile.selectedSound), // Customize the sound
      // Add additional parameters as needed
    );

    // Create a NotificationDetails object with the Android settings.
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    int notificationId = DateTime.now().millisecondsSinceEpoch;
    // Show the notification.
    await flutterLocalNotificationsPlugin.show(
      notificationId, // Notification ID (unique for each notification)
      'Alert', // Title of the notification
      message, // Body of the notification
      platformChannelSpecifics,
      payload: 'notification_payload', // Optional payload
    );
  }

  Future<void> scheduleNotification(BuildContext context, String message,
      AlarmProfile savedProfile, DateTime scheduledTime) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alert_channel_id',
      'Alert Channel',
      'Alert Notification Description',
      importance: Importance.max,
      priority: Priority.high,
      // Other settings...
    );
    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.schedule(
      scheduledTime.millisecondsSinceEpoch,
      'Scheduled Alert',
      message,
      scheduledTime,
      platformChannelSpecifics,
      payload: 'notification_payload',
    );
  }

  void snoozeNotification(AlarmProfile profile, int snoozeMinutes) async {
    var scheduledTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    // Reschedule the notification
    await showNotification(
        context, 'Snoozed Notification', profile, scheduledTime);
  }

  void stopNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  void snoozeAlarm(String? snoozeDuration, AlarmProfile savedProfile,
      BuildContext context, StateMgr stateMgr) {
    log('Entering snooze alarm because snooze button clicked');
    log('check the snoozeDuration: ${snoozeDuration}');
    int snoozeMinutes = int.tryParse(snoozeDuration ?? '10') ?? 10;
    DateTime snoozeEndTime =
        DateTime.now().add(Duration(minutes: snoozeMinutes));
    log('Snooze Duration: ${snoozeMinutes} minutes');
    log('Snooze End Time: ${snoozeEndTime}');
    savedProfile.isSnoozeEnabled = true;
    // Set the snooze state to active and store the end time
    stateMgr.setSnoozeActive(true);
    stateMgr.setSnoozeEndTimeForProfile(snoozeEndTime, savedProfile);

    // Start a timer to trigger after snoozeMinutes
    Timer(Duration(minutes: snoozeMinutes), () {
      log('Snooze period ended. Rechecking conditions.');
      savedProfile.isSnoozeEnabled = false;
      stateMgr.setSnoozeActive(false); // Reset snooze state
      checkHandleNotificationCondition(context);
    });
  }

  Future<void> showAlertDialogOnEvent(
      BuildContext context, String message, AlarmProfile savedProfile) async {
    log('>> calling showAlertDialogOnEvent method!');
    log('>> calling savedProfile on showAlertDialogOnEvent >> ${savedProfile}');

    // If a dialog is already displayed, dismiss it
    if (isAlertDisplayed) {
      Navigator.of(context).pop();
      isAlertDisplayed = false;
    }

    isAlertDisplayed = true;
    _alertmessage = message; // Simplify the setState logic
    log('AlertPage:showAlertDialogOnEvent(). CHECKING _USE_GLOBAL_KEY VALUE IS ${_USE_GLOBAL_KEY}');
    log('AlertPage:showAlertDialogOnEvent(). CHECKING _USE_AUDIO_PLAYBACK VALUE IS ${_USE_AUDIO_PLAYBACK}');
    log('AlertPage:showAlertDialogOnEvent(). CHECKING CsaudioPlayer VALUE IS ${CsaudioPlayer()}');
    if (_USE_GLOBAL_KEY == true) {
      log('AlertPage:showAlertDialogOnEvent(). CHECKING _USE_AUDIO_PLAYBACK VALUE inside IS ${_USE_AUDIO_PLAYBACK}');
      if (_USE_AUDIO_PLAYBACK == true) {
        log('>> calling _USE_AUDIO_PLAYBACK true!');
        //playAlert() ;
        if (mAudioPlayer == null) {
          log('Initializing mAudioPlayer');
          mAudioPlayer = CsaudioPlayer();
        } else {
          log('mAudioPlayer already initialized');
        }

        if (mAudioPlayer != null) {
          log('Using mAudioPlayer for playback');
          if (mAudioPlayer!.isPlaying == true) {
            log('checking mAudioPlayer!.isPlaying here >>> ');
            mAudioPlayer!.stop();
            mAudioPlayer!.isPlaying = false;
          }
          log('>> Checking value on showAlertDialogOnEvent = selectedSound: ${savedProfile.selectedSound}');
          log('>> Checking value on showAlertDialogOnEvent = message: ${savedProfile.selectedSound}');
          mAudioPlayer!.playAlertNotificationNew(savedProfile.selectedSound);
          log('mAudioPlayer state after playAlertNotificationNew: ${mAudioPlayer != null}');
        } else {
          log('AlertPage:showAlertDialogOnEvent():kai:can not mAudioPlayer.playAlert, mAudioPlayer is null');
        }
      }
      dialogCompleter = Completer<void>();
      showDialog<BuildContext>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          if (dialogCompleter == null || dialogCompleter.isCompleted) {
            dialogCompleter = Completer<void>();
          }
          return FutureBuilder<void>(
            future: playAlertAndShowDialog(context, message, savedProfile),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // Reset the alert display flag when dialog is closed
                isAlertDisplayed = false;
              }
              return AlertDialog(
                title: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '${context.l10n.alert}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.all(0),
                content: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      log('AlertPage:showAlertDialogOnEvent(). CHECKING 2_USE_GLOBAL_KEY VALUE IS ${_USE_GLOBAL_KEY}');
                      log('AlertPage:showAlertDialogOnEvent(). CHECKING  2 _USE_AUDIO_PLAYBACK VALUE IS ${_USE_AUDIO_PLAYBACK}');
                      log('AlertPage:showAlertDialogOnEvent(). CHECKING 2 CsaudioPlayer VALUE IS ${CsaudioPlayer()}');

                      if (_USE_AUDIO_PLAYBACK) {
                        log('Before attempting to stop, mAudioPlayer is null: ${mAudioPlayer == null}');
                        if (mAudioPlayer != null) {
                          log('Stopping audio playback');
                          mAudioPlayer!.stopAlert();
                          log('Audio playback stopped');
                        } else {
                          log('AlertPage:showAlertDialogOnEvent().dismiss:kai:can not mAudioPlayer.stopAlert, mAudioPlayer is null');
                        }
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text('${context.l10n.stop}'),
                  ),
                ],
              );
            },
          );
        },
      );
      // Set the popup message in SwitchState
      switchState.setPopupMessage(message);
    }
  }

  Future<void> showAlertDialog(BuildContext context, String message,
      AlarmProfile savedProfile, StateMgr stateMgr) async {
    log('>> calling showAlertDialog method!');

    if (isAlertDisplayed) {
      log('Alert is already displayed. Skipping.');
      return;
    }
    isAlertDisplayed = true;

    if (mounted) {
      setState(() {
        _alertmessage = message;
      });
    } else {
      _alertmessage = message;
    }

    log('AlertPage:showAlertDialog(). CHECKING _USE_GLOBAL_KEY VALUE IS ${_USE_GLOBAL_KEY}');
    log('AlertPage:showAlertDialog(). CHECKING _USE_AUDIO_PLAYBACK VALUE IS ${_USE_AUDIO_PLAYBACK}');
    log('AlertPage:showAlertDialog(). CHECKING CsaudioPlayer VALUE IS ${CsaudioPlayer()}');
    if (_USE_GLOBAL_KEY == true) {
      if (_USE_AUDIO_PLAYBACK == true) {
        log('>> calling _USE_AUDIO_PLAYBACK true!');
        //playAlert() ;
        if (mAudioPlayer == null) {
          mAudioPlayer = CsaudioPlayer();
        }

        if (mAudioPlayer != null) {
          log('Using mAudioPlayer for playback');
          if (mAudioPlayer!.isPlaying == true) {
            log('checking mAudioPlayer!.isPlaying here >>> ');
            mAudioPlayer!.stop();
            mAudioPlayer!.isPlaying = false;
          }
          log('>> Checking value on showAlertDialog = selectedSound: ${savedProfile.selectedSound}');
          log('>> Checking value on showAlertDialog = message: ${_alertmessage}');
          mAudioPlayer!.playAlertNotificationNew(savedProfile.selectedSound);
          log('mAudioPlayer state after playAlertNotificationNew: ${mAudioPlayer != null}');
        } else {
          log('AlertPage:showAlertDialog():kai:can not mAudioPlayer.playAlert, mAudioPlayer is null');
        }
      }
      dialogCompleter = Completer<void>();
      showDialog<BuildContext>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          int alarmDuration = savedProfile.alarmDuration ?? 5;
          log('>>showAlertDialog checking alarm duration ${savedProfile.alarmDuration}!');
          log('>>showAlertDialog checking alarm duration ${alarmDuration}!');
          if (dialogCompleter == null || dialogCompleter.isCompleted) {
            dialogCompleter = Completer<void>();
          }
          Future.delayed(Duration(minutes: alarmDuration), () {
            if (!dialogCompleter.isCompleted) {
              Navigator.pop(context);
              log('>>showAlertDialog off!');
              isAlertDisplayed = false;

              if (_USE_AUDIO_PLAYBACK) {
                if (mAudioPlayer != null) {
                  mAudioPlayer!.stopAlert();
                  log('>> showAlertDialog 1 _USE_AUDIO_PLAYBACK off too : ${_USE_AUDIO_PLAYBACK}!');
                } else {
                  log('AlertPage:showAlertDialog().dismiss:kai:can not mAudioPlayer.stopAlert, mAudioPlayer is null');
                }
              }
              dialogCompleter.complete();
            }
          });

          return AlertDialog(
            title: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Text(
                '${context.l10n.alert}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            titlePadding: const EdgeInsets.all(0),
            content: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (_USE_AUDIO_PLAYBACK) {
                    if (mAudioPlayer != null) {
                      mAudioPlayer!.stopAlert();
                      log('>> showAlertDialog _USE_AUDIO_PLAYBACK off too : ${_USE_AUDIO_PLAYBACK}!');
                    } else {
                      log('AlertPage:showAlertDialog().dismiss:kai:can not mAudioPlayer.stopAlert, mAudioPlayer is null');
                    }
                  }
                  Navigator.of(context).pop();
                },
                child: Text('${context.l10n.stop}'),
              ),
              TextButton(
                onPressed: () {
                  if (_USE_AUDIO_PLAYBACK) {
                    if (mAudioPlayer != null) {
                      mAudioPlayer!.stopAlert();
                      log('>> Snooze button pressed. Stopping audio.');
                    } else {
                      log('AlertPage:showAlertDialog().dismiss:kai:can not mAudioPlayer.stopAlert, mAudioPlayer is null');
                    }
                  }
                  log('check the snoozeDuration: ${savedProfile.snoozeDuration}');
                  snoozeAlarm(savedProfile.snoozeDuration, savedProfile,
                      context, stateMgr);
                  Navigator.of(context).pop();
                },
                child: Text('${context.l10n.snooze}'),
              ),
            ],
          );
        },
      );
    }
    // Set the popup message in SwitchState
    switchState.setPopupMessage(message);
  }

  Future<void> showCGMLowAlertDialogOnEvent(
    BuildContext context,
    String message,
  ) async {
    log('>> calling showCGMLowAlertDialogOnEvent method!');

    if (isAlertDisplayed) {
      log('Alert is already displayed. Skipping.');
      return;
    }

    isAlertDisplayed = true;

    if (mounted) {
      setState(() {
        _alertmessage = message;
      });
    } else {
      _alertmessage = message;
    }

    log('AlertPage:showCGMLowAlertDialogOnEvent(). CHECKING _USE_GLOBAL_KEY VALUE IS ${_USE_GLOBAL_KEY}');
    log('AlertPage:showCGMLowAlertDialogOnEvent(). CHECKING _USE_AUDIO_PLAYBACK VALUE IS ${_USE_AUDIO_PLAYBACK}');
    log('AlertPage:showCGMLowAlertDialogOnEvent(). CHECKING CsaudioPlayer VALUE IS ${CsaudioPlayer()}');
    if (_USE_GLOBAL_KEY == true) {
      if (_USE_AUDIO_PLAYBACK == true) {
        log('>> calling _USE_AUDIO_PLAYBACK true!');
        //playAlert() ;
        if (mAudioPlayer == null) {
          mAudioPlayer = CsaudioPlayer();
        }

        if (mAudioPlayer != null) {
          if (mAudioPlayer!.isPlaying == true) {
            await mAudioPlayer!.stop();
            mAudioPlayer!.isPlaying = false;
          }
          mAudioPlayer = null;
          mAudioPlayer!.playAlertNotificationCGM(message);
        } else {
          log('AlertPage:showCGMLowAlertDialogOnEvent():kai:can not mAudioPlayer.playAlert, mAudioPlayer is null');
        }
      }
      dialogCompleter = Completer<void>();
      showDialog<BuildContext>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          if (dialogCompleter == null || dialogCompleter.isCompleted) {
            dialogCompleter = Completer<void>();
          }

          Future.delayed(Duration(minutes: 15), () {
            if (!dialogCompleter.isCompleted) {
              Navigator.pop(context);
              log('>>showAlertDialogOnEvent off!');
              isAlertDisplayed = false;

              if (_USE_AUDIO_PLAYBACK) {
                if (mAudioPlayer != null) {
                  mAudioPlayer!.stopAlert();
                  log('>> showCGMLowAlertDialogOnEvent 1 _USE_AUDIO_PLAYBACK off too : ${_USE_AUDIO_PLAYBACK}!');
                } else {
                  log('AlertPage:showCGMLowAlertDialogOnEvent().dismiss:kai:can not mAudioPlayer.stopAlert, mAudioPlayer is null');
                }
              }
              dialogCompleter.complete();
            }
          });

          return AlertDialog(
            title: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Text(
                '${context.l10n.alert}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            titlePadding: const EdgeInsets.all(0),
            content: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (_USE_AUDIO_PLAYBACK) {
                    if (mAudioPlayer != null) {
                      mAudioPlayer!.stopAlert();
                      log('>> showCGMLowAlertDialogOnEvent _USE_AUDIO_PLAYBACK off too : ${_USE_AUDIO_PLAYBACK}!');
                    } else {
                      log('AlertPage:showAlertDialogOnEvent().dismiss:kai:can not mAudioPlayer.stopAlert, mAudioPlayer is null');
                    }
                  }
                  Navigator.of(context).pop();
                },
                child: Text('${context.l10n.stop}'),
              ),
            ],
          );
        },
      );
    }
    // Set the popup message in SwitchState
    switchState.setPopupMessage(message);
  }

  void showAlertToastMessage(
    BuildContext context,
    String Msg,
    String ColorType,
    int showingTime,
  ) {
    var _color = Colors.blueAccent[700];
    var ShowingDuration = 2;

    ///< default 2 secs
    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      ShowingDuration = showingTime;
    }

    switch (ColorType.toLowerCase()) {
      case 'red':
        {
          _color = Colors.redAccent[700];

          //kai_20231021 let's playback alert onetime here
          if (USE_AUDIO_PLAYBACK == true) {
            if (mAudioPlayer == null) {
              mAudioPlayer = CsaudioPlayer();
            }
            if (mAudioPlayer != null) {
              //mAudioPlayer!.playLowBatAlert();
              mAudioPlayer!.playAlertOneTime('occlusion');
            }
          }
        }
        break;

      case 'yellow':
        _color = Colors.yellowAccent[700];
        break;

      case 'green':
        _color = Colors.greenAccent[700];
        break;

      case 'blue':
        _color = Colors.blueAccent[700];
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        /*  // kai_20230501 blocked show message in center for the consistency of toast message
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            left: 30.0, right: 30.0, top: 30.0, bottom: 300.0),
       */
        backgroundColor: _color, // Colors.blueAccent[700],
        content: Text(Msg),
        duration: Duration(seconds: ShowingDuration),
      ),
    );
  }

  void initializeAudioPlayer() {
    if (mAudioPlayer == null) {
      mAudioPlayer = CsaudioPlayer();
    }
  }

  void safelyPlaySound(
      String soundType, String message, AlarmProfile savedProfile) {
    initializeAudioPlayer();
    if (mAudioPlayer!.isPlaying) {
      mAudioPlayer!.stop();
    }
    mAudioPlayer!.playAlertNotification(message, savedProfile.selectedSound);
  }

  void safelyStopSound() {
    initializeAudioPlayer();
    if (mAudioPlayer!.isPlaying) {
      mAudioPlayer!.stopAlert();
    }
  }
}

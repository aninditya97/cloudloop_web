import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloudloop_mobile/app/locator.dart';
import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/helpers/date_time_helper.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/index/sections/scan_dialog_section.dart';
import 'package:cloudloop_mobile/features/settings/domain/entities/xdrip_data.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/XDripLauncher.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/audioplay/csaudioplayer.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Pump.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/PumpCsp1.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/PumpDanars.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/serviceUuid.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:formz/formz.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

const bool debugMessageFlag = true;

class Device {
  Device({
    required this.id,
    required this.validCode,
  });
  final String id;
  final int validCode;
}

class XdripOption {
  XdripOption({
    required this.id,
    required this.url,
  });
  final String id;
  final String url;
}

class ConnectionDialogPage extends StatefulWidget {
  const ConnectionDialogPage({
    Key? key,
    required this.onPressed,
    this.cgmData,
    this.onUpdateBloodGlucose,
    required this.context,
    required this.accessType,
    this.onRefresh,

    ///< home , setting_cgm, setting_pump
    /// required this.onCheckAlertCondition,
    required this.switchStateAlert,

    ///< SwitchStateAlert Notification check instance
  }) : super(key: key);

  final VoidCallback onPressed;
  final CgmData? cgmData;
  final ValueChanged<dynamic>? onUpdateBloodGlucose;
  final BuildContext context;
  final String accessType;
  //final VoidCallback onCheckAlertCondition;
  final VoidCallback? onRefresh;
  final SwitchState switchStateAlert;

  @override
  State<ConnectionDialogPage> createState() => _ConnectionDialogPageState();
}

class _ConnectionDialogPageState extends State<ConnectionDialogPage> {
/*
  late List<Device> _devices;
  late List<XdripOption> _xdripOptions;
 */

  final List<XdripOption> _xdripOptions = [
    XdripOption(id: 'xdripHome', url: 'XDripLauncher.launchXDripHome'),
    XdripOption(id: 'StartSensor', url: 'XDripLauncher.StartNewSensor'),
    XdripOption(id: 'BGHistory', url: 'XDripLauncher.BGHistory'),
    XdripOption(id: 'BluetoothScan', url: 'XDripLauncher.BluetoothScan'),
    XdripOption(id: 'FakeNumbers', url: 'XDripLauncher.FakeNumbers'),
  ];

  final int maxValidCodeLength = 4;
  final int maxTransmitterIDLength = 6;
  final String tag = 'ConnectionDialog:';

  //kai_20230705 add
  String? _confirmSelectedDeviceId;
  String? _selectedDeviceId;
  String? _transmitterId;
  bool _isConnecting = false;
  String? _selectedXdripOptionId;
  PumpData? _pumpIsConnected;
  bool setDose = false;
  double? _totalUnits = 0;
  bool? _canToTheNext = false;
  bool? _sendBolus = false;
  int _duration = 30;
  Timer? _timer;
  double _iob = 0;
  bool _pumpVirtualSelected = false;
  bool _broadcastingSelected = false;
  String? _accessType;

  late CsaudioPlayer _csaudioPlayer;
  late int _validCode = 0;
  late ConnectivityMgr _mCMgr;

  @override
  void initState() {
    super.initState();
    //let's init csp preference instance here
    // CspPreference.initPrefs();  ///< shared Preference

    _mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
    _pumpVirtualSelected = false;
    _accessType = widget.accessType;
    debugPrint('udin:call cgm data : ${widget.cgmData},'
        ' accessType = ${widget.accessType}');
    //kai_20230901 added to accessType for
    //showing dialog based on distinguished accessType
    if (widget.accessType == 'setting_pump') {
    } else

    ///< (accessType == home || accessType == setting_cgm)
    {
      if (widget.cgmData != null) {
        if (widget.cgmData!.deviceId.contains('i-sens')) {
          _selectedDeviceId = widget.cgmData!.deviceId;
          _validCode = int.parse(widget.cgmData!.transmitterCode);
          _transmitterId = widget.cgmData!.transmitterCode;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _onConnectPressed();
              Navigator.of(context).pop();
            }
          });
        } else {
          _onXdripOptionSelected(
            widget.cgmData!.transmitterCode,
          );
          Future.delayed(
            const Duration(seconds: 3),
            () async {
              Navigator.of(context).pop();
            },
          );
        }
      }
    }

    if (USE_AUDIO_PLAYBACK == true) {
      if (USE_AUDIOCACHE == true) {
        //maudioCacheplayer = AudioCache();
        _csaudioPlayer = CsaudioPlayer();
      } else {
        // _csaudioPlayer = AudioPlayer();
        _csaudioPlayer = CsaudioPlayer();
      }
    }

    // dwi_20240129 call to calculate iob
    _getIob();
  }

  /*
   * @fn updateBloodGlucosePageBySensor(String Glucose)
   * @brief update glucose data and emit it to server
   *        this API is used in DialogView
   * @param[in] Glucose : String double glucose data
   */
  void _updateBloodGlucosePageBySensor(String glucose) {
    if (FORCE_BGLUCOSE_UPDATE_FLAG) {
      final sensorInputGlucose =
          InputBloodGlucoseBloc(inputBloodGlucose: getIt())
            ..add(
              InputBloodGlucoseValueChanged(value: double.parse(glucose)),
            );
      if (debugMessageFlag) {
        log(
          'updateBloodGlucosePageBySensor: before status = '
          '${sensorInputGlucose.state.status.isValidated}',
        );
      }
      //  sensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
      sensorInputGlucose.add(
        const InputBloodGlucoseSubmitted(source: ReportSource.sensor),
      );

      ///< updated by sensor
    }
  }

  /*
   * @brief Update SummaryReportSection in Home screen
   *        this API is used in DialogView
   */
  Future<void> _updateSummaryReport() async {
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

    SummaryReportBloc(summary: getIt()).add(
      SummaryReportFetched(startDate: _date.start, endDate: _date.end),
    );
  }

  /*
   * @brief Update BloodGlucoseSection in Home screen
   *        this API is used in DialogView
   */
  Future<void> _updateBloodGlucose() async {
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
    GlucoseReportBloc(glucoseReport: getIt()).add(
      GlucoseReportFetched(
        startDate: _date.start,
        endDate: _date.end,
        filter: false,
      ),
    );
  }

  void _inputBloodGlucosePageBySensor(String glucose, int timeDate) {
    if (FORCE_BGLUCOSE_UPDATE_FLAG) {
      final sensorInputGlucose = GetIt.I<InputBloodGlucoseBloc>()
        ..add(
          InputBloodGlucoseValueChanged(
            value: double.parse(
              glucose,
            ),
          ),
        );
      if (debugMessageFlag) {
        log(
          'updateBloodGlucosePageBySensor: before status = '
          '${sensorInputGlucose.state.status.isValidated}',
        );
      }
      //  sensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
      sensorInputGlucose.add(
        InputBloodGlucoseSubmitted(
          source: ReportSource.sensor,
          time: DateTime.fromMillisecondsSinceEpoch(
            timeDate,
          ),
        ),
      );

      ///< updated by sensor
    }
  }

  /*
   * @fn _BloodGlucoseDataStreamCallback(dynamic event)
   * @param[in] event : received event data structure based on json
   * @brief receive the glucose data from android MainActivity thru xdrip
   *        caller should implement this callback in order to forward the
   *  received data to the PolicyNet Executor
   *        This API is used in DialogView
   */
  void _bloodGlucoseDataStreamCallback(dynamic event) {
    debugPrint('kai:callback BG Data Stream in connection dialog');
    //check event here
    setDose = false;
    if (debugMessageFlag) {
      // {"glucose":"150.0","timestamp":"1669944611002","raw":"0.0","direction":"Flat","source":"G6 Native / G5 Native"}
      debugPrint('$tag: _BloodGlucoseDataStreamCallback: is called: set '
          'false for setDose = $setDose, mounted = $mounted');
    }
    //parse json format sent from MaiActivity here
    final jsonData = json.decode(event.toString()) as Map<String, dynamic>;

    if (debugMessageFlag) {
      debugPrint('$tag: gluecose = ${jsonData['glucose']}');
      debugPrint('$tag: timestamp = ${jsonData['timestamp']}');
      debugPrint('$tag: raw = ${jsonData['raw']}');
      debugPrint('$tag: direction = ${jsonData['direction']}');
      debugPrint('$tag: source = ${jsonData['source']}');
      debugPrint('$tag: sensorSerial = ${jsonData['sensorSerial']}');
      debugPrint('$tag: calibrationInfo = ${jsonData['calibrationInfo']}');
    }

    /* save received bloodglucose time  and value here */
    final timeDate = int.parse(jsonData['timestamp'].toString());
    final glucose = jsonData['glucose'].toString();

    //update UI Screen here
    debugPrint('kai: mounted = $mounted, call setState() for update UI');
    if (mounted) {
      setState(() {
        _mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
        //kai_20230509 if Glucose have floating point as like double " 225.0 "
        //then convert the value to int exclude ".0" by using floor()
        // _mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
        _mCMgr.mCgm!.setBloodGlucoseValue(double.parse(glucose).floor());
        _mCMgr.mCgm!.setRecievedTimeHistoryList(
          0,
          DateTime.fromMillisecondsSinceEpoch(
            timeDate,
          ).toIso8601String(),
        );
        _mCMgr.mCgm!.setBloodGlucoseHistoryList(
          0,
          double.parse(glucose).floor(),
        );
        _mCMgr.mCgm!.cgmModelName = jsonData['source'].toString();
        _mCMgr.mCgm!.cgmSN = jsonData['sensorSerial'].toString();
        final xDripData = XdripData.fromJson(jsonData);
        _mCMgr.mCgm!.setCollectBloodGlucose(xDripData);
      });
    } else {
      debugPrint('kai: !mounted = $mounted,  update UI');
      _mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
      //kai_20230509 if Glucose have floating point as like double " 225.0 "
      //then convert the value to int exclude ".0" by using floor()
      // _mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
      _mCMgr.mCgm!.setBloodGlucoseValue(double.parse(glucose).floor());
      _mCMgr.mCgm!.setRecievedTimeHistoryList(
        0,
        DateTime.fromMillisecondsSinceEpoch(
          timeDate,
        ).toIso8601String(),
      );
      _mCMgr.mCgm!.setBloodGlucoseHistoryList(
        0,
        double.parse(glucose).floor(),
      );
      _mCMgr.mCgm!.cgmModelName = jsonData['source'].toString();
      _mCMgr.mCgm!.cgmSN = jsonData['sensorSerial'].toString();
      final xDripData = XdripData.fromJson(jsonData);
      _mCMgr.mCgm!.setCollectBloodGlucose(xDripData);
    }

    // UI Update here
    if (debugMessageFlag) {
      final mCgmGlucoseReceiveTime = DateFormat('yyyy/MM/dd HH:mm a')
          .format(DateTime.fromMillisecondsSinceEpoch(timeDate));
      final mCgmGlucoseValue = jsonData['glucose'].toString();

      debugPrint(
          '$tag:>>xdrip:$mCgmGlucoseReceiveTime: glucose = $mCgmGlucoseValue '
          'raw = ${jsonData['raw']}');
    }

    _inputBloodGlucosePageBySensor(glucose, timeDate);
    // update chart graph after upload received glucose data to server
    // updateBloodGlucosePageBySensor(glucose);
    _setDoseExecution();

    if (USE_ALERT_PAGE_INSTANCE == true) {
      debugPrint(
        '$tag:_bloodGlucoseDataStreamCallback:mounted($mounted)kai:call '
        'checkAlertNotification()',
      );

      //widget.onCheckAlertCondition.call();
      if (widget.switchStateAlert != null &&
          widget.switchStateAlert.appContext != null) {
        widget.switchStateAlert.mAlertPage!.checkAlertNotificationCondition(
          mounted == true ? context : widget.switchStateAlert.appContext!,
        );
        if (USE_CHECK_NEW_BG_IS_INCOMING) {
          widget.switchStateAlert.mAlertPage!.checkNewBGIncomingTimer(
            mounted == true ? context : widget.switchStateAlert.appContext!,
          );
        }
      } else {
        debugPrint(
          '$tag:kai:can not call mAlertPage!.checkAlertNotificationCondition()',
        );
      }
    }
  }

  Future<double> _iPolicyNetCalculate(
    int announceMeal,
    UserProfile user,
  ) async {
    debugPrint('udin:call using policynet');

    final intValue = _mCMgr.mCgm!.getBloodGlucoseValue();
    debugPrint('udin:call current glucose: $intValue');

    final lastValue = _mCMgr.mCgm!.getLastBloodGlucose() > 0
        ? _mCMgr.mCgm!.getLastBloodGlucose()
        : intValue;
    debugPrint('udin:call last glucose: $lastValue');

    final receivedTimeHistoryList =
        _mCMgr.mCgm!.getRecievedTimeHistoryList().getRange(
              0,
              5,
            );

    final timeHist = receivedTimeHistoryList.map((i) => i).toList();

    final bloodGlucoseHistoryList =
        _mCMgr.mCgm!.getBloodGlucoseHistoryList().getRange(
              0,
              5,
            );

    final cgmHist = bloodGlucoseHistoryList
        .map(
          (i) => i.toDouble(),
        )
        .toList();

    final lastInsulin = _mCMgr.mPump!.getLastBolusDeliveryValue();

    await _getIob();

    debugPrint('kai:call announceMeal status = $announceMeal');
    debugPrint('kai:call total daily dose = ${user.totalDailyDose}');
    debugPrint('kai:call basal rate = ${user.basalRate}');
    debugPrint('kai:call cgmHist = $cgmHist');
    debugPrint('kai:call timeHist = $timeHist');
    debugPrint('kai:call insulin '
        'carb ratio = ${user.insulinCarbRatio.toString()}');
    debugPrint('iob = $_iob');

    final response = await _mCMgr.mPN!.execution(
      cgmHist: cgmHist,
      timeHist: timeHist,
      lastInsulin: lastInsulin,
      announceMeal: announceMeal,
      totalDailyDose: user.totalDailyDose,
      basalRate: user.basalRate ?? 0.0,
      insulinCarbRatio: user.insulinCarbRatio ?? 0.0,
      iob: _iob,
    );

    return response;
  }

  Future _setDoseExecution() async {
    //kai_20230615 let's notify to consummer or selector in other pages.
    _mCMgr.mCgm!.changeNotifier();
    _mCMgr.changeNotifier();

    ///< send bloodglucose data to the DB or notify PolicyNet Executor
    Future.delayed(
      const Duration(seconds: 2),
      () async {
        //set insulin data source from sensor or manual user
        _mCMgr.mPump!.setInsulinSource(ReportSource.sensor);

        //To do something here .....

        //1. notify to PolicyNet Executor

        _pumpIsConnected = (await GetIt.I<GetPumpUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          null,
          (r, previous) => r,
        );

        final _autoMode = (await GetIt.I<GetAutoModeUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          0,
          (r, previous) => r,
        );

        final _announceMeal = (await GetIt.I<GetAnnounceMealUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          0,
          (r, previous) => r,
        );

        final _user = (await GetIt.I<GetProfileUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          const UserProfile(
            gender: Gender.female,
            name: '',
            id: '',
            weight: 0,
            totalDailyDose: 0,
          ),
          (r, previous) => r,
        );
        debugPrint('udin:call auto mode : $_autoMode');

        if (_autoMode > 0) {
          final response = await _iPolicyNetCalculate(_announceMeal, _user);

          debugPrint('kai:call _mCMgr.mPN!.execution(): response = $response');
          //2. PolicyNet Executor send the calculated bolus(insulin) value
          // to the connected Pump device
          // after check connection status is connected
          if (response > 0) {
            if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
                CspPreference.getBooleanDefaultFalse(
                      CspPreference.broadcastingPolicyNetBolus,
                    ) ==
                    true) {
              await _mCMgr.mPN!.broadcasting(
                bolus: response,
                pkgName: CspPreference.getString(
                  CspPreference.destinationPackageName,
                  defaultValue: 'com.kai.bleperipheral',
                ),
              );

              await _updateInsulinDeliveryDialogView(
                response.toString(),
                _mCMgr.mPump!.getInsulinSource(),
              );
            } else if (_mCMgr.mPump!.ConnectionStatus ==
                BluetoothDeviceState.connected) {
              //kai_20230905 let's set flag which update insulin delivery DataBase
              // setDose = false;

              final insulinValue = response
                  .toString(); // U or mL, which will be calculated by PolicyNet
              const mode =
                  0x00; //mode : total dose injection(0x00), (Correction Bolus)
              // 0x01, (Meal bolus) 0x02
              const BluetoothCharacteristic? characteristic =
                  null; // set null then control it based on the
              // internal implementation
              await _mCMgr.mPump!
                  .sendSetDoseValue(insulinValue, mode, characteristic);
            } else {
              debugPrint('kai:_mCMgr.mPump!.connectionStatus != '
                  'BluetoothDeviceState.connected');
              debugPrint('udin:call auto connect status : $_pumpIsConnected');
              if (_pumpIsConnected != null &&
                  _pumpIsConnected?.status == true) {
                await _autoConnect().whenComplete(
                  () async {
                    if (_mCMgr.mPump!.ConnectionStatus ==
                        BluetoothDeviceState.connected) {
                      //kai_20230905 let's set flag which update
                      // insulin delivery DataBase
                      //setDose = false;

                      final insulinValue = response
                          .toString(); // U or mL, which will be calculated
                      // by PolicyNet
                      const mode = 0x00; //mode : total dose injection(0x00),
                      //(Correction Bolus)
                      // 0x01, (Meal bolus) 0x02
                      const BluetoothCharacteristic? characteristic =
                          null; // set null then control it based on the
                      // internal implementation
                      await _mCMgr.mPump!
                          .sendSetDoseValue(insulinValue, mode, characteristic);
                    }
                  },
                );
              }
            }
          } else {
            await _updateInsulinDeliveryDialogView(
              response.toString(),
              _mCMgr.mPump!.getInsulinSource(),
            );
          }

          if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
              CspPreference.getBooleanDefaultFalse(
                    CspPreference.broadcastingPolicyNetBolus,
                  ) ==
                  true) {
            // send policynet result to the destination android aps application
            await _mCMgr.mPN!.broadcasting(
              bolus: response,
              pkgName: CspPreference.getString(
                CspPreference.destinationPackageName,
                defaultValue: 'com.kai.bleperipheral',
              ),
            );
          }
        } else {
          debugPrint('udin:call using basal rate');

          final basalRate = ((_user.basalRate! / 12) * 20.0).round() / 20.0;

          debugPrint('$tag:udin:call basal rate : ${_user.basalRate}');
          debugPrint('$tag:udin:call basal rate : $basalRate');
          debugPrint('udin:call using policynet');
          final intValue = _mCMgr.mCgm!.getBloodGlucoseValue();
          debugPrint('udin:call current glucose: $intValue');

          // 2. PolicyNet Executor send the calculated bolus(insulin) value
          // to the connected Pump device after
          // check connection status is connected
          debugPrint('$tag:kai:CspPreference.broadcastingPolicyNetBolus('
              '${CspPreference.getBooleanDefaultFalse(
            CspPreference.broadcastingPolicyNetBolus,
          )})');
          if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
              CspPreference.getBooleanDefaultFalse(
                    CspPreference.broadcastingPolicyNetBolus,
                  ) ==
                  true) {
            await _mCMgr.mPN!.broadcasting(
              bolus: double.parse(
                basalRate.toString(),
              ),
              pkgName: CspPreference.getString(
                CspPreference.destinationPackageName,
                defaultValue: 'com.kai.bleperipheral',
              ),
            );

            await _updateInsulinDeliveryDialogView(
              basalRate.toString(),
              _mCMgr.mPump!.getInsulinSource(),
            );
          } else {
            if (_mCMgr.mPump!.ConnectionStatus ==
                BluetoothDeviceState.connected) {
              const mode =
                  0x00; //mode : total dose injection(0x00), (Correction Bolus)
              // 0x01, (Meal bolus) 0x02
              const BluetoothCharacteristic? characteristic =
                  null; // set null then control it based on the
              // internal implementation
              await _mCMgr.mPump!.sendSetDoseValue(
                basalRate.toString(),
                mode,
                characteristic,
              );
            } else {
              debugPrint('kai:udin:call _mCMgr.mPump!.connectionStatus != '
                  'BluetoothDeviceState.connected');
              debugPrint(
                  'kai:udin:call auto connect status : $_pumpIsConnected');
              if (_pumpIsConnected != null &&
                  _pumpIsConnected?.status == true) {
                await _autoConnect().whenComplete(
                  () async {
                    if (_mCMgr.mPump!.ConnectionStatus ==
                        BluetoothDeviceState.connected) {
                      const mode = 0x00; //mode : total dose injection(0x00),
                      // (Correction Bolus)
                      // 0x01, (Meal bolus) 0x02
                      const BluetoothCharacteristic? characteristic =
                          null; // set null then control it based on the
                      // internal implementation
                      await _mCMgr.mPump!.sendSetDoseValue(
                        basalRate.toString(),
                        mode,
                        characteristic,
                      );
                    }
                  },
                );
              }
            }
          }
        }
      },
    );
  }

  Future<void> _autoConnect() async {
    debugPrint('kai:call auto connect pump');
    //kai_20230926 added the case of disconnecting by user
    if (CspPreference.getBooleanDefaultFalse(
          CspPreference.disconnectedByUser,
        ) ==
        true) {
      debugPrint(
        'kai:CspPreference.disconnectedByUser is true: '
        'not proceed autoconnection at this time',
      );
      return;
    }
    await _mCMgr.mPump!.startScan(5).whenComplete(
      () async {
        final device = _mCMgr.mPump!.getConnectedDevice();
        debugPrint('kai:udin:call device name : ${device?.name}');
        if (device != null) {
          await _mCMgr.mPump!.connectToDevice(device);
          debugPrint('kai:udin:call prev device $device');
        } else {
          debugPrint(
            'kai:udin:call new device ${_mCMgr.mPump!.getScannedDeviceLists()}',
          );

          //kai_20230925
          if (_mCMgr.mPump!.getScannedDeviceLists() != null &&
              _mCMgr.mPump!.getScannedDeviceLists()!.isNotEmpty) {
            await _mCMgr.mPump!
                .connectToDevice(_mCMgr.mPump!.getScannedDeviceLists()![0]);
          }
          debugPrint(
            'kai:udin:call new device ${_mCMgr.mPump!.getScannedDeviceLists()}',
          );
        }

        //kai_20240116 check previous register callback exit here
        // if use below callback then call cancel here because
        // already statecallback is registered during processing connectToDevice() above
        if (_mCMgr.mPump!.mPumpconnectionSubscription != null) {
          _mCMgr.mPump!.mPumpconnectionSubscription!.cancel();
        }

        _mCMgr.mPump!.registerPumpStateCallback(
          (state) {
            switch (state) {
              case BluetoothDeviceState.connected:
                {
                  _mCMgr.mPump!.ConnectionStatus =
                      BluetoothDeviceState.connected;
                  debugPrint(
                    '$tag:kai:_autoConnect.registerPumpStateCallback.connected',
                  );
                  if (_mCMgr != null &&
                      _mCMgr.mPump != null &&
                      device != null) {
                    _mCMgr.mPump!.ModelName = device.name;
                    _mCMgr.mPump!.changeNotifier();
                    _mCMgr.changeNotifier();
                  }
                }

                break;

              case BluetoothDeviceState.disconnected:
                {
                  _mCMgr.mPump!.ConnectionStatus =
                      BluetoothDeviceState.disconnected;
                  debugPrint(
                    '$tag:kai:_autoConnect.registerPumpStateCallback.disconnected',
                  );
                  if (_mCMgr != null && _mCMgr.mPump != null) {
                    _mCMgr.mPump!.ModelName = '';
                    _mCMgr.mPump!.changeNotifier();
                    _mCMgr.changeNotifier();

                    if (_mCMgr.mPump! is PumpDanars) {
                      //reset the flag here first
                      if (USE_DANAI_CHECK_CONNECTION_COMMAND_SENT) {
                        (_mCMgr.mPump as PumpDanars)
                            .issendPumpCheckAfterConnectFailed = 1;
                        (_mCMgr.mPump as PumpDanars).onRetrying = false;
                        if (USE_CHECK_ENCRYPTION_ENABLED) {
                          (_mCMgr.mPump as PumpDanars).enabledStartEncryption =
                              false;
                        }
                      }
                    }
                  }
                }
                break;

              case BluetoothDeviceState.disconnecting:
                {
                  _mCMgr.mPump!.ConnectionStatus =
                      BluetoothDeviceState.disconnecting;
                }

                break;

              case BluetoothDeviceState.connecting:
                {
                  _mCMgr.mPump!.ConnectionStatus =
                      BluetoothDeviceState.connecting;
                }

                break;
            }
          },
        );
      },
    );
  }

  Future<void> _saveCgm(String id, String code, String deviceId) async {
    GetIt.I<SaveCgmUseCase>()(
      CgmData(
        id: const Uuid().v4(),
        transmitterId: id,
        transmitterCode: code,
        deviceId: deviceId,
        status: true,
        connectAt: DateTime.now(),
      ),
    );
  }

  Future<void> _onXdripOptionSelected(String? deviceId) async {
    debugPrint('kai:index.page.dart:_onXdripOptionSelected($deviceId)');
    debugPrint('kai:call xdrip option selected in connection dialog');
    _selectedXdripOptionId = deviceId;

    //kai_20231127 let's check the Xdrip is installed first here
    final isInstalled = await XDripLauncher.isXdripInstalled();
    if (!isInstalled) {
      //show install is needed to use Xdrip message here
      _showToastMessage(
        (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
            ? _mCMgr.appContext!
            : context,
        '${(USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted) ? _mCMgr.appContext! : context.l10n.appInstallNeeded}',
        'blue',
        0,
      );
      return;
    }
    //let's move to the select page here
    //let's set BGStream Callback here
    switch (deviceId) {
      case 'xdripHome':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await _mCMgr.changeCGM();

        ///< update Cgm instance
        _mCMgr.registerBGStreamDataListen(
          _mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        unawaited(_saveCgm('xdrip', 'xdripHome', deviceId.toString()));
        await XDripLauncher.launchXDripHome();
        break;
      case 'StartSensor':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await _mCMgr.changeCGM();

        ///< update Cgm instance
        _mCMgr.registerBGStreamDataListen(
          _mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        unawaited(_saveCgm('xdrip', 'StartSensor', deviceId.toString()));
        await XDripLauncher.startNewSensor();

        break;
      case 'BGHistory':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await _mCMgr.changeCGM();

        ///< update Cgm instance
        _mCMgr.registerBGStreamDataListen(
          _mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        unawaited(_saveCgm('xdrip', 'BGHistory', deviceId.toString()));
        await XDripLauncher.bgHistory();

        break;
      case 'BluetoothScan':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await _mCMgr.changeCGM();

        ///< update Cgm instance
        _mCMgr.registerBGStreamDataListen(
          _mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        unawaited(_saveCgm('xdrip', 'BluetoothScan', deviceId.toString()));
        await XDripLauncher.bluetoothScan();

        break;

      case 'FakeNumbers':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await _mCMgr.changeCGM();

        ///< update Cgm instance
        debugPrint('kai:FakeNumbers:call _mCMgr.registerBGStreamDataListen( '
            '_mCMgr.mCgm!, _BloodGlucoseDataStreamCallback)');
        _mCMgr.registerBGStreamDataListen(
          _mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});

        unawaited(_saveCgm('xdrip', 'FakeNumbers', deviceId.toString()));
        await XDripLauncher.fakeNumbers();

        break;
    }
  }

  void _onDeviceSelected(String? deviceId) {
    if (mounted) {
      setState(() {
        debugPrint('kai:index.page.dart:_onDeviceSelected($deviceId)');
        _selectedDeviceId = deviceId;
        // _confirmSelectedDeviceId = deviceId;
      });
    } else {
      debugPrint('kai:index.page.dart:_onDeviceSelected($deviceId)');
      _selectedDeviceId = deviceId;
      // _confirmSelectedDeviceId = deviceId;
    }
  }

  void _onTransmitterIdChanged(String value) {
    if (mounted) {
      setState(() {
        _transmitterId = value;
      });
    } else {
      _transmitterId = value;
    }
  }

  void _onValidCodeChanged(String value) {
    if (mounted) {
      setState(() {
        _validCode = int.parse(value);
      });
    } else {
      _validCode = int.parse(value);
    }
  }

  /*
   * @brief let's implement additional service here
   */
  Future<void> _onConnectPressed() async {
    //let's check valid code and transmitter ID here
    debugPrint('kai:index.page.dart:_onConnectPressed($_selectedDeviceId)');
    //kai_20231102 if use virtual as xdrip then use below condition here
    if ((USE_XDRIP_AS_VIRTUAL_CGM == true)
        ? _selectedDeviceId != context.l10n.useXdrip &&
            _selectedDeviceId != context.l10n.virtual
        : _selectedDeviceId != context.l10n.useXdrip) //Use XDrip
    {
      if (_validCode.toString().isEmpty && _transmitterId.toString().isEmpty) {
        _showWarningMessage(
          context,
          context.l10n.putValidCodeNtransmitterID,
        );
        return;
      } else if (_validCode.toString().isEmpty) {
        _showWarningMessage(context, context.l10n.putValidCode);
        return;
      } else if (_transmitterId.toString().isEmpty) {
        _showWarningMessage(context, context.l10n.putTransmitterID);
        return;
      } else if (_validCode.toString().length < maxValidCodeLength) {
        _showWarningMessage(
          context,
          '${context.l10n.invalidCode},$maxValidCodeLength '
          '${context.l10n.digitRequired}',
        );
        return;
      } else if (_transmitterId.toString().length < maxTransmitterIDLength) {
        _showWarningMessage(
          context,
          '${context.l10n.invalidID}, $maxTransmitterIDLength '
          '${context.l10n.digitRequired}',
        );
        return;
      }

      //Update UI
      await CspPreference.setString('dex_txid', _transmitterId!);
      if (mounted) {
        setState(() {
          _isConnecting = true;
        });
      } else {
        _isConnecting = true;
      }

      // Simulate connection attempt
      try {
        debugPrint(
            'kai: check _selectedDeviceId=${_selectedDeviceId.toString()} '
            'here');

        /// 1. update selected Cgm instance here
        /// kai_20231102 if use virtual as xdrip then block below condition here
        if ((USE_XDRIP_AS_VIRTUAL_CGM == true)
            ? _selectedDeviceId == context.l10n.dexcom
            : _selectedDeviceId == context.l10n.dexcom ||
                _selectedDeviceId == context.l10n.virtual) {
          await CspPreference.setString('cgmSourceTypeKey', 'Dexcom');
          ResponseCallback? prevRspCallback;
          if (_mCMgr.mCgm == null) {
            await _mCMgr.changeCGM();
            //kai_20230519 let's backup previous setResponse callback before
            //changing cgm instance here
            prevRspCallback = _mCMgr.mCgm!.getResponseCallbackListener();
          } else {
            //kai_20230519 let's backup previous setResponse callback before
            //changing cgm instance here
            prevRspCallback = _mCMgr.mCgm!.getResponseCallbackListener();
            await _mCMgr.changeCGM();
          }

          if (prevRspCallback != null) {
            // because clearDeviceInfo is always called in this case.
            _mCMgr.registerResponseCallbackListener(
              _mCMgr.mCgm,
              prevRspCallback,
            );
          } else {
            _mCMgr.registerResponseCallbackListener(
              _mCMgr.mCgm,
              _handleCgmResponseCallbackDialogView,
            );
          }

          debugPrint('kai: after call registerResponseCallbackListener()');
        } else if (_selectedDeviceId == context.l10n.iSens) {
          if (USE_ISENSE_BROADCASTING == true) {
            //kai_20231127 add to check caresensAir app is installed first here
            /*
            bool isCaresensAirInstalled = await XDripLauncher.isCareSensAirInstalled();

            if(!isCaresensAirInstalled)
            {
              //show install is needed to use Xdrip message here
              _showToastMessage((USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                  ? _mCMgr.appContext!: context,
                  '${(USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                      ? _mCMgr.appContext!: context.l10n.appInstallNeeded}', 'blue', 0);
              _isConnecting = false;

              if (mounted) {
                Navigator.of(context).pop();
              }

              return;
            }
            else
            {
               XDripLauncher.launchCareSensAir();
            }
            */
            await CspPreference.setString('cgmSourceTypeKey', 'i-sens');
            await _mCMgr.changeCGM();

            ///< update Cgm instance
            _mCMgr.registerBGStreamDataListen(
              _mCMgr.mCgm,
              _bloodGlucoseDataStreamCallback,
            );

            //dismiss dialog here
            debugPrint(
                'kai:CgmIsenseBC:dismiss dialog call _onConnectPressed()');
            _isConnecting = false;
            //kai_20231013 update cgm Model Name here
            if (_mCMgr != null && _mCMgr.mCgm != null) {
              _mCMgr.mCgm!.cgmModelName = context.l10n.iSens;
              _mCMgr.mCgm!.changeNotifier();
              _mCMgr.changeNotifier();
            }

            unawaited(
              _saveCgm(
                _transmitterId.toString(),
                _validCode.toString(),
                _selectedDeviceId.toString(),
              ),
            );

            _showSelectionMessage(
              (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                  ? _mCMgr.appContext!
                  : context,
              _mCMgr.appContext!.l10n.isensCgmIsReadyNow,
            );

            // if (mounted) {
            //   Navigator.of(context).pop();
            // } else {
            //   //kai_20230721 no need  Navigator.of((USE_APPCONTEXT == true &&
            //   //_mCMgr.appContext != null && !mounted) ? _mCMgr.appContext!: context).pop();
            // }

            if (_mCMgr.mPump!.ConnectionStatus !=
                BluetoothDeviceState.connected) {
              //kai_20230830 let's allow to access Pump setup first time only on home page
              if (CspPreference.getBooleanDefaultFalse(
                    CspPreference.pumpSetupfirstTimeDone,
                  ) !=
                  true) {
                // _showPumpDialog();
                _accessType = 'setting_pump';
                setState(() {});
              }
            }

            //kai_20230724 let's skip below procedure in case of CgmIsenseBC
            return;
          } else {
            await CspPreference.setString('cgmSourceTypeKey', 'i-sens');
            ResponseCallback? prevRspCallback;
            if (_mCMgr.mCgm == null) {
              await _mCMgr.changeCGM();
              //kai_20230519 let's backup previous setResponse callback before
              //changing cgm instance here
              prevRspCallback = _mCMgr.mCgm!.getResponseCallbackListener();
            } else {
              //kai_20230519 let's backup previous setResponse callback before
              //changing cgm instance here
              prevRspCallback = _mCMgr.mCgm!.getResponseCallbackListener();
              await _mCMgr.changeCGM();
            }

            ///< update Cgm instance
            if (prevRspCallback != null) {
              // because clearDeviceInfo is always called in this case.
              _mCMgr.registerResponseCallbackListener(
                _mCMgr.mCgm,
                prevRspCallback,
              );
            } else {
              _mCMgr.registerResponseCallbackListener(
                _mCMgr.mCgm,
                _handleCgmResponseCallbackDialogView,
              );
            }
          }
        }

        /// 2. start scanning and stop after 5 secs,
        /// then try to connect the device
        ///    that is detected by using specified device name with
        ///  transmitter ID & valid code automatically.
        if (_mCMgr != null && _mCMgr.mCgm != null) {
          debugPrint('kai: call _mCMgr.mCgm!.startScan(5)');
          await _mCMgr.mCgm!.startScan(5);
        } else {
          debugPrint('kai: _mCMgr.mCgm is null');
        }

        debugPrint('kai: delayed(Duration(seconds: 5)');
        //wait 5 secs until scan is complete
        await Future<void>.delayed(const Duration(seconds: 5), () async {
          debugPrint('kai: after delayed(Duration(seconds: 5)');
          //let's set callback to check result after 5 secs here
          Future<void>.delayed(const Duration(seconds: 5), () async {
            if (debugMessageFlag) {
              debugPrint('kai: after scan _isConnecting = $_isConnecting , '
                  'mounted = $mounted and pop '
                  'dialog:(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                DateTime.now(),
              )})');
            }
            if (_isConnecting = true) {
              if (mounted) {
                setState(() {
                  _isConnecting = false;
                });
              } else {
                _isConnecting = false;
              }
              _mCMgr.mCgm!.changeNotifier();
              _mCMgr.changeNotifier();
              if (mounted) {
                Navigator.of(context).pop();
                if (_mCMgr.mPump!.ConnectionStatus !=
                    BluetoothDeviceState.connected) {
                  //kai_20230830 let's allow to access Pump
                  //setup first time only on home page
                  if (CspPreference.getBooleanDefaultFalse(
                        CspPreference.pumpSetupfirstTimeDone,
                      ) !=
                      true) {
                    await _showPumpDialog();
                  }
                }
              } else {
                /*
                //kai_20230831  blocked
                //Failed assertion: line 74 pos 9: '_matches.isNotEmpty': You have popped the last page off of the stack, there are no pages left to show
                Navigator.of(
                  (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                      ? _mCMgr.appContext!
                      : context,
                ).pop();
                  */
                if (_mCMgr.mPump!.ConnectionStatus !=
                    BluetoothDeviceState.connected) {
                  //kai_20230830 let's allow to access Pump setup first time only on home page
                  if (CspPreference.getBooleanDefaultFalse(
                        CspPreference.pumpSetupfirstTimeDone,
                      ) !=
                      true) {
                    await _showPumpDialog();
                  }
                }
              }
            }
          });

          //scan success case
          debugPrint(
              'kai:check _mCMgr.mCgm!.getScannedDeviceLists()!.isNotEmpty');
          // if(_mCMgr.mCgm!.getScannedDeviceLists()!.isNotEmpty)
          if (_mCMgr.mCgm!.cgmDevices.isNotEmpty) {
            // get last two digit thru CspPreference.getString("dex_txid")
            final transmitter = CspPreference.getString('dex_txid');
            var lastTwoDigits = '';
            if (transmitter != null && transmitter.isNotEmpty) {
              lastTwoDigits = transmitter.substring(transmitter.length - 2);
            } else {}

            final matchName = CspPreference.mCGM_NAME + lastTwoDigits;
            debugPrint('kai:matchName = $matchName');

            for (final dev in _mCMgr.mCgm!.cgmDevices) {
              if (dev.name.contains(matchName)) {
                await _mCMgr.mCgm!.connectToDevice(dev);

                if (_mCMgr.mCgm!.cgmConnectedDevice != null) {
                  debugPrint('kai:success to connect $matchName');
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _showSelectionMessage(
                        context,
                        '${context.l10n.successToCgmConnect} $matchName',
                      );
                    });
                  } else {
                    _isConnecting = false;
                    _showSelectionMessage(
                      (USE_APPCONTEXT == true &&
                              _mCMgr.appContext != null &&
                              !mounted)
                          ? _mCMgr.appContext!
                          : context,
                      '${_mCMgr.appContext!.l10n.successToCgmConnect} $matchName',
                    );
                  }

                  //kai_20231013 update cgm Model Name here
                  if (_mCMgr != null && _mCMgr.mCgm != null) {
                    _mCMgr.mCgm!.cgmModelName = matchName;
                    _mCMgr.mCgm!.changeNotifier();
                    _mCMgr.changeNotifier();
                  }
                } else {
                  debugPrint('kai:fail to connect $matchName');
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _showSelectionMessage(
                        context,
                        '${context.l10n.canNotToCgmConnect} '
                        '$matchName ${context.l10n.atThisTime}',
                      );
                    });
                  } else {
                    _isConnecting = false;
                    _showSelectionMessage(
                      (USE_APPCONTEXT == true &&
                              _mCMgr.appContext != null &&
                              !mounted)
                          ? _mCMgr.appContext!
                          : context,
                      '${_mCMgr.appContext!.l10n.canNotToCgmConnect} '
                      '$matchName ${_mCMgr.appContext!.l10n.atThisTime}',
                    );
                  }
                }

                break;
              } else if (dev.name
                  .toLowerCase()
                  .contains(CspPreference.mCGM_NAME.toLowerCase())) {
                //kai_20230625 consider the case of not using last two digits
                if (debugMessageFlag) {
                  debugPrint('kai:Not use Two digits :call '
                      '_mCMgr.mCgm!.connectToDevice(${dev.name})');
                }
                await _mCMgr.mCgm!.connectToDevice(dev);
                if (debugMessageFlag) {
                  debugPrint('kai:Not use Two digits :after call '
                      '_mCMgr.mCgm!.connectToDevice(${dev.name})');
                }
                if (_mCMgr.mCgm!.cgmConnectedDevice != null) {
                  if (debugMessageFlag) {
                    log(
                      'kai:Not use Two digits :success to connect ${dev.name}',
                    );
                  }
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _showSelectionMessage(
                        context,
                        '${context.l10n.successToCgmConnect} ${dev.name}',
                      );
                    });
                  } else {
                    _isConnecting = false;
                    _showSelectionMessage(
                      (USE_APPCONTEXT == true &&
                              _mCMgr.appContext != null &&
                              !mounted)
                          ? _mCMgr.appContext!
                          : context,
                      '${_mCMgr.appContext!.l10n.successToCgmConnect} '
                      '${dev.name}',
                    );
                  }

                  //kai_20231013 update cgm Model Name here
                  if (_mCMgr != null && _mCMgr.mCgm != null) {
                    _mCMgr.mCgm!.cgmModelName = dev.name;
                    _mCMgr.mCgm!.changeNotifier();
                    _mCMgr.changeNotifier();
                  }
                } else {
                  if (debugMessageFlag) {
                    log(
                      'kai:Not use Two digits :fail to connect ${dev.name}',
                    );
                  }
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _showSelectionMessage(
                          context,
                          '${context.l10n.canNotToCgmConnect} ${dev.name} '
                          '${context.l10n.atThisTime}');
                    });
                  } else {
                    _isConnecting = false;
                    _showSelectionMessage(
                        (USE_APPCONTEXT == true &&
                                _mCMgr.appContext != null &&
                                !mounted)
                            ? _mCMgr.appContext!
                            : context,
                        '${_mCMgr.appContext!.l10n.canNotToCgmConnect} '
                        '${dev.name} '
                        '${_mCMgr.appContext!.l10n.atThisTime}');
                  }
                }
                break;
              }
            }

            if (_isConnecting == true) {
              debugPrint('kai:No matched device in the scan list');
              if (mounted) {
                setState(() {
                  _isConnecting = false;
                  _showSelectionMessage(
                    context,
                    '${context.l10n.noMatchedDevice} $matchName '
                    '${context.l10n.atThisTime}',
                  );
                });
              } else {
                _isConnecting = false;
                _showSelectionMessage(
                  (USE_APPCONTEXT == true &&
                          _mCMgr.appContext != null &&
                          !mounted)
                      ? _mCMgr.appContext!
                      : context,
                  '${_mCMgr.appContext!.l10n.noMatchedDevice} $matchName '
                  '${_mCMgr.appContext!.l10n.atThisTime}',
                );
              }
            }

            _mCMgr.mCgm!.changeNotifier();
          } else {
            //show toast message "There is no scanned cgm device at this
            //time!!, try it again!!" here.
            if (mounted) {
              setState(() {
                _isConnecting = false;
                _showSelectionMessage(
                  context,
                  context.l10n.noScanListAtThisTime,
                );
              });
            } else {
              _isConnecting = false;
              _showSelectionMessage(
                (USE_APPCONTEXT == true &&
                        _mCMgr.appContext != null &&
                        !mounted)
                    ? _mCMgr.appContext!
                    : context,
                _mCMgr.appContext!.l10n.noScanListAtThisTime,
              );
            }
          }
        });
      } catch (e) {
        debugPrint('${tag}kai: startScan failed  $e');
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _showSelectionMessage(
              context,
              context.l10n.scanFailed,
            );
          });
        } else {
          _isConnecting = false;
          _showSelectionMessage(
            (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                ? _mCMgr.appContext!
                : context,
            _mCMgr.appContext!.l10n.scanFailed,
          );
        }
      }

      /// 3. go to the previous CgmPage
      /// Screen after dismiss the ConnectionDialog.
      debugPrint('kai:not Xdrip: dismiss dialog call '
          '_onConnectPressed():mounted($mounted)');
      if (mounted) {
        Navigator.of(context).pop();
      } else {
        //kai_20230721 no need // Navigator.of((USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted) ? _mCMgr.appContext!: context).pop();
      }

      if (_mCMgr.mPump!.ConnectionStatus != BluetoothDeviceState.connected) {
        //kai_20230830 let's allow to access
        //Pump setup first time only on home page
        if (CspPreference.getBooleanDefaultFalse(
              CspPreference.pumpSetupfirstTimeDone,
            ) !=
            true) {
          await _showPumpDialog();
        }
      }
    } else {
      //dismiss dialog here
      debugPrint(
        'kai:Xdrip:dismiss dialog call _onConnectPressed():mounted($mounted)',
      );
      //kai_20230613 if call below Navigator.of(context).pop() w/o _showPumpDialog() then context does not valid.
      // so we have to call together
      if (mounted) {
        Navigator.of(context).pop();
      } else {
        //kai_20230721 no need  Navigator.of((USE_APPCONTEXT == true &&
        //_mCMgr.appContext != null && !mounted) ?
        //_mCMgr.appContext!: context).pop();
      }

      if (_mCMgr.mPump!.ConnectionStatus != BluetoothDeviceState.connected) {
        //kai_20230830 let's allow to access Pump
        //setup first time only on home page
        if (CspPreference.getBooleanDefaultFalse(
              CspPreference.pumpSetupfirstTimeDone,
            ) !=
            true) {
          await _showPumpDialog();
        }
      }
    }
  }

  /*
   * @fn updateInsulinDeliveryDialogView(String bolus)
   * @brief update bolus data and emit it to server
   *        this API is used in DialogView
   * @param[in] Glucose : String double bolus data
   */
  Future<void> _updateInsulinDeliveryDialogView(
    String bolus,
    ReportSource source,
  ) async {
    debugPrint(
      '${tag}kai:_updateInsulinDeliveryDialogView:setDose = $setDose , '
      'mounted = $mounted',
    );

    // get autoMode from local database
    final autoMode = (await GetIt.I<GetAutoModeUseCase>().call(
      const NoParams(),
    ))
        .foldRight(
      0,
      (r, previous) => r,
    );

    // get announceMeal from local database
    final announceMeal = (await GetIt.I<GetAnnounceMealUseCase>().call(
      const NoParams(),
    ))
        .foldRight(
      0,
      (r, previous) => r,
    );

    if (!setDose) {
      setDose = true;
      debugPrint(
        '${tag}kai:_updateInsulinDeliveryDialogView:set true for setDose '
        '= $setDose',
      );
      if (FORCE_BGLUCOSE_UPDATE_FLAG) {
        final pumpInsulinDelivery = InputInsulinBloc(inputInsulin: getIt())
          ..add(InputInsulinValueChanged(value: double.parse(bolus)));
        if (debugMessageFlag) {
          debugPrint(
              '${tag}kia:updateInsulinDeliveryDialogView: before status = '
              '${pumpInsulinDelivery.state.status.isValidated}');
        }
        // pumpInsulinDelivery.add(InputInsulinSubmitted());  ///< updated by User
        pumpInsulinDelivery.add(
          InputInsulinSubmitted(
            source: source,
            announceMeal: announceMeal > 0,
            autoMode: autoMode > 0,
            iob: _iob,
            hypoPrevention: 0,
          ),
        );
        _mCMgr.changeNotifier();

        ///< updated by sensor
      }
    }
  }

  /*
   * @brief show toast message on the bottom of the screen
   */
  void showMsgProgress(
    BuildContext context,
    String message,
    String colorType,
    int showingTime,
  ) {
    var showingDuration = 3;
    var _color = Colors.blueAccent[700];

    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      showingDuration = showingTime;
    }

    switch (colorType.toLowerCase()) {
      case 'red':
        _color = Colors.redAccent[700];
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

    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: showingDuration),
      backgroundColor: _color,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    final overlayState = Overlay.of(context)!;
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 50,
        left: MediaQuery.of(context).size.width / 2 - 50,
        width: 100,
        height: 100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_color!),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Timer(Duration(seconds: showingDuration), () {
      overlayEntry.remove();
    });
  }

  void _showToastMessage(
    BuildContext context,
    String msg,
    String colorType,
    int showingTime,
  ) {
    var _color = Colors.blueAccent[700];
    var showingDuration = 2;

    ///< default 2 secs
    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      showingDuration = showingTime;
    }

    switch (colorType.toLowerCase()) {
      case 'red':
        {
          _color = Colors.redAccent[700];

          //kai_20231021 let's playback alert onetime here
          if (USE_AUDIO_PLAYBACK == true) {
            if (_csaudioPlayer == null) {
              _csaudioPlayer = CsaudioPlayer();
            }
            _csaudioPlayer.playAlertOneTime('battery');

            if (_csaudioPlayer != null) {
              _csaudioPlayer.playAlertOneTime('battery');
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
        content: Text(msg),
        duration: Duration(seconds: showingDuration),
      ),
    );
  }

  Timer? debounceTimer;
  int debounceDuration = 2;
  int showingDuration = 2;
  String lastMessage = '';

  void showToastMessageDebounce(
    BuildContext context,
    String newMessage,
    String colorType,
    int showingTime,
  ) {
    var _color = Colors.blueAccent[700];
    var showingDuration = 2;

    ///< default 2 secs
    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      showingDuration = showingTime;
    }

    switch (colorType.toLowerCase()) {
      case 'red':
        {
          _color = Colors.redAccent[700];
          //kai_20231021 let's playback alert onetime here
          if (USE_AUDIO_PLAYBACK == true) {
            if (_csaudioPlayer == null) {
              _csaudioPlayer = CsaudioPlayer();
            }
            if (_csaudioPlayer != null) {
              _csaudioPlayer.playAlertOneTime('battery');
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

    if (debounceTimer != null && debounceTimer!.isActive) {
      debounceTimer!.cancel();
    }

    if (newMessage != lastMessage) {
      debounceTimer = Timer(Duration(seconds: debounceDuration), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _color,
            content: Text(newMessage),
            duration: Duration(seconds: showingDuration),
          ),
        );
        lastMessage = newMessage;
      });
    }
  }

  /*
   * @breif show Warning message with audio playback
   */
  void warningMsgDlg(String title, String msg, String colorType, int showTime) {
    var _title = 'Warning';
    Color _color = Colors.red;

    if (showTime > 0) {
      //let's showToast Message with duration showTime
      _showToastMessage(
        (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
            ? _mCMgr.appContext!
            : context,
        msg,
        colorType,
        showTime,
      );
      return;
    }

    if (title.isNotEmpty && title.isNotEmpty) {
      _title = title;
    }

    switch (colorType) {
      case 'red':
        _color = Colors.red;
        break;

      case 'blue':
        _color = Colors.blue;
        break;

      case 'green':
        _color = Colors.green;
        break;

      default:
        _color = Colors.red;
        break;
    }

    // create dialog and start alert playback onetime
    if (USE_AUDIO_PLAYBACK == true) {
      if (_csaudioPlayer == null) {
        _csaudioPlayer = CsaudioPlayer();
      }
      if (_csaudioPlayer != null) {
        if (_csaudioPlayer.isPlaying == true) {
          _csaudioPlayer.stop();
          _csaudioPlayer.isPlaying = false;
        }
        // _csaudioPlayer.playLowBatAlert();
        // _csaudioPlayer.loopAssetsAudio();
        _csaudioPlayer.playAlert('battery');
        // _csaudioPlayer.loopAssetsAudioOcclusion();
      } else {
        debugPrint(
            'kai:homePage:WarningMsgDlg:_csaudioPlayer is null:can not call '
            '_csaudioPlayer.loopAssetsAudio()');
      }
    }
    showDialog<BuildContext>(
      context: (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
          ? _mCMgr.appContext!
          : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        // _USE_GLOBAL_KEY //   key: _key,
        title: Container(
          decoration: BoxDecoration(
            color: _color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimens.dp10),
              topRight: Radius.circular(Dimens.dp10),
            ),
          ),
          padding: const EdgeInsets.all(Dimens.dp14),
          child: Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Dimens.dp16,
            ),
          ),
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.normal,
            fontSize: Dimens.dp16,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.dp10),
        ),
        actions: [
          TextButton(
            onPressed: () {
              //send "BZ1=0" to stop  buzzer in csp-1
              //_mCMgr.mPump!.SendMessage2Pump('BZ1=0');
              _mCMgr.mPump!.pumpTxCharacteristic!.write(utf8.encode('BZ2=0'));
              //stop playback alert
              if (USE_AUDIO_PLAYBACK == true) {
                if (_csaudioPlayer != null) {
                  _csaudioPlayer.stopAlert();
                  //_csaudioPlayer.stopAssetsAudio();
                } else {
                  debugPrint(
                      'kai:homePage:WarningMsgDlg:_csaudioPlayer is null:can '
                      'not call _csaudioPlayer.stopAssetsAudio()');
                }
              }

              Navigator.of(
                (USE_APPCONTEXT == true &&
                        _mCMgr.appContext != null &&
                        !mounted)
                    ? _mCMgr.appContext!
                    : context,
              ).pop();
            },
            child: Text(_mCMgr.appContext!.l10n.dismiss),
          ),
        ],
      ),
    );
  }

  void showTXErrorMsgDialog(String title, String message) {
    final titleDialog = title;
    final msgDialog = message;

    // create dialog and start alert playback onetime
    if (USE_AUDIO_PLAYBACK == true) {
      if (_csaudioPlayer == null) {
        _csaudioPlayer = CsaudioPlayer();
      }

      if (_csaudioPlayer != null) {
        if (_csaudioPlayer.isPlaying == true) {
          _csaudioPlayer.stop();
          _csaudioPlayer.isPlaying = false;
        }

        // _csaudioPlayer.playLowBatAlert();
        _csaudioPlayer.playAlertOneTime('battery');
      } else {
        debugPrint(
            'kai:homePage:showTXErrorMsgDialog:_csaudioPlayer is null:can not '
            'call _csaudioPlayer.playLowBatAlert()');
      }
    }

    showDialog<BuildContext>(
      context: (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
          ? _mCMgr.appContext!
          : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        // _USE_GLOBAL_KEY  // key: _key,
        title:
            //Text('Alert'),
            Container(
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Dimens.dp10),
              topRight: Radius.circular(Dimens.dp10),
            ),
          ),
          padding: const EdgeInsets.all(Dimens.dp14),
          child: Text(
            titleDialog,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Dimens.dp16,
            ),
          ),
        ),
        content: Text(
          msgDialog,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.normal,
            fontSize: Dimens.dp16,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.dp10),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (USE_AUDIO_PLAYBACK == true) {
                if (_csaudioPlayer != null) {
                  _csaudioPlayer.stop();
                } else {
                  debugPrint(
                      'kai:homePage:showTXErrorMsgDialog:_csaudioPlayer is '
                      'null:can not call _csaudioPlayer.stop()');
                }
              }
              //let's try it again here
              Navigator.of(
                (USE_APPCONTEXT == true &&
                        _mCMgr.appContext != null &&
                        !mounted)
                    ? _mCMgr.appContext!
                    : context,
              ).pop();
            },
            child: Text(_mCMgr.appContext!.l10n.ok),
          ),
          TextButton(
            onPressed: () {
              if (USE_AUDIO_PLAYBACK == true) {
                if (_csaudioPlayer != null) {
                  _csaudioPlayer.stop();
                } else {
                  debugPrint(
                      'kai:homePage:showTXErrorMsgDialog:_csaudioPlayer is '
                      'null:can not call _csaudioPlayer.stop()');
                }
              }
              Navigator.of(
                (USE_APPCONTEXT == true &&
                        _mCMgr.appContext != null &&
                        !mounted)
                    ? _mCMgr.appContext!
                    : context,
              ).pop();
            },
            child: Text(_mCMgr.appContext!.l10n.dismiss),
          ),
        ],
      ),
    );
  }

  void _showSetupWizardMsgDialog(
    String title,
    String message,
    String actionType,
  ) {
    final titleDialog = title;
    final msgDialog = message;
    final actionTypeDialog = actionType;
    var inputText = '';
    var enableTextField = true;

    ///< enable/disable TextField
    const readOnlyTextField = false;

    ///< block typing something
    var hintStringTextField = _mCMgr.appContext!.l10n.enterYourInput;

    switch (actionType) {
      case 'HCL_DOSE_CANCEL_REQ':
        enableTextField = false;
        hintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = _mCMgr.appContext!.l10n.cancelInjectionDose;
        break;

      case 'PATCH_DISCARD_REQ':
        enableTextField = false;
        hintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = _mCMgr.appContext!.l10n.discardPatch;
        break;

      case 'SAFETY_CHECK_REQ':
      case 'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST':
        enableTextField = false;
        hintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = _mCMgr.appContext!.l10n.safetyCheck;
        break;

      case 'PATCH_INFO_REQ':
        enableTextField = false;
        hintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = _mCMgr.appContext!.l10n.patchInfoRequest;
        break;

      case 'CANNULAR_INSERT_RPT_SUCCESS':
      case 'CANNULAR_INSERT_RSP_SUCCESS':
      case 'INFUSION_INFO_RPT_SUCCESS':
      case 'INFUSION_INFO_RPT_REMAIN_AMOUNT':
      case 'INFUSION_INFO_RPT_30MIN_REPEATEDLY':
      case 'INFUSION_INFO_RPT_RECONNECTED':
      case 'SET_TIME_RSP_SUCCESS':
      case 'PATCH_INFO_RPT1_SUCCESS':
      case 'PATCH_INFO_RPT2_SUCCESS':
      case 'SAFETY_CHECK_RSP_SUCCESS':
      case 'SAFETY_CHECK_RSP_GOT_1STRSP':
      case 'HCL_BOLUS_CANCEL_RSP_SUCCESS':
        {
          ///kai_20231011 let's update setting screen
          _mCMgr.changeNotifier();
          //kai_20230510 if processing dialog is showing now, then
          // dismiss it also here
          _showToastMessage(
            (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                ? _mCMgr.appContext!
                : context,
            msgDialog,
            'blue',
            0,
          );
        }
        break;
      case 'PATCH_NOTICE_RPT':
      case 'BUZZER_CHECK_RSP_SUCCESS':
      case 'PATCH_DISCARD_RSP_SUCCESS':
      case 'PATCH_RESET_RPT_SUCCESS_MODE0':
      case 'PATCH_RESET_RPT_SUCCESS_MODE1':
      case 'BUZZER_CHANGE_RSP_SUCCESS':
        {
          _showToastMessage(
            (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                ? _mCMgr.appContext!
                : context,
            msgDialog,
            'blue',
            0,
          );
        }
        break;

      case 'HCL_BOLUS_RSP_SUCCESS':
        {
          //let's update dose injection result here
          // update local DB & Remote DB thru cloudLoop
          _showToastMessage(
            (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                ? _mCMgr.appContext!
                : context,
            msgDialog,
            'blue',
            0,
          );
        }
        break;

      case 'SET_TIME_RSP_FAILED':
      case 'SAFETY_CHECK_RSP_LOW_INSULIN':
      case 'SAFETY_CHECK_RSP_ABNORMAL_PUMP':
      case 'SAFETY_CHECK_RSP_LOW_VOLTAGE':
      case 'SAFETY_CHECK_RSP_FAILED':
      case 'INFUSION_THRESHOLD_RSP_FAILED':
      case 'HCL_BOLUS_RSP_FAILED':
      case 'HCL_BOLUS_RSP_OVERFLOW':
      case 'HCL_BOLUS_CANCEL_RSP_FAILED':
      case 'CANNULAR_INSERT_RPT_FAILED':
      case 'CANNULAR_INSERT_RSP_FAILED':
      case 'PATCH_DISCARD_RSP_FAILED':
      case 'BUZZER_CHECK_RSP_FAILED':
      case 'BUZZER_CHANGE_RSP_FAILED':
        {
          _showToastMessage(
            (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                ? _mCMgr.appContext!
                : context,
            msgDialog,
            'red',
            0,
          );
        }
        break;

      case 'SET_TIME_REQ':
      case 'INFUSION_THRESHOLD_REQ':
      case 'HCL_DOSE_REQ':
      case 'INFUSION_INFO_REQ':
      case 'PATCH_RESET_REQ':
        enableTextField = true;
        hintStringTextField = _mCMgr.appContext!.l10n.enterYourInput;
        break;

      default:
        return;
    }

    debugPrint(
      'kai:check _key.currentContext == Null , lets create dialog here',
    );
    showDialog<BuildContext>(
      context: (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
          ? _mCMgr.appContext!
          : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        // _USE_GLOBAL_KEY //  key: _key,
        title:
            //Text('Alert'),
            Container(
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Dimens.dp10),
              topRight: Radius.circular(Dimens.dp10),
            ),
          ),
          padding: const EdgeInsets.all(Dimens.dp14),
          child: Text(
            titleDialog,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Dimens.dp16,
            ),
          ),
        ),
        titlePadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msgDialog,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
                fontSize: Dimens.dp16,
              ),
            ),
            TextField(
              enabled: enableTextField,

              ///< let's handle enable/disable based on ActionType
              onChanged: (value) {
                inputText = value;
              },
              decoration: InputDecoration(
                hintText: hintStringTextField,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.dp10),
        ),
        actions: [
          TextButton(
            onPressed: () {
              //let's check inputText is empty first
              log(
                'kai: press OK Button: _ActionType = $ActionType',
              );
              if (inputText.isNotEmpty) {
                final type = actionTypeDialog;
                debugPrint('kai: _ActionType = $type');
                switch (type) {
                  case 'SET_TIME_REQ':

                    ///< 0x11 : set total injected insulin amount : reservoir
                    {
                      // Date/Time,Injection amount, HCL Mode
                      // put reservoir injection amount here 1 ~ 300 U ( 2mL ~ 3mL )
                      final value = int.parse(inputText);
                      if (value > 300 || value < 1) {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} '
                              ': 10 ~ 200',
                          'red',
                          0,
                        );
                      } else {
                        CspPreference.setString(
                          CspPreference.pumpReservoirInjectionKey,
                          inputText,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                        ).pop();
                        _mCMgr.mPump!
                            .SendSetTimeReservoirRequest(value, 0x01, null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          '${_mCMgr.appContext!.l10n.sendingTimeNInjectInsulinAmount}($value)U ...',
                          'blue',
                          0,
                        );
                      }
                    }
                    break;

                  case 'INFUSION_THRESHOLD_REQ':

                    ///< 0x17 : 인슐린 주입 임계치 설정 요청
                    {
                      // TYPE: 최대 주입 량 설정 (0x01)
                      // 최대 볼러스 주입 량 (U, 2 byte: 정수+ 소수점 X 100) : 입력 범위 0.5 ~ 25 U
                      // 사용자가 설정 메뉴 중 볼러스 주입 정보의 최대 볼러스 량 정보를 재 설정하면 본 메시지가 송신된다.
                      //int value = int.parse(inputText)*100; ///< scaling by 100
                      if (!inputText.contains('.')) {
                        // in case that no floating point on the typed String sequence
                        inputText = '$inputText.0';
                      }
                      final value = (double.parse(inputText) * 100).toInt();
                      if (value > 2500 || value < 50)

                      ///< scaled range from 25 ~ 0.5
                      {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} '
                              ': 0.5 ~ 25',
                          'red',
                          0,
                        );
                      } else {
                        CspPreference.setString(
                          CspPreference.pumpMaxInfusionThresholdKey,
                          inputText,
                        );
                        _mCMgr.mPump!
                            .sendSetMaxBolusThreshold(inputText, 0x01, null);

                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          // ignore: lines_longer_than_80_chars
                          '${_mCMgr.appContext!.l10n.sendingMaxBolusInjectionAmount}($inputText)U ...',
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                        ).pop();
                      }
                    }
                    break;

                  case 'HCL_DOSE_REQ':

                    ///< 0x67 : Bolus/ Dose injection
                    {
                      // Mode (1 byte): HCL 통합 주입(0x00), 교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
                      // HCLBy APP” 모드에서 기저와 볼러스 주입이 통합된 자동 모드에서 주입할 인슐린 총량을 주입하기위해 사용
                      // HCL By App” 모드에서 교정 볼러스 주입 제어 알고리즘에 의한 교정 볼러스 계산기 주입 값을 가감한
                      // 최종 교정 볼러스 주입량이 있으면 본 메시지를 패치로 전송한다.
                      //int value = int.parse(inputText)*100; ///< scaling by 100
                      if (!inputText.contains('.')) {
                        // in case that no floating point on the typed String sequence
                        inputText = '$inputText.0';
                      }
                      final value = (double.parse(inputText) * 100).toInt();
                      if (value > 2500 || value < 1)

                      ///< scaled range from 25 ~ 0.01
                      {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} '
                              ': 0.01 ~ 25',
                          'red',
                          0,
                        );
                      } else {
                        //kai_20230427 let's check isDoseInjectingNow is true
                        if (_mCMgr.mPump!.isDoseInjectingNow == true) {
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                          ).pop();

                          ///< due to toast popup is showing behind the active dialog
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            _mCMgr.appContext!.l10n.doseProcessingMsg,
                            'red',
                            0,
                          );
                          // ko : 펌프가 이전 도즈 주입을 처리중입니다.처리가 완료 될때 까지 잠시만 기다려 주세요.
                        } else {
                          CspPreference.setString(
                            CspPreference.pumpHclDoseInjectionKey,
                            inputText,
                          );
                          _mCMgr.mPump!.sendSetDoseValue(inputText, 0x00, null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            '${_mCMgr.appContext!.l10n.sendingDoseAmount}($inputText)U ...',
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  case 'HCL_DOSE_CANCEL_REQ':
                    {
                      log(
                        'kai: HCL_DOSE_CANCEL_REQ: enableTextField = $enableTextField',
                      );
                      if (enableTextField == false) {
                        _mCMgr.mPump!.cancelSetDoseValue(0x00, null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          _mCMgr.appContext!.l10n
                              .sendingDoseInjectionCancelRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                        ).pop();
                      } else {
                        //int value = int.parse(inputText)*100; ///< scaling by 100
                        if (!inputText.contains('.')) {
                          // in case that no floating point on the typed String sequence
                          inputText = '$inputText.0';
                        }
                        final value = (double.parse(inputText) * 100).toInt();
                        if (value > 2500 || value < 50)

                        ///< scaled range from 25 ~ 0.5
                        {
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            // ignore: lines_longer_than_80_chars
                            '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.5 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          _mCMgr.mPump!.cancelSetDoseValue(0x00, null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            _mCMgr.appContext!.l10n
                                .sendingDoseInjectionCancelRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  case 'PATCH_DISCARD_REQ':
                    {
                      if (enableTextField == false) {
                        _mCMgr.mPump!.sendDiscardPatch(null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          _mCMgr.appContext!.l10n.sendingDiscardPatchRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                        ).pop();
                      } else {
                        //int value = int.parse(inputText)*100; ///< scaling by 100
                        if (!inputText.contains('.')) {
                          // ignore: lines_longer_than_80_chars
                          // in case that no floating point on the typed String sequence
                          inputText = '$inputText.0';
                        }
                        final value = (double.parse(inputText) * 100).toInt();
                        if (value > 2500 || value < 50)

                        ///< scaled range from 25 ~ 0.5
                        {
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            // ignore: lines_longer_than_80_chars
                            '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.5 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          _mCMgr.mPump!.sendDiscardPatch(null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            _mCMgr.appContext!.l10n.sendingDiscardPatchRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  case 'INFUSION_INFO_REQ':
                    {
                      final value = int.parse(inputText);
                      if (value > 1 || value < 0)

                      ///< scaled range from 0 ~ 1
                      {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          // ignore: lines_longer_than_80_chars
                          '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                          'red',
                          0,
                        );
                      } else {
                        _mCMgr.mPump!.sendInfusionInfoRequest(
                          int.parse(inputText),
                          null,
                        );
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          _mCMgr.appContext!.l10n.sendingInfusionInfoRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                        ).pop();
                      }
                    }
                    break;

                  case 'SAFETY_CHECK_REQ':
                  case 'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST':
                    {
                      if (enableTextField == false) {
                        _mCMgr.mPump!.sendSafetyCheckRequest(null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          _mCMgr.appContext!.l10n.sendingSafetyCheckRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                        ).pop();
                      } else {
                        final value = int.parse(inputText);
                        if (value > 1 || value < 0)

                        ///< scaled range from 0 ~ 1
                        {
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            // ignore: lines_longer_than_80_chars
                            '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                            'red',
                            0,
                          );
                        } else {
                          _mCMgr.mPump!.sendSafetyCheckRequest(null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            _mCMgr.appContext!.l10n.sendingSafetyCheckRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  case 'PATCH_RESET_REQ':
                    {
                      final value = int.parse(inputText);
                      if (value > 1 || value < 0)

                      ///< scaled range from 0 ~ 1
                      {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          // ignore: lines_longer_than_80_chars
                          '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                          'red',
                          0,
                        );
                      } else {
                        _mCMgr.mPump!
                            .sendResetPatch(int.parse(inputText), null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          _mCMgr.appContext!.l10n.sendingResetRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                        ).pop();
                      }
                    }
                    break;

                  case 'PATCH_INFO_REQ':
                    {
                      if (enableTextField == false) {
                        _mCMgr.mPump!.sendPumpPatchInfoRequest(null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                          _mCMgr.appContext!.l10n.sendingPatchInfoRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  _mCMgr.appContext != null &&
                                  !mounted)
                              ? _mCMgr.appContext!
                              : context,
                        ).pop();
                      } else {
                        //int value = int.parse(inputText)*100; ///< scaling by 100
                        if (!inputText.contains('.')) {
                          // 입력된 문자열에 소수점이 없는 경우
                          inputText = '$inputText.0';
                        }
                        final value = (double.parse(inputText) * 100).toInt();
                        if (value > 2500 || value < 50)

                        ///< scaled range from 25 ~ 0.5
                        {
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            // ignore: lines_longer_than_80_chars
                            '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.5 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          _mCMgr.mPump!.sendPumpPatchInfoRequest(null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            _mCMgr.appContext!.l10n.sendingPatchInfoRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  default:
                    {
                      Navigator.of(
                        (USE_APPCONTEXT == true &&
                                _mCMgr.appContext != null &&
                                !mounted)
                            ? _mCMgr.appContext!
                            : context,
                      ).pop();
                    }
                    break;
                }
              }
            },
            child: Text(_mCMgr.appContext!.l10n.ok),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                (USE_APPCONTEXT == true &&
                        _mCMgr.appContext != null &&
                        !mounted)
                    ? _mCMgr.appContext!
                    : context,
              ).pop();
            },
            child: Text(_mCMgr.appContext!.l10n.cancel),
          ),
        ],
      ),
    );
  }

  /*
   * @fn _handlePumpResponseCallbackDialogView(RSPType indexRsp, String
   * message, String ActionType)
   * @brief when bolus injection is success then pushing the data to remote 
   * DB by using this API.
   *        this API is used in DialogView
   * @param[in] indexRsp : RESPType index
   * @param[in] message : message
   * @param[in] ActionType : pump protocol Command Type
   */
  void _handlePumpResponseCallbackDialogView(
    RSPType indexRsp,
    String message,
    String actionType,
  ) {
    if (_mCMgr.mPump == null) {
      debugPrint(
          'kai:_handlePumpResponseCallbackDialogView():_mCMgr.mPump is null!!: '
          'Cannot handle the response event!! ');
      return;
    }

    debugPrint(
      '${tag}kai:_handlePumpResponseCallbackDialogView() is called, mounted = '
      '$mounted',
    );
    debugPrint('${tag}kai:RSPType($indexRsp)'
        '\nmessage($message)\nActionType($actionType)');

    switch (indexRsp) {
      case RSPType.PROCESSING_DONE:
        {
          // To do something here after receive the processing result
          if (actionType == HCL_BOLUS_RSP_SUCCESS) {
            //kai_20230613 add to update insulin delivery chart and DB here
            if (_mCMgr != null && _mCMgr.mPump != null) {
              //kai_20230712  final insulDelivery =
              //_mCMgr.mPump!.BolusDeliveryValue;
              setDose = false;
              final insulDelivery = _mCMgr.mPump!.getBolusDeliveryValue();
              final source = _mCMgr.mPump!.getInsulinSource();
              debugPrint('kai:HCL_BOLUS_RSP_SUCCESS:'
                  'BolusDeliveryValue(${insulDelivery.toString()}), call '
                  'updateInsulinDeliveryDialogView()');
              _updateInsulinDeliveryDialogView(
                insulDelivery.toString(),
                source,
              );
              _mCMgr.changeNotifier();
            }
          }
        }
        break;

      case RSPType.TOAST_POPUP:
        {
          debugPrint('${tag}kai:TOAST_POPUP: redraw Screen widgits gas');
        }
        {
          // Pump _notifier = _mCMgr.mPump!;

          final msg = message;
          // String Title = '${(USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted) ? _mCMgr.appContext!: context.l10n.processing}';
          final type = actionType;
          _mCMgr.mPump!.showNoticeMsgDlg = false;
          _mCMgr.mPump!.SetUpWizardMsg = '';

          ///< clear
          _mCMgr.mPump!.SetUpWizardActionType = '';

          //kai_20230512 let's call connectivityMgr.notifyListener() to notify bolus injection processing time & value
          // for consumer or selector page
          _mCMgr.changeNotifier();

          showMsgProgress(
            (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                ? _mCMgr.appContext!
                : context,
            msg,
            'blue',
            int.parse(type),
          );
        }

        break;

      case RSPType.ALERT:
        {
          debugPrint('${tag}kai:ALERT: redraw Screen widgits ');
        }
        if (_mCMgr.mPump!.showALertMsgDlg) {
          final msg = _mCMgr.mPump!.AlertMsg;
          final title = _mCMgr.appContext!.l10n.alert;
          _mCMgr.mPump!
            ..showALertMsgDlg = false
            ..AlertMsg = '';

          ///< clear
          //  _showTXErrorMsgDialog(Title,Msg);
          // create dialog and start alert playback onetime
          warningMsgDlg(title, msg, 'red', 5);
        }

        break;

      case RSPType.NOTICE:
        {
          debugPrint('${tag}kai:NOTICE: show toast message ');
          final msg = _mCMgr.mPump!.NoticeMsg;
          final type = actionType;
          _mCMgr.mPump!.showNoticeMsgDlg = false;
          _mCMgr.mPump!.NoticeMsg = '';
          // _showToastMessage(context,Msg,'blue',int.parse(Type));
          showToastMessageDebounce(
            (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
                ? _mCMgr.appContext!
                : context,
            msg,
            'blue',
            int.parse(
              type,
            ),
          );
          //kai_20240109 should call below to refresh changed variable on the Pump info of setting page.
          _mCMgr.changeNotifier();
        }
        break;

      case RSPType.ERROR:
        {
          debugPrint('${tag}kai:ERROR: redraw Screen widgits ');
        }
        if (_mCMgr.mPump!.showTXErrorMsgDlg) {
          //let' clear variable here after copy them to buffer
          final msg = _mCMgr.mPump!.TXErrorMsg;
          final title = _mCMgr.appContext!.l10n.error;
          _mCMgr.mPump!
            ..showTXErrorMsgDlg = false
            ..TXErrorMsg = '';

          ///< clear
          showTXErrorMsgDialog(title, msg);
        }

        break;

      case RSPType.WARNING:
        {
          debugPrint('${tag}kai:WARNING: redraw Screen widgits ');
        }
        if (_mCMgr.mPump!.showWarningMsgDlg) {
          final msg = _mCMgr.mPump!.WarningMsg;
          final title = _mCMgr.appContext!.l10n.warning;
          _mCMgr.mPump!.showWarningMsgDlg = false;
          //  _notifier.WarningMsg = '';  ///< clear

          //kai_20230512 let's call connectivityMgr.notifyListener() to notify bolus injection processing time & value
          // for consumer or selector page
          _mCMgr.changeNotifier();

          //  _showTXErrorMsgDialog(Title,Msg);
          // create dialog and start alert playback onetime
          warningMsgDlg(title, msg, 'red', 0);
        }

        break;

      case RSPType.SETUP_INPUT_DLG:
        {
          debugPrint('${tag}kai:SETUP_INPUT_DLG: redraw Screen widgits ');
          // Pump _notifier = _mCMgr.mPump!;
          final msg = message;
          final title = _mCMgr.appContext!.l10n.setup;
          final type = actionType;
          _mCMgr.mPump!
            ..showNoticeMsgDlg = false
            ..SetUpWizardMsg = ''

            ///< clear
            ..SetUpWizardActionType = '';
          _showSetupWizardMsgDialog(title, msg, type);
        }
        break;

      case RSPType.SETUP_DLG:
        {
          debugPrint('${tag}kai:SETUP_DLG: redraw Screen widgits ');
          final msg = message;
          final title = _mCMgr.appContext!.l10n.setup;
          final type = actionType;
          _mCMgr.mPump!
            ..showNoticeMsgDlg = false
            ..SetUpWizardMsg = ''

            ///< clear
            ..SetUpWizardActionType = '';
          _showSetupWizardMsgDialog(title, msg, type);
        }
        break;

      case RSPType.UPDATE_SCREEN:
        {
          //update screen, redraw
          // setState(() {
          //   //kai_20230502
          //   debugPrint('${tag}kai:Pump:UPDATE_SCREEN: redraw Screen widgits ');
          // });

          switch (actionType) {
            case 'DISCONNECT_PUMP_FROM_USER_ACTION':
              {
                debugPrint('${tag}kai:DISCONNECT_PUMP_FROM_USER_ACTION');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${CspPreference.mPUMP_NAME} ${context.l10n.disconnectByUSer}',
                    );
                  });
                } else {
                  _showMessage(
                    (USE_APPCONTEXT == true &&
                            _mCMgr.appContext != null &&
                            !mounted)
                        ? _mCMgr.appContext!
                        : context,
                    '${CspPreference.mPUMP_NAME} ${_mCMgr.appContext!.l10n.disconnectByUSer}',
                  );
                }

                _mCMgr.changeNotifier();
              }
              break;

            case 'DISCONNECT_FROM_DEVICE_PUMP':
              {
                debugPrint('${tag}kai:DISCONNECT_FROM_DEVICE_PUMP');
                if (mounted) {
                  setState(() {
                    _showWarningMessage(
                      context,
                      '${CspPreference.mPUMP_NAME} ${context.l10n.disconnectDevice}',
                    );
                  });
                } else {
                  _showWarningMessage(
                    (USE_APPCONTEXT == true &&
                            _mCMgr.appContext != null &&
                            !mounted)
                        ? _mCMgr.appContext!
                        : context,
                    '${CspPreference.mPUMP_NAME} ${_mCMgr.appContext!.l10n.disconnectDevice}',
                  );
                }

                _mCMgr.changeNotifier();
                //kai_20230612 we need to consider auto reconnection in this
                //case in order to keep use the service.
              }
              break;

            case 'CONNECT_TO_DEVICE_PUMP':
              {
                debugPrint('${tag}kai:CONNECT_TO_DEVICE_PUMP');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${CspPreference.mPUMP_NAME} ${context.l10n.hasBeenConnected}',
                    );
                  });
                } else {
                  _showMessage(
                    (USE_APPCONTEXT == true &&
                            _mCMgr.appContext != null &&
                            !mounted)
                        ? _mCMgr.appContext!
                        : context,
                    '${CspPreference.mPUMP_NAME} ${_mCMgr.appContext!.l10n.hasBeenConnected}',
                  );
                }

                _mCMgr.changeNotifier();
              }
              break;

            case 'TIMEOUT_CONNECT_TO_DEVICE_PUMP':
              {
                debugPrint('${tag}kai:TIMEOUT_CONNECT_TO_DEVICE_PUMP');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${context.l10n.timeoutForConnecting} ${CspPreference.mPUMP_NAME}!!',
                    );
                  });
                } else {
                  _showMessage(
                    (USE_APPCONTEXT == true &&
                            _mCMgr.appContext != null &&
                            !mounted)
                        ? _mCMgr.appContext!
                        : context,
                    '${_mCMgr.appContext!.l10n.timeoutForConnecting} ${CspPreference.mPUMP_NAME}!!',
                  );
                }

                _mCMgr.changeNotifier();
              }
              break;
          }
        }
        break;
      case RSPType.MAX_RSPTYPE:
        // TODO: Handle this case.
        break;
    }
  }

  /*
   * @fn HandleCgmResponseCallbackDialogView(RSPType indexRsp, String message,
   * String ActionType)
   * @brief if bloodglucose data is received from CGM then pushing the data to 
   * remote DB by using this API.
   *        this API is used in DialogView
   * @param[in] indexRsp : RESPType index
   * @param[in] message : message
   * @param[in] ActionType : cgm protocol Command Type and extend command type
   */
  void _handleCgmResponseCallbackDialogView(
    RSPType indexRsp,
    String message,
    String actionType,
  ) {
    if (_mCMgr.mPump == null) {
      debugPrint(
          'kai:HandleCgmResponseCallbackDialogView(): _mCMgr.mCgm is null!!: '
          'Cannot handle the response event!! ');
      return;
    }

    debugPrint(
        '${tag}kai:HandleCgmResponseCallbackDialogView() is called, mounted = $mounted');
    debugPrint('${tag}kai:RSPType($indexRsp)\nmessage($message)'
        '\nActionType($ActionType)');

    switch (indexRsp) {
      case RSPType.PROCESSING_DONE:
        {
          debugPrint('${tag}kai:PROCESSING_DONE: redraw Screen widgits ');
          // To do something here after receive the processing result
          if (actionType == HCL_BOLUS_RSP_SUCCESS) {}
        }
        break;

      case RSPType.TOAST_POPUP:
        {
          debugPrint('${tag}kai:TOAST_POPUP: redraw Screen widgits ');
        }
        break;

      case RSPType.ALERT:
        {
          debugPrint('${tag}kai:ALERT: redraw Screen widgits ');
        }
        break;

      case RSPType.NOTICE:
        {
          debugPrint('${tag}kai:NOTICE: redraw Screen widgits ');
        }
        break;

      case RSPType.ERROR:
        {
          debugPrint('${tag}kai:ERROR: redraw Screen widgits ');
        }
        break;

      case RSPType.WARNING:
        {
          debugPrint('${tag}kai:WARNING: redraw Screen widgits ');
        }
        break;

      case RSPType.SETUP_INPUT_DLG:
        {
          debugPrint('${tag}kai:SETUP_INPUT_DLG: redraw Screen widgits ');
        }
        break;

      case RSPType.SETUP_DLG:
        {
          debugPrint('${tag}kai:SETUP_DLG: redraw Screen widgits ');
        }
        break;

      case RSPType.UPDATE_SCREEN:
        {
          debugPrint('${tag}kai:UPDATE_SCREEN: redraw Screen widgits ');

          switch (actionType) {
            case 'NEW_BLOOD_GLUCOSE':
              {
                Future.delayed(
                  const Duration(seconds: 1),
                  () async {
                    //To do something here .....
                    final intValue = _mCMgr.mCgm!.getBloodGlucoseValue();
                    //1. update chart graph after upload received
                    //glucose data to server
                    _updateBloodGlucosePageBySensor(intValue.toString());
                    //kai_20230615 let's notify to consummer or
                    //selector in other pages.
                    // _mCMgr.mCgm!.notifyListeners();
                    // _mCMgr.notifyListeners();

                    //kai_20230905 let's set flag which update insulin delivery DataBase
                    setDose = false;
                    debugPrint(
                      '${tag}kai:_handleCgmResponseCallbackDialogView:NEW_BLOOD_GLUCOSE:_set false for setDose = $setDose',
                    );

                    //2. notify to PolicyNet Executor
                    await _setDoseExecution();
                    //4. refresh all
                    if (TEST_FEATCH_DATA_UPDATE == true) {
                      Future.delayed(
                        const Duration(seconds: 2),
                        () async {
                          await _updateBloodGlucose();
                          await _updateSummaryReport();
                        },
                      );
                    }
                  },
                );

                //kai_20230512 let's call connectivityMgr.notifyListener() to
                //notify  for consumer or selector page
                _mCMgr.changeNotifier();
              }
              break;

            case 'CGM_SCAN_UPDATE':
              {
                debugPrint('${tag}CGM_SCAN_UPDATE');
              }
              break;

            case 'DISCONNECT_FROM_USER_ACTION':
              {
                debugPrint('${tag}kai:DISCONNECT_FROM_USER_ACTION');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${CspPreference.mCGM_NAME} ${context.l10n.disconnectByUSer}',
                    );
                  });
                } else {
                  _showMessage(
                    (USE_APPCONTEXT == true &&
                            _mCMgr.appContext != null &&
                            !mounted)
                        ? _mCMgr.appContext!
                        : context,
                    '${CspPreference.mCGM_NAME} ${_mCMgr.appContext!.l10n.disconnectByUSer}',
                  );
                }

                _mCMgr.changeNotifier();
              }
              break;

            case 'DISCONNECT_FROM_DEVICE_CGM':
              {
                debugPrint('${tag}kai:DISCONNECT_FROM_DEVICE_CGM');
                if (mounted) {
                  setState(() {
                    _showWarningMessage(
                      context,
                      '${CspPreference.mCGM_NAME} ${context.l10n.disconnectDevice}',
                    );
                  });
                } else {
                  _showWarningMessage(
                    (USE_APPCONTEXT == true &&
                            _mCMgr.appContext != null &&
                            !mounted)
                        ? _mCMgr.appContext!
                        : context,
                    '${CspPreference.mCGM_NAME} ${_mCMgr.appContext!.l10n.disconnectDevice}',
                  );
                }

                _mCMgr.changeNotifier();
                //kai_20230612 we need to consider auto reconnection in this
                //case in order to keep use the service.
              }
              break;

            case 'CONNECT_TO_DEVICE_CGM':
              {
                debugPrint('${tag}kai:CONNECT_TO_DEVICE_CGM');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${CspPreference.mCGM_NAME} ${context.l10n.hasBeenConnected}',
                    );
                  });
                } else {
                  _showMessage(
                    (USE_APPCONTEXT == true &&
                            _mCMgr.appContext != null &&
                            !mounted)
                        ? _mCMgr.appContext!
                        : context,
                    '${CspPreference.mCGM_NAME} ${_mCMgr.appContext!.l10n.hasBeenConnected}',
                  );
                }

                _mCMgr.changeNotifier();
              }
              break;

            case 'TIMEOUT_CONNECT_TO_DEVICE_CGM':
              {
                debugPrint('${tag}kai:TIMEOUT_CONNECT_TO_DEVICE_CGM');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${context.l10n.timeoutForConnecting} ${CspPreference.mCGM_NAME}!!',
                    );
                  });
                } else {
                  _showMessage(
                    (USE_APPCONTEXT == true &&
                            _mCMgr.appContext != null &&
                            !mounted)
                        ? _mCMgr.appContext!
                        : context,
                    '${_mCMgr.appContext!.l10n.timeoutForConnecting} ${CspPreference.mCGM_NAME}!!',
                  );
                }

                _mCMgr.changeNotifier();
              }
              break;
          }
        }
        break;
      case RSPType.MAX_RSPTYPE:
        // TODO: Handle this case.
        break;
    }
  }

  Future<void> _showPumpDialog() async {
    var selectedRadio = '';
    return showDialog(
      context: (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
          ? _mCMgr.appContext!
          : context,
      barrierDismissible: false, // user must tap button!
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          title: Text(context.l10n.selectInputItem(context.l10n.pump)),
          content: StatefulBuilder(
            // You need this, notice the parameters below:
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height / 3,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        context.l10n.pumpType(context.l10n.danai),
                      ),
                      leading: Radio(
                        value: context.l10n.danai,
                        groupValue: selectedRadio,
                        onChanged: (value) {
                          setState(() => selectedRadio = value.toString());
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        context.l10n.pumpType(context.l10n.caremedi),
                      ),
                      leading: Radio(
                        value: context.l10n.caremedi,
                        groupValue: selectedRadio,
                        onChanged: (value) {
                          setState(() => selectedRadio = value.toString());
                        },
                      ),
                    ),
                    ListTile(
                      title: Text(
                        context.l10n.pumpType(context.l10n.virtual),
                      ),
                      leading: Radio(
                        value: context.l10n.virtual,
                        groupValue: selectedRadio,
                        onChanged: (value) {
                          setState(
                            () => selectedRadio = value.toString(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Row(
              children: [
                const SizedBox(
                  width: Dimens.dp16,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.white,
                      ),
                      overlayColor: MaterialStateProperty.resolveWith(
                        (states) {
                          return states.contains(MaterialState.pressed)
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : null;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimens.dp10),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(
                  width: Dimens.dp16,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedRadio == context.l10n.danai) {
                        debugPrint('kai:selectedRadio == Dana-i');
                        if (Platform.isAndroid) {
                          WidgetsFlutterBinding.ensureInitialized();
                          debugPrint(
                            'kai:check android ble permission: cspPreference.pumpname ='
                            ' ${CspPreference.mPUMP_NAME}',
                          );
                          await [
                            Permission.location,
                            Permission.storage,
                            Permission.bluetooth,
                            Permission.bluetoothConnect,
                            Permission.bluetoothScan
                          ].request().then((status) async {
                            //kai_20230615 let's backup previous setResponse
                            //callback before changing cgm instance here
                            if (!CspPreference.mPUMP_NAME
                                    .contains(serviceUUID.DANARS_PUMP_NAME) ||
                                (_mCMgr.mPump! is! PumpDanars)) {
                              debugPrint(
                                'kai:set Dana-i to CspPreference.PUMP = '
                                '${CspPreference.mPUMP_NAME}',
                              );
                              await CspPreference.setString(
                                'pumpSourceTypeKey',
                                serviceUUID.DANARS_PUMP_NAME,
                              );
                              final prevRspCallback =
                                  _mCMgr.mPump!.getResponseCallbackListener();
                              await _mCMgr.changePUMP();

                              ///< update Cgm instance

                              if (prevRspCallback != null) {
                                // because clearDeviceInfo is always called
                                // in this case.
                                debugPrint(
                                  'kai:Not Dana-i :register prevRspCallback',
                                );
                                _mCMgr.registerResponseCallbackListener(
                                  _mCMgr.mPump,
                                  prevRspCallback,
                                );
                              } else {
                                debugPrint('kai:Not Dana-i :register '
                                    '_handlePumpResponseCallbackDialogView');
                                _mCMgr.registerResponseCallbackListener(
                                  _mCMgr.mPump,
                                  _handlePumpResponseCallbackDialogView,
                                );
                              }
                            } else {
                              final prevRspCallback =
                                  _mCMgr.mPump!.getResponseCallbackListener();
                              if (prevRspCallback != null) {
                                debugPrint(
                                    'kai:Dana-i :unregister prevRspCallback');
                                _mCMgr.unRegisterResponseCallbackListener(
                                  _mCMgr.mPump,
                                  _handlePumpResponseCallbackDialogView,
                                );
                              }
                              debugPrint('kai:Dana-i :register '
                                  '_handlePumpResponseCallbackDialogView');
                              _mCMgr.registerResponseCallbackListener(
                                _mCMgr.mPump,
                                _handlePumpResponseCallbackDialogView,
                              );
                            }
                            Navigator.of(context).pop();
                            debugPrint(
                              'kai:call widget.onPressed.call()==> _onSearchPumpDialog',
                            );
                            // widget.onPressed.call();
                            // GoRouter.of(context).push('/scan');
                            // await _onSearchPumpDialog(context);
                            const hasConnectedBefore = false;
                            await showDialog<String>(
                              barrierDismissible: false,
                              context: (USE_APPCONTEXT == true &&
                                      _mCMgr.appContext != null &&
                                      !mounted)
                                  ? _mCMgr.appContext!
                                  : context,
                              builder: (_) => WillPopScope(
                                onWillPop: () => Future.value(false),
                                child: const ScanDialogPage(
                                  hasConnectedBefore: hasConnectedBefore,
                                ),
                              ),
                            );
                          });
                          // widget.onPress.call();
                          // GoRouter.of(context).push('/scan');
                          // await _onSearchPumpDialog(context);
                        }

                        //kai_20230830 let's allow to access
                        //Pump setup first time only on home page
                        //let's update value here
                        if (CspPreference.getBooleanDefaultFalse(
                              CspPreference.pumpSetupfirstTimeDone,
                            ) !=
                            true) {
                          await CspPreference.setBool(
                            CspPreference.pumpSetupfirstTimeDone,
                            true,
                          );
                        }
                      } else if (selectedRadio == context.l10n.caremedi) {
                        debugPrint('kai:selectedRadio == Caremedi');
                        if (Platform.isAndroid) {
                          WidgetsFlutterBinding.ensureInitialized();
                          debugPrint(
                            'kai:check android ble permission: '
                            'cspPreference.pumpname = '
                            '${CspPreference.mPUMP_NAME}',
                          );
                          await [
                            Permission.location,
                            Permission.storage,
                            Permission.bluetooth,
                            Permission.bluetoothConnect,
                            Permission.bluetoothScan
                          ].request().then(
                            (status) async {
                              //kai_20230615 let's backup previous setResponse
                              //callback before changing cgm instance here
                              if (!CspPreference.mPUMP_NAME
                                  .contains(serviceUUID.CareLevo_PUMP_NAME)) {
                                debugPrint(
                                  'kai:set CareLevo to CspPreference.PUMP = '
                                  '${CspPreference.mPUMP_NAME}',
                                );
                                await CspPreference.setString(
                                  'pumpSourceTypeKey',
                                  'CareLevo',
                                );
                                final prevRspCallback =
                                    _mCMgr.mPump!.getResponseCallbackListener();
                                await _mCMgr.changePUMP();

                                ///< update Cgm instance

                                if (prevRspCallback != null) {
                                  // because clearDeviceInfo is always called
                                  // in this case.
                                  debugPrint(
                                    'kai:Not CareLevo :register prevRspCallback',
                                  );
                                  _mCMgr.registerResponseCallbackListener(
                                    _mCMgr.mPump,
                                    prevRspCallback,
                                  );
                                } else {
                                  debugPrint('kai:Not CareLevo :register '
                                      '_handlePumpResponseCallbackDialogView');
                                  _mCMgr.registerResponseCallbackListener(
                                    _mCMgr.mPump,
                                    _handlePumpResponseCallbackDialogView,
                                  );
                                }
                              } else {
                                final prevRspCallback =
                                    _mCMgr.mPump!.getResponseCallbackListener();
                                if (prevRspCallback != null) {
                                  debugPrint(
                                    'kai:CareLevo :unregister prevRspCallback',
                                  );
                                  _mCMgr.unRegisterResponseCallbackListener(
                                    _mCMgr.mPump,
                                    _handlePumpResponseCallbackDialogView,
                                  );
                                }
                                debugPrint('kai:CareLevo :register '
                                    '_handlePumpResponseCallbackDialogView');
                                _mCMgr.registerResponseCallbackListener(
                                  _mCMgr.mPump,
                                  _handlePumpResponseCallbackDialogView,
                                );
                              }
                              Navigator.of(context).pop();
                              debugPrint(
                                'kai:call widget.onPressed.call()==> _onSearchPumpDialog',
                              );
                              // widget.onPressed.call();
                              // GoRouter.of(context).push('/scan');
                              // await _onSearchPumpDialog(context);
                              const hasConnectedBefore = false;
                              await showDialog<String>(
                                barrierDismissible: false,
                                context: (USE_APPCONTEXT == true &&
                                        _mCMgr.appContext != null &&
                                        !mounted)
                                    ? _mCMgr.appContext!
                                    : context,
                                builder: (_) => WillPopScope(
                                  onWillPop: () => Future.value(false),
                                  child: const ScanDialogPage(
                                    hasConnectedBefore: hasConnectedBefore,
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        //kai_20230830 let's allow to access
                        //Pump setup first time only on home page
                        //let's update value here
                        if (CspPreference.getBooleanDefaultFalse(
                              CspPreference.pumpSetupfirstTimeDone,
                            ) !=
                            true) {
                          await CspPreference.setBool(
                            CspPreference.pumpSetupfirstTimeDone,
                            true,
                          );
                        }
                      } else {
                        //kai_20230911 added to test csp-1
                        if (USE_CAREMEDI_COMMAND == true) {
                          if (selectedRadio == context.l10n.virtual) {
                            debugPrint('kai:selectedRadio == Virtual');
                            if (Platform.isAndroid) {
                              WidgetsFlutterBinding.ensureInitialized();
                              debugPrint(
                                'kai:check android ble permission: '
                                'cspPreference.pumpname = ${CspPreference.mPUMP_NAME}',
                              );
                              await [
                                Permission.location,
                                Permission.storage,
                                Permission.bluetooth,
                                Permission.bluetoothConnect,
                                Permission.bluetoothScan
                              ].request().then(
                                (status) async {
                                  //kai_20230615 let's backup previous setResponse callback
                                  //before changing cgm instance here
                                  if (!CspPreference.mPUMP_NAME.contains(
                                        serviceUUID.CSP_PUMP_NAME,
                                      ) ||
                                      (_mCMgr.mPump! is! PumpCsp1)) {
                                    debugPrint(
                                      'kai:set csp-1 to CspPreference.PUMP = '
                                      '${CspPreference.mPUMP_NAME}',
                                    );
                                    await CspPreference.setString(
                                      'pumpSourceTypeKey',
                                      'csp-1',
                                    );
                                    final prevRspCallback = _mCMgr.mPump!
                                        .getResponseCallbackListener();
                                    await _mCMgr.changePUMP();

                                    ///< update Cgm instance

                                    if (prevRspCallback != null) {
                                      // because clearDeviceInfo is always called
                                      // in this case.
                                      debugPrint(
                                        'kai:Not CareLevo :register prevRspCallback',
                                      );
                                      _mCMgr.registerResponseCallbackListener(
                                        _mCMgr.mPump,
                                        prevRspCallback,
                                      );
                                    } else {
                                      debugPrint('kai:Not csp-1 :register '
                                          '_handlePumpResponseCallbackDialogView');
                                      _mCMgr.registerResponseCallbackListener(
                                        _mCMgr.mPump,
                                        _handlePumpResponseCallbackDialogView,
                                      );
                                    }
                                  } else {
                                    final prevRspCallback = _mCMgr.mPump!
                                        .getResponseCallbackListener();
                                    if (prevRspCallback != null) {
                                      debugPrint(
                                        'kai:csp-1 :unregister prevRspCallback',
                                      );
                                      _mCMgr.unRegisterResponseCallbackListener(
                                        _mCMgr.mPump,
                                        _handlePumpResponseCallbackDialogView,
                                      );
                                    }
                                    debugPrint('kai:csp-1 :register '
                                        '_handlePumpResponseCallbackDialogView');
                                    _mCMgr.registerResponseCallbackListener(
                                      _mCMgr.mPump,
                                      _handlePumpResponseCallbackDialogView,
                                    );
                                  }
                                  Navigator.of(context).pop();
                                  debugPrint(
                                    'kai:call widget.onPressed.call()==> '
                                    '_onSearchPumpDialog',
                                  );
                                  // widget.onPressed.call();
                                  // GoRouter.of(context).push('/scan');
                                  // await _onSearchPumpDialog(context);
                                  const hasConnectedBefore = false;
                                  await showDialog<String>(
                                    barrierDismissible: false,
                                    context: (USE_APPCONTEXT == true &&
                                            _mCMgr.appContext != null &&
                                            !mounted)
                                        ? _mCMgr.appContext!
                                        : context,
                                    builder: (_) => WillPopScope(
                                      onWillPop: () => Future.value(false),
                                      child: const ScanDialogPage(
                                        hasConnectedBefore: hasConnectedBefore,
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              debugPrint(
                                'kai:check not android platform: close dialog',
                              );
                              Navigator.of(context).pop();
                              // widget.onPress.call();
                              // GoRouter.of(context).push('/scan');
                              // await _onSearchPumpDialog(context);
                            }

                            //kai_20230830 let's allow to access
                            //Pump setup first time only on home page
                            //let's update value here
                            if (CspPreference.getBooleanDefaultFalse(
                                  CspPreference.pumpSetupfirstTimeDone,
                                ) !=
                                true) {
                              await CspPreference.setBool(
                                CspPreference.pumpSetupfirstTimeDone,
                                true,
                              );
                            }
                          }
                        }
                      }
                    },
                    child: Text(context.l10n.select), //kai_20230705 changed
                  ),
                )
              ],
            ),
          ],
        );
      },
    );
  }

  /*
   * @brief showing the selected Item during 2 secs
   */
  void _showSelectionMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  /*
   * @brief showing an warning message during 2 secs
   */
  void _showWarningMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Future<void> _getIob() async {
    if (_mCMgr != null && _mCMgr.mPump != null) {
      _iob = await _mCMgr.mPN!.iobCalculate(
        lastInsulin: _mCMgr.mPump!.lastBolusDeliveryValue,
      );
      if (mounted) setState(() {});
    }
  }

  Future<void> _savePump(PumpData pump) async {
    GetIt.I<SavePumpBloc>().add(
      SavePump(
        pump: pump,
      ),
    );
  }

  final _broadcastingTargetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ///kai_20230901 added
    if (_accessType == 'setting_pump') {
      var selectedRadio = '';
      return AlertDialog(
        title: Text(
          context.l10n.selectInputItem(context.l10n.pump),
          style: const TextStyle(
            fontSize: Dimens.dp16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: StatefulBuilder(
          // You need this, notice the parameters below:
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height / 3,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      context.l10n.pumpType(context.l10n.danai),
                    ),
                    leading: Radio(
                      value: context.l10n.danai,
                      groupValue: selectedRadio,
                      onChanged: (value) {
                        setState(() => selectedRadio = value.toString());
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(
                      _pumpVirtualSelected
                          ? 'Broadcasting bolus delivery'
                          : context.l10n.pumpType(context.l10n.caremedi),
                    ),
                    leading: Radio(
                      value: _pumpVirtualSelected
                          ? 'Broadcasting bolus delivery'
                          : context.l10n.caremedi,
                      groupValue: selectedRadio,
                      onChanged: (value) {
                        setState(
                          () {
                            if (_pumpVirtualSelected) {
                              _broadcastingSelected = true;
                            }
                            selectedRadio = value.toString();
                            debugPrint(
                              'select pump virtual $_broadcastingSelected',
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_broadcastingSelected) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Dimens.dp32,
                        right: Dimens.dp16,
                      ),
                      child: CustomTextField(
                        controller: _broadcastingTargetController,
                        formLabel: '',
                        hintText: context.l10n.typeDestinationPackage,
                        inputType: TextInputType.text,
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                  ListTile(
                    title: Text(
                      context.l10n.pumpType(context.l10n.virtual),
                    ),
                    leading: Radio(
                      value: context.l10n.virtual,
                      groupValue: selectedRadio,
                      onChanged: (value) {
                        setState(
                          () {
                            selectedRadio = value.toString();
                            if (_pumpVirtualSelected) {
                              _broadcastingSelected = false;
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          Row(
            children: [
              const SizedBox(
                width: Dimens.dp16,
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Colors.white,
                    ),
                    overlayColor: MaterialStateProperty.resolveWith(
                      (states) {
                        return states.contains(MaterialState.pressed)
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : null;
                      },
                    ),
                    foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).primaryColor,
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimens.dp10),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(
                width: Dimens.dp16,
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedRadio == context.l10n.danai) {
                      debugPrint('kai:selectedRadio == Dana-i');
                      if (Platform.isAndroid) {
                        WidgetsFlutterBinding.ensureInitialized();
                        debugPrint(
                          'kai:check android ble permission: '
                          'cspPreference.pumpname= ${CspPreference.mPUMP_NAME}',
                        );
                        await [
                          Permission.location,
                          Permission.storage,
                          Permission.bluetooth,
                          Permission.bluetoothConnect,
                          Permission.bluetoothScan
                        ].request().then((status) async {
                          //kai_20230615 let's backup previous setResponse callback
                          //before changing cgm instance here
                          if (!CspPreference.mPUMP_NAME
                                  .contains(serviceUUID.DANARS_PUMP_NAME) ||
                              (_mCMgr.mPump! is! PumpDanars)) {
                            debugPrint(
                              'kai:set Dana-i to CspPreference.PUMP = '
                              '${CspPreference.mPUMP_NAME}',
                            );
                            await CspPreference.setString(
                              'pumpSourceTypeKey',
                              serviceUUID.DANARS_PUMP_NAME,
                            );
                            final prevRspCallback =
                                _mCMgr.mPump!.getResponseCallbackListener();
                            await _mCMgr.changePUMP();

                            ///< update Cgm instance

                            if (prevRspCallback != null) {
                              // because clearDeviceInfo is always called
                              // in this case.
                              debugPrint(
                                'kai:Not Dana-i :register prevRspCallback',
                              );
                              _mCMgr.registerResponseCallbackListener(
                                _mCMgr.mPump,
                                prevRspCallback,
                              );
                            } else {
                              debugPrint('kai:Not Dana-i :register '
                                  '_handlePumpResponseCallbackDialogView');
                              _mCMgr.registerResponseCallbackListener(
                                _mCMgr.mPump!,
                                _handlePumpResponseCallbackDialogView,
                              );
                            }
                          } else {
                            final prevRspCallback =
                                _mCMgr.mPump!.getResponseCallbackListener();
                            if (prevRspCallback != null) {
                              debugPrint(
                                  'kai:Dana-i :unregister prevRspCallback');
                              _mCMgr.unRegisterResponseCallbackListener(
                                _mCMgr.mPump,
                                _handlePumpResponseCallbackDialogView,
                              );
                            }
                            debugPrint('kai:Dana-i :register '
                                '_handlePumpResponseCallbackDialogView');
                            _mCMgr.registerResponseCallbackListener(
                              _mCMgr.mPump,
                              _handlePumpResponseCallbackDialogView,
                            );
                          }
                          Navigator.of(context).pop();
                          debugPrint(
                            'kai:call widget.onPressed.call() => '
                            '_onSearchPumpDialog',
                          );
                          // widget.onPressed.call();
                          // GoRouter.of(context).push('/scan');
                          // await _onSearchPumpDialog(context);
                          const hasConnectedBefore = false;
                          await showDialog<String>(
                            barrierDismissible: false,
                            context: (USE_APPCONTEXT == true &&
                                    _mCMgr.appContext != null &&
                                    !mounted)
                                ? _mCMgr.appContext!
                                : context,
                            builder: (_) => WillPopScope(
                              onWillPop: () => Future.value(false),
                              child: const ScanDialogPage(
                                hasConnectedBefore: hasConnectedBefore,
                              ),
                            ),
                          );
                        });
                        // widget.onPress.call();
                        // GoRouter.of(context).push('/scan');
                        // await _onSearchPumpDialog(context);
                      }

                      //kai_20230830 let's allow to access
                      //Pump setup first time only on home page
                      //let's update value here
                      if (CspPreference.getBooleanDefaultFalse(
                            CspPreference.pumpSetupfirstTimeDone,
                          ) !=
                          true) {
                        await CspPreference.setBool(
                          CspPreference.pumpSetupfirstTimeDone,
                          true,
                        );
                      }
                    } else if (selectedRadio == context.l10n.caremedi) {
                      debugPrint('kai:selectedRadio == Caremedi');
                      if (Platform.isAndroid) {
                        WidgetsFlutterBinding.ensureInitialized();
                        debugPrint(
                          'kai:check android ble permission: '
                          'cspPreference.pumpname = '
                          '${CspPreference.mPUMP_NAME}',
                        );
                        await [
                          Permission.location,
                          Permission.storage,
                          Permission.bluetooth,
                          Permission.bluetoothConnect,
                          Permission.bluetoothScan
                        ].request().then(
                          (status) async {
                            //kai_20230615 let's backup previous setResponse callback
                            //before changing cgm instance here
                            if (!CspPreference.mPUMP_NAME
                                    .contains(serviceUUID.CareLevo_PUMP_NAME) ||
                                (_mCMgr.mPump! is! Pump)) {
                              debugPrint(
                                'kai:set CareLevo to CspPreference.PUMP = '
                                '${CspPreference.mPUMP_NAME}',
                              );
                              await CspPreference.setString(
                                'pumpSourceTypeKey',
                                'CareLevo',
                              );
                              final prevRspCallback =
                                  _mCMgr.mPump!.getResponseCallbackListener();
                              await _mCMgr.changePUMP();

                              ///< update Cgm instance

                              if (prevRspCallback != null) {
                                // because clearDeviceInfo is always called
                                // in this case.
                                debugPrint(
                                  'kai:Not CareLevo :register prevRspCallback',
                                );
                                _mCMgr.registerResponseCallbackListener(
                                  _mCMgr.mPump,
                                  prevRspCallback,
                                );
                              } else {
                                debugPrint('kai:Not CareLevo :register '
                                    '_handlePumpResponseCallbackDialogView');
                                _mCMgr.registerResponseCallbackListener(
                                  _mCMgr.mPump,
                                  _handlePumpResponseCallbackDialogView,
                                );
                              }
                            } else {
                              final prevRspCallback =
                                  _mCMgr.mPump!.getResponseCallbackListener();
                              if (prevRspCallback != null) {
                                debugPrint(
                                  'kai:CareLevo :unregister prevRspCallback',
                                );
                                _mCMgr.unRegisterResponseCallbackListener(
                                  _mCMgr.mPump,
                                  _handlePumpResponseCallbackDialogView,
                                );
                              }
                              debugPrint('kai:CareLevo :register '
                                  '_handlePumpResponseCallbackDialogView');
                              _mCMgr.registerResponseCallbackListener(
                                _mCMgr.mPump,
                                _handlePumpResponseCallbackDialogView,
                              );
                            }
                            Navigator.of(context).pop();
                            debugPrint(
                              'kai:call widget.onPressed.call() ==> '
                              '_onSearchPumpDialog',
                            );
                            // widget.onPressed.call();
                            // GoRouter.of(context).push('/scan');
                            // await _onSearchPumpDialog(context);
                            const hasConnectedBefore = false;
                            await showDialog<String>(
                              barrierDismissible: false,
                              context: (USE_APPCONTEXT == true &&
                                      _mCMgr.appContext != null &&
                                      !mounted)
                                  ? _mCMgr.appContext!
                                  : context,
                              builder: (_) => WillPopScope(
                                onWillPop: () => Future.value(false),
                                child: const ScanDialogPage(
                                  hasConnectedBefore: hasConnectedBefore,
                                ),
                              ),
                            );
                          },
                        );
                        // widget.onPress.call();
                        // GoRouter.of(context).push('/scan');
                        // await _onSearchPumpDialog(context);
                      }

                      //kai_20230830 let's allow to access
                      //Pump setup first time only on home page
                      //let's update value here
                      if (CspPreference.getBooleanDefaultFalse(
                            CspPreference.pumpSetupfirstTimeDone,
                          ) !=
                          true) {
                        await CspPreference.setBool(
                          CspPreference.pumpSetupfirstTimeDone,
                          true,
                        );
                      }
                    } else {
                      //kai_20230911 added to test csp-1
                      debugPrint('kai:selectedRadio == Virtual Pump');
                      if (!_pumpVirtualSelected) {
                        _pumpVirtualSelected = true;
                        setState(() {});
                      } else if (_broadcastingSelected) {
                        await CspPreference.setBool(
                          CspPreference.broadcastingPolicyNetBolus,
                          true,
                        );
                        await CspPreference.setString(
                          CspPreference.destinationPackageName,
                          _broadcastingTargetController.text,
                        );
                        unawaited(
                          _savePump(
                            PumpData(
                              id: const Uuid().v4(),
                              name: _broadcastingTargetController.text,
                              status: true,
                              connectAt: DateTime.now(),
                            ),
                          ),
                        );

                        if (mounted) {
                          _showSelectionMessage(
                            context,
                            '${context.l10n.youWillReceiveDataFrom} '
                            '${_broadcastingTargetController.text}',
                          );
                        }

                        if (mounted) Navigator.of(context).pop();
                      } else {
                        if (USE_CAREMEDI_COMMAND == true) {
                          if (selectedRadio == context.l10n.virtual) {
                            debugPrint('kai:selectedRadio == Virtual');
                            if (Platform.isAndroid) {
                              WidgetsFlutterBinding.ensureInitialized();
                              debugPrint(
                                'kai:check android ble permission: '
                                'cspPreference.pumpname = '
                                '${CspPreference.mPUMP_NAME}',
                              );
                              await [
                                Permission.location,
                                Permission.storage,
                                Permission.bluetooth,
                                Permission.bluetoothConnect,
                                Permission.bluetoothScan
                              ].request().then(
                                (status) async {
                                  //kai_20230615 let's backup previous setResponse callback
                                  //before changing cgm instance here
                                  if (!CspPreference.mPUMP_NAME.contains(
                                        serviceUUID.CSP_PUMP_NAME,
                                      ) ||
                                      (_mCMgr.mPump! is! PumpCsp1)) {
                                    debugPrint(
                                      'kai:set csp-1 to CspPreference.PUMP = '
                                      '${CspPreference.mPUMP_NAME}',
                                    );
                                    await CspPreference.setString(
                                      'pumpSourceTypeKey',
                                      'csp-1',
                                    );
                                    final prevRspCallback = _mCMgr.mPump!
                                        .getResponseCallbackListener();
                                    await _mCMgr.changePUMP();

                                    ///< update Cgm instance

                                    if (prevRspCallback != null) {
                                      // because clearDeviceInfo is always called
                                      // in this case.
                                      debugPrint(
                                        'kai:Not CareLevo '
                                        ':register prevRspCallback',
                                      );
                                      _mCMgr.registerResponseCallbackListener(
                                        _mCMgr.mPump,
                                        prevRspCallback,
                                      );
                                    } else {
                                      debugPrint(
                                        'kai:Not csp-1 :register '
                                        '_handlePumpResponseCallbackDialogView',
                                      );
                                      _mCMgr.registerResponseCallbackListener(
                                        _mCMgr.mPump,
                                        _handlePumpResponseCallbackDialogView,
                                      );
                                    }
                                  } else {
                                    final prevRspCallback = _mCMgr.mPump!
                                        .getResponseCallbackListener();
                                    if (prevRspCallback != null) {
                                      debugPrint(
                                        'kai:csp-1 :unregister prevRspCallback',
                                      );
                                      _mCMgr.unRegisterResponseCallbackListener(
                                        _mCMgr.mPump,
                                        _handlePumpResponseCallbackDialogView,
                                      );
                                    }
                                    debugPrint('kai:csp-1 :register '
                                        '_handlePumpResponseCallbackDialogView');
                                    _mCMgr.registerResponseCallbackListener(
                                      _mCMgr.mPump,
                                      _handlePumpResponseCallbackDialogView,
                                    );
                                  }
                                  Navigator.of(context).pop();

                                  debugPrint(
                                    'kai:call widget.onPressed.call()==> '
                                    '_onSearchPumpDialog',
                                  );
                                  // widget.onPressed.call();
                                  // GoRouter.of(context).push('/scan');
                                  // await _onSearchPumpDialog(context);
                                  const hasConnectedBefore = false;
                                  await showDialog<String>(
                                    barrierDismissible: false,
                                    context: (USE_APPCONTEXT == true &&
                                            _mCMgr.appContext != null &&
                                            !mounted)
                                        ? _mCMgr.appContext!
                                        : context,
                                    builder: (_) => WillPopScope(
                                      onWillPop: () => Future.value(false),
                                      child: const ScanDialogPage(
                                        hasConnectedBefore: hasConnectedBefore,
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              debugPrint(
                                'kai:check not android platform: close dialog',
                              );
                              Navigator.of(context).pop();
                              // widget.onPress.call();
                              // GoRouter.of(context).push('/scan');
                              // await _onSearchPumpDialog(context);
                            }

                            //kai_20230830 let's allow to access
                            //Pump setup first time only on home page
                            //let's update value here
                            if (CspPreference.getBooleanDefaultFalse(
                                  CspPreference.pumpSetupfirstTimeDone,
                                ) !=
                                true) {
                              await CspPreference.setBool(
                                CspPreference.pumpSetupfirstTimeDone,
                                true,
                              );
                            }
                          }
                        }
                      }
                    }
                  },
                  child: Text(context.l10n.select), //kai_20230705 changed
                ),
              ),
              const SizedBox(
                width: Dimens.dp16,
              ),
            ],
          ),
        ],
      );
    } else if (_accessType == 'blood_glucose_calibrate') {
      double? bgValue = 0;
      return AlertDialog(
        title: Container(
          padding: const EdgeInsets.all(Dimens.dp12),
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Dimens.dp10),
              topRight: Radius.circular(Dimens.dp10),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: Dimens.dp18,
              ),
              const SizedBox(
                width: Dimens.dp8,
              ),
              Text(
                context.l10n.bloodGlucose,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: Dimens.dp16,
                ),
              ),
            ],
          ),
        ),
        titlePadding: EdgeInsets.zero,
        content: StatefulBuilder(
          builder: (stfContext, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: Dimens.dp16,
                ),
                Text(
                  context.l10n.bloodGlucoseValue,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                    fontSize: Dimens.dp16,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(
                  height: Dimens.dp8,
                ),
                TextField(
                  enabled: true,
                  keyboardType: TextInputType.number,

                  ///< let's handle enable/disable based on ActionType
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      bgValue = double.parse(value);
                    }
                  },
                  decoration: const InputDecoration(
                    hoverColor: Colors.amber,
                    hintText: '0',
                    suffixText: 'mg/dL',
                  ),
                ),
                const SizedBox(
                  height: Dimens.dp4,
                ),
                const Text(
                  'mg/dL',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                    fontSize: Dimens.dp12,
                  ),
                ),
                const SizedBox(
                  height: Dimens.dp16,
                ),
              ],
            );
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.dp10),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(_mCMgr.appContext!.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final userInputGlucose = GetIt.I<InputBloodGlucoseBloc>()
                ..add(
                  InputBloodGlucoseValueChanged(
                    value: bgValue,
                  ),
                );
              if (debugMessageFlag) {
                log(
                  'updateBloodGlucosePageBySensor: before status = '
                  '${userInputGlucose.state.status.isValidated}',
                );
              }
              //  sensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
              userInputGlucose.add(
                InputBloodGlucoseSubmitted(time: DateTime.now()),
              );
              _mCMgr.changeNotifier();
            },
            child: Text(_mCMgr.appContext!.l10n.confirm),
          ),
        ],
      );
    } else if (_accessType == 'manual_bolus_injection') {
      if (_canToTheNext == false) {
        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(Dimens.dp12),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimens.dp10),
                topRight: Radius.circular(Dimens.dp10),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: Dimens.dp18,
                ),
                const SizedBox(
                  width: Dimens.dp8,
                ),
                Text(
                  context.l10n.bolus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Dimens.dp16,
                  ),
                ),
              ],
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: SizedBox(
            height: MediaQuery.of(context).size.height / 3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        direction: Axis.vertical,
                        children: [
                          Text(
                            context.l10n.glucose,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                              fontSize: Dimens.dp16,
                            ),
                          ),
                          const Text(
                            'mg/dL',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                              fontSize: Dimens.dp12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimens.dp12,
                          vertical: Dimens.dp4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(
                              Dimens.dp4,
                            ),
                          ),
                        ),
                        child: Text(
                          double.parse(
                            (_mCMgr != null && _mCMgr.mCgm != null)
                                ? _mCMgr.mCgm!
                                        .getCollectBloodGlucose()
                                        ?.glucose ??
                                    '0'
                                : '0',
                          ).floor().toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                            fontSize: Dimens.dp16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: Dimens.dp16,
                  ),
                  Text(
                    context.l10n.carbs,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      fontSize: Dimens.dp16,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(
                    height: Dimens.dp8,
                  ),
                  TextField(
                    enabled: true,
                    keyboardType: TextInputType.number,

                    ///< let's handle enable/disable based on ActionType
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        final _user = (await GetIt.I<GetProfileUseCase>().call(
                          const NoParams(),
                        ))
                            .foldRight(
                          const UserProfile(
                            gender: Gender.female,
                            name: '',
                            id: '',
                            weight: 0,
                            totalDailyDose: 0,
                          ),
                          (r, previous) => r,
                        );

                        _totalUnits =
                            ((_user.insulinCarbRatio! + double.parse(value) >
                                        150)
                                    ? 1
                                    : 0) *
                                (double.parse(value) - 140) /
                                _user.insulinSensitivityFactor!;

                        // (meal * env_sample_time) / quest.CR/ICR.values + (glucose(current_cgm) > 150 ? 1 : 0) *
                        //  (glucose - 140) / quest.CF/ISF.values).item()
                      } else {
                        _totalUnits = 0;
                      }
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hoverColor: Colors.amber,
                      hintText: '0',
                      suffixText: 'g',
                    ),
                  ),
                  const SizedBox(
                    height: Dimens.dp16,
                  ),
                  Text(
                    'IOB of ${_iob.floor()} U',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.normal,
                      fontSize: Dimens.dp16,
                    ),
                  ),
                  const SizedBox(
                    height: Dimens.dp32,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      direction: Axis.vertical,
                      alignment: WrapAlignment.end,
                      children: [
                        Text(
                          (_totalUnits ?? 0.0).toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                            fontSize: Dimens.dp24,
                          ),
                        ),
                        Text(
                          context.l10n.totalUnits,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                            fontSize: Dimens.dp12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _totalUnits = 0;
              },
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                _canToTheNext = true;
                setState(() {});
              },
              child: Text(context.l10n.next),
            ),
          ],
        );
      } else {
        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(Dimens.dp12),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimens.dp10),
                topRight: Radius.circular(Dimens.dp10),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: Dimens.dp18,
                ),
                const SizedBox(
                  width: Dimens.dp8,
                ),
                Text(
                  context.l10n.confirmBolus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Dimens.dp16,
                  ),
                ),
              ],
            ),
          ),
          titlePadding: EdgeInsets.zero,
          content: SizedBox(
            height: MediaQuery.of(context).size.height / 4,
            child: StatefulBuilder(
              builder: (stfContext, setState) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.totalBolus,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        fontSize: Dimens.dp18,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(
                      height: Dimens.dp8,
                    ),
                    Text(
                      '$_totalUnits U',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        fontSize: Dimens.dp32,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(
                      height: Dimens.dp8,
                    ),
                    if (_sendBolus == true) ...[
                      const SizedBox(
                        height: Dimens.dp16,
                      ),
                      Text(
                        context.l10n.deliverWillStartIn,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                          fontSize: Dimens.dp16,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        _duration.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                          fontSize: Dimens.dp24,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        context.l10n.second,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                          fontSize: Dimens.dp16,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.dp10),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_sendBolus == false) {
                  _canToTheNext = false;
                  _timer?.cancel();
                  setState(() {});
                } else {
                  _canToTheNext = false;
                  _sendBolus = false;
                  _totalUnits = 0;
                  _duration = 30;
                  Navigator.of(context).pop();
                }
              },
              child: _sendBolus == false
                  ? Text(context.l10n.back)
                  : Text(context.l10n.cancel),
            ),
            if (_sendBolus == false) ...[
              TextButton(
                onPressed: () {
                  _sendBolus = true;
                  _startCountdown();
                  setState(() {});
                },
                child: Text(context.l10n.back),
              ),
            ],
          ],
        );
      }
    } else {
      return AlertDialog(
        title: Text(
          context.l10n.selectCgm,
          style: const TextStyle(
            fontSize: Dimens.dp16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: _isConnecting || widget.cgmData != null
            ? Text(
                context.l10n.scanNConnecting,
              ) //kai_20230705 changed // const Center(child: CircularProgressIndicator())
            : (_selectedDeviceId == null || _confirmSelectedDeviceId == null) &&
                    (CspPreference.getBooleanDefaultFalse(
                          CspPreference.pumpTestPage,
                        ) !=
                        true)
                ? SizedBox(
                    height: MediaQuery.of(context).size.height / 3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //kai_20231005 seperate test mode and normal mode
                        // for (var device in _devices)
                        RadioListTile(
                          title: Text(
                            context.l10n.cgmType(context.l10n.iSens),
                            style: const TextStyle(
                              fontSize: Dimens.dp16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          value: context.l10n.iSens,
                          groupValue: _selectedDeviceId,
                          onChanged: _onDeviceSelected,
                        ),
                        RadioListTile(
                          title: Text(
                            context.l10n.cgmType(context.l10n.virtual),
                            style: const TextStyle(
                              fontSize: Dimens.dp16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          value: context.l10n.virtual,
                          groupValue: _selectedDeviceId,
                          onChanged: _onDeviceSelected,
                        ),
                        //kai_20230705 added
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.end,
                        //   // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   // crossAxisAlignment: CrossAxisAlignment.center,
                        //   children: [
                        //     TextButton(
                        //       child: Text(context.l10n.confirm),
                        //       onPressed: () {
                        //         _confirmSelectedDeviceId = _selectedDeviceId;
                        //         if (mounted) {
                        //           setState(() {
                        //             //update screen
                        //           });
                        //         }
                        //       },
                        //     ),
                        //     TextButton(
                        //       child: Text(context.l10n.cancel),
                        //       onPressed: () {
                        //         Navigator.of(context).pop();
                        //       },
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  )
                : (_selectedDeviceId == null ||
                            _confirmSelectedDeviceId == null) &&
                        CspPreference.getBooleanDefaultFalse(
                              CspPreference.pumpTestPage,
                            ) ==
                            true
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height / 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //kai_20231005 seperate test mode and normal mode
                            // for (var device in _devicesTest)
                            RadioListTile(
                              title: Text(
                                context.l10n.cgmType(context.l10n.dexcom),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              value: context.l10n.dexcom,
                              groupValue: _selectedDeviceId,
                              onChanged: _onDeviceSelected,
                            ),
                            RadioListTile(
                              title: Text(
                                context.l10n.cgmType(context.l10n.iSens),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              value: context.l10n.iSens,
                              groupValue: _selectedDeviceId,
                              onChanged: _onDeviceSelected,
                            ),
                            RadioListTile<String>(
                              title: Text(
                                context.l10n.cgmType(context.l10n.useXdrip),
                                style: const TextStyle(
                                  fontSize: Dimens.dp16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              value: context.l10n.useXdrip,
                              groupValue: _selectedDeviceId,
                              onChanged: _onDeviceSelected,
                            ),
                          ],
                        ),
                      )
                    : ((USE_XDRIP_AS_VIRTUAL_CGM == true)
                            ? (_selectedDeviceId == context.l10n.useXdrip ||
                                _selectedDeviceId == context.l10n.virtual)
                            : _selectedDeviceId ==
                                context.l10n.useXdrip) // Use Xdrip
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height / 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var device in _xdripOptions)
                                  RadioListTile(
                                    title: Text(
                                      device.id,
                                      style: const TextStyle(
                                        fontSize: Dimens.dp16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    value: device.id,
                                    groupValue: _selectedXdripOptionId,
                                    onChanged: _onXdripOptionSelected,
                                  ),
                              ],
                            ),
                          )
                        : SizedBox(
                            height: MediaQuery.of(context).size.height / 3,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: context.l10n.transmitterID,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: _onTransmitterIdChanged,
                                ),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: context.l10n.validCode,
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: _onValidCodeChanged,
                                ),
                              ],
                            ),
                          ),
        actions: [
          if (_selectedDeviceId != null &&
              _confirmSelectedDeviceId != null) ...[
            Row(
              children: [
                const SizedBox(
                  width: Dimens.dp16,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _selectedDeviceId = null;
                      _confirmSelectedDeviceId = null;
                      if (mounted) {
                        setState(
                          () {
                            //update screen
                          },
                        );
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        Colors.white,
                      ),
                      overlayColor: MaterialStateProperty.resolveWith(
                        (states) {
                          return states.contains(MaterialState.pressed)
                              ? Theme.of(context).primaryColor.withOpacity(
                                    0.2,
                                  )
                              : null;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimens.dp10),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    child: Text(context.l10n.back),
                  ),
                ),
                const SizedBox(
                  width: Dimens.dp16,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      //kai_20230705 changed
                      if (_isConnecting) {
                        _isConnecting = false;
                        Navigator.of(context).pop();
                        if (_mCMgr.mPump!.ConnectionStatus !=
                            BluetoothDeviceState.connected) {
                          //kai_20230830 let's allow to access
                          //Pump setup first time only on home page
                          if (CspPreference.getBooleanDefaultFalse(
                                CspPreference.pumpSetupfirstTimeDone,
                              ) !=
                              true) {
                            await _showPumpDialog();
                          }
                        }
                      } else {
                        await _onConnectPressed();
                        //kai_20230613 blocked
                        /*
                Future.delayed(const Duration(seconds: 2), () async {
                  await _showPumpDialog();
                });
                */
                      }
                    },
                    child: _isConnecting
                        ? Text(context.l10n.cancel)
                        : Text(context.l10n.select), //kai_20230705 changed
                  ),
                ),
                const SizedBox(
                  width: Dimens.dp16,
                ),
              ],
            ),
          ] else if (widget.cgmData != null) ...[
            const SizedBox(),
          ] else ...[
            Row(
              children: [
                const SizedBox(
                  width: Dimens.dp16,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.white,
                      ),
                      overlayColor: MaterialStateProperty.resolveWith(
                        (states) {
                          return states.contains(MaterialState.pressed)
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : null;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor,
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimens.dp10),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    child: Text(context.l10n.cancel),
                  ),
                ),
                const SizedBox(
                  width: Dimens.dp8,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _confirmSelectedDeviceId = _selectedDeviceId;
                      if (mounted) {
                        setState(
                          () {
                            //update screen
                          },
                        );
                      }
                    },
                    child: Text(context.l10n.next), //kai_20230705 changed
                  ),
                ),
                const SizedBox(
                  width: Dimens.dp16,
                ),
              ],
            ),
          ],
        ],
      );
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_duration <= 0) {
          timer.cancel();
          // Timer finished
          debugPrint('Countdown complete!');
          Future.delayed(
            const Duration(seconds: 3),
            () {
              Navigator.of(context).pop();
            },
          );
        } else {
          if (mounted) {
            setState(
              () {
                // Update timer display or perform other actions
                debugPrint('Time remaining: $_duration seconds');
                _duration--;
                if (_duration == 0) {
                  _sendDose(
                    _totalUnits.toString(),
                  );
                  _mCMgr.changeNotifier();
                }
              },
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendDose(String inputText) async {
    // Mode (1 byte): HCL 통합 주입(0x00), 교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
    // HCLBy APP” 모드에서 기저와 볼러스 주입이 통합된 자동 모드에서 주입할 인슐린 총량을 주입하기위해 사용
    // HCL By App” 모드에서 교정 볼러스 주입 제어 알고리즘에 의한 교정 볼러스 계산기 주입 값을 가감한
    // 최종 교정 볼러스 주입량이 있으면 본 메시지를 패치로 전송한다.
    //int value = int.parse(inputText)*100; ///< scaling by 100
    _mCMgr.mPump!.setInsulinSource(ReportSource.user);
    if (!inputText.contains('.')) {
      // in case that no floating point on the typed String sequence
      inputText = '$inputText.0';
    }
    final value = (double.parse(inputText) * 100).toInt();
    if (value > 2500 || value < 1)

    ///< scaled range from 25 ~ 0.01
    {
      _showToastMessage(
        (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
            ? _mCMgr.appContext!
            : context,
        '${_mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.01 ~ 25',
        'red',
        0,
      );
    } else {
      //kai_20230427 let's check isDoseInjectingNow is true
      if (_mCMgr.mPump!.isDoseInjectingNow == true) {
        Navigator.of(
          (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
              ? _mCMgr.appContext!
              : context,
        ).pop();

        ///< due to toast popup is showing behind the active dialog
        _showToastMessage(
          (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
              ? _mCMgr.appContext!
              : context,
          _mCMgr.appContext!.l10n.doseProcessingMsg,
          'red',
          0,
        );
        // ko : 펌프가 이전 도즈 주입을 처리중입니다.처리가 완료 될때 까지 잠시만 기다려 주세요.
      } else {
        await CspPreference.setString(
          CspPreference.pumpHclDoseInjectionKey,
          inputText,
        );
        await _mCMgr.mPump!.sendSetDoseValue(inputText, 0x00, null);
        _showToastMessage(
          (USE_APPCONTEXT == true && _mCMgr.appContext != null && !mounted)
              ? _mCMgr.appContext!
              : context,
          '${_mCMgr.appContext!.l10n.sendingDoseAmount}($inputText)U ...',
          'blue',
          0,
        );
      }
    }
  }
}

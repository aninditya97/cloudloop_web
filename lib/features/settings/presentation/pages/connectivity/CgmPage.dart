import 'dart:convert';
import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/XDripLauncher.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// show debug message
const bool DEBUG_MESSAGE_FLAG = true;

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

class ConnectionDialog extends StatefulWidget {
  const ConnectionDialog({Key? key}) : super(key: key);

  @override
  _ConnectionDialogState createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog> {
  final int maxValidCodeLength = 4;
  final int maxTransmitterIDLength = 6;
  final String TAG = '_ConnectionDialogState:';

  final List<Device> _devices = [
    Device(id: 'Dexcom', validCode: 5678),
    Device(id: 'i-sens', validCode: 1234),
    Device(id: 'Use Xdrip', validCode: 9012),
  ];

  final List<XdripOption> _xdripOptions = [
    XdripOption(id: 'xdripHome', url: 'XDripLauncher.launchXDripHome'),
    XdripOption(id: 'StartSensor', url: 'XDripLauncher.StartNewSensor'),
    XdripOption(id: 'BGHistory', url: 'XDripLauncher.BGHistory'),
    XdripOption(id: 'BluetoothScan', url: 'XDripLauncher.BluetoothScan'),
    XdripOption(id: 'FakeNumbers', url: 'XDripLauncher.FakeNumbers'),
  ];

  late String? _selectedDeviceId = null;
  late String? _TransmitterId = null;
  late int _validCode = 0;
  bool _isConnecting = false;
  late String? _selectedXdripOptionId = null;
  late ConnectivityMgr mCMgr;

  @override
  void initState() {
    super.initState();
    //let's init csp preference instance here
    // CspPreference.initPrefs();  ///< shared Preference
    // super.initState();
    mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
  }

  /*
   * @fn _BloodGlucoseDataStreamCallback(dynamic event)
   * @param[in] event : received event data structure based on json
   * @brief receive the glucose data from android MainActivity thru xdrip
   *        caller should implement this callback in order to forward the
   *  received data to the PolicyNet Executor
   */
  void _bloodGlucoseDataStreamCallback(dynamic event) {
    //check event here
    if (DEBUG_MESSAGE_FLAG) {
      // {"glucose":"150.0","timestamp":"1669944611002","raw":"0.0","direction":"Flat","source":"G6 Native / G5 Native"}
      log('$TAG:_BloodGlucoseDataStreamCallback: is called');
    }
    //parse json format sent from MaiActivity here
    final jsonData = json.decode(event.toString()) as Map<String, dynamic>;

    if (DEBUG_MESSAGE_FLAG) {
      log('$TAG: gluecose = ${jsonData['glucose']}');
      log('$TAG: timestamp = ${jsonData['timestamp']}');
      log('$TAG: raw = ${jsonData['raw']}');
      log('$TAG: direction = ${jsonData['direction']}');
      log('$TAG: source = ${jsonData['source']}');
    }

    /* save received bloodglucose time  and value here */
    final timeDate = int.parse(jsonData['timestamp'].toString());
    final glucose = jsonData['glucose'].toString();

    //update UI Screen here
    log('kai: mounted = $mounted, call setState() for update UI');
    if (mounted) {
      setState(() {
        mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
        //kai_20230509 if Glucose have floating point as like double " 225.0 "
        //then convert the value to int exclude ".0" by using floor()
        // mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
        mCMgr.mCgm!.setBloodGlucoseValue(double.parse(glucose).floor());
        mCMgr.mCgm!.setRecievedTimeHistoryList(
          0,
          DateTime.fromMillisecondsSinceEpoch(
            timeDate,
          ).toIso8601String(),
        );
        mCMgr.mCgm!
            .setBloodGlucoseHistoryList(0, double.parse(glucose).floor());
        mCMgr.mCgm!.cgmModelName = jsonData['source'].toString();
        mCMgr.mCgm!.cgmSN = jsonData['sensorSerial'].toString();
      });
    } else {
      log('kai: !mounted = $mounted,  update UI');
      mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
      //kai_20230509 if Glucose have floating point as like double " 225.0 "
      //then convert the value to int exclude ".0" by using floor()
      // mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
      mCMgr.mCgm!.setBloodGlucoseValue(double.parse(glucose).floor());
      mCMgr.mCgm!.setRecievedTimeHistoryList(
        0,
        DateTime.fromMillisecondsSinceEpoch(
          timeDate,
        ).toIso8601String(),
      );
      mCMgr.mCgm!.setBloodGlucoseHistoryList(
        0,
        double.parse(glucose).floor(),
      );
      mCMgr.mCgm!.cgmModelName = jsonData['source'].toString();
      mCMgr.mCgm!.cgmSN = jsonData['sensorSerial'].toString();
    }

    //kai_20230512 let's call mCmgr.notifyListeners() for consummer or selector
    // pages which listening the updated value
    mCMgr.notifyListeners();

    // UI Update here
    if (DEBUG_MESSAGE_FLAG) {
      final mCgmGlucoseReceiveTime = DateFormat('yyyy/MM/dd HH:mm a')
          .format(DateTime.fromMillisecondsSinceEpoch(timeDate));
      final mCgmGlucoseValue = jsonData['glucose'].toString();

      log('$TAG:>>xdrip:$mCgmGlucoseReceiveTime: glucose = $mCgmGlucoseValue '
          'raw = ${jsonData['raw']}');
    }
    // update chart graph after upload received glucose data to server
    // updateBloodGlucosePageBySensor(Glucose);
    ///< send bloodglucose data to the DB or notify PolicyNet Executor
    Future.delayed(const Duration(seconds: 1), () async {
      //To do something here .....
      //1. notify to PolicyNet Executor
      final user =
          (await GetIt.I<GetProfileUseCase>().call(const NoParams())).foldRight(
        const UserProfile(
          gender: Gender.female,
          name: '',
          id: '',
          weight: 0,
          totalDailyDose: 0,
        ),
        (r, previous) => r,
      );

      final announceMeal =
          (await GetIt.I<GetAutoModeUseCase>().call(const NoParams()))
              .foldRight(0, (r, previous) => r);
      final intValue = mCMgr.mCgm!.getBloodGlucoseValue();
      final lastValue = mCMgr.mCgm!.getLastBloodGlucose() > 0
          ? mCMgr.mCgm!.getLastBloodGlucose()
          : intValue;
      log('udin:call last glucose: $lastValue');
      final receivedTimeHistoryList = mCMgr.mCgm!.getRecievedTimeHistoryList();
      final timeHist = receivedTimeHistoryList.map<String>((i) => i).toList();

      final bloodGlucoseHistoryList =
          mCMgr.mCgm!.getBloodGlucoseHistoryList().getRange(0, 5);
      final cgmHist =
          bloodGlucoseHistoryList.map<double>((i) => i.toDouble()).toList();

      final lastInsulin = mCMgr.mPump!.getBolusDeliveryValue();
      log('kai:call mCMgr.mPN!.execution(${cgmHist.toString()})');
      log('kai:call insulin '
          'carb ratio = ${user.insulinCarbRatio.toString()}');
      final response = await mCMgr.mPN!.execution(
        cgmHist: cgmHist,
        timeHist: timeHist,
        lastInsulin: lastInsulin,
        announceMeal: announceMeal,
        totalDailyDose: user.totalDailyDose,
        basalRate: user.basalRate ?? 0.0,
        insulinCarbRatio: user.insulinCarbRatio ?? 0.0,
        iob: 0,
      );

      //2. PolicyNet Executor send the calculated bolus(insulin) value to the
      // connected Pump device after check connection status is connected
      if (mCMgr.mPump!.ConnectionStatus == BluetoothDeviceState.connected) {
        final insulinValue = response
            .toString(); // U or mL, which will be calculated by PolicyNet
        const mode =
            0x00; //mode : total dose injection(0x00), (Correction Bolus) 0x01,
        // (Meal bolus) 0x02
        const BluetoothCharacteristic? characteristic =
            null; // set null then control it based on the internal
        //implementation
        await mCMgr.mPump!.sendSetDoseValue(insulinValue, mode, characteristic);
        /*
          //3. wait for the response from Pump
          //4. send CGM / delivered bolus(insulin) value to the DB
          //5. update graphic chart on CloudLoop App as like below;
          below operation could be proceed
           in void HandleResponseCallback(RSPType indexRsp, String message,
            String ActionType) defined in PumpPage
            case RSPType.PROCESSING_DONE:
              {
                // update something here after receive the processing result
                if(ActionType == HCL_BOLUS_RSP_SUCCESS)
                {
                  /*
                    /*
                     * @fn updateBloodGlucosePageBySensor(String Glucose)
                     * @brief update glucose data and emit it to server
                     * @param[in] Glucose : String double glucose data
                     */
                    void updateBloodGlucosePageBySensor(String Glucose)
                    {
                      if(FORCE_BGLUCOSE_UPDATE_FLAG) {
                        InputBloodGlucoseBloc SensorInputGlucose =
                        InputBloodGlucoseBloc(
                            inputBloodGlucose: getIt());
                        SensorInputGlucose.add(
                            InputBloodGlucoseValueChanged(value: 
                            double.parse(Glucose)));
                        if(DEBUG_MESSAGE_FLAG) {
                          debugPrint(
                              'updateBloodGlucosePageBySensor: before status =
                               ${SensorInputGlucose.state.status.isValidated}');
                        }
                        // SensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
                        SensorInputGlucose.add(const InputBloodGlucoseSubmitted.sensor()); ///< updated by sensor
                      }
                    }
                 */
                }
              }
              break;
         */
      }
    });
  }

  Future<void> _onXdripOptionSelected(String? deviceId) async {
    _selectedXdripOptionId = deviceId;
    //let's move to the select page here
    //let's set BGStream Callback here
    switch (_selectedXdripOptionId) {
      case 'xdripHome':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        await XDripLauncher.launchXDripHome();
        break;
      case 'StartSensor':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        await XDripLauncher.startNewSensor();
        break;
      case 'BGHistory':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm!,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        await XDripLauncher.bgHistory();
        break;
      case 'BluetoothScan':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        await XDripLauncher.bluetoothScan();
        break;

      case 'FakeNumbers':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        await XDripLauncher.fakeNumbers();
        break;
    }
  }

  void _onDeviceSelected(String? deviceId) {
    setState(() {
      _selectedDeviceId = deviceId;
    });
  }

  void _onTransmitterIdChanged(String value) {
    setState(() {
      _TransmitterId = value;
    });
  }

  void _onValidCodeChanged(String value) {
    setState(() {
      _validCode = int.parse(value);
    });
  }

  /*
   * @fn _handleCgmResponseCallbackDialogView(RSPType indexRsp, String message, 
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
    log('${TAG}kai:_handleCgmResponseCallbackDialogView() is called, mounted = ${mounted}');
    log('${TAG}kai:RSPType($indexRsp)\nmessage($message)'
        '\nActionType($actionType)');
    final _notifier = mCMgr.mCgm!;
    if (_notifier == null) {
      log('${TAG}kai:_handleCgmResponseCallbackDialogView(): mCMgr.mCgm is '
          'null!!: Cannot handle the response event!! ');
      return;
    }

    switch (indexRsp) {
      case RSPType.PROCESSING_DONE:
        {
          log('${TAG}kai:PROCESSING_DONE: redraw Screen widgits ');
          // To do something here after receive the processing result
          if (actionType == HCL_BOLUS_RSP_SUCCESS) {
            /*
              /*
               * @fn updateBloodGlucosePageBySensor(String Glucose)
               * @brief update glucose data and emit it to server
               * @param[in] Glucose : String double glucose data
               */
              void updateBloodGlucosePageBySensor(String Glucose)
              {
                if(FORCE_BGLUCOSE_UPDATE_FLAG) {
                  InputBloodGlucoseBloc SensorInputGlucose = 
                  InputBloodGlucoseBloc(inputBloodGlucose: getIt());
                  SensorInputGlucose.add(    
                  InputBloodGlucoseValueChanged(value: double.parse(Glucose)));
                  if(DEBUG_MESSAGE_FLAG) {
                    debugPrint(
                        'updateBloodGlucosePageBySensor: before status = 
                        ${SensorInputGlucose.state
                            .status.isValidated}');
                  }
                  // SensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
                  SensorInputGlucose.add(const InputBloodGlucoseSubmitted.sensor()); ///< updated by sensor
                }
              }
           */
          }
        }
        break;

      case RSPType.TOAST_POPUP:
        {
          log('${TAG}kai:TOAST_POPUP: redraw Screen widgits ');
        }
        break;

      case RSPType.ALERT:
        {
          log('${TAG}kai:ALERT: redraw Screen widgits ');
        }
        break;

      case RSPType.NOTICE:
        {
          log('${TAG}kai:NOTICE: redraw Screen widgits ');
        }
        break;

      case RSPType.ERROR:
        {
          log('${TAG}kai:ERROR: redraw Screen widgits ');
        }
        break;

      case RSPType.WARNING:
        {
          log('${TAG}kai:WARNING: redraw Screen widgits ');
        }
        break;

      case RSPType.SETUP_INPUT_DLG:
        {
          log('${TAG}kai:SETUP_INPUT_DLG: redraw Screen widgits ');
        }
        break;

      case RSPType.SETUP_DLG:
        {
          log('${TAG}kai:SETUP_DLG: redraw Screen widgits ');
        }
        break;

      case RSPType.UPDATE_SCREEN:
        {
          log('${TAG}kai:UPDATE_SCREEN: redraw Screen widgits ');

          switch (actionType) {
            case 'NEW_BLOOD_GLUCOSE':
              {
                Future.delayed(const Duration(seconds: 1), () async {
                  final user = (await GetIt.I<GetProfileUseCase>()
                          .call(const NoParams()))
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

                  final announceMeal =
                      (await GetIt.I<GetAutoModeUseCase>().call(
                    const NoParams(),
                  ))
                          .foldRight(0, (r, previous) => r);
                  //To do something here .....
                  //1. notify to PolicyNet Executor
                  final intValue = mCMgr.mCgm!.getBloodGlucoseValue();
                  final lastValue = mCMgr.mCgm!.getLastBloodGlucose() > 0
                      ? mCMgr.mCgm!.getLastBloodGlucose()
                      : intValue;
                  log('udin:call last glucose: $lastValue');
                  final receivedTimeHistoryList =
                      mCMgr.mCgm!.getRecievedTimeHistoryList().getRange(0, 5);
                  final timeHist =
                      receivedTimeHistoryList.map<String>((i) => i).toList();

                  final bloodGlucoseHistoryList =
                      mCMgr.mCgm!.getBloodGlucoseHistoryList().getRange(0, 5);
                  final cgmHist = bloodGlucoseHistoryList
                      .map<double>((i) => i.toDouble())
                      .toList();

                  final lastInsulin = mCMgr.mPump!.getBolusDeliveryValue();
                  log('kai:call insulin '
                      'carb ratio = ${user.insulinCarbRatio.toString()}');
                  final response = await mCMgr.mPN!.execution(
                    cgmHist: cgmHist,
                    timeHist: timeHist,
                    lastInsulin: lastInsulin,
                    announceMeal: announceMeal,
                    totalDailyDose: user.totalDailyDose,
                    basalRate: user.basalRate ?? 0.0,
                    insulinCarbRatio: user.insulinCarbRatio ?? 0.0,
                    iob: 0,
                  );

                  //2. PolicyNet Executor send the calculated bolus(insulin)
                  //value to the connected Pump device after check connection
                  //status is connected
                  if (mCMgr.mPump!.ConnectionStatus ==
                      BluetoothDeviceState.connected) {
                    final insulinValue =
                        response.toString(); // U or mL, which will
                    //be calculated by PolicyNet
                    log('${TAG}kai:NEW_BLOOD_GLUCOSE:mPN.execution '
                        'result($insulinValue), call '
                        'sendSetDoseValue($insulinValue)');
                    const mode = 0x00; //mode : total dose injection(0x00),
                    //(Correction Bolus) 0x01, (Meal bolus) 0x02
                    const BluetoothCharacteristic? characteristic =
                        null; // set null then control it based on the internal
                    //implementation
                    await mCMgr.mPump!
                        .sendSetDoseValue(insulinValue, mode, characteristic);
                  }
                });

                //kai_20230512 let's call connectivityMgr.notifyListener() to
                //notify  for consumer or selector page
                mCMgr.notifyListeners();
              }
              break;

            case 'CGM_SCAN_UPDATE':
              {
                log('${TAG}CGM_SCAN_UPDATE');
                setState(() {});
                mCMgr.notifyListeners();
              }
              break;

            case 'DISCONNECT_FROM_DEVICE_CGM':
              {
                log('${TAG}DISCONNECT_FROM_DEVICE_CGM');
                setState(() {});
                mCMgr.notifyListeners();
              }
              break;

            case 'CONNECT_TO_DEVICE_CGM':
              {
                log('${TAG}CONNECT_TO_DEVICE_CGM');
                setState(() {});
                mCMgr.notifyListeners();
              }
              break;
          }
          /*
          setState(() {

          });
          */
        }
        break;
      case RSPType.MAX_RSPTYPE:
        // TODO: Handle this case.
        break;
    }

    //kai_20230501 let's update UI variables shown on the screen
    //let's update build of the widget
    if (_notifier.iscgmscanning == false) {
      debugPrint(
        '${TAG}_handleCgmResponseCallbackDialogView(): '
        '_notifier.iscgmscanning == false',
      );
      //mCMgr!.notifyListeners();
      setState(() {
        //let's update variables here
        if (_notifier.cgmfw.isNotEmpty) {
          //  mCgmFWVersion = mCMgr.mCgm!.cgmfw;
        }
      });
    }
  }

  /*
   * @brief let's implement additional service here
   */
  Future<void> _onConnectPressed() async {
    //let's check valid code and transmitter ID here
    log('kai:index.page.dart:_onConnectPressed($_selectedDeviceId)');

    if (_selectedDeviceId != 'Use Xdrip') {
      if (_validCode.toString().isEmpty && _TransmitterId.toString().isEmpty) {
        _showWarningMessage(
          context,
          'Please put valid code and transmitter ID!!',
        );
        return;
      } else if (_validCode.toString().isEmpty) {
        _showWarningMessage(context, 'Please put valid code!!');
        return;
      } else if (_TransmitterId.toString().isEmpty) {
        _showWarningMessage(context, 'Please put transmitter ID!!');
        return;
      } else if (_validCode.toString().length < maxValidCodeLength) {
        _showWarningMessage(
          context,
          'Invalid code,$maxValidCodeLength digits are required!!',
        );
        return;
      } else if (_TransmitterId.toString().length < maxTransmitterIDLength) {
        _showWarningMessage(
          context,
          'Invalid ID, $maxTransmitterIDLength digits are required!!',
        );
        return;
      }

      //Update UI
      await CspPreference.setString('dex_txid', _TransmitterId!);
      setState(() {
        _isConnecting = true;
      });

      // Simulate connection attempt
      try {
        /// 1. update selected Cgm instance here
        if (_selectedDeviceId == 'Dexcom') {
          await CspPreference.setString('cgmSourceTypeKey', 'Dexcom');

          ///< update Cgm instance
          //kai_20230519 let's backup previous setResponse callback before
          //changing cgm instance here
          final prevRspCallback = mCMgr.mCgm!.getResponseCallbackListener();
          await mCMgr.changeCGM();

          ///< update Cgm instance
          if (prevRspCallback != null) {
            // because clearDeviceInfo is always called in this case.
            mCMgr.registerResponseCallbackListener(
              mCMgr.mCgm,
              prevRspCallback,
            );
          } else {
            mCMgr.registerResponseCallbackListener(
              mCMgr.mCgm!,
              _handleCgmResponseCallbackDialogView,
            );
          }
        } else if (_selectedDeviceId == 'i-sens') {
          await CspPreference.setString('cgmSourceTypeKey', 'i-sens');
          //kai_20230519 let's backup previous setResponse callback before
          //changing cgm instance here
          final prevRspCallback = mCMgr.mCgm!.getResponseCallbackListener();
          await mCMgr.changeCGM();

          ///< update Cgm instance
          if (prevRspCallback != null) {
            // because clearDeviceInfo is always called in this case.
            mCMgr.registerResponseCallbackListener(
              mCMgr.mCgm,
              prevRspCallback,
            );
          } else {
            mCMgr.registerResponseCallbackListener(
              mCMgr.mCgm,
              _handleCgmResponseCallbackDialogView,
            );
          }
        }

        /// 2. start scanning and stop after 5 secs,
        ///  then try to connect the device
        ///    that is detected by using specified device name with
        ///  transmitter ID & valid code automatically.
        if (mCMgr.mCgm != null) {
          log('kai: call mCMgr.mCgm!.startScan(5)');
          await mCMgr.mCgm!.startScan(5);
        } else {
          log('kai: mCMgr.mCgm is null');
        }

        log('kai: delayed(Duration(seconds: 5)');
        //wait 5 secs until scan is complete
        await Future<void>.delayed(const Duration(seconds: 5));
        log('kai: after delayed(Duration(seconds: 5)');
        //scan success case
        log('kai:check mCMgr.mCgm!.getScannedDeviceLists()!.isNotEmpty');
        // if(mCMgr.mCgm!.getScannedDeviceLists()!.isNotEmpty)
        if (mCMgr.mCgm!.cgmDevices.isNotEmpty) {
          // get last two digit thru CspPreference.getString("dex_txid")
          final transmitter = CspPreference.getString('dex_txid');
          var lastTwoDigits = '';
          if (transmitter.isNotEmpty) {
            lastTwoDigits = transmitter.substring(transmitter.length - 2);
          } else {}

          final matchName = CspPreference.mCGM_NAME + lastTwoDigits;
          log('kai:matchName = $matchName');

          for (final dev in mCMgr.mCgm!.cgmDevices) {
            if (dev.name.contains(matchName)) {
              await mCMgr.mCgm!.connectToDevice(dev);

              if (mCMgr.mCgm!.cgmConnectedDevice != null) {
                log('kai:success to connect $matchName');
                setState(() {
                  _isConnecting = false;
                  _showSelectionMessage(
                    context,
                    'Success to connect scanned cgm device $matchName',
                  );
                });
              } else {
                log('kai:fail to connect $matchName');
                setState(() {
                  _isConnecting = false;
                  _showSelectionMessage(
                    context,
                    'Can not to connect scanned cgm device $matchName at '
                    'this time!!',
                  );
                });
              }

              break;
            }
          }

          mCMgr.mCgm!.notifyListeners();
        } else {
          //show toast message "There is no scanned cgm device at this time!!,
          //try it again!!" here.
          setState(() {
            _isConnecting = false;
            _showSelectionMessage(
              context,
              'There is no scanned cgm at this time.\nTry it again later!!',
            );
          });
        }
      } catch (e) {
        log('${TAG}kai: startScan failed  $e');
        setState(() {
          _isConnecting = false;
          _showSelectionMessage(
            context,
            'Scan failed. There is no scanned cgm at this time!!',
          );
        });
      }

      /// 3. go to the previous CgmPage Screen after dismiss the
      ///  ConnectionDialog.
      log('kai:not Xdrip: dismiss dialog call _onConnectPressed()');
      Navigator.of(context).pop();
    } else {
      //dismiss dialog here
      log('kai:Xdrip:dismiss dialog call _onConnectPressed()');
      //kai_20230613 if call below Navigator.of(context).pop() w/o _showPumpDialog() then context does not valid.
      // so we have to call together
      Navigator.of(context).pop();
    }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Select CGM',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: _isConnecting
          ? const Center(child: CircularProgressIndicator())
          : _selectedDeviceId == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var device in _devices)
                      RadioListTile(
                        title: Text(
                          device.id,
                          style: const TextStyle(
                            fontSize: Dimens.dp16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        value: device.id,
                        groupValue: _selectedDeviceId,
                        onChanged: _onDeviceSelected,
                      ),
                  ],
                )
              : _selectedDeviceId == 'Use Xdrip'
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var device in _xdripOptions)
                          RadioListTile<String>(
                            title: Text(
                              device.id,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            value: device.id,
                            groupValue: _selectedXdripOptionId,
                            onChanged: _onXdripOptionSelected,
                          ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Transmitter ID',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: _onTransmitterIdChanged,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Valid Code',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: _onValidCodeChanged,
                        ),
                      ],
                    ),
      actions: [
        if (_selectedDeviceId == null)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          )
        else
          ElevatedButton(
            onPressed: _onConnectPressed,
            child: const Text('Connect'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class CgmPage extends StatefulWidget {
  const CgmPage({Key? key}) : super(key: key);

  @override
  _CgmPageState createState() => _CgmPageState();
}

class _CgmPageState extends State<CgmPage> {
  final String TAG = '_CgmPageState:';
  bool _isConnected = false;
  late ConnectivityMgr mCMgr;
  //kai_20230615 backup previous callback
  ResponseCallback? mPrevRspCallback;

  @override
  void initState() {
    //let's init csp preference instance here
    CspPreference.initPrefs();

    ///< shared Preference
    super.initState();
    log('kai:cgmPage:initState() is called');
    mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
    //kai_20230519 register response callback here
    final prevRspCallbackCgm = mCMgr.mCgm!.getResponseCallbackListener();
    if (prevRspCallbackCgm == null) {
      log('kai:cgmPage.initState(): register '
          'mCMgr.registerResponseCallbackListener(mCMgr.mCgm!, '
          'HandleResponseCallbackCgm)');
      mCMgr.registerResponseCallbackListener(
        mCMgr.mCgm,
        HandleResponseCallbackCgm,
      );
      //backup here
      mPrevRspCallback = mCMgr.mCgm!.getResponseCallbackListener();
    } else {
      mPrevRspCallback = prevRspCallbackCgm;
    }
  }

  @override
  void dispose() {
    log('kai:cgmPage:dispose() is called');

    //kai_20230519 register response callback here
    mCMgr.unRegisterResponseCallbackListener(
      mCMgr.mCgm,
      HandleResponseCallbackCgm,
    );
    //kai_20230614 leave it
    if (mPrevRspCallback != null) {
      log('kai:call mCMgr.registerResponseCallbackListener(mCMgr.mPump!, mPrevRspCallback!)');
      mCMgr.registerResponseCallbackListener(mCMgr.mCgm!, mPrevRspCallback!);
      mPrevRspCallback = null;
    }

    super.dispose();
  }

  ///< ConnectivityManager provider for cgm/pump
  void _onConnectButtonPressed() {
    setState(() {
      _isConnected = !_isConnected;
    });
  }

  void _onSearch_ConnectButtonPressed() async {
    if (mCMgr.mCgm!.cgmConnectionStatus == BluetoothDeviceState.connected) {
      log('${TAG}_onSearch_ConnectButtonPressed():call '
          'mCMgr.mCgm!.disconnectFromDevice()');
      await mCMgr.mCgm!.disconnectFromDevice();
      //update screen
      mCMgr.mCgm!.notifyListeners();
      mCMgr.notifyListeners();
    } else {
      final result = await showDialog<BuildContext>(
        context: context,
        builder: (_) => const ConnectionDialog(),
      );
      if (result != null) {
        // TODO: Show connected device information
        //update screen
        // mCMgr.mCgm!.notifyListeners();
        mCMgr.notifyListeners();
      }
    }
  }

  void _showSelectionMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected item: $item'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    var inputText = '';
    showDialog<BuildContext>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter a value'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: const InputDecoration(hintText: 'Enter a value'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                //let's check inputText is empty first
                if (inputText.isNotEmpty) {
                  await CspPreference.setString(
                    'cgmSourceTypeKey',
                    inputText,
                  );
                  _showSelectionMessage(context, inputText);
                  await mCMgr.changeCGM();

                  ///< update Cgm instance
                  //kai_20230519 register response callback here
                  mCMgr.registerResponseCallbackListener(
                    mCMgr.mCgm,
                    HandleResponseCallbackCgm,
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDialog(BuildContext context, String value) {
    final children = <Widget>[
      ListTile(
        title: const Text('1.Dexcom'),
        onTap: () async {
          //let's update cspPreference here
          await CspPreference.setString('cgmSourceTypeKey', 'Dexcom');
          _showSelectionMessage(context, 'Dexcom');
          await mCMgr.changeCGM();

          ///< update Cgm instance
          //kai_20230519 register response callback here
          mCMgr.registerResponseCallbackListener(
            mCMgr.mCgm!,
            HandleResponseCallbackCgm,
          );
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('2.Libro'),
        onTap: () async {
          await CspPreference.setString('cgmSourceTypeKey', 'Libro');
          _showSelectionMessage(context, 'Libro');
          await mCMgr.changeCGM();

          ///< update Cgm instance
          ///kai_20230519 register response callback here
          mCMgr.registerResponseCallbackListener(
            mCMgr.mCgm!,
            HandleResponseCallbackCgm,
          );
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('3.i-sens'),
        onTap: () async {
          await CspPreference.setString('cgmSourceTypeKey', 'i-sens');
          _showSelectionMessage(context, 'i-sens');
          await mCMgr.changeCGM();

          ///< update Cgm instance
          ///kai_20230519 register response callback here
          mCMgr.registerResponseCallbackListener(
            mCMgr.mCgm!,
            HandleResponseCallbackCgm,
          );
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('4.Xdrip'),
        onTap: () async {
          await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
          await mCMgr.changeCGM();

          ///< update Cgm instance
          // mCMgr.UnregisterBGStreamDataListen(mCMgr.mCgm!);
          mCMgr.registerBGStreamDataListen(mCMgr.mCgm!, _bGDataStreamCallback);
          //XDripLauncher.FakeNumbers();
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('5.others'),
        onTap: () {
          _showInputDialog(context);
        },
      )
    ];

    //let's show dialog here
    showDialog<BuildContext>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select CGM Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  /*
   * @fn _BGDataStreamCallback(dynamic event)
   * @param[in] event : received event data structure based on json
   * @brief receive the glucose data from android MainActivity thru xdrip
   *        caller should implement this callback in order to forward the received data to the PolicyNet Executor
   */
  void _bGDataStreamCallback(dynamic event) {
    //check event here
    /*
    if(DEBUG_MESSAGE_FLAG)
    {
      // {"glucose":"150.0","timestamp":"1669944611002","raw":"0.0","direction":"Flat","source":"G6 Native / G5 Native"}
     log(TAG + ':_BGDataStreamCallback: is called');
    }
     */

    //parse json format sent from MaiActivity here
    final jsonData = json.decode(event.toString()) as Map<String, dynamic>;
/*
    if(DEBUG_MESSAGE_FLAG)
    {
     log(TAG + ': gluecose = ' +
          jsonData['glucose'].toString());
     log(TAG + ': timestamp = ' +
          jsonData['timestamp'].toString());
     log(TAG + ': raw = ' +
          jsonData['raw'].toString());
     log(TAG + ': direction = ' +
          jsonData['direction'].toString());
     log(TAG + ': source = ' +
          jsonData['source'].toString());
    }
 */

    /* save received bloodglucose time  and value here */
    final timeDate = int.parse(jsonData['timestamp'].toString());
    final glucose = jsonData['glucose'].toString();

    //update UI Screen here
    if (mounted) {
      //log('kai: mounted = ${mounted}, call setState() for update UI');
      setState(() {
        mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
        //kai_20230509 if Glucose have floating point as like double " 225.0 "
        //then convert the value to int exclude ".0" by using floor()
        // mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
        mCMgr.mCgm!.setBloodGlucoseValue(double.parse(glucose).floor());
        mCMgr.mCgm!.cgmModelName = jsonData['source'].toString();
        mCMgr.mCgm!.cgmSN = jsonData['sensorSerial'].toString();
      });
    } else {
      //log('kai: !mounted = ${mounted},  update UI');
      mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
      //kai_20230509 if Glucose have floating point as like double " 225.0 "
      //then convert the value to int exclude ".0" by using floor()
      // mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
      mCMgr.mCgm!.setBloodGlucoseValue(double.parse(glucose).floor());
      mCMgr.mCgm!.cgmModelName = jsonData['source'].toString();
      mCMgr.mCgm!.cgmSN = jsonData['sensorSerial'].toString();
    }

    //kai_20230512 let's call mCmgr.notifyListeners() for consummer or selector
    //pages which listening the updated value
    mCMgr.notifyListeners();

    // UI Update here
    if (DEBUG_MESSAGE_FLAG) {
      final mCgmGlucoseReceiveTime = DateFormat('yyyy/MM/dd HH:mm a')
          .format(DateTime.fromMillisecondsSinceEpoch(timeDate));
      final mCgmGlucoseValue = jsonData['glucose'].toString();

      log('$TAG:>>xdrip:$mCgmGlucoseReceiveTime, glucose = $mCgmGlucoseValue, '
          'raw = ${jsonData['raw']}, direction = ${jsonData['direction']}, '
          'source = ${jsonData['source']}');
    }
    // update chart graph after upload received glucose data to server
    // updateBloodGlucosePageBySensor(Glucose);
    ///< send bloodglucose data to the DB or notify PolicyNet Executor
    Future.delayed(const Duration(seconds: 1), () async {
      final user =
          (await GetIt.I<GetProfileUseCase>().call(const NoParams())).foldRight(
        const UserProfile(
          gender: Gender.female,
          name: '',
          id: '',
          weight: 0,
          totalDailyDose: 0,
        ),
        (r, previous) => r,
      );

      final announceMeal =
          (await GetIt.I<GetAutoModeUseCase>().call(const NoParams()))
              .foldRight(0, (r, previous) => r);

      //To do something here .....
      //1. notify to PolicyNet Executor
      final intValue = mCMgr.mCgm!.getBloodGlucoseValue();
      final lastValue = mCMgr.mCgm!.getLastBloodGlucose() > 0
          ? mCMgr.mCgm!.getLastBloodGlucose()
          : intValue;
      log('udin:call last glucose: $lastValue');

      final receivedTimeHistoryList =
          mCMgr.mCgm!.getRecievedTimeHistoryList().getRange(0, 5);
      final timeHist = receivedTimeHistoryList.map<String>((i) => i).toList();

      final bloodGlucoseHistoryList =
          mCMgr.mCgm!.getBloodGlucoseHistoryList().getRange(0, 5);
      final cgmHist =
          bloodGlucoseHistoryList.map<double>((i) => i.toDouble()).toList();

      final lastInsulin = mCMgr.mPump!.getBolusDeliveryValue();
      log('kai:call mCMgr.mPN!.execution(${cgmHist.toString()})');
      log('kai:call insulin '
          'carb ratio = ${user.insulinCarbRatio.toString()}');
      final response = await mCMgr.mPN!.execution(
        cgmHist: cgmHist,
        timeHist: timeHist,
        lastInsulin: lastInsulin,
        announceMeal: announceMeal,
        totalDailyDose: user.totalDailyDose,
        basalRate: user.basalRate ?? 0.0,
        insulinCarbRatio: user.insulinCarbRatio ?? 0.0,
        iob: 0,
      );

      //2. PolicyNet Executor send the calculated bolus(insulin) value to the connected Pump device after check connection status is connected
      if (mCMgr.mPump!.ConnectionStatus == BluetoothDeviceState.connected) {
        final insulinValue = response
            .toString(); // U or mL, which will be calculated by PolicyNet
        log('kai:mPN.execution result($insulinValue), call sendSetDoseValue($insulinValue)');
        const mode =
            0x00; //mode : total dose injection(0x00), (Correction Bolus) 0x01, (Meal bolus) 0x02
        const BluetoothCharacteristic? characteristic =
            null; // set null then control it based on the internal implementation
        await mCMgr.mPump!.sendSetDoseValue(insulinValue, mode, characteristic);
        /*
          //3. wait for the response from Pump
          //4. send CGM / delivered bolus(insulin) value to the DB
          //5. update graphic chart on CloudLoop App as like below;
          below operation could be proceed
           in void HandleResponseCallback(RSPType indexRsp, String message, String ActionType) defined in PumpPage
            case RSPType.PROCESSING_DONE:
              {
                // update something here after receive the processing result
                if(ActionType == HCL_BOLUS_RSP_SUCCESS)
                {
                  /*
                    /*
                     * @fn updateBloodGlucosePageBySensor(String Glucose)
                     * @brief update glucose data and emit it to server
                     * @param[in] Glucose : String double glucose data
                     */
                    void updateBloodGlucosePageBySensor(String Glucose)
                    {
                      if(FORCE_BGLUCOSE_UPDATE_FLAG) {
                        InputBloodGlucoseBloc SensorInputGlucose = InputBloodGlucoseBloc(
                            inputBloodGlucose: getIt());
                        SensorInputGlucose.add(
                            InputBloodGlucoseValueChanged(value: double.parse(Glucose)));
                        if(DEBUG_MESSAGE_FLAG) {
                          debugPrint(
                              'updateBloodGlucosePageBySensor: before status = ${SensorInputGlucose.state
                                  .status.isValidated}');
                        }
                        // SensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
                        SensorInputGlucose.add(const InputBloodGlucoseSubmitted.sensor()); ///< updated by sensor
                      }
                    }
                 */
                }
              }
              break;
         */
      }
    });
  }

  /*
   * @brief Handle ResponseCallback event sent from CGM
   *        if caller register this callback which should be implemented
   *        by using ConnectivityMgr.registerResponseCallbackListener(IDevice,
   *  ResponseCallback) then
   *        caller can receive an event delivered from Cgm and handle it.
   */
  void HandleResponseCallbackCgm(
    RSPType indexRsp,
    String message,
    String ActionType,
  ) {
    log('${TAG}kai:HandleResponseCallbackCgm() is called, mounted = ${mounted}');
    log('${TAG}kai:RSPType($indexRsp)\nmessage($message)\n'
        'ActionType($ActionType)');
    final _notifier = mCMgr.mCgm!;
    if (_notifier == null) {
      log('${TAG}kai:HandleResponseCallback(): mCMgr.mCgm is null!!: Cannot '
          'handle the response event!! ');
      return;
    }

    switch (indexRsp) {
      case RSPType.PROCESSING_DONE:
        {
          log('${TAG}kai:PROCESSING_DONE: redraw Screen widgits ');
          // To do something here after receive the processing result
          if (ActionType == HCL_BOLUS_RSP_SUCCESS) {
            /*
              /*
               * @fn updateBloodGlucosePageBySensor(String Glucose)
               * @brief update glucose data and emit it to server
               * @param[in] Glucose : String double glucose data
               */
              void updateBloodGlucosePageBySensor(String Glucose)
              {
                if(FORCE_BGLUCOSE_UPDATE_FLAG) {
                  InputBloodGlucoseBloc SensorInputGlucose = 
                  InputBloodGlucoseBloc(
                      inputBloodGlucose: getIt());
                  SensorInputGlucose.add(
                      InputBloodGlucoseValueChanged(value: 
                      double.parse(Glucose)));
                  if(DEBUG_MESSAGE_FLAG) {
                    debugPrint(
                        'updateBloodGlucosePageBySensor: 
                        before status = ${SensorInputGlucose.state
                            .status.isValidated}');
                  }
                  // SensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
                  SensorInputGlucose.add(const InputBloodGlucoseSubmitted.sensor()); ///< updated by sensor
                }
              }
           */
          }
        }
        break;

      case RSPType.TOAST_POPUP:
        {
          log('${TAG}kai:TOAST_POPUP: redraw Screen widgits ');
        }
        break;

      case RSPType.ALERT:
        {
          log('${TAG}kai:ALERT: redraw Screen widgits ');
        }
        break;

      case RSPType.NOTICE:
        {
          log('${TAG}kai:NOTICE: redraw Screen widgits ');
        }
        break;

      case RSPType.ERROR:
        {
          log('${TAG}kai:ERROR: redraw Screen widgits ');
        }
        break;

      case RSPType.WARNING:
        {
          log('${TAG}kai:WARNING: redraw Screen widgits ');
        }
        break;

      case RSPType.SETUP_INPUT_DLG:
        {
          log('${TAG}kai:SETUP_INPUT_DLG: redraw Screen widgits ');
        }
        break;

      case RSPType.SETUP_DLG:
        {
          log('${TAG}kai:SETUP_DLG: redraw Screen widgits ');
        }
        break;

      case RSPType.UPDATE_SCREEN:
        {
          log('${TAG}kai:UPDATE_SCREEN: redraw Screen widgits ');

          switch (ActionType) {
            case 'NEW_BLOOD_GLUCOSE':
              {
                Future.delayed(const Duration(seconds: 1), () async {
                  final user = (await GetIt.I<GetProfileUseCase>()
                          .call(const NoParams()))
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

                  final announceMeal = (await GetIt.I<GetAutoModeUseCase>()
                          .call(const NoParams()))
                      .foldRight(0, (r, previous) => r);
                  //To do something here .....
                  //1. notify to PolicyNet Executor

                  final receivedTimeHistoryList =
                      mCMgr.mCgm!.getRecievedTimeHistoryList().getRange(0, 5);
                  final timeHist =
                      receivedTimeHistoryList.map<String>((i) => i).toList();

                  final bloodGlucoseHistoryList =
                      mCMgr.mCgm!.getBloodGlucoseHistoryList().getRange(0, 5);
                  final cgmHist = bloodGlucoseHistoryList
                      .map<double>((i) => i.toDouble())
                      .toList();

                  final lastInsulin = mCMgr.mPump!.getBolusDeliveryValue();

                  log('kai:call announceMeal status = $announceMeal');
                  log('kai:call total daily dose = ${user.totalDailyDose}');
                  log('kai:call basal rate = ${user.basalRate}');
                  log('kai:call cgmHist = $cgmHist');
                  log('kai:call timeHist = $timeHist');
                  log('kai:call insulin '
                      'carb ratio = ${user.insulinCarbRatio.toString()}');
                  final response = await mCMgr.mPN!.execution(
                    cgmHist: cgmHist,
                    timeHist: timeHist,
                    lastInsulin: lastInsulin,
                    announceMeal: announceMeal,
                    totalDailyDose: user.totalDailyDose,
                    basalRate: user.basalRate ?? 0.0,
                    insulinCarbRatio: user.insulinCarbRatio ?? 0.0,
                    iob: 0,
                  );

                  //2. PolicyNet Executor send the calculated bolus(insulin)
                  //value to the connected Pump device after check connection
                  //status is connected
                  if (mCMgr.mPump!.ConnectionStatus ==
                      BluetoothDeviceState.connected) {
                    final insulinValue =
                        response.toString(); // U or mL, which will be
                    // calculated by PolicyNet
                    log('${TAG}kai:NEW_BLOOD_GLUCOSE:mPN.execution '
                        'result($insulinValue), call '
                        'sendSetDoseValue($insulinValue)');
                    const mode = 0x00; //mode : total dose injection(0x00),
                    //(Correction Bolus) 0x01, (Meal bolus) 0x02
                    const BluetoothCharacteristic? characteristic =
                        null; // set null then control it based on the
                    //internal implementation
                    await mCMgr.mPump!
                        .sendSetDoseValue(insulinValue, mode, characteristic);
                  }
                });

                //kai_20230512 let's call connectivityMgr.notifyListener()
                ////to notify  for consumer or selector page
                mCMgr.notifyListeners();
              }
              break;

            case 'CGM_SCAN_UPDATE':
              {
                log('${TAG}CGM_SCAN_UPDATE');
                setState(() {});
                mCMgr.notifyListeners();
              }
              break;

            case 'DISCONNECT_FROM_DEVICE_CGM':
              {
                log('${TAG}DISCONNECT_FROM_DEVICE_CGM');
                setState(() {});
                mCMgr.notifyListeners();
              }
              break;

            case 'CONNECT_TO_DEVICE_CGM':
              {
                log('${TAG}CONNECT_TO_DEVICE_CGM');
                setState(() {});
                mCMgr.notifyListeners();
              }
              break;
          }
          /*
          setState(() {

          });
          */
        }
        break;
      case RSPType.MAX_RSPTYPE:
        break;
    }

    //kai_20230501 let's update UI variables shown on the screen
    //let's update build of the widget
    if (_notifier.iscgmscanning == false) {
      debugPrint(
        '${TAG}HandleResponseCallbackCgm(): _notifier.iscgmscanning == false',
      );
      //mCMgr!.notifyListeners();
      setState(() {
        //let's update variables here
        if (_notifier.cgmfw.isNotEmpty) {
          //  mCgmFWVersion = mCMgr.mCgm!.cgmfw;
        }
      });
    }
  }

  /*
   * @brief show the lists that scanned device by using predefined device name
   */
  // Build the ListView of devices
  Widget _buildListView() {
    final listTiles = <ListTile>[];

    if (mCMgr.mPump!.getScannedDeviceLists() != null) {
      for (final device in mCMgr.mCgm!.getScannedDeviceLists()!) {
        listTiles.add(
          ListTile(
            title: Text(
              device.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            subtitle: Text(
              device.id.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            trailing: ElevatedButton(
              style: ButtonStyle(
                minimumSize: MaterialStateProperty.all<Size>(
                  const Size(60, 25),
                ),
                // backgroundColor:
                // MaterialStateProperty.all<Color>(Colors.white),
                // shadowColor: MaterialStateProperty.all<Color>(Colors.grey),
              ),
              child: Text(
                mCMgr.mCgm!.cgmConnectionStatus ==
                        BluetoothDeviceState.connected
                    ? 'Disconnect'
                    : 'Connect',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  // color: Button_primarySolidColor,
                ),
              ),
              onPressed: () => (mCMgr.mCgm!.cgmConnectionStatus ==
                      BluetoothDeviceState.connected)
                  ? mCMgr.mCgm!.disconnectFromDevice()
                  : mCMgr.mCgm!.connectToDevice(device),
            ),
          ),
        );
      }
    }

    return ListView(
      children: listTiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select CGM Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'xdripHome':
                  XDripLauncher.launchXDripHome();
                  break;
                case 'StartSensor':
                  XDripLauncher.startNewSensor();
                  break;
                case 'BGHistory':
                  XDripLauncher.bgHistory();
                  break;

                case 'BluetoothScan':
                  XDripLauncher.bluetoothScan();
                  break;

                case 'FakeNumbers':
                  XDripLauncher.fakeNumbers();
                  break;

                case 'CGM_Type':
                  _showDialog(context, value);
                  break;

                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'xdripHome',
                  child: Text('xdripHome'),
                ),
                const PopupMenuItem(
                  value: 'StartSensor',
                  child: Text('StartSensor'),
                ),
                const PopupMenuItem(
                  value: 'BGHistory',
                  child: Text('BGHistory'),
                ),
                const PopupMenuItem(
                  value: 'BluetoothScan',
                  child: Text('BluetoothScan'),
                ),
                const PopupMenuItem(
                  value: 'FakeNumbers',
                  child: Text('FakeNumbers'),
                ),
                const PopupMenuItem(
                  value: 'CGM_Type',
                  child: Text('CGM Type'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        //color: Colors.grey.shade300,
        padding: const EdgeInsets.all(16),
        child: Column(
          //kai_20230501 center align // mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,

          ///< left align
          children: <Widget>[
            Text(
              //'Connection Status: ${_isConnected ?
              //'Connected' : 'Disconnected'}',
              'Connection Status: '
              '${mCMgr.mCgm!.cgmConnectionStatus == BluetoothDeviceState.connected ? 'Connected' : 'Disconnected'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: Dimens.dp16),
            Text(
              'Device Name: ${mCMgr.mCgm!.getModelName()}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: Dimens.dp16),
            Text(
              'Latest Glucose Value: ${mCMgr.mCgm!.getBloodGlucoseValue().toString()}mg/dL',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: Dimens.dp16),
            Text(
              'Latest Receive Time: '
              '${mCMgr.mCgm!.getLastTimeBGReceived() == 0 ? '' : 'DateFormat '
                  '("yyyy/MM/dd HH:mm:ss").format(DateTime. '
                  'fromMillisecondsSinceEpoch(mCMgr.mCgm!.'
                  'getLastTimeBGReceived()))'}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onSearch_ConnectButtonPressed,
              child: Text(
                /*_isConnected ? 'Disconnect' : 'Search & Connect',*/
                mCMgr.mCgm!.cgmConnectionStatus ==
                        BluetoothDeviceState.connected
                    ? 'Disconnect'
                    : 'Search & Connect',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Expanded(
              child: (mCMgr.mCgm!.getScannedDeviceLists() != null &&
                      mCMgr.mCgm!.getScannedDeviceLists()!.isEmpty)
                  ? const Center(
                      child: Text(
                        'No device found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    )
                  : _buildListView(),
              // (Csp1devices != null && Csp1devices!.isEmpty) ? Center( child:
              //Text('No devices found'),) : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }
}

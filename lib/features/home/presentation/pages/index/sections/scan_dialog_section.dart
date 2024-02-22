import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/settings/domain/entities/entities.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILog.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILogDB.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/audioplay/csaudioplayer.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/csBluetoothProvider.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/PumpDanars.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/presentation.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

//kai_20230519  if use simulation by using
//virtual cgm app then set true here, others set false;
const bool USE_SIMULATION_THRU_VIRTUAL_CGM = false;
// kai_20230225 TEST Feature define here
const bool FEATURE_CHECK_WR_CHARACTERISTIC = false;
//request csp information
const bool FEATURE_CSP_INFO_REQUEST = true;
//use status listener
const bool FEATURE_STATUS_REGISTER_BY_USER = false;
//use cs bluetooth provider
const bool _USE_CSBLUETOOTH_PROVIDER = true;
//kai_20300404  test only
const bool _USE_TEST_SCAN = false;
//kai_20300411  tts
const bool _USE_TTS_PLAYBACK = false;
const bool _USE_AUDIO_PLAYBACK = true;
const bool _USE_AUDIOCACHE = true;

//kai_20230515 added to address some problems ( dialog & RX char Notify issue )
const bool _USE_GLOBAL_KEY = true;
const bool _USE_FORCE_RX_NOTI_ENABLE = true;

/*
 * @brief Curestream Pump UUID
 */
const String CSP_SERVICE_UUID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

///< sending data from app to csp
const String CSP_TX_CHARACTERISTIC =
    '6e400003'; //0x0003               /*< The UUID of the TX Characteristic. */
const String CSP_RX_CHARACTERISTIC =
    '6e400002'; //0x0002               /*< The UUID of the RX Characteristic. */
const String CSP_TX_WRITE_CHARACTER_UUID =
    '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

///< sending data from app to csp
const String CSP_RX_READ_CHARACTER_UUID =
    '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

///< receiving data from csp to app
const String CSP_BATLEVEL_NOTIFY_CHARACTER_UUID =
    '00002a19-0000-1000-8000-00805f9b34fb';

///< receiving battery level data from csp
const String CSP_PUMP_NAME = 'csp-1';

/*
 * @brief danaRS Pump UUID
 */
const String DANARS_BOLUS_SERVICE = '0000fff0-0000-1000-8000-00805f9b34fb';
const String DANARS_READ_UUID = '0000fff1-0000-1000-8000-00805f9b34fb';
const String DANARS_WRITE_UUID = '0000fff2-0000-1000-8000-00805f9b34fb';
const String DANARS_PUMP_NAME = 'Dana-i';

///< Dana-i5

/*
 * @brief caremedi pump UUID
 *
 */
const String CareLevoSERVICE_UUID = 'e1b40001-ffc4-4daa-a49b-1c92f99072ab';

///< pump service uuid
const String CareLevoRX_CHAR_UUID = 'e1b40003-ffc4-4daa-a49b-1c92f99072ab';

///< pump send msg to app
const String CareLevoTX_CHAR_UUID = 'e1b40002-ffc4-4daa-a49b-1c92f99072ab';

///< pump receive msg from app
const String CareLevo_PUMP_NAME = 'CareLevo'; //'CM100K';

/*
 * @brief dexcom pump UUID
 */
const String DexcomSERVICE_UUID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

///< pump service uuid
const String DexcomRX_CHAR_UUID = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

///< pump send msg to app
const String DexcomTX_CHAR_UUID = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

///< pump receive msg from app
const String Dexcom_PUMP_NAME = 'Dexcom';

/*
 * @brief curestream pump commands
 */
//curestream pump commands define here
const String _cmdBatLevel = 'BAT:';

///< Battery Level:
const String _cmdFwVersion = 'FWV:';

///< Firmware Version:
const String _cmdInjectInsulin = 'IJI:';

///< Injection Insulin Amount:
const String _cmdRemainInsulinAmount = 'RIA:';

///< Remained Insulin Amount:
const String _cmdOcclusionAlert = 'OCA:';

///< Occlusion Alert Status:
const String _cmdInjectTime = 'IJT:';

///< Latest Insulin Injection Time:
const String _cmdInjectIntervalTime = 'IIT:';

///< Insulin Injection Interval Time:
const String _cmdIJILogHeader = 'IJILog';

///< Insulin Injection Log Header Command :
/*
 *@brief Sync local time delivered from mobile app to CSP1 and the format is like "2023-01-01,14:10:20"
 */
const String _cmdActionSyncLocalTime = 'CTS=';

//CSP1 Alert String
const String _alertOcclusion = 'Occlusion';

///< occlusion "OCLAL"
const String _alertLowBattery = 'Low Battery';

///<  Battery Low "BATLO"
const String _alertLowReservoir = 'Low Reservoir';

///< Remained Insulin Amount Low  "RIALO"
const String _alertReport = 'Report';

///< report result for sending IJILog to mobile app

const String _cmdSerialNumber = 'SLN:';

///< serial number

final List<String> iJILogTypes = [
  'bolus',
  'basal',
  'occlusion',
  'low battery',
  'low reservoir'
];

///< CSP1 Injection Insulin Log Type String

//color for button
const Color buttonPrimarySolidColor = Color(0xFF5297FF);
const Color selectedItemColor = Color(0xff3267E3);
const Color unselectedItemColor = Color(0xff94A3B8);

class ScanDialogPage extends StatelessWidget {
  const ScanDialogPage({
    Key? key,
    required this.hasConnectedBefore,
  }) : super(key: key);

  final bool hasConnectedBefore;

  @override
  Widget build(BuildContext context) {
    return ScanDialogView(
      hasConnectedBefore: hasConnectedBefore,
    );
  }
}

class ScanDialogView extends StatefulWidget {
  const ScanDialogView({
    Key? key,
    required this.hasConnectedBefore,
  }) : super(key: key);

  final bool hasConnectedBefore;

  @override
  State<ScanDialogView> createState() => _ScanDialogViewState();
}

class _ScanDialogViewState extends State<ScanDialogView> {
  final GlobalKey<State> _key = GlobalKey();

  ///< context for showing dialog anywhere
  String _alertmessage = '';

  ///< text field that showing alert message sent from pump
  String _txErrorMsg = '';

  ///< toast message field to show sending message error

  String _setupWizardMessage = '';

  ///< dialog message field that showing a notification which give a option to user
  String _ActionType = '';

  ///< setupWizard dialog action type to distinguish the actions

  final String TAG = '_ScanDialogViewState:';
  //kai input message string variable for pump and cgm
  String inputTextCgm = '';

  ///< input dialog text field for Cgm
  String inputTextPump = '';

  ///< input dialog text field for Pump

  String mBOLUS_SERVICE = CSP_SERVICE_UUID;

  ///< connected device's service UUID
  String mRX_READ_UUID = CSP_RX_READ_CHARACTER_UUID;

  ///< connected device's RX UUID
  String mTX_WRITE_UUID = CSP_TX_WRITE_CHARACTER_UUID;

  ///< connected device's TX UUID
  String mPUMP_NAME = CSP_PUMP_NAME;

  ///< connected device's Name
  int mFindCharacteristicMax = 3;

  ///< supported characteristic number for each type (RX,TX, Battery,  etc...)

  //csp characteristic variable define here
  BluetoothCharacteristic? m_TX_WRITE_CHARACTERISTIC = null;

  ///< connected device's TX characteristic instance
  BluetoothCharacteristic? m_RX_READ_CHARACTERISTIC = null;

  ///< connected device's RX characteristic instance
  BluetoothCharacteristic? m_RX_BATLEVEL_CHARACTERISTIC = null;

  ///< connected device's RX Battery characteristic instance
  BluetoothDevice? mPump = null;

  ///< connected device instance

  /*
  var m_RX_READ_CHARACTERISTIC_VALUE_LISTENER = null; ///< RX characteristic's value listener
  var m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER = null; ///< RX Battery characteristic's value listener
  */
  StreamSubscription<List<int>>? m_RX_READ_CHARACTERISTIC_VALUE_LISTENER = null;
  StreamSubscription<List<int>>? m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
      null;

  //StreamSubscription<ScanResult>? _csp1scanSubscription;
  StreamSubscription<List<ScanResult>>? _csp1scanSubscription = null;

  ///< connected device's scanning status listener
  // Handle connection status changes.
  StreamSubscription<BluetoothDeviceState>? connectionSubscription;

  ///< connected device's connection status listener
  FlutterBluePlus? Csp1flutterBlue;

  ///<  = FlutterBluePlus.instance;
  List<BluetoothDevice>? Csp1devices;

  ///< scanned device lists // = <BluetoothDevice>[];

  // device name, battery status alert, connection status, Remained Insulin Amount,
  // Injected Insulin Amount, Inject Insulin time, occlusion alert, setting for insulin injection time
  String mPumpName = '';

  ///< device name
  String mPumpMacAddress = '';

  ///< device ID
  String mModelName = '';

  ///< connected device model name
  String mPumpFWVersion = '';

  ///< connected device f/w version as like csp1v.0.0.0
  String mSN = '';

  ///< connected device serial number
  String mPumpConnectionStatus = 'Disconnected'; //l10n!.disconnected;
  String mFirstConnectionTime = '';

  ///< first pump connection time
  String mPatchUseAvailableTime = '';

  ///< pump usage remain Available Time
  String mPumpInsulinRemain = '';

  ///< reservoir : max 20 ml ~ 0 ml
  String mPumpInsulinInject = '';

  ///< 0.05 ml ~ 25 : double
  String mPumpInjectIntervalTime = '';

  ///< minute
  String mPumpInjectTime = '';

  ///< miliseconds : int =>  DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
  String mPumpBatteryStatus = '';

  ///< battery status : lower than 30% , alert low Battery
  String mPumpOcclusionAlert = '';

  ///< alert showing message field : l10n!.normal; //  ///< alert, normal
  String mPumpstateText = 'Disconnected';

  ///< connection status text field =>  //l10n!.disconnected; //
  String mPumpconnectButtonText = 'Disconnect';

  ///< button text show => l10n!.disconnect; //

  // save current status
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  ///< cgm
  BluetoothDeviceState mPumpdeviceState = BluetoothDeviceState.disconnected;

  ///< Pump

  // show insulin injection history to Pump
  String mPumpInsulinHistoryLog = '';

  ///< insulin delivery data & time history log => 20221122-16-26,0.05ml,5ml
  //define IJILog database variable : Injection Insulin Log data
  late IJILogDB mIJILogDB;

  ///< insulin delivery data & time database

  late CsaudioPlayer mAudioPlayer;

  ///< alert audio sound playback instance
  late BluetoothProvider mBTProvider;

  ///< csBluetoothProvider
  late ConnectivityMgr mCMgr;

  ///< ConnectivityManager provider for cgm/pump

  //let's handle pendding dialog to set dialog Pendding flag here
  int penddingDialogKeyCurrentContextNULL = 0;
  List<String> pendingDlgMsg = [];
  List<String> pendingDlgAction = [];
  List<String> pendingDlgTitle = [];

  //kai_20230515 let's monitoring reconnection case after disconnect
  // due to sometimes RX Characteristic Notify does not enabled
  // regardless of status is true.
  int disconnectedAfterConnection = 0;

  //kai_20230615 backup previous callback
  ResponseCallback? mPrevRspCallback = null;

  //kai_20230830
  String mShowScanStatus = ''; //"Scanning...";
  bool isScanningTimeout = false;
  late BuildContext? mContext = null;

  @override
  void initState() {
    super.initState();
    //let's init csp preference instance here
    // cspPreference.initPrefs();  ///< shared Preference
    // super.initState();
    mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
    mContext = (USE_APPCONTEXT == true && mCMgr.appContext != null)
        ? mCMgr.appContext!
        : context;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });

    //get IJILog database and logs  here
    mIJILogDB = IJILogDB();
    mIJILogDB.getIJIDataBase();
  }

  Future<void> _start() async {
    //kai_20230830
    isScanningTimeout = false;
    setState(() {
      mShowScanStatus = context.l10n.scanning; //"Scanning...";
    });

    //kai_20230925 clear connected
    //list here in case of hasConnectedBefore is false
    if (widget.hasConnectedBefore == false) {
      if (mCMgr.mPump!.getConnectedDevice() != null) {
        await mCMgr.mPump!.getConnectedDevice()!.clearGattCache();
        mCMgr.mPump!.ConnectedDevice = null;
        debugPrint(
          '$TAG:kai:call mCMgr.mPump!.getScannedDeviceLists()!.clear()',
        );
      }
    }

    Future.delayed(
      Duration(seconds: widget.hasConnectedBefore ? 0 : 5),
      _startScan,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.l10n.selectInputItem(context.l10n.pump),
        style: const TextStyle(
          fontSize: Dimens.dp16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: _buildListView(),
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
              width: Dimens.dp8,
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: isScanningTimeout
                    ? () async {
                        await _start();
                      }
                    : null,
                child: Text(context.l10n.search), //kai_20230705 changed
              ),
            ),
            const SizedBox(
              width: Dimens.dp16,
            ),
          ],
        ),
        // ElevatedButton(
        //   onPressed: () {
        //     //kai_20230911 let's clear scanedlist here
        //     if (mCMgr.mPump!.getScannedDeviceLists() != null) {
        //       mCMgr.mPump!.getScannedDeviceLists()!.clear();
        //       debugPrint(
        //         '$TAG:kai:call mCMgr.mPump!.getScannedDeviceLists()!.clear()',
        //       );
        //     }
        //     Navigator.of(context).pop();
        //   },
        //   child: Text(context.l10n.cancel),
        // ),
      ],
    );
  }

  /*
   * @brief start scanning
   */
  Future<void> _startScan() async {
    try {
      debugPrint('$TAG:_startScan(): mounted = $mounted');
      /*
      if(mounted)
      {
        setState(() {
          mShowScanStatus = context.l10n.scanning; //"Scanning...";
        });
      }
      */
      //clear Csp1devices here before start scan
      if (_USE_CSBLUETOOTH_PROVIDER == true) {
        if (mCMgr.mPump!.getScannedDeviceLists() != null) {
          mCMgr.mPump!.getScannedDeviceLists()!.clear();
        }

        //kai_20230516 release mode,
        // we get the error that whenever start scan, bluetooth does not enabled
        // let's check instance again here
        if (mCMgr.mPump!.mPumpflutterBlue == null) {
          mCMgr.mPump!.mPumpflutterBlue = FlutterBluePlus.instance;
        }

        if (mCMgr.mPump!.mPumpflutterBlue.isScanning == true) {
          debugPrint(
            '$TAG:kai: _stopScan(): mounted = $mounted',
          );
          await _stopScan();
          if (_csp1scanSubscription != null) {
            await _csp1scanSubscription!.cancel();
            _csp1scanSubscription = null;
          }
        }

        if (_csp1scanSubscription != null) {
          //kai_20230517 clear previous scanSubscription here
          log(':kai: call _csp1scanSubscription!.cancel()');
          await _csp1scanSubscription!.cancel();
          _csp1scanSubscription = null;
        }

        if (_csp1scanSubscription == null) {
          debugPrint(
            '$TAG:kai: register scanResults.listen(): mounted = $mounted',
          );
          _csp1scanSubscription =
              mCMgr.mPump!.mPumpflutterBlue.scanResults.listen((results) {
            debugPrint('$TAG:kai: call PumpflutterBlue!.scanResults.listen:');
            for (final r in results) {
              if (r.device.name.isNotEmpty) {
                if (_USE_TEST_SCAN == true) {
                  debugPrint(
                    '${TAG}kai:_startScan :r.device.name(${r.device.name}), '
                    'cspPreference.mPUMP_NAME = ${CspPreference.mPUMP_NAME}, '
                    'r.device.id(${r.device.id})',
                  );
                }
              } else {
                //kai_20300404 test only
                if (_USE_TEST_SCAN == true) {
                  debugPrint(
                    '${TAG}kai: _startScan : '
                    'Csp1devices!.add(${r.device.name}), '
                    'r.device.id(${r.device.id}), mounted = $mounted',
                  );
                }
              }

              if (mounted &&
                  (mCMgr.mPump!.getScannedDeviceLists() != null &&
                      !mCMgr.mPump!
                          .getScannedDeviceLists()!
                          .contains(r.device))) {
                if (mounted) {
                  // Check if the widget is still mounted
                  setState(() {
                    if (r.device.name.isNotEmpty) {
                      if (r.device.name.contains(CspPreference.mPUMP_NAME)) {
                        debugPrint(
                          '${TAG}kai: _startScan : '
                          'Csp1devices!.add(${r.device.name}), '
                          'r.device.id(${r.device.id})',
                        );

                        if (widget.hasConnectedBefore) {
                          connectDiscovery(r.device);
                        }
                        mCMgr.mPump!.getScannedDeviceLists()!.add(r.device);
                      } else {
                        debugPrint('${TAG}kai: _startScan : not matched ');
                        //in case of danai  device name is serial number, so need to add here
                        if (CspPreference.mPUMP_NAME.isNotEmpty &&
                            CspPreference.mPUMP_NAME
                                .contains(DANARS_PUMP_NAME)) {
                          //if (r.device.name.toString().contains('XML'))
                          if (r.device.name.length >= 10 &&
                              r.device.name.toLowerCase()[0] == 'x' &&
                              r.device.name.toLowerCase()[9] == 'i') {
                            mCMgr.mPump!.getScannedDeviceLists()!.add(r.device);
                          }
                        }
                        //kai_20300404 test only
                        if (_USE_TEST_SCAN == true) {
                          mCMgr.mPump!.getScannedDeviceLists()!.add(r.device);
                        }
                      }
                    } else {
                      //kai_20300404 test only
                      if (_USE_TEST_SCAN == true) {
                        debugPrint(
                          '${TAG}kai: _startScan : '
                          'Csp1devices!.add(${r.device.name}), '
                          'r.device.id(${r.device.id})',
                        );
                        mCMgr.mPump!.getScannedDeviceLists()!.add(r.device);
                      }
                    }
                  });
                }
              }
            }

            if (mCMgr.mPump != null &&
                mCMgr.mPump!.getScannedDeviceLists()!.isEmpty) {
              debugPrint(
                '$TAG:kai: call PumpflutterBlue!.scanResults.listen: '
                'mpumpdeviceLists is zero!!',
              );
            } else {
              debugPrint(
                '$TAG:kai: call PumpflutterBlue!.scanResults.listen: '
                'done : mpumpdeviceLists.length = '
                '${mCMgr.mPump!.getScannedDeviceLists()!.length}',
              );
            }
          });
        } else {
          debugPrint(
            '$TAG:kai: failed to register '
            'scanResults.listen(): mounted = $mounted',
          );
        }

        debugPrint(
          '$TAG:kai: PumpflutterBlue!.startScan(timeout: '
          'Duration(seconds: 5)): mounted = $mounted',
        );

        //kai_20230830
        /*
        setState(() {
          mShowScanStatus = context.l10n.scanning; //"Scanning...";
        });
        */
        /*kai_20230830  await mCMgr.mPump!.mPumpflutterBlue
            .startScan(timeout: const Duration(seconds: 5));  */
        await mCMgr.mPump!.mPumpflutterBlue
            .startScan(timeout: const Duration(seconds: 5))
            .whenComplete(
          () async {
            if (mounted) {
              if (mCMgr.mPump!.getScannedDeviceLists()!.isEmpty) {
                //kai_20230839 timeout
                //scanning device & connected device on the list
                setState(
                  () {
                    isScanningTimeout = true;
                    mShowScanStatus = context
                        .l10n.noScanListAtThisTime; //"There is no scanned
                    //device at this time. try it again later!!";
                  },
                );
              }
            }
          },
        );
      } else {
        if (Csp1devices != null) {
          Csp1devices!.clear();
        }

        if (mCMgr.mPump!.mPumpflutterBlue.isScanning == true) {
          await _stopScan();
          if (_csp1scanSubscription != null) {
            await _csp1scanSubscription!.cancel();
          }
        }

        _csp1scanSubscription ??=
            mCMgr.mPump!.mPumpflutterBlue.scanResults.listen(
          (results) {
            for (final r in results) {
              if (r.device.name.isNotEmpty) {
                debugPrint(
                  '${TAG}kai:_startScan :r.device.name(${r.device.name}), '
                  'cspPreference.mPUMP_NAME = ${CspPreference.mPUMP_NAME}, '
                  'r.device.id(${r.device.id})',
                );
              }

              if (Csp1devices != null && !Csp1devices!.contains(r.device)) {
                if (mounted) {
                  // Check if the widget is still mounted
                  setState(
                    () {
                      if (r.device.name.isNotEmpty) {
                        if (r.device.name.contains(CspPreference.mPUMP_NAME)) {
                          debugPrint(
                            '${TAG}kai: _startScan : '
                            'Csp1devices!.add(${r.device.name}), '
                            'r.device.id(${r.device.id})',
                          );
                          Csp1devices!.add(r.device);
                          if (widget.hasConnectedBefore) {
                            connectDiscovery(r.device);
                          }
                        } else {
                          //debugPrint('kai: _startScan : not matched ');
                        }
                      } else {
                        //kai_20230420 let's add device which do not have
                        //name also here
                        debugPrint('${TAG}kai: _startScan: no device name ');
                      }
                    },
                  );
                }
              }
            }
          },
        );

        await mCMgr.mPump!.mPumpflutterBlue.startScan(
          timeout: Duration(seconds: widget.hasConnectedBefore ? 0 : 5),
        );
      }
    } catch (ex) {
      log('${TAG}Error starting scan: $ex');
      //let's show pop up message as like "bluetooth should be activated
      //first to scan device!!
      if (mounted) {
        // Check if the widget is still mounted
        setState(
          () {
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('${TAG}Bluetooth not enabled !!');
            }
            // kai_20221125  let's show dialog with message "There is no scanned
            //device at this time !!"
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(
                  left: 30,
                  right: 30,
                  top: 30,
                  bottom: 300,
                ),
                backgroundColor: Colors.red[700],
                content: const Text(
                  'bluetooth should be activated first to scan device!!',
                ),
              ),
            );
          },
        );
      }
    }
  }

  /*
   * @brief stop the scann
   */
  Future<void> _stopScan() async {
    try {
      debugPrint('$TAG:_stopScan()');
      if (_USE_CSBLUETOOTH_PROVIDER == true) {
        await mCMgr.mPump!.mPumpflutterBlue.stopScan();

        if (_csp1scanSubscription != null) {
          await _csp1scanSubscription!.cancel();
          _csp1scanSubscription = null;
        }
      } else {
        await mCMgr.mPump!.mPumpflutterBlue.stopScan();

        if (_csp1scanSubscription != null) {
          await _csp1scanSubscription!.cancel();
          _csp1scanSubscription = null;
        }
      }
    } catch (ex) {
      log('${TAG}Error stopping scan: $ex');
    }
  }

  /*
   * @brief parsing the received data thru the connected Pump device's 
   * RX read characteristic
   */
  void handlePumpValue(List<int> value) {
    if (value.isEmpty || value.isEmpty) {
      return;
    }
    debugPrint('${TAG}kai: handlePumpValue() is called: mounted($mounted)');
    //kai_20230519 let's check received data is json object format first here
    if (USE_SIMULATION_THRU_VIRTUAL_CGM == true) {
      String receivedData;
      // Try to decode as UTF-8
      try {
        debugPrint('${TAG}kai:handlePumpValue():check utf8.decode');
        receivedData = utf8.decode(value);
        debugPrint(
          '${TAG}kai:handlePumpValue():receivedData = $receivedData',
        );
        final dynamic decodedValue = json.decode(receivedData);
        debugPrint(
          '${TAG}kai:handlePumpValue():check json.decode(receivedData)',
        );
        if (decodedValue is Map<String, dynamic>) {
          // JSON 객체일 경우 필요한 처리 수행
          final receivedJsonObj = decodedValue;

          debugPrint('${TAG}kai:handlePumpValue():find json format');
          // 필드 값 추출
          /*
          String glucoseValue = receivedJsonObj['glucose'].toString();
          String timestampValue = receivedJsonObj['timestamp'].toString();
          String rawValue = receivedJsonObj['raw'].toString();
          String directionValue = receivedJsonObj['direction'].toString();
          String sourceValue = receivedJsonObj['source'].toString();
          */
          final glucoseValue = receivedJsonObj['g'].toString();
          // String timestampValue = receivedJsonObj['t'].toString();
          // String sourceValue = receivedJsonObj['s'].toString();

          // 추출한 필드 값을 활용하여 원하는 작업 수행
          const sourceValue = 'virtualCgm';
          final timeDate =
              int.parse(DateTime.now().millisecondsSinceEpoch.toString());
          // int timeDate = int.parse(timestampValue);
          mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
          //kai_20230509 if Glucose have floating point as like double " 225.0 "
          //then convert the value to int exclude ".0" by using floor()
          // mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
          mCMgr.mCgm!.setBloodGlucoseValue(
            double.parse(glucoseValue).floor(),
          );
          mCMgr.mCgm!.setRecievedTimeHistoryList(
            0,
            DateTime.fromMillisecondsSinceEpoch(
              timeDate,
            ).toIso8601String(),
          );
          mCMgr.mCgm!.setBloodGlucoseHistoryList(
            0,
            double.parse(glucoseValue).floor(),
          );
          mCMgr.mCgm!.cgmModelName = sourceValue;
          mCMgr.mCgm!.cgmSN = 'VCgm0000';
          // ...
          mCMgr.mCgm!.changeNotifier();

          //let's notify updating to the registered client cgm widgit
          mCMgr.mCgm!.setResponseMessage(
            RSPType.UPDATE_SCREEN,
            'New Blood Glucose',
            'NEW_BLOOD_GLUCOSE',
          );
          return;
        } else {
          // JSON 객체가 아닐 경우 처리
          debugPrint('${TAG}kai:handlePumpValue():no json format');
          // ...
        }
      } on FormatException {
        debugPrint('${TAG}kai:handlePumpValue():FormatException');
        // If UTF-8 decoding fails, try ASCII decoding
        receivedData =
            ascii.decode(value.where((byte) => byte <= 0x7f).toList());
      }
    }

    //kai_20230420 add to check current device.name is caremedi or not
    final pumpname = CspPreference.mPUMP_NAME;
    if (pumpname.isNotEmpty &&
        pumpname.contains(BluetoothProvider.CareLevo_PUMP_NAME)) {
      mCMgr.mPump!.handleCaremediPump(value);
    } else if (pumpname.isNotEmpty &&
        pumpname.contains(BluetoothProvider.DANARS_PUMP_NAME)) {
      mCMgr.mPump!.handleDanaiPump(value);
    }
    // 데이터 읽기 처리!
    else {
      // Check if the widget is still mounted
      if (mounted) {
        setState(() {
          String data;
          // Try to decode as UTF-8
          try {
            data = utf8.decode(value);
          } on FormatException {
            // If UTF-8 decoding fails, try ASCII decoding
            data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
          }
          // Process decoded string
          log('${TAG}kai: handlePumpValue():decodedString = $data');

          //kai_20230217 showing IJILog Message sent from csp1
          if (data.contains(_cmdIJILogHeader)) {
            // example received message : "IJILog(6)1676635096,1,0.05,0"
            // index, time, type, data value, report
            // IJILog DB index 6
            // injection Time 1676635096
            // type 1(bolus) 2(basal)
            // 3(occlusion alert) 4(low battery alert) 5(low reservoir alert)
            // data  xx.xx      xx.xx
            // OCLAL              BATLO                RIALO
            final index =
                data.substring(data.indexOf('(') + 1, data.indexOf(')'));
            final injectTime =
                data.substring(data.indexOf(')') + 1, data.indexOf(','));
            final remainStr = data.substring(data.indexOf(',') + 1);
            final type = remainStr.substring(0, remainStr.indexOf(','));
            final remainStr2 = remainStr.substring(remainStr.indexOf(',') + 1);
            final dataValue = remainStr2.substring(0, remainStr2.indexOf(','));
            final report = remainStr2.substring(remainStr2.indexOf(',') + 1);
            //kai_20230217
            // let's covert the timestamp based on
            //seconds & UTC time sent from CSP1
            // into miliseconds time by using
            //DateTime class with set isUTC as true
            //String _time = DateFormat("yyyy/MM/dd-HH:mm:ss").format(DateTime.fromMillisecondsSinceEpoch(int.parse(injectTime)*1000));
            final _time = DateFormat('yyyy/MM/dd-HH:mm:ss').format(
              DateTime.fromMillisecondsSinceEpoch(
                int.parse(injectTime) * 1000,
                isUtc: true,
              ),
            );
            final typeValue = int.parse(type);

            data = '$_cmdIJILogHeader($index)$_time,'
                '${iJILogTypes[(typeValue - 1)]}($dataValue)'
                ',$_alertReport($report)';
            //kai_20230217
            // let's consider to save the received IJILog data into Local data base or remote database thru http://post command method here
            //Map<String, dynamic> ijidata = dataValue as Map<String, dynamic>;
            // Map<String, dynamic> ijidata = json.decode(dataValue);
            final log = IJILog(
              time: int.parse(injectTime) * 1000,
              type: typeValue,
              data: dataValue,
              report: int.parse(report),
            );
            mIJILogDB.insertLog(log);
          }

          //update log history
          mPumpInsulinHistoryLog =
              '>>:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: '
              'Notify = $data\n$mPumpInsulinHistoryLog';

          //let's check the response of command we sent to csp-1 device
          if (data.contains(_cmdFwVersion)) {
            mPumpFWVersion = data.substring(_cmdFwVersion.length);
            //kai_20230926 update battery level
            if (mCMgr != null && mCMgr.mPump != null) {
              mCMgr.mPump!.fw = mPumpFWVersion;
              // mCMgr.mPump!.notifyListeners();
              mCMgr.changeNotifier();
            }
          } else if (data.contains(_cmdSerialNumber)) {
            mSN = data.substring(_cmdSerialNumber.length);
            //kai_20230926 update battery level
            if (mCMgr != null && mCMgr.mPump != null) {
              mCMgr.mPump!.SN = mSN;
              // mCMgr.mPump!.notifyListeners();
              mCMgr.changeNotifier();
            }
          } else if (data.contains(_cmdBatLevel)) {
            mPumpBatteryStatus = data.substring(_cmdBatLevel.length);
            //let's show low battery pop up if the value is <= 18
            final lowLevel = data.substring(_cmdBatLevel.length);
            final level = int.parse(lowLevel);
            //kai_20230926 update battery level
            if (mCMgr != null && mCMgr.mPump != null) {
              mCMgr.mPump!.Battery = lowLevel;
              // mCMgr.mPump!.notifyListeners();
              mCMgr.changeNotifier();
            }
            if (level <= 18) {
              /* pop up window have a dismiss button which send "BZ1=0" to
            stop buzzer of the connected csp-1 pump
            and  also can stop the playback predefined alarm in application side
             */
              _showAlertDialogOnEvent(
                '${(!mounted) ? mContext : context.l10n.pump}'
                '${(!mounted) ? mContext : context.l10n.lowBattery} $level%',
              );
            }
          } else if (data.contains(_cmdInjectInsulin)) {
            mPumpInsulinInject = data.substring(_cmdInjectInsulin.length);
          } else if (data.contains(_cmdInjectTime)) {
            mPumpInjectTime = data.substring(_cmdInjectTime.length);
            //kai_20230102 modified
            // csp1 send current time as like " 02/02/23 - 17:29:16"
            // so shows received strings w/o converting
            /*
            mPumpInjectTime = DateFormat("yyyy-MM-dd HH:mm a").format(
                DateTime.fromMillisecondsSinceEpoch
                (int.parse(mPumpInjectTime)));
            */
          } else if (data.contains(_cmdRemainInsulinAmount)) {
            mPumpInsulinRemain = data.substring(_cmdRemainInsulinAmount.length);
            //kai_20230926 update battery level
            if (mCMgr != null && mCMgr.mPump != null) {
              mCMgr.mPump!.reservoir = mPumpInsulinRemain;
              //mCMgr.mPump!.notifyListeners();
              mCMgr.changeNotifier();
            }
          } else if (data.contains(_cmdOcclusionAlert)) {
            mPumpOcclusionAlert = data.substring(_cmdOcclusionAlert.length);
          } else if (data.contains(_cmdInjectIntervalTime)) {
            mPumpInjectIntervalTime =
                data.substring(_cmdInjectIntervalTime.length);
          } else

          ///kai_20230911 add to match command w/ caremedi
          {
            if (USE_CAREMEDI_COMMAND == true) {
              mCMgr.mPump!.handleCaremediPump(value);
            }
          }
        });
      } else {
        String data;
        // Try to decode as UTF-8
        try {
          data = utf8.decode(value);
        } on FormatException {
          // If UTF-8 decoding fails, try ASCII decoding
          data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
        }
        // Process decoded string
        log('${TAG}kai:mounted(false) handlePumpValue():decodedString = $data');

        //kai_20230217 showing IJILog Message sent from csp1
        if (data.contains(_cmdIJILogHeader)) {
          // example received message : "IJILog(6)1676635096,1,0.05,0"
          // index, time, type, data value, report
          // IJILog DB index 6
          // injection Time 1676635096
          // type 1(bolus) 2(basal)
          // 3(occlusion alert) 4(low battery alert) 5(low reservoir alert)
          // data  xx.xx      xx.xx   OCLAL
          // BATLO                RIALO
          final index =
              data.substring(data.indexOf('(') + 1, data.indexOf(')'));
          final injectTime =
              data.substring(data.indexOf(')') + 1, data.indexOf(','));
          final remainStr = data.substring(data.indexOf(',') + 1);
          final type = remainStr.substring(0, remainStr.indexOf(','));
          final remainStr2 = remainStr.substring(remainStr.indexOf(',') + 1);
          final dataValue = remainStr2.substring(0, remainStr2.indexOf(','));
          final report = remainStr2.substring(remainStr2.indexOf(',') + 1);
          //kai_20230217
          // let's covert the timestamp based on
          //seconds & UTC time sent from CSP1
          // into miliseconds time by using
          //DateTime class with set isUTC as true
          //String _time = DateFormat("yyyy/MM/dd-HH:mm:ss").format(DateTime.fromMillisecondsSinceEpoch(int.parse(injectTime)*1000));
          final _time = DateFormat('yyyy/MM/dd-HH:mm:ss').format(
            DateTime.fromMillisecondsSinceEpoch(
              int.parse(injectTime) * 1000,
              isUtc: true,
            ),
          );
          final typeValue = int.parse(type);

          data = '$_cmdIJILogHeader($index)$_time,'
              '${iJILogTypes[(typeValue - 1)]}($dataValue)'
              ',$_alertReport($report)';
          //kai_20230217
          // let's consider to save the received IJILog data into Local data base or remote database thru http://post command method here
          //Map<String, dynamic> ijidata = dataValue as Map<String, dynamic>;
          // Map<String, dynamic> ijidata = json.decode(dataValue);
          final log = IJILog(
            time: int.parse(injectTime) * 1000,
            type: typeValue,
            data: dataValue,
            report: int.parse(report),
          );
          mIJILogDB.insertLog(log);
        }

        //update log history
        mPumpInsulinHistoryLog =
            '>>:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: '
            'Notify = $data\n$mPumpInsulinHistoryLog';

        //let's check the response of command we sent to csp-1 device
        if (data.contains(_cmdFwVersion)) {
          mPumpFWVersion = data.substring(_cmdFwVersion.length);
          //kai_20230926 update firmware version
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.fw = mPumpFWVersion;
            debugPrint(
              '${TAG}kai:mounted(false)'
              'handlePumpValue():mCMgr.mPump!.fw(${mCMgr.mPump!.fw})',
            );
            // mCMgr.mPump!.notifyListeners();
            mCMgr.changeNotifier();
          }
        } else if (data.contains(_cmdSerialNumber)) {
          mSN = data.substring(_cmdSerialNumber.length);
          //kai_20230926 update battery level
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.SN = mSN;
            // mCMgr.mPump!.notifyListeners();
            mCMgr.changeNotifier();
          }
        } else if (data.contains(_cmdBatLevel)) {
          mPumpBatteryStatus = data.substring(_cmdBatLevel.length);
          //let's show low battery pop up if the value is <= 18
          final LowLevel = data.substring(_cmdBatLevel.length);
          final level = int.parse(LowLevel);
          //kai_20230926 update battery level
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.Battery = LowLevel;
            debugPrint(
              '${TAG}kai:mounted(false) '
              'handlePumpValue():mCMgr.mPump!.Battery(${mCMgr.mPump!.Battery})',
            );
            //mCMgr.mPump!.notifyListeners();
            mCMgr.changeNotifier();
          }
          if (level <= 18) {
            /* pop up window have a dismiss button which send "BZ1=0" to
            stop buzzer of the connected csp-1 pump
            and  also can stop the playback predefined alarm in application side
             */
            _showAlertDialogOnEvent(
              '${(!mounted) ? mContext : context.l10n.pump}'
              '${(!mounted) ? mContext : context.l10n.lowBattery} $level%',
            );
          }
        } else if (data.contains(_cmdInjectInsulin)) {
          mPumpInsulinInject = data.substring(_cmdInjectInsulin.length);
        } else if (data.contains(_cmdInjectTime)) {
          mPumpInjectTime = data.substring(_cmdInjectTime.length);
          //kai_20230102 modified
          // csp1 send current time as like " 02/02/23 - 17:29:16"
          // so shows received strings w/o converting
          /*
            mPumpInjectTime = DateFormat("yyyy-MM-dd HH:mm a").format(
                DateTime.fromMillisecondsSinceEpoch
                (int.parse(mPumpInjectTime)));
            */
        } else if (data.contains(_cmdRemainInsulinAmount)) {
          mPumpInsulinRemain = data.substring(_cmdRemainInsulinAmount.length);
          //kai_20230926 update battery level
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.reservoir = mPumpInsulinRemain;
            debugPrint(
              '${TAG}kai:mounted(false) handlePumpValue():mCMgr.mPump!.reservoir(${mCMgr.mPump!.reservoir})',
            );
            //mCMgr.mPump!.notifyListeners();
            mCMgr.notifyListeners();
          }
        } else if (data.contains(_cmdOcclusionAlert)) {
          mPumpOcclusionAlert = data.substring(_cmdOcclusionAlert.length);
        } else if (data.contains(_cmdInjectIntervalTime)) {
          mPumpInjectIntervalTime =
              data.substring(_cmdInjectIntervalTime.length);
        } else

        ///kai_20230911 add to match command w/ caremedi
        {
          if (USE_CAREMEDI_COMMAND == true) {
            mCMgr.mPump!.handleCaremediPump(value);
          }
        }
      }
    }
  }

  /*
   * @brief try to connect to the device that scanned by using 
   * predefined device name
   *        and find service and supported characteristics
   */
  Future<void> connectDiscovery(BluetoothDevice device) async {
    try {
      // ignore: unrelated_type_equality_checks
      debugPrint('${TAG}kai: start  connectDiscovery()');
      if (_USE_CSBLUETOOTH_PROVIDER == true) {
        if (mCMgr.mPump!.mPumpflutterBlue.isScanning == true) {
          await mCMgr.mPump!.mPumpflutterBlue.stopScan();
        }
      } else {
        if (Csp1flutterBlue != null && Csp1flutterBlue!.isScanning == true) {
          await Csp1flutterBlue!.stopScan();
        }
      }

      //let's check current set pump type here
      final type = CspPreference.mPUMP_NAME;
      debugPrint('${TAG}kai: cspPreference.mPUMP_NAME = $type');
      if (type.contains(CSP_PUMP_NAME)) {
        mBOLUS_SERVICE = CSP_SERVICE_UUID;
        mRX_READ_UUID = CSP_RX_READ_CHARACTER_UUID;
        mTX_WRITE_UUID = CSP_TX_WRITE_CHARACTER_UUID;
        mPUMP_NAME = CSP_PUMP_NAME;
        mFindCharacteristicMax = 3;
        debugPrint('${TAG}kai: pumptype = $type');
      } else if (type.contains(CareLevo_PUMP_NAME)) {
        mBOLUS_SERVICE = CareLevoSERVICE_UUID;
        mRX_READ_UUID = CareLevoRX_CHAR_UUID;
        mTX_WRITE_UUID = CareLevoTX_CHAR_UUID;
        mPUMP_NAME = CareLevo_PUMP_NAME;
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: pumptype = $type');
      } else if (type.contains(DANARS_PUMP_NAME)) {
        mBOLUS_SERVICE = DANARS_BOLUS_SERVICE;
        mRX_READ_UUID = DANARS_READ_UUID;
        mTX_WRITE_UUID = DANARS_WRITE_UUID;
        mPUMP_NAME = DANARS_PUMP_NAME;
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: pumptype = $type');
      } else if (type.contains(Dexcom_PUMP_NAME)) {
        mBOLUS_SERVICE = DexcomSERVICE_UUID;
        mRX_READ_UUID = DexcomRX_CHAR_UUID;
        mTX_WRITE_UUID = DexcomTX_CHAR_UUID;
        mPUMP_NAME = CSP_PUMP_NAME;
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: pumptype = $type');
      } else {
        mBOLUS_SERVICE = CSP_SERVICE_UUID;
        mRX_READ_UUID = CSP_RX_READ_CHARACTER_UUID;
        mTX_WRITE_UUID = CSP_TX_WRITE_CHARACTER_UUID;
        mPUMP_NAME = CSP_PUMP_NAME;
        mFindCharacteristicMax = 3;
        debugPrint('${TAG}kai: pumptype = $type');
      }

      debugPrint('${TAG}kai: connectDiscovery(): call device.connect() '
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      //kai_20230522  if use auto: true then connection does
      //not established in android M.
      // i don't know why it happened
      if (USE_AUTO_CONNECTION == true) {
        await device.connect();
      } else {
        await device.connect(autoConnect: false);
      }

      if (USE_CHECK_PAIRED_DEV == true &&
          type.contains(DANARS_PUMP_NAME) &&
          (mCMgr.mPump! is PumpDanars)) {
        // check device bonding status here
        var isBonded = (await mCMgr.mPump!.mPumpflutterBlue.bondedDevices)
            .contains(device);

        debugPrint('${TAG}kai: isbonded($isBonded) '
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
          DateTime.now(),
        )})');

        if (!isBonded) {
          // wait for the device bonding is complete, timeout :30 secs
          var secondsWaited = 0;

          while (!isBonded && secondsWaited < 30) {
            debugPrint(
                '${TAG}kai:Waiting for bonding...Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
              DateTime.now(),
            )})');
            await Future<void>.delayed(const Duration(seconds: 1));
            // check device bonding status again here
            isBonded = (await mCMgr.mPump!.mPumpflutterBlue.bondedDevices)
                .contains(device);
            secondsWaited++;
          }

          if (!isBonded) {
            debugPrint('${TAG}kai:Timeout waiting for bonding. '
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
              DateTime.now(),
            )})');
            // timeout 30secs or alert here later
            return;
          } else {
            debugPrint('${TAG}kai: bonding is done. '
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
              DateTime.now(),
            )})');
          }
        }
      }

      debugPrint(
        '${TAG}kai: connectDiscovery(): call device.discoverServices() '
        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
      );
      /* int mtu = await device.requestMtu(247);
      // MTU 요청이 성공적으로 완료됨
     log('MTU size set to: $mtu');
      */

      var finddanaWRCharacteristic = 0;
      final isfindDevice =
          await device.discoverServices().then((services) async {
        //debugging service count
        var svcCnt = 0;
        var characterCnt = 0;
        for (final service in services) {
          svcCnt++;
          debugPrint(
            '${TAG}kai: cnt($svcCnt) serviceuuid = '
            '${service.uuid.toString().toLowerCase()}',
          );

          if (FEATURE_CHECK_WR_CHARACTERISTIC != true) {
            for (final characteristic in service.characteristics) {
              characterCnt++;
              debugPrint(
                '${TAG}kai: cnt($characterCnt) characteruuid = '
                '${characteristic.uuid.toString().toLowerCase()}',
              );
              if (characteristic.uuid.toString().toLowerCase() ==
                  mRX_READ_UUID.toLowerCase()) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_RX_READ_CHARACTERISTIC = characteristic;
                debugPrint('${TAG}kai: found m_RX_READ_CHARACTERISTIC '
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                  DateTime.now(),
                )})');

                //check the characteristic have notify property and Notify
                //is enabled first here
                if (m_RX_READ_CHARACTERISTIC!.properties.notify &&
                    m_RX_READ_CHARACTERISTIC!.descriptors.isNotEmpty) {
                  if (!m_RX_READ_CHARACTERISTIC!.isNotifying) {
                    //let's set notify enable here first
                    if (USE_CHECK_CONNECTION_STATUS) {
                      try {
                        debugPrint(
                          '${TAG}kai: call m_RX_READ_CHARACTERISTIC!.setNotifyValue(true)'
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                            DateTime.now(),
                          )})',
                        );

                        await m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);

                        if (mCMgr != null && mCMgr.mPump != null) {
                          mCMgr.mPump!.isSetNotifyFailed = false;
                          debugPrint(
                              '${TAG}kai: set isSetNotifyFailed(false) after m_RX_READ_CHARACTERISTIC!.setNotifyValue(true)'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                            DateTime.now(),
                          )})');
                        }
                      } catch (e) {
                        debugPrint(
                          '$TAG:kai: 1st m_RX_READ_CHARACTERISTIC notify set error: uuid =  ${m_RX_READ_CHARACTERISTIC!.uuid} $e'
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                            DateTime.now(),
                          )})',
                        );

                        if (mCMgr != null && mCMgr.mPump != null) {
                          mCMgr.mPump!.isSetNotifyFailed = true;
                          debugPrint(
                              '${TAG}kai: Error set isSetNotifyFailed(true) after call m_RX_READ_CHARACTERISTIC!.setNotifyValue(true)'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                            DateTime.now(),
                          )})');
                        }
                      }
                    }

                    try {
                      //kai_20230310 unregister listener first due to
                      //duplicated register notify operation occurred
                      // regardless of unregistering the listener
                      //when device is disconnected
                      //debugPrint('kai: force unregister previous
                      //registered lister before registering');
                      //m_RX_READ_CHARACTERISTIC!.value.listen((event)
                      //{ }).cancel();
                      if (mCMgr.mPump!.isSetNotifyFailed == true) {
                        await m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);
                        debugPrint(
                          '${TAG}kai: set '
                          'm_RX_READ_CHARACTERISTIC_VALUE_LISTENER '
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                            DateTime.now(),
                          )})',
                        );
                      }

                      if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
                        //kai_20240122 let's release previous listener here
                        await m_RX_READ_CHARACTERISTIC_VALUE_LISTENER!.cancel();
                        m_RX_READ_CHARACTERISTIC_VALUE_LISTENER = null;
                      }
                      m_RX_READ_CHARACTERISTIC_VALUE_LISTENER =
                          m_RX_READ_CHARACTERISTIC!.value.listen((value) {
                        // kai_20230225 let's implement parser for received
                        // data or message sent from connected pump
                        // Handle incoming data here.
                        debugPrint(
                          '${TAG}kai: call  handlePumpValue() : '
                          'uuid(${m_RX_READ_CHARACTERISTIC!.uuid})',
                        );
                        handlePumpValue(value);
                      });

                      if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
                        mCMgr.mPump!.pumpValueSubscription =
                            m_RX_READ_CHARACTERISTIC_VALUE_LISTENER;
                        debugPrint(
                          '${TAG}kai: 1 mCMgr.mPump!.pumpValueSubscription = '
                          'm_RX_READ_CHARACTERISTIC_VALUE_LISTENER'
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                            DateTime.now(),
                          )})',
                        );
                      }

                      //kai_20240121let's consider set retry after delay here
                      if (mCMgr.mPump!.isSetNotifyFailed == true) {
                        if (USE_CHECK_CONNECTION_STATUS) {
                          await Future<void>.delayed(
                              const Duration(milliseconds: 500), () async {
                            debugPrint(
                              '$TAG:kai: 2nd call m_RX_READ_CHARACTERISTIC!.setNotifyValue(true) '
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                                DateTime.now(),
                              )})',
                            );

                            await m_RX_READ_CHARACTERISTIC!
                                .setNotifyValue(true);
                            mCMgr.mPump!.isSetNotifyFailed = false;
                            debugPrint(
                              // ignore: lines_longer_than_80_chars
                              '$TAG:kai: complete 2nd call m_RX_READ_CHARACTERISTIC!.setNotifyValue(false) '
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                                DateTime.now(),
                              )})',
                            );
                          });
                        } else {
                          await m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);
                          mCMgr.mPump!.isSetNotifyFailed = false;
                          debugPrint(
                            // ignore: lines_longer_than_80_chars
                            '$TAG:kai: complete 2nd call m_RX_READ_CHARACTERISTIC!.setNotifyValue(false) '
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                              DateTime.now(),
                            )})',
                          );
                        }
                      } else {
                        // set delay after setting
                        await Future<void>.delayed(
                          const Duration(milliseconds: 500),
                        );
                      }
                    } catch (e) {
                      debugPrint(
                        '$TAG characteristic notify set error: uuid =  '
                        '${m_RX_READ_CHARACTERISTIC!.uuid} $e'
                        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                          DateTime.now(),
                        )})',
                      );
                      //kai_20240117 let's update set notify status here
                      mCMgr.mPump!.isSetNotifyFailed = true;
                    }
                  }
                }
              }

              if (characteristic.uuid.toString().toLowerCase() ==
                  mTX_WRITE_UUID.toLowerCase()) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_TX_WRITE_CHARACTERISTIC = characteristic;
                debugPrint('${TAG}kai: found m_TX_WRITE_CHARACTERISTIC '
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                  DateTime.now(),
                )})');
              }

              if (characteristic.uuid.toString().toLowerCase() ==
                  CSP_BATLEVEL_NOTIFY_CHARACTER_UUID.toLowerCase()) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_RX_BATLEVEL_CHARACTERISTIC = characteristic;
                debugPrint('${TAG}kai: found m_RX_BATLEVEL_CHARACTERISTIC '
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                  DateTime.now(),
                )})');
                //check the characteristic have notify property and Notify is
                //enabled first here
                if (m_RX_BATLEVEL_CHARACTERISTIC!.properties.notify &&
                    m_RX_BATLEVEL_CHARACTERISTIC!.descriptors.isNotEmpty) {
                  if (!m_RX_BATLEVEL_CHARACTERISTIC!.isNotifying) {
                    try {
                      //kai_20230310 try to enable for register battery level
                      // characteristic notify
                      // but error comes up.
                      //kai_20231115 exception error ,
                      //let's set delay 3 secs to set battery notify
                      Future.delayed(const Duration(seconds: 3), () async {
                        if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
                          debugPrint(
                            '${TAG}kai: after 3 secs : '
                            'm_RX_BATLEVEL_CHARACTERISTIC!.setNotifyValue(true)'
                            'is called '
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                              DateTime.now(),
                            )})',
                          );
                          try {
                            await m_RX_BATLEVEL_CHARACTERISTIC!
                                .setNotifyValue(true);
                          } catch (e) {
                            debugPrint(
                              '${TAG}kai: battery characteristic '
                              'notify set error: uuid = '
                              '${m_RX_BATLEVEL_CHARACTERISTIC!.uuid} $e'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                            );
                            mCMgr.mPump!.isSetNotifyFailed = true;
                          }
                        }
                      });
                      //kai_20231115 exception error
                      //m_RX_BATLEVEL_CHARACTERISTIC!.setNotifyValue(true);
                      debugPrint(
                        '${TAG}kai: '
                        'set m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER ',
                      );
                      m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
                          m_RX_BATLEVEL_CHARACTERISTIC!.value.listen((value) {
                        // kai_20230225 let's implement parser for received
                        // data or message sent from connected pump
                        // Handle incoming data here.
                        debugPrint(
                          '${TAG}kai: call  _handlePumpBatLevelValue() : '
                          'uuid(${m_RX_BATLEVEL_CHARACTERISTIC!.uuid})',
                        );
                        _handlePumpBatLevelValue(value);
                      });

                      if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER != null) {
                        mCMgr.mPump!.pumpBatValueSubscription =
                            m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
                        debugPrint(
                          '${TAG}kai: 1 : '
                          'mCMgr.mPump!.pumpBatValueSubscription '
                          '= m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER',
                        );
                      }
                      // set delay after setting
                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                    } catch (e) {
                      debugPrint(
                        '$TAG characteristic notify set error: uuid = '
                        '${m_RX_BATLEVEL_CHARACTERISTIC!.uuid} $e',
                      );
                    }
                  }
                }
              }
            }

            if (finddanaWRCharacteristic >= mFindCharacteristicMax) {
              if (_USE_CSBLUETOOTH_PROVIDER == true) {
                mCMgr.mPump!.ConnectedDevice = device;
                mPump = device;
                mPumpMacAddress = mPump!.id.toString();
                mPumpName = mPump!.name;

                //kai_20240116 check previous register callback exit here
                // if use below callback then call cancel here because
                // already statecallback is registered during processing connectToDevice() above
                if (mCMgr.mPump!.mPumpconnectionSubscription != null) {
                  await mCMgr.mPump!.mPumpconnectionSubscription!.cancel();
                  mCMgr.mPump!.mPumpconnectionSubscription = null;
                }

                // kai_20230225 register status change listener and Handle
                // connection status changes.
                mCMgr.mPump!.registerPumpStateCallback((state) async {
                  debugPrint(
                    '${TAG}kai: PumpStateCallback(): mounted($mounted), '
                    'mPumpdeviceState = $mPumpdeviceState,  state = $state, '
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                      DateTime.now(),
                    )})',
                  );
                  if (mPumpdeviceState == state) {
                    /*kai_20231101  sometimes we get the below status 
                    when we try to connect again after user disconnect
                  // [onConnectionStateChange] status: 133 newState: 0
                  // PumpStateCallback(): mounted(true), state = BluetoothDeviceState.disconnected, new state = BluetoothDeviceState.disconnected
                  // in this case , if previous registered callback exist, let's cancel it here
                  */
                    if (mPumpdeviceState == BluetoothDeviceState.disconnected) {
                      //let's bypass
                    } else {
                      debugPrint(
                        '${TAG}kai: scanDialog: mounted($mounted), '
                        'return same state from connected to connected !! '
                        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                          DateTime.now(),
                        )})',
                      );
                      return;
                    }
                  }

                  switch (state) {
                    case BluetoothDeviceState.connected:
                      {
                        debugPrint(
                          '${TAG}kai:Connected to pump : mounted($mounted)',
                        );
                        //kai_20231013 add to update device name here
                        if (mCMgr != null &&
                            mCMgr.mPump != null &&
                            device != null) {
                          // mCMgr.mPump!.ModelName = device.name;
                          if (CspPreference.mPUMP_NAME
                              .toLowerCase()
                              .contains(DANARS_PUMP_NAME.toLowerCase())) {
                            mCMgr.mPump!.ModelName = DANARS_PUMP_NAME;
                          } else {
                            mCMgr.mPump!.ModelName = device.name;
                          }
                          mCMgr.mPump!.changeNotifier();
                          mCMgr.changeNotifier();
                        }
                        await _savePump(
                          PumpData(
                            id: device.id.id,
                            name: device.name,
                            status: true,
                          ),
                        ).whenComplete(
                          () {
                            if (widget.hasConnectedBefore) {
                              Navigator.pop(context);
                            }
                          },
                        );

                        if (mounted) {
                          // Check if the widget is still mounted
                          setState(
                            () {
                              mPumpConnectionStatus = context.l10n.connected;
                              mPumpstateText = context.l10n.connected;
                              mPumpconnectButtonText = context.l10n.disconnect;
                              mPumpdeviceState = state;
                              mCMgr.mPump!.ConnectionStatus = state;

                              //kai_20240122 below is needed really?
                              //let's clear scan device list here
                              if (mCMgr.mPump!.getScannedDeviceLists() !=
                                  null) {
                                //  mCMgr.mPump!.getScannedDeviceLists()!.clear();
                              }

                              //let's set timer after 5 secs trigger to check RX
                              //characteristic and battery Notify
                              Future.delayed(
                                const Duration(seconds: 5),
                                () async {
                                  if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER ==
                                      null) {
                                    debugPrint(
                                      '${TAG}kai: register RX_Read characteristic '
                                      'for value listener due to auto reconnection',
                                    );
                                    if (m_RX_READ_CHARACTERISTIC != null) {
                                      //kai_20240122 i'm not sure that previous
                                      // value listener still alive or not
                                      // regardless of this value is NULL
                                      // that's why cancel first again here

                                      // dwi_20240130 i think any bug in here
                                      // so current i comment this method
                                      // await m_RX_READ_CHARACTERISTIC!.value
                                      //     .listen(handlePumpValue)
                                      //     .cancel();

                                      m_RX_READ_CHARACTERISTIC_VALUE_LISTENER =
                                          m_RX_READ_CHARACTERISTIC!.value
                                              .listen(handlePumpValue);

                                      try {
                                        if (!m_RX_READ_CHARACTERISTIC!
                                            .isNotifying) {
                                          debugPrint(
                                            '${TAG}kai: register RX_Read '
                                            'characteristic set Notify due to '
                                            'auto reconnection',
                                          );

                                          if (mCMgr.mPump!.isSetNotifyFailed) {
                                            await m_RX_READ_CHARACTERISTIC!
                                                .setNotifyValue(true);
                                            //kai_20240117 let's update set notify
                                            //status here
                                            // dwi_20240130 comment for temporary
                                            // mCMgr.mPump!.isSetNotifyFailed = false;
                                          }
                                        } else {
                                          //kai_20230515 workaround
                                          if (_USE_FORCE_RX_NOTI_ENABLE ==
                                              true) {
                                            if (disconnectedAfterConnection >
                                                0) {
                                              disconnectedAfterConnection =
                                                  disconnectedAfterConnection -
                                                      1;
                                              if (disconnectedAfterConnection <
                                                  0) {
                                                disconnectedAfterConnection = 0;
                                              }
                                              debugPrint(
                                                '${TAG}kai: register RX_Read '
                                                'characteristic  Notify already '
                                                'enabled: due to auto reconnection',
                                              );
                                              await m_RX_READ_CHARACTERISTIC!
                                                  .setNotifyValue(true);

                                              // dwi_20240130 comment for temporary
                                              // if (mCMgr.mPump!.isSetNotifyFailed) {
                                              //   await m_RX_READ_CHARACTERISTIC!
                                              //       .setNotifyValue(true);
                                              //   //kai_20240117 let's update set notify status here
                                              //   mCMgr.mPump!.isSetNotifyFailed =
                                              //       false;
                                              // }
                                            }
                                          }
                                        }
                                      } catch (ex) {
                                        debugPrint(
                                          'kai: BluetoothDeviceState.connected: '
                                          'Error: $ex:Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                                            DateTime.now(),
                                          )})',
                                        );
                                        //kai_20240117 let's update set notify status here
                                        mCMgr.mPump!.isSetNotifyFailed = true;
                                      }
                                    }
                                  }
                                },
                              );
                            },
                          );
                        } else {
                          //kai_20230616 added
                          mPumpConnectionStatus = mContext!.l10n.connected;
                          mPumpstateText = mContext!.l10n.connected;
                          mPumpconnectButtonText = mContext!.l10n.disconnect;
                          mPumpdeviceState = state;

                          //kai_20240121 below is needed really?
                          // scanning and if user press connect buttion on the scanned list screen
                          // then select pump poupu comes up with message " there is no scanned device, please try it again?

                          //let's clear scan device list here
                          if (mCMgr.mPump != null) {
                            mCMgr.mPump!.ConnectionStatus = state;
                            if (mCMgr.mPump!.getScannedDeviceLists() != null) {
                              // mCMgr.mPump!.getScannedDeviceLists()!.clear();
                            }
                          }
                        }
                      }

                      break;

                    case BluetoothDeviceState.disconnected:
                      {
                        debugPrint(
                          '${TAG}kai:Disconnected from pump: mounted($mounted) '
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                            DateTime.now(),
                          )})',
                        );

                        //kai_20231013 add to update device name here
                        if (mCMgr != null && mCMgr.mPump != null) {
                          mCMgr.mPump!.ModelName = '';
                          mCMgr.mPump!.changeNotifier();
                          mCMgr.changeNotifier();

                          if (mCMgr.mPump! is PumpDanars) {
                            //reset the flag here first
                            if (USE_DANAI_CHECK_CONNECTION_COMMAND_SENT) {
                              (mCMgr.mPump as PumpDanars)
                                  .issendPumpCheckAfterConnectFailed = 1;
                              (mCMgr.mPump as PumpDanars).onRetrying = false;
                              if (USE_CHECK_ENCRYPTION_ENABLED) {
                                (mCMgr.mPump as PumpDanars)
                                    .enabledStartEncryption = false;
                              }
                            }
                          }
                        }

                        if (_USE_FORCE_RX_NOTI_ENABLE == true) {
                          disconnectedAfterConnection =
                              disconnectedAfterConnection + 1;
                        }

                        String typePump = CspPreference.mPUMP_NAME;
                        if (typePump.toLowerCase().contains(
                              BluetoothProvider.DANARS_PUMP_NAME.toLowerCase(),
                            )) {
                          debugPrint('${TAG}kai::PumpType($typePump)');
                          //kai_20231228  let's send Pump Check command here after connection
                          if (mCMgr.mPump! is PumpDanars) {
                            debugPrint('${TAG}kai::disconnected: '
                                'call KeepConnectionStatusTimer.cancel()'
                                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                            (mCMgr.mPump as PumpDanars)
                                .KeepConnectionStatusTimer
                                ?.cancel();
                            (mCMgr.mPump as PumpDanars)
                                .KeepConnectionStatusTimer = null;
                          }
                        }

                        if (mounted) {
                          // Check if the widget is still mounted
                          setState(() {
                            mPumpConnectionStatus = context.l10n.disconnected;
                            mPumpstateText = context.l10n.disconnected;
                            mPumpconnectButtonText = context.l10n.connect;
                            mPumpdeviceState = state;
                            mCMgr.mPump!.ConnectionStatus = state;
                          });
                        } else {
                          //kai_20230616 added
                          mPumpConnectionStatus =
                              '${(!mounted) ? mContext : context.l10n.disconnected}';
                          mPumpstateText =
                              '${(!mounted) ? mContext : context.l10n.disconnected}';
                          mPumpconnectButtonText =
                              '${(!mounted) ? mContext : context.l10n.connect}';
                          mPumpdeviceState = state;
                          if (mCMgr.mPump != null) {
                            mCMgr.mPump!.ConnectionStatus = state;
                            mCMgr.mPump!.notifyListeners();
                            mCMgr.notifyListeners();
                          }
                        }
                        // kai_20230205 let's clear used resource and
                        // unregister used listener here
                        if (_csp1scanSubscription != null) {
                          debugPrint(
                            '${TAG}kai : '
                            'disconnect: _csp1scanSubscription!.cancel()'
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                          );
                          await _csp1scanSubscription!.cancel();

                          ///< scan result listener
                        }

                        //kai_20230310 if call below unregister status listener
                        //then auto reconnection status updating does not work .
                        // so block it temporary
                        if (FEATURE_STATUS_REGISTER_BY_USER == true) {
                          if (connectionSubscription != null) {
                            debugPrint(
                              '${TAG}kai : disconnect: '
                              'connectionSubscription!.cancel()'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                            );
                            await connectionSubscription!.cancel();

                            ///< connection status listener
                          }

                          if (mounted &&
                              mCMgr.mPump!.mPumpconnectionSubscription !=
                                  null) {
                            debugPrint(
                              '${TAG}kai : disconnect: '
                              'unregisterPumpStateCallback()'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                            );
                            mCMgr.mPump!.unregisterPumpStateCallback();
                          } else if (mCMgr.mPump!.mPumpconnectionSubscription !=
                              null) {
                            debugPrint(
                              '${TAG}kai : mounted(false) disconnect: '
                              'unregisterPumpStateCallback()'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                            );
                            mCMgr.mPump!.unregisterPumpStateCallback();
                          }
                        }

                        if (m_RX_READ_CHARACTERISTIC != null) {
                          debugPrint(
                            '${TAG}kai : disconnect: '
                            'm_RX_READ_CHARACTERISTIC!.value.listen((event) '
                            '{}).cancel():mount = $mounted'
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                          );
                          if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
                            await m_RX_READ_CHARACTERISTIC_VALUE_LISTENER!
                                .cancel();
                            m_RX_READ_CHARACTERISTIC_VALUE_LISTENER = null;

                            if (mounted) {
                              mCMgr.mPump!.pumpValueSubscription =
                                  m_RX_READ_CHARACTERISTIC_VALUE_LISTENER;
                              debugPrint(
                                '${TAG}kai : disconnect: '
                                'mCMgr.mPump!.pumpValueSubscription = '
                                'm_RX_READ_CHARACTERISTIC_VALUE_LISTENER'
                                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                              );
                            }
                          }
                        }

                        if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
                          debugPrint(
                            '${TAG}kai : disconnect: '
                            'm_RX_BATLEVEL_CHARACTERISTIC!.value.listen((event)'
                            '{}).cancel():mount = $mounted'
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                          );
                          if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER !=
                              null) {
                            await m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER!
                                .cancel();
                            m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER = null;
                            if (mounted) {
                              mCMgr.mPump!.pumpBatValueSubscription =
                                  m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
                              debugPrint(
                                '${TAG}kai : disconnect: '
                                'mCMgr.mPump!.pumpBatValueSubscription '
                                '= m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER'
                                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                              );
                            }
                          }
                        }
                      }
                      break;

                    case BluetoothDeviceState.disconnecting:
                      if (mounted) {
                        // Check if the widget is still mounted
                        setState(() {
                          mPumpstateText = context.l10n.disconnecting;
                          mPumpConnectionStatus = mPumpstateText;
                          mPumpconnectButtonText = mPumpstateText;
                          mPumpdeviceState = state;
                          mCMgr.mPump!.ConnectionStatus = state;
                        });
                      } else {
                        //kai_20230616
                        mPumpstateText =
                            '${(!mounted) ? mContext : context.l10n.disconnecting}';
                        mPumpConnectionStatus = mPumpstateText;
                        mPumpconnectButtonText = mPumpstateText;
                        mPumpdeviceState = state;
                        if (mCMgr.mPump != null) {
                          mCMgr.mPump!.ConnectionStatus = state;
                          mCMgr.mPump!.notifyListeners();
                          mCMgr.notifyListeners();
                        }
                      }

                      break;

                    case BluetoothDeviceState.connecting:
                      if (mounted) {
                        // Check if the widget is still mounted
                        setState(() {
                          mPumpstateText = context.l10n.connecting;
                          mPumpConnectionStatus = mPumpstateText;
                          mPumpconnectButtonText = mPumpstateText;
                          mPumpdeviceState = state;
                          mCMgr.mPump!.ConnectionStatus = state;
                        });
                      } else {
                        mPumpstateText =
                            '${(!mounted) ? mContext : context.l10n.connecting}';
                        mPumpConnectionStatus = mPumpstateText;
                        mPumpconnectButtonText = mPumpstateText;
                        mPumpdeviceState = state;
                        if (mCMgr.mPump != null) {
                          mCMgr.mPump!.ConnectionStatus = state;
                          mCMgr.mPump!.notifyListeners();
                          mCMgr.notifyListeners();
                        }
                      }
                      break;
                  }
                });

                //backup the pump connection status listener instance here
                connectionSubscription =
                    mCMgr.mPump!.mPumpconnectionSubscription;

                if (m_RX_READ_CHARACTERISTIC != null) {
                  mCMgr.mPump!.PumpRxCharacteristic = m_RX_READ_CHARACTERISTIC;
                  debugPrint(
                    '${TAG}kai: mCMgr.mPump!.PumpRxCharacteristic = '
                    'm_RX_READ_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }

                if (m_TX_WRITE_CHARACTERISTIC != null) {
                  mCMgr.mPump!.PumpTxCharacteristic = m_TX_WRITE_CHARACTERISTIC;
                  debugPrint(
                    '${TAG}kai: mCMgr.mPump!.PumpTxCharacteristic = '
                    'm_TX_WRITE_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }

                if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
                  mCMgr.mPump!.pumpValueSubscription =
                      m_RX_READ_CHARACTERISTIC_VALUE_LISTENER;
                  debugPrint(
                    '${TAG}kai: 2 mCMgr.mPump!.pumpValueSubscription = '
                    'm_RX_READ_CHARACTERISTIC_VALUE_LISTENER'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }

                if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
                  mCMgr.mPump!.PumpRXBatLvlCharacteristic =
                      m_RX_BATLEVEL_CHARACTERISTIC;
                  debugPrint(
                    '${TAG}kai: mCMgr.mPump!.PumpRXBatLvlCharacteristic = '
                    'm_RX_BATLEVEL_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }

                if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER != null) {
                  mCMgr.mPump!.pumpBatValueSubscription =
                      m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
                  debugPrint(
                    '${TAG}kai: 2 mCMgr.mPump!.pumpBatValueSubscription = '
                    'm_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }
              }
              return true;
            }
          } else {
            if (service.uuid.toString().toLowerCase() ==
                mBOLUS_SERVICE.toLowerCase()) {
              return true;
            }
          }
        }
        return false;
      }).catchError((dynamic error) {
        debugPrint('kai: Error discovering services: $error'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

        // 예외 처리 로직 추가
        if (error is PlatformException &&
            error.code == 'set_notification_error') {
          // 특정 예외인 경우 다시 연결 시도
          if (mounted) {
            // Check if the widget is still mounted
            setState(() {
              mPumpConnectionStatus = context.l10n.disconnected;
              mPumpstateText = context.l10n.disconnected;
              mPumpconnectButtonText = context.l10n.connect;
              mPumpdeviceState = BluetoothDeviceState.disconnected;
              mCMgr.mPump!.ConnectionStatus = mPumpdeviceState;
              _showToastMessage(
                context,
                context.l10n.connectingError,
                'red',
                3,
              );
            });
          } else {
            //kai_20230616
            mPumpConnectionStatus =
                '${(!mounted) ? mContext : context.l10n.disconnected}';
            mPumpstateText =
                '${(!mounted) ? mContext : context.l10n.disconnected}';
            mPumpconnectButtonText =
                '${(!mounted) ? mContext : context.l10n.connect}';
            mPumpdeviceState = BluetoothDeviceState.disconnected;

            _showToastMessage(
              (!mounted) ? mContext! : context,
              '${(!mounted) ? mContext : context.l10n.connectingError}',
              'red',
              3,
            );
            if (mCMgr.mPump != null) {
              mCMgr.mPump!.ConnectionStatus = mPumpdeviceState;
              mCMgr.mPump!.notifyListeners();
              mCMgr.notifyListeners();
            }
          }
          /*
          Future.delayed(const Duration(seconds: 3), () async {
           log('kai: retry connectDiscovery after 3 secs');
            connectDiscovery(device);
          });
          */
          return false;
        } else if (error is Exception &&
            error.toString().contains(
                  'Cannot discoverServices while device is not connected. '
                  'State == BluetoothDeviceState.disconnected',
                )) {
          // 연결이 끊어진 상태인 경우 다시 연결 시도
          if (mounted) {
            // Check if the widget is still mounted
            setState(() {
              mPumpConnectionStatus = context.l10n.disconnected;
              mPumpstateText = context.l10n.disconnected;
              mPumpconnectButtonText = context.l10n.connect;
              mPumpdeviceState = BluetoothDeviceState.disconnected;
              mCMgr.mPump!.ConnectionStatus = mPumpdeviceState;
              _showToastMessage(
                context,
                context.l10n.connectingError,
                'red',
                3,
              );
            });
          } else {
            //kai_20230616 added
            mPumpConnectionStatus =
                '${(!mounted) ? mContext : context.l10n.disconnected}';
            mPumpstateText =
                '${(!mounted) ? mContext : context.l10n.disconnected}';
            mPumpconnectButtonText =
                '${(!mounted) ? mContext : context.l10n.connect}';
            mPumpdeviceState = BluetoothDeviceState.disconnected;
            if (mCMgr.mPump != null) {
              mCMgr.mPump!.ConnectionStatus = mPumpdeviceState;
              mCMgr.mPump!.notifyListeners();
              mCMgr.notifyListeners();
            }
            _showToastMessage(
              (!mounted) ? mContext! : context,
              '${(!mounted) ? mContext : context.l10n.connectingError}',
              'red',
              3,
            );
          }
          /*
          Future.delayed(const Duration(seconds: 3), () async {
           log('kai: retry connectDiscovery after 3 secs');
            connectDiscovery(device);
          });
          */
          return false;
        } else {
          // 다른 예외인 경우 추가 예외 처리 로직 수행
          return false;
          // ...
        }
      });

      if (!isfindDevice) {
        debugPrint('$TAG: connectDiscovery: there is no matched device '
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      } else {
        /*
        //kai_20231013 add to update device name here
        if(mCMgr != null && mCMgr.mPump != null) {
          mCMgr.mPump!.ModelName = mPumpName;
          mCMgr.mPump!.notifyListeners();
          mCMgr.notifyListeners();
        } */

        //let's request connected device info here
        final typePump = CspPreference.mPUMP_NAME.toLowerCase();

        debugPrint(
            '$TAG:kai:connectDiscovery: there is matched device($typePump)'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
        if (typePump.contains(
          BluetoothProvider.CareLevo_PUMP_NAME.toLowerCase(),
        )) {
          //let's set total reservoir amount here 200U = 2000uL = 2mL
          //( 1U = 10uL = 0.01mL )
          // show a dialog or direct sending it automatically
          mCMgr.mPump!.SetUpWizardMsg =
              '${(!mounted) ? mContext : context.l10n.setAmountReservior} 10 ~ 200U';
          //레저버에 주입된 양을 설정해 주세요
          mCMgr.mPump!.SetUpWizardActionType = 'SET_TIME_REQ';
          mCMgr.mPump!.showSetUpWizardMsgDlg = true;

          //kai_20230508 let's check the patch already set time & date first
          //then skip this
          if (CspPreference.getBooleanDefaultFalse(
                CspPreference.pumpSetTimeReqDoneKey,
              ) !=
              true) {
            mCMgr.mPump!.setResponseMessage(
              RSPType.SETUP_INPUT_DLG,
              mCMgr.mPump!.SetUpWizardMsg,
              SET_TIME_REQ,
            );
            //_showSetupWizardMsgDialog('Setup', mCMgr.mPump!.SetUpWizardMsg,
            //'SET_TIME_REQ');
          }
        } else if (typePump.contains(
          BluetoothProvider.CSPumpDeviceName.toLowerCase(),
        )) {
          //kai_20230926
          if (USE_CAREMEDI_COMMAND == true) {
            // show a dialog or direct sending it automatically
            mCMgr.mPump!.SetUpWizardMsg =
                '${(!mounted) ? mContext : context.l10n.setAmountReservior} 10 ~ 200U';
            //레저버에 주입된 양을 설정해 주세요
            mCMgr.mPump!.SetUpWizardActionType = 'SET_TIME_REQ';
            mCMgr.mPump!.showSetUpWizardMsgDlg = true;

            debugPrint(
                '$TAG: kai: check CspPreference.pumpSetTimeReqDoneKey(${CspPreference.getBooleanDefaultFalse(
              CspPreference.pumpSetTimeReqDoneKey,
            )})');
            //kai_20230508 let's check the patch already set time & date first
            //then skip this
            if (CspPreference.getBooleanDefaultFalse(
                  CspPreference.pumpSetTimeReqDoneKey,
                ) !=
                true) {
              mCMgr.mPump!.setResponseMessage(
                RSPType.SETUP_INPUT_DLG,
                mCMgr.mPump!.SetUpWizardMsg,
                SET_TIME_REQ,
              );
              //_showSetupWizardMsgDialog('Setup', mCMgr.mPump!.SetUpWizardMsg,
              //'SET_TIME_REQ');
            } else {
              requestPumpInfo();
            }
          } else {
            requestPumpInfo();
          }
        } else if (typePump.contains(
          BluetoothProvider.DANARS_PUMP_NAME.toLowerCase(),
        )) {
          debugPrint(
              '${TAG}kai::isfindDevice($isfindDevice):PumpType($typePump)'
              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
          //kai_20231228  let's send Pump Check command here after connection
          if (mCMgr.mPump! is PumpDanars) {
            if ((mCMgr.mPump as PumpDanars).onRetrying == false) {
              //reset the flag here first
              (mCMgr.mPump as PumpDanars).issendPumpCheckAfterConnectFailed = 0;

              //let's set timeout count
              if (USE_CHECK_CONNECTION_STATUS) {
                int MaxWaitCnt = 50;

                /// 5secs
                int waitCnt = 0;
                while (mCMgr.mPump!.ConnectionStatus !=
                    BluetoothDeviceState.connected) {
                  waitCnt++;
                  debugPrint(
                      '${TAG}kai::wait($waitCnt) for that mCMgr.mPump!.ConnectionStatus is goning to ${mCMgr.mPump!.ConnectionStatus}'
                      ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                  await Future<void>.delayed(
                    const Duration(milliseconds: 100),
                  );
                  if (waitCnt > MaxWaitCnt) {
                    debugPrint(
                        '${TAG}kai: timeout(5secs) for waiting connected of connection status!!'
                        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                    break;
                  }
                }
              }
              debugPrint(
                  '${TAG}kai::isfindDevice($isfindDevice):call sendPumpCheckAfterConnect()'
                  ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
              await (mCMgr.mPump as PumpDanars).sendPumpCheckAfterConnect();

              ///< null check
            }
          } else {
            debugPrint(
                '${TAG}kai::isfindDevice($isfindDevice):skip to call sendPumpCheckAfterConnect()'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
          }
        } else {
          requestPumpInfo();
        }
      }
    } catch (ex) {
      debugPrint('${TAG}kai:PumpPgae.dart:Error connecting to device: $ex'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
    }

    debugPrint('$TAG: kai: end connectDiscovery: !!!'
        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
  }

  /*
   * @brief request connected pump information
   */
  void requestPumpInfo() {
    if (FEATURE_CSP_INFO_REQUEST) {
      if (m_TX_WRITE_CHARACTERISTIC != null &&
          m_RX_READ_CHARACTERISTIC != null) {
        if (m_TX_WRITE_CHARACTERISTIC!.uuid
                .toString()
                .contains(CSP_TX_WRITE_CHARACTER_UUID) &&
            m_RX_READ_CHARACTERISTIC!.uuid
                .toString()
                .contains(CSP_RX_READ_CHARACTER_UUID)) {
          //kai_20221216  let's below request here
          // firmware version and battery level
          // remained Insulin amount, ( pressure sensor )
          // latest Insulin Injection amount,
          // latest Insulin Injected time
          // Occlusion Alert Status
          // local time sync 2023-01-02,17:55:50"

          Future.delayed(const Duration(seconds: 1), () async {
            //local time sync
            await sendMessage2Pump(
              _cmdActionSyncLocalTime +
                  DateFormat('yyyy-MM-dd,HH:mm:ss').format(DateTime.now()),
            );
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint(
                '$TAG:kai:call SendMessage2Pump(_cmdActionSyncLocalTime)',
              );
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: '
                    'Request = $_cmdActionSyncLocalTime\n'
                    '$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));

            //firmware version
            await sendMessage2Pump(_cmdFwVersion);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG:kai: call SendMessage2Pump(_cmdFwVersion)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: Request = $_cmdFwVersion\n$mPumpInsulinHistoryLog';
              });
            }

            await Future<void>.delayed(const Duration(seconds: 2));

            //send serial number request
            await sendMessage2Pump(_cmdSerialNumber);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG:kaI; call SendMessage2Pump(_cmdSerialNumber)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: Request = $_cmdSerialNumber\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));

            //battery level
            await sendMessage2Pump(_cmdBatLevel);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG:kai: call SendMessage2Pump(_cmdBatLevel)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: Request = $_cmdBatLevel\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
            //remained insulin amount
            await sendMessage2Pump(_cmdRemainInsulinAmount);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint(
                '$TAG:kai: call SendMessage2Pump(_cmdRemainInsulinAmount)',
              );
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: Request = $_cmdRemainInsulinAmount\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
            //latest injected insulin amount
            await sendMessage2Pump(_cmdInjectInsulin);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG:kai: call SendMessage2Pump(_cmdInjectInsulin)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: Request = $_cmdInjectInsulin\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
            //latest injected insulin time
            await sendMessage2Pump(_cmdInjectTime);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG:kai: call SendMessage2Pump(_cmdInjectTime)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: Request = $_cmdInjectTime\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));

            //occlusion alert status
            await sendMessage2Pump(_cmdOcclusionAlert);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG:kai: call SendMessage2Pump(_cmdOcclusionAlert)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: Request = $_cmdOcclusionAlert\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
            //Insulin injection time interval
            await sendMessage2Pump(_cmdInjectIntervalTime);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint(
                '$TAG:kai: call SendMessage2Pump(_cmdInjectIntervalTime)',
              );
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(
                  DateTime.now(),
                )}: Request = $_cmdInjectIntervalTime\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
          });

          // belows are configure items could be saved in storages
          // and editable by user
          // Injection Interval Time, on/off, (one time timer)
          // Pressure sensor check timer interval, on/off  ( Remained Insulin Amount : periodic timer)
          // Solenoid Motor Status check timer interval, on/off ( Occlusion Alert Status : periodic timer)
          // Occlusion Alert timer interval, on/off ( one time timer repeatedly )
          // Low Battery Alert timer interval, on/off ( one time timer repeatedly )
          // Low Insulin Amount Alert timer interval, on/off ( one time timer repeatedly )
          // RTC time sync setting [ long _rtcCurrTime ]
          // Injection history items ( injected time, injection amount,
          // remain amount )
          // typedef struct { uint64_t injectTime, uint8_t injectAmount,
          // uint8_t remainAmount } InjectHistory_t;
        }
      }
    }
  }

  Future<void> _savePump(PumpData pump) async {
    GetIt.I<SavePumpBloc>().add(
      SavePump(
        pump: pump,
      ),
    );
  }

  /*
   * @brief try to connect to the device that scanned by using 
   * predefined device name
   *
   */
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      if (USE_AUTO_CONNECTION == true) {
        await device.connect();
      } else {
        await device.connect(autoConnect: false);
      }
      // kai_20230307 let's consider this after //Navigator.of(context).pop(device);

    } catch (ex) {
      log('${TAG}Error connecting to device: $ex');
    }
  }

  Future<List<ListTile>> _getPumpdevicesList(
    List<BluetoothDevice> devices,
  ) async {
    final deviceList = <ListTile>[];
    var finddanaWRCharacteristic = 0;
    for (final device in devices) {
      finddanaWRCharacteristic = 0;

      ///< clear

      if (USE_AUTO_CONNECTION == true) {
        await device.connect();
      } else {
        await device.connect(autoConnect: false);
      }
      final isPumpDeviceFounded =
          await device.discoverServices().then((services) {
        for (final service in services) {
          if (FEATURE_CHECK_WR_CHARACTERISTIC != true) {
            for (final characteristic in service.characteristics) {
              if (characteristic.uuid.toString().toLowerCase() ==
                  mRX_READ_UUID) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_RX_READ_CHARACTERISTIC = characteristic;
                m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);
                m_RX_READ_CHARACTERISTIC!.value.listen((value) {
                  // kai_20230225 let's implement parser for received data
                  // or message sent from danaRS pump
                  // Handle incoming data here.
                  debugPrint('${TAG}Received data: $value');
                });
              } else if (characteristic.uuid.toString().toLowerCase() ==
                  mTX_WRITE_UUID) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_TX_WRITE_CHARACTERISTIC = characteristic;
              }
            }

            if (finddanaWRCharacteristic >= 2) {
              if (_USE_CSBLUETOOTH_PROVIDER == true) {
                mPump = device;
                mCMgr.mPump!.ConnectedDevice = device;
                // kai_20230225 register status change listener and Handle
                //connection status changes.
                connectionSubscription =
                    mCMgr.mPump!.ConnectedDevice!.state.listen((state) {
                  if (state == BluetoothDeviceState.connected) {
                    debugPrint('${TAG}Connected to pump');
                  } else if (state == BluetoothDeviceState.disconnected) {
                    debugPrint('${TAG}Disconnected from pump');
                    // kai_20230205 let's clear used resource and unregister
                    // used listener here
                    if (_csp1scanSubscription != null) {
                      _csp1scanSubscription!.cancel();

                      ///< scan result listener
                    }

                    if (connectionSubscription != null) {
                      connectionSubscription!.cancel();

                      ///< connection status listener
                    }

                    if (m_RX_READ_CHARACTERISTIC != null) {
                      m_RX_READ_CHARACTERISTIC!.value
                          .listen((event) {})
                          .cancel();

                      ///< value change listener
                      m_RX_READ_CHARACTERISTIC = null;
                      mCMgr.mPump!.PumpRxCharacteristic =
                          m_RX_READ_CHARACTERISTIC;
                    }

                    if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
                      m_RX_BATLEVEL_CHARACTERISTIC!.value
                          .listen((event) {})
                          .cancel();

                      ///< battery level value change listener
                      m_RX_BATLEVEL_CHARACTERISTIC = null;
                      mCMgr.mPump!.PumpRXBatLvlCharacteristic =
                          m_RX_BATLEVEL_CHARACTERISTIC;
                    }
                  }
                });
              }
              return true;
            }
          } else {
            if (service.uuid.toString().toLowerCase() == mBOLUS_SERVICE) {
              return true;
            }
          }
        }
        return false;
      });

      if (isPumpDeviceFounded) {
        deviceList.add(
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
            onTap: () {
              _connectToDevice(device);
            },
          ),
        );
      }
    }
    return deviceList;
  }

  /*
   * @brief Send a command to the connected Pump device
   */
  // Send a command to the connected pump.
  Future<void> sendMessage2Pump(String _data) async {
    try {
      if (m_TX_WRITE_CHARACTERISTIC != null) {
        await m_TX_WRITE_CHARACTERISTIC?.write(
          utf8.encode(
            _data,
          ),
        );
      } else {
        debugPrint(
          '${TAG}kai: SendMessage2Pump(): '
          'failed m_TX_WRITE_CHARACTERISTIC is null',
        );
      }
    } catch (ex) {
      debugPrint('${TAG}Error connecting to device: $ex');
    }
  }

  /*
   * @brief try to connect to the device that scanned by using predefined
   *  device name
   *
   */
  Future<void> _disconnectDevice(BluetoothDevice device) async {
    try {
      //kai_20230310 unregister listener first due to duplicated register
      // notify operation occurred
      // regardless of unregistering the listener when device is disconnected
      debugPrint('${TAG}kai: _disconnectDevice(): unregister Listener here');

      if (m_RX_READ_CHARACTERISTIC != null) {
        debugPrint(
          '${TAG}kai : _disconnectDevice: '
          'm_RX_READ_CHARACTERISTIC!.value.listen((event) {}).cancel()',
        );
        if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
          debugPrint(
            '${TAG}kai : _disconnectDevice: '
            'm_RX_READ_CHARACTERISTIC_VALUE_LISTENER.cancel()',
          );
          await m_RX_READ_CHARACTERISTIC_VALUE_LISTENER!.cancel();
          m_RX_READ_CHARACTERISTIC_VALUE_LISTENER = null;

          if (_USE_CSBLUETOOTH_PROVIDER == true) {
            mCMgr.mPump!.pumpValueSubscription =
                m_RX_READ_CHARACTERISTIC_VALUE_LISTENER;
          }
        }
      }

      if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
        debugPrint(
          '${TAG}kai : _disconnectDevice: '
          'm_RX_BATLEVEL_CHARACTERISTIC!.value.listen((event) {}).cancel()',
        );
        if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER != null) {
          debugPrint(
            '${TAG}kai : _disconnectDevice: '
            'm_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER.cancel()',
          );
          await m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER!.cancel();
          m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER = null;

          if (_USE_CSBLUETOOTH_PROVIDER == true) {
            mCMgr.mPump!.pumpBatValueSubscription =
                m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
          }
        }
      }

      await device.disconnect();
    } catch (ex) {
      log('${TAG}Error connecting to device: $ex');
    }
  }

  /*
   * @brief show the lists that scanned device by using predefined device name
   */
  // Build the ListView of devices
  Widget _buildListView() {
    final listTiles = <Widget>[
      Container(
        alignment: Alignment.center,
        //kai_20230830 child: const Text('Scanning...'),
        // child: Text(mShowScanStatus),
        child: isScanningTimeout
            ? Container(
                alignment: Alignment.center,
                height: 300,
                child: IllustrationMessage(
                  imagePath: MainAssets.searchFamilyMember,
                  title: '',
                  message: mShowScanStatus,
                ),
              )
            : Container(
                alignment: Alignment.center,
                height: 300,
                child: Text(
                  mShowScanStatus,
                ),
              ),
      )
    ];

    if (_USE_CSBLUETOOTH_PROVIDER == true) {
      if (mCMgr.mPump!.getConnectedDevice() != null
          //   && widget.hasConnectedBefore == true
          ) {
        // listTiles.clear();÷
        debugPrint(
          '${TAG}kai:_buildListView():'
          'mCMgr.mPump!.getConnectedDevice() != null',
        );
        final device = mCMgr.mPump!.getConnectedDevice();
        listTiles
          ..clear()
          ..add(
            ListTile(
              title: Text(
                device!.name,
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
                ),
                onPressed: widget.hasConnectedBefore
                    ? null
                    : () {
                        if (mPumpConnectionStatus ==
                            '${(!mounted) ? mContext : context.l10n.connected}') {
                          _disconnectDevice(device);
                          CspPreference.setBool(
                            CspPreference.disconnectedByUser,
                            true,
                          );
                        } else {
                          _connectToDevice(device);
                          CspPreference.setBool(
                            CspPreference.disconnectedByUser,
                            false,
                          );
                        }
                      },
                child: Text(
                  mPumpConnectionStatus ==
                          '${(!mounted) ? mContext : context.l10n.connected}'
                      ? '${(!mounted) ? mContext : context.l10n.disconnect}'
                      : widget.hasConnectedBefore
                          ? '${(!mounted) ? mContext : context.l10n.connecting}'
                          : '${(!mounted) ? mContext : context.l10n.connect}',
                  style: const TextStyle(
                    fontSize: Dimens.dp14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
      } else if (mCMgr.mPump!.getScannedDeviceLists() != null &&
          mCMgr.mPump!.getScannedDeviceLists()!.isNotEmpty) {
        debugPrint(
          '${TAG}kai:_buildListView(): '
          'mCMgr.mPump!.getScannedDeviceLists().length = '
          '${mCMgr.mPump!.getScannedDeviceLists()!.length}',
        );
        isScanningTimeout = true;
        listTiles.clear();
        for (final device in mCMgr.mPump!.getScannedDeviceLists()!) {
          listTiles.add(
            ListTile(
              title: Text(
                device.name,
                style: const TextStyle(
                  fontSize: Dimens.dp12,
                  fontWeight: FontWeight.normal,
                ),
              ),
              subtitle: Text(
                device.id.toString(),
                style: const TextStyle(
                  fontSize: Dimens.dp12,
                  fontWeight: FontWeight.normal,
                ),
              ),
              trailing: ElevatedButton(
                style: ButtonStyle(
                  minimumSize:
                      MaterialStateProperty.all<Size>(const Size(60, 25)),
                ),
                onPressed: widget.hasConnectedBefore
                    ? null
                    : () {
                        connectDiscovery(device);
                        CspPreference.setBool(
                          CspPreference.disconnectedByUser,
                          false,
                        );
                      },
                child: Text(
                  widget.hasConnectedBefore
                      ? '${(!mounted) ? mContext : context.l10n.connecting}'
                      : '${(!mounted) ? mContext : context.l10n.connect}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }
      }
    } else {
      if (Csp1devices != null) {
        isScanningTimeout = true;
        for (final device in Csp1devices!) {
          listTiles
            ..clear()
            ..add(
              ListTile(
                title: Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: Dimens.dp12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  device.id.toString(),
                  style: const TextStyle(
                    fontSize: Dimens.dp12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                trailing: ElevatedButton(
                  style: ButtonStyle(
                    minimumSize:
                        MaterialStateProperty.all<Size>(const Size(60, 25)),
                  ),
                  onPressed: widget.hasConnectedBefore
                      ? null
                      : () => connectDiscovery(device),
                  child: Text(
                    widget.hasConnectedBefore
                        ? '${(!mounted) ? mContext : context.l10n.connecting}'
                        : '${(!mounted) ? mContext : context.l10n.connect}',
                    style: const TextStyle(
                      fontSize: Dimens.dp14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
        }
      }
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height / 3,
      child: SingleChildScrollView(
        // <--- Put it here.
        child: Column(
          children: listTiles,
        ),
      ),
    );
  }

  /*
   * @brief show alert message dialog regard to low battery, occlusion,
   *  low reservoir
   */
  void _showAlertDialogOnEvent(String message) {
    // String Title = 'Alert';

    setState(() {
      _alertmessage = message;
    });

    // if (_key.currentContext == null)
    if (_USE_GLOBAL_KEY == true) {
      // create alert dialog and start tts low battery alert playback
      /*
        if(_USE_TTS_PLAYBACK == true)
        {
          setState(()
          {
            tts_playing = true;
            repeatSpeak(_alertmessage);
          });
        }

       */
      if (_USE_AUDIO_PLAYBACK == true) {
        //playAlert() ;
        if (mAudioPlayer == null) {
          mAudioPlayer = CsaudioPlayer();
        }

        if (mAudioPlayer != null) {
          if (mAudioPlayer.isPlaying == true) {
            mAudioPlayer.stop();
            mAudioPlayer.isPlaying = false;
          }
          mAudioPlayer.playAlert(message);
        } else {
          log('kai:scan_dialog_section:_showAlertDialogOnEvent: '
              'mAudioPlayer is  null: can not call '
              'mAudioPlayer.playAlert(message)');
        }
      }

      showDialog<BuildContext>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          // _USE_GLOBAL_KEY //  key: _key,
          title:
              //Text('Alert'),
              Container(
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Text(
              context.l10n.alerts,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: Dimens.dp16,
              ),
            ),
          ),
          content: Text(
            _alertmessage,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.normal,
              fontSize: Dimens.dp16,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: [
            TextButton(
              onPressed: () {
                //send "BZ1=0" to stop  buzzer in csp-1
                sendMessage2Pump('BZ2=0');
                //stop playback alert
                /*
                if(_USE_TTS_PLAYBACK == true)
                {
                  setState(()
                  {
                    tts_playing = false;
                  });
                }
                 */
                if (_USE_AUDIO_PLAYBACK == true) {
                  //stopAlert();
                  if (mAudioPlayer != null) {
                    mAudioPlayer.stopAlert();
                  } else {
                    log('kai:scan_dialog_section:'
                        '_showAlertDialogOnEvent:mAudioPlayer '
                        'is null:can not call mAudioPlayer.stopAlert()');
                  }
                }

                Navigator.of(context).pop();
              },
              child: Text(context.l10n.dismiss),
            ),
          ],
        ),
      );
    } else {
      // in case that the dialog already activated on the screen, call
      // setState() to update UI screen.
      setState(() {
        if (_key.currentState != null) {
          updateAlertMessage(_alertmessage);
        }
      });
    }
  }

  void updateAlertMessage(String message) {
    setState(() {
      _alertmessage = message;
    });
  }

  void updateTXErrorMessage(String message) {
    setState(() {
      _txErrorMsg = message;
    });
  }

  void _showTXErrorMsgDialog(String title, String message) {
    final Title = title;
    updateTXErrorMessage(message);
    final msg = _txErrorMsg;

    // if (_key.currentContext == null)
    if (_USE_GLOBAL_KEY == true) {
      // create dialog and start alert playback onetime
      if (_USE_AUDIO_PLAYBACK == true) {
        if (mAudioPlayer != null) {
          if (mAudioPlayer.isPlaying == true) {
            mAudioPlayer.stop();
            mAudioPlayer.isPlaying = false;
          }
          //  mAudioPlayer.playLowBatAlert();
          mAudioPlayer.playAlertOneTime('battery');
        }
      }

      showDialog<BuildContext>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          // _USE_GLOBAL_KEY  // key: _key,
          title: Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimens.dp10),
                topRight: Radius.circular(Dimens.dp10),
              ),
            ),
            padding: const EdgeInsets.all(Dimens.dp14),
            child: Text(
              Title,
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
                if (_USE_AUDIO_PLAYBACK == true) {
                  if (mAudioPlayer != null) {
                    mAudioPlayer.stop();
                  }
                }
                //let's try it again here
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.ok),
            ),
            TextButton(
              onPressed: () {
                if (_USE_AUDIO_PLAYBACK == true) {
                  if (mAudioPlayer != null) {
                    mAudioPlayer.stop();
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.dismiss),
            ),
          ],
        ),
      );
    } else {
      // in case that the dialog already activated on the screen,
      // call setState() to update UI screen.
      setState(() {
        if (_key.currentState != null) {
          updateTXErrorMessage(message);
        }
      });
    }
  }

  void updateSetupWizardMessage(String message, String actionType) {
    setState(() {
      _setupWizardMessage = message;
      _ActionType = actionType;
    });
  }

  void _showSetupWizardMsgDialog(
    String title,
    String message,
    String actionType,
  ) {
    final Title = title;
    updateSetupWizardMessage(message, actionType);
    final Msg = _setupWizardMessage;
    final ActionType = actionType;
    var inputText = '';
    var enableTextField = true;

    ///< enable/disable TextField
    const readOnlyTextField = false;

    ///< block typing something
    var HintStringTextField = context.l10n.enterYourInput;

    switch (actionType) {
      case 'HCL_DOSE_CANCEL_REQ':
        enableTextField = false;
        HintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = context.l10n.cancelInjectionDose;
        break;

      case 'PATCH_DISCARD_REQ':
        enableTextField = false;
        HintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = context.l10n.discardPatch;
        break;

      case 'SAFETY_CHECK_REQ':
      case 'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST':
        enableTextField = false;
        HintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = context.l10n.safetyCheck;
        break;

      case 'PATCH_INFO_REQ':
        enableTextField = false;
        HintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = context.l10n.patchInfoRequest;
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
          //  if(_key.currentContext == null)
          if (_USE_GLOBAL_KEY == true) {
            //kai_20230510 if procesing dialog is showing now, then
            // dismiss it also here
            _showToastMessage(context, Msg, 'blue', 0);
          }
          return;
        }
        break;
      case 'CANNULAR_INSERT_RPT_SUCCESS':
      case 'CANNULAR_INSERT_RSP_SUCCESS':
      case 'PATCH_NOTICE_RPT':
      case 'BUZZER_CHECK_RSP_SUCCESS':
      case 'PATCH_DISCARD_RSP_SUCCESS':
      case 'PATCH_RESET_RPT_SUCCESS_MODE0':
      case 'PATCH_RESET_RPT_SUCCESS_MODE1':
      case 'BUZZER_CHANGE_RSP_SUCCESS':
        {
          // if(_key.currentContext == null)
          if (_USE_GLOBAL_KEY == true) {
            _showToastMessage(context, Msg, 'blue', 0);
          }
          return;
        }
        break;

      case 'HCL_BOLUS_RSP_SUCCESS':
        {
          //let's update dose injection result here
          // update local DB & Remote DB thru cloudLoop
          // if(_key.currentContext == null)
          if (_USE_GLOBAL_KEY == true) {
            _showToastMessage(context, Msg, 'blue', 0);
          }
          return;
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
          //if(_key.currentContext == null)
          if (_USE_GLOBAL_KEY == true) {
            _showToastMessage(context, Msg, 'red', 0);
          }
          return;
        }
        break;

      case 'SET_TIME_REQ':
      case 'INFUSION_THRESHOLD_REQ':
      case 'HCL_DOSE_REQ':
      case 'INFUSION_INFO_REQ':
      case 'PATCH_RESET_REQ':
        enableTextField = true;
        HintStringTextField = context.l10n.enterYourInput;
        break;

      default:
        return;
    }

    //if (_key.currentContext == null)
    if (_USE_GLOBAL_KEY == true) {
      log(
        '${TAG}kai:check _key.currentContext == Null , lets create dialog here',
      );
      showDialog<BuildContext>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          // _USE_GLOBAL_KEY //  key: _key,
          title:
              //Text('Alert'),
              Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Text(
              Title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: Dimens.dp16,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Msg,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              TextField(
                enabled: enableTextField,

                ///< let's handle enable/disable based on ActionType
                onChanged: (value) {
                  inputText = value;
                },
                decoration: InputDecoration(
                  hintText: HintStringTextField,
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: [
            TextButton(
              onPressed: () {
                //let's check inputText is empty first
                log(
                  '${TAG}kai: press OK Button: _ActionType = $ActionType',
                );
                if (inputText.isNotEmpty) {
                  final type = ActionType;
                  log('${TAG}kai: _ActionType = $type');
                  switch (type) {
                    case 'SET_TIME_REQ':

                      ///< 0x11 : set total injected insulin amount : reservoir
                      {
                        // Date/Time,Injection amount, HCL Mode
                        // put reservoir injection amount
                        // here 1 ~ 300 U ( 2mL ~ 3mL )
                        final value = int.parse(inputText);
                        if (value > 300 || value < 1) {
                          _showToastMessage(
                            context,
                            '${context.l10n.pleaseTypeAvailableValue} : 10 ~ 200',
                            'red',
                            0,
                          );
                        } else {
                          CspPreference.setString(
                            CspPreference.pumpReservoirInjectionKey,
                            inputText,
                          );
                          Navigator.of(context).pop();
                          mCMgr.mPump!
                              .SendSetTimeReservoirRequest(value, 0x01, null);
                          _showToastMessage(
                            context,
                            '${context.l10n.sendingTimeNInjectInsulinAmount}'
                                '($value)U ...',
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
                        // 최대 볼러스 주입 량 (U, 2 byte: 정수+ 소수점 X 100) :
                        // 입력 범위 0.5 ~ 25 U
                        // 사용자가 설정 메뉴 중 볼러스 주입 정보의 최대 볼러스 량 정보를
                        // 재 설정하면 본 메시지가 송신된다.
                        //int value = int.parse(inputText)*100; ///< scaling by 100
                        if (!inputText.contains('.')) {
                          // in case that no floating point on the typed
                          // String sequence
                          inputText = '$inputText.0';
                        }
                        final value = (double.parse(inputText) * 100).toInt();
                        if (value > 2500 || value < 50)

                        ///< scaled range from 25 ~ 0.5
                        {
                          _showToastMessage(
                            context,
                            '${context.l10n.pleaseTypeAvailableValue} : '
                                '0.5 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          CspPreference.setString(
                            CspPreference.pumpMaxInfusionThresholdKey,
                            inputText,
                          );
                          mCMgr.mPump!
                              .sendSetMaxBolusThreshold(inputText, 0x01, null);
                          _showToastMessage(
                            context,
                            '${context.l10n.sendingMaxBolusInjectionAmount}'
                                '($inputText)U ...',
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
                        }
                      }
                      break;

                    case 'HCL_DOSE_REQ':

                      ///< 0x67 : Bolus/ Dose injection
                      {
                        // Mode (1 byte): HCL 통합 주입(0x00), 교정 볼러스
                        // (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
                        // HCLBy APP” 모드에서 기저와 볼러스 주입이 통합된 자동 모드에서
                        // 주입할 인슐린 총량을 주입하기위해 사용
                        // HCL By App” 모드에서 교정 볼러스 주입 제어 알고리즘에 의한
                        // 교정 볼러스 계산기 주입 값을 가감한
                        // 최종 교정 볼러스 주입량이 있으면 본 메시지를 패치로 전송한다.
                        //int value = int.parse(inputText)*100; ///< scaling by 100
                        if (!inputText.contains('.')) {
                          // in case that no floating point on the typed
                          // String sequence
                          inputText = '$inputText.0';
                        }
                        final value = (double.parse(inputText) * 100).toInt();
                        if (value > 2500 || value < 1)

                        ///< scaled range from 25 ~ 0.01
                        {
                          _showToastMessage(
                            context,
                            '${context.l10n.pleaseTypeAvailableValue} : '
                                '0.01 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          //kai_20230427 let's check isDoseInjectingNow is true
                          if (mCMgr.mPump!.isDoseInjectingNow == true) {
                            Navigator.of(context).pop();

                            ///< due to toast popup is showing behind
                            /// the active dialog
                            _showToastMessage(
                              context,
                              context.l10n.doseProcessingMsg,
                              'red',
                              0,
                            );
                            // ko : 펌프가 이전 도즈 주입을 처리중입니다.처리가 완료
                            // 될때 까지 잠시만 기다려 주세요.
                          } else {
                            CspPreference.setString(
                              CspPreference.pumpHclDoseInjectionKey,
                              inputText,
                            );
                            mCMgr.mPump!
                                .sendSetDoseValue(inputText, 0x00, null);
                            _showToastMessage(
                              context,
                              '${context.l10n.sendingDoseAmount}'
                                  '($inputText)U ...',
                              'blue',
                              0,
                            );
                            Navigator.of(context).pop();
                          }
                        }
                      }
                      break;

                    case 'HCL_DOSE_CANCEL_REQ':
                      {
                        log(
                          'kai: HCL_DOSE_CANCEL_REQ: enableTextField = '
                          '$enableTextField',
                        );
                        if (enableTextField == false) {
                          mCMgr.mPump!.cancelSetDoseValue(0x00, null);
                          _showToastMessage(
                            context,
                            context.l10n.sendingDoseInjectionCancelRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
                        } else {
                          //int value = int.parse(inputText)*100; ///< scaling by 100
                          if (!inputText.contains('.')) {
                            // in case that no floating point on the typed
                            // String sequence
                            inputText = '$inputText.0';
                          }
                          final value = (double.parse(inputText) * 100).toInt();
                          if (value > 2500 || value < 50)

                          ///< scaled range from 25 ~ 0.5
                          {
                            _showToastMessage(
                              context,
                              '${context.l10n.pleaseTypeAvailableValue} : '
                                  '0.5 ~ 25',
                              'red',
                              0,
                            );
                          } else {
                            mCMgr.mPump!.cancelSetDoseValue(0x00, null);
                            _showToastMessage(
                              context,
                              context.l10n.sendingDoseInjectionCancelRequest,
                              'blue',
                              0,
                            );
                            Navigator.of(context).pop();
                          }
                        }
                      }
                      break;

                    case 'PATCH_DISCARD_REQ':
                      {
                        if (enableTextField == false) {
                          mCMgr.mPump!.sendDiscardPatch(null);
                          _showToastMessage(
                            context,
                            context.l10n.sendingDiscardPatchRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
                        } else {
                          //int value = int.parse(inputText)*100; ///< scaling by 100
                          if (!inputText.contains('.')) {
                            // in case that no floating point on the typed
                            // String sequence
                            inputText = '$inputText.0';
                          }
                          final value = (double.parse(inputText) * 100).toInt();
                          if (value > 2500 || value < 50)

                          ///< scaled range from 25 ~ 0.5
                          {
                            _showToastMessage(
                              context,
                              '${context.l10n.pleaseTypeAvailableValue} : '
                                  '0.5 ~ 25',
                              'red',
                              0,
                            );
                          } else {
                            mCMgr.mPump!.sendDiscardPatch(null);
                            _showToastMessage(
                              context,
                              context.l10n.sendingDiscardPatchRequest,
                              'blue',
                              0,
                            );
                            Navigator.of(context).pop();
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
                            context,
                            '${context.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                            'red',
                            0,
                          );
                        } else {
                          mCMgr.mPump!.sendInfusionInfoRequest(
                            int.parse(inputText),
                            null,
                          );
                          _showToastMessage(
                            context,
                            context.l10n.sendingInfusionInfoRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
                        }
                      }
                      break;

                    case 'SAFETY_CHECK_REQ':
                    case 'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST':
                      {
                        if (enableTextField == false) {
                          mCMgr.mPump!.sendSafetyCheckRequest(null);
                          _showToastMessage(
                            context,
                            context.l10n.sendingSafetyCheckRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
                        } else {
                          final value = int.parse(inputText);
                          if (value > 1 || value < 0)

                          ///< scaled range from 0 ~ 1
                          {
                            _showToastMessage(
                              context,
                              '${context.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                              'red',
                              0,
                            );
                          } else {
                            mCMgr.mPump!.sendSafetyCheckRequest(null);
                            _showToastMessage(
                              context,
                              context.l10n.sendingSafetyCheckRequest,
                              'blue',
                              0,
                            );
                            Navigator.of(context).pop();
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
                            context,
                            '${context.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                            'red',
                            0,
                          );
                        } else {
                          mCMgr.mPump!
                              .sendResetPatch(int.parse(inputText), null);
                          _showToastMessage(
                            context,
                            context.l10n.sendingResetRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
                        }
                      }
                      break;

                    case 'PATCH_INFO_REQ':
                      {
                        if (enableTextField == false) {
                          mCMgr.mPump!.sendPumpPatchInfoRequest(null);
                          _showToastMessage(
                            context,
                            context.l10n.sendingPatchInfoRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
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
                              context,
                              '${context.l10n.pleaseTypeAvailableValue} : 0.5 ~ 25',
                              'red',
                              0,
                            );
                          } else {
                            mCMgr.mPump!.sendPumpPatchInfoRequest(null);
                            _showToastMessage(
                              context,
                              context.l10n.sendingPatchInfoRequest,
                              'blue',
                              0,
                            );
                            Navigator.of(context).pop();
                          }
                        }
                      }
                      break;

                    default:
                      {
                        Navigator.of(context).pop();
                      }
                      break;
                  }
                }
              },
              child: Text(context.l10n.ok),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.cancel),
            ),
          ],
        ),
      );
    } else {
      // 다이얼로그가 이미 띄워진 경우, setState()를 호출하여 업데이트합니다.
      log(
        '${TAG}kai:check _key.currentContext != Null, pendding dialog, just update value w/o showing dialog ',
      );
      if (_key.currentState != null) {
        setState(() {
          updateSetupWizardMessage(message, actionType);
        });

        //let's handle pendding dialog to set dialog Pendding flag here
        // PenddingDialog_key_currentContextNULL ++;
        pendingDlgMsg.add(Msg);
        pendingDlgTitle.add(Title);
        pendingDlgAction.add(ActionType);
        penddingDialogKeyCurrentContextNULL++;
      }
    }
  }

  /*
   * @brief parsing the received battery level data thru the connected 
   * Pump device's RX read Battery characteristic
   */
  void _handlePumpBatLevelValue(List<int> value) {
    debugPrint('${TAG}_handlePumpBatLevelValue() is called ');
    if (value.isEmpty || value.isEmpty) {
      return;
    }

    // 데이터 읽기 처리!
    if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        /*
        String data = utf8.decode(
            value, allowMalformed: true);
         */
        String data;
        // Try to decode as UTF-8
        try {
          data = utf8.decode(value);
        } on FormatException {
          // If UTF-8 decoding fails, try ASCII decoding
          data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
        }
        // Process decoded string
        log('${TAG}kai: handlePumpBatLevelValue():decodedString = $data');
        //let's check battery level notify characteristic first
        // insert _cmdBatLevel to data string w/ value here to update UI
        // received battery level data "[45]"
        var batlvl = value.toString();
        batlvl = batlvl.substring(batlvl.indexOf('[') + 1, batlvl.indexOf(']'));
        data = _cmdBatLevel + batlvl;

        if (data.contains(_cmdBatLevel)) {
          mPumpBatteryStatus = data.substring(_cmdBatLevel.length);
        }

        //update log history
        mPumpInsulinHistoryLog =
            '>>:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Notify = $data\n$mPumpInsulinHistoryLog';
      });
    } else {
      debugPrint('${TAG}_handlePumpBatLevelValue(): mounted is false ');
    }
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

    // showToast(context,Msg,_color!);
    /*
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            left: 30.0, right: 30.0, top: 30.0, bottom: 300.0),
        backgroundColor: _color,
        content: Text('$Msg'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
*/

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

  void showToast(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    OverlayEntry entry;

    entry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay?.insert(entry);

    Future<void>.delayed(const Duration(seconds: 2)).then((_) {
      entry.remove();
    });
  }
}

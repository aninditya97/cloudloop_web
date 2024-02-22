import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILog.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILogDB.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILogViewPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/audioplay/csaudioplayer.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/csBluetoothProvider.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/PumpDanars.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:formz/formz.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

//debug message
const bool DEBUG_MESSAGE_FLAG = true;
//kai_20230519  if use simulation by using virtual cgm app then set true here,
//others set false;
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
//kai_20230703  test connectionstatus callabck
const bool USE_TEST_CONNECTION_STATUS_CALLBACK = true;
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
 *@brief Sync local time delivered from mobile app to CSP1 and the format is 
 like "2023-01-01,14:10:20"
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
const Color Button_primarySolidColor = Color(0xFF5297FF);
const Color SelectedItemColor = Color(0xff3267E3);
const Color UnselectedItemColor = Color(0xff94A3B8);

class PumpPage extends StatefulWidget {
  @override
  _PumpPageState createState() => _PumpPageState();
}

class _PumpPageState extends State<PumpPage> {
  final GlobalKey<State> _key = GlobalKey();

  ///< context for showing dialog anywhere
  String _alertmessage = '';

  ///< text field that showing alert message sent from pump
  String _TxErrorMsg = '';

  ///< toast message field to show sending message error

  String _setupWizardMessage = '';

  ///< dialog message field that showing a notification which give a option to user
  String _ActionType = '';

  ///< setupWizard dialog action type to distinguish the actions

  final String TAG = '_PumpPageState:';
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

  //StreamSubscription<ScanResult>? _Csp1scanSubscription;
  StreamSubscription<List<ScanResult>>? _Csp1scanSubscription = null;

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
  int PenddingDialog_key_currentContextNULL = 0;
  List<String> PendingDlgMsg = [];
  List<String> PendingDlgAction = [];
  List<String> PendingDlgTitle = [];

  //kai_20230515 let's monitoring reconnection case after disconnect
  // due to sometimes RX Characteristic Notify does not enabled  regardless of status is true.
  int DisconnectedAfterConnection = 0;

  //kai_20230615 backup previous callback
  ResponseCallback? mPrevRspCallback = null;

  @override
  void didChangeDependencies() {
    //let's check pendding dialog exist here
    log(
      '${TAG}kai: didChangeDependencies() is called!!: PendingDLg = $PenddingDialog_key_currentContextNULL',
    );
    if (PenddingDialog_key_currentContextNULL >= 1) {
      if (PendingDlgMsg.isNotEmpty && PendingDlgMsg.isNotEmpty) {
        if (PendingDlgAction.isNotEmpty && PendingDlgAction.isNotEmpty) {
          if (PendingDlgTitle.isNotEmpty && PendingDlgTitle.isNotEmpty) {
            final Title = PendingDlgTitle.elementAt(
              PenddingDialog_key_currentContextNULL,
            );
            final Message =
                PendingDlgMsg.elementAt(PenddingDialog_key_currentContextNULL);
            final Action = PendingDlgAction.elementAt(
              PenddingDialog_key_currentContextNULL,
            );
            log(
              '${TAG}kai:didChangeDependencies():pendingCnt($PenddingDialog_key_currentContextNULL):Title = $Title\nMessage = $Message\nActionType = $Action',
            );

            _showSetupWizardMsgDialog(Title, Message, Action);

            PendingDlgTitle.clear();
            PendingDlgMsg.clear();
            PendingDlgAction.clear();

            PenddingDialog_key_currentContextNULL--;
            if (PenddingDialog_key_currentContextNULL <= 0) {
              PenddingDialog_key_currentContextNULL = 0;
            }
          }
        }
      }
    }
  }

  @override
  void initState() {
    //let's init csp preference instance here
    CspPreference.initPrefs();

    ///< shared Preference
    super.initState();

    if (_USE_CSBLUETOOTH_PROVIDER == true)

    ///< in case of using provider feature
    {
      mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);

      Csp1flutterBlue = mCMgr.mPump!.mPumpflutterBlue;
      Csp1devices = mCMgr.getScannedDeviceLists(mCMgr.mPump!);
      if (mCMgr.mPump!.ConnectionStatus == BluetoothDeviceState.connected) {
        mPumpconnectButtonText = 'Disconnect';
        debugPrint('${TAG}pumpConnectionState is connected');
      } else if (mCMgr.mPump!.ConnectionStatus ==
          BluetoothDeviceState.disconnected) {
        mPumpconnectButtonText = 'Connect';
        debugPrint('${TAG}pumpConnectionState is disconnected');
      } else if (mCMgr.mPump!.ConnectionStatus ==
          BluetoothDeviceState.disconnecting) {
        mPumpconnectButtonText = 'Connecting';
        debugPrint('${TAG}pumpConnectionState is disconnecting');
      } else if (mCMgr.mPump!.ConnectionStatus ==
          BluetoothDeviceState.connecting) {
        mPumpconnectButtonText = 'Disconnecting';
        debugPrint('${TAG}pumpConnectionState is connecting');
      }

      //get streamsubscription for value listener , connection status listener, battery level listener here
      if (mCMgr.mPump!.pumpValueSubscription == null) {
        debugPrint('${TAG}pumpValueSubscription is null');
      }
      if (mCMgr.mPump!.pumpBatValueSubscription == null) {
        debugPrint('${TAG}pumpBatValueSubscription is null');
      }
      if (mCMgr.mPump!.mPumpconnectionSubscription == null) {
        debugPrint('${TAG}mPumpconnectionSubscription is null');
      } else {
        if (USE_TEST_CONNECTION_STATUS_CALLBACK) {
          //kai_20230703 let's replace callback here for pump already have previous status callback of scan_dialog_section
          if (mCMgr.mPump!.ConnectionStatus == BluetoothDeviceState.connected) {
            debugPrint(
              '$TAG kai:registerPumpStateCallback(PumpStateCallback)',
            );
            // PrevconnectionSubscription = mCMgr.mPump!.mPumpconnectionSubscription;
            mCMgr.mPump!.mPumpconnectionSubscription!.cancel();
            mCMgr.mPump!.registerPumpStateCallback(PumpStateCallback);
            connectionSubscription = mCMgr.mPump!.mPumpconnectionSubscription;
          }
        }
      }

      if (mCMgr.mPump!.pumpRxCharacteristic == null) {
        debugPrint('${TAG}pumpRxCharacteristic is null');
      }
      if (mCMgr.mPump!.pumpTxCharacteristic == null) {
        debugPrint('${TAG}pumpTxCharacteristic is null');
      }
      if (mCMgr.mPump!.PumpRXBatLvlCharacteristic == null) {
        debugPrint('${TAG}PumpRXBatLvlCharacteristic is null');
      }

      if (m_RX_BATLEVEL_CHARACTERISTIC == null) {
        debugPrint('${TAG}m_RX_BATLEVEL_CHARACTERISTIC is null');
        if (mCMgr.mPump!.PumpRXBatLvlCharacteristic != null) {
          m_RX_BATLEVEL_CHARACTERISTIC =
              mCMgr.mPump!.PumpRXBatLvlCharacteristic;
        }
      }

      if (m_RX_READ_CHARACTERISTIC == null) {
        debugPrint('${TAG}m_RX_READ_CHARACTERISTIC is null');
        if (mCMgr.mPump!.pumpRxCharacteristic != null) {
          m_RX_READ_CHARACTERISTIC = mCMgr.mPump!.pumpRxCharacteristic;
        }
      }

      if (m_TX_WRITE_CHARACTERISTIC == null) {
        debugPrint('${TAG}m_TX_WRITE_CHARACTERISTIC is null');
        if (mCMgr.mPump!.pumpTxCharacteristic != null) {
          m_TX_WRITE_CHARACTERISTIC = mCMgr.mPump!.pumpTxCharacteristic;
        }
      }

      if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER == null) {
        debugPrint('${TAG}m_RX_READ_CHARACTERISTIC_VALUE_LISTENER is null');
        if (mCMgr.mPump!.pumpValueSubscription != null) {
          m_RX_READ_CHARACTERISTIC_VALUE_LISTENER =
              mCMgr.mPump!.pumpValueSubscription;
        }
      }

      if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER == null) {
        debugPrint('${TAG}m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER is null');
        if (mCMgr.mPump!.pumpBatValueSubscription != null) {
          m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
              mCMgr.mPump!.pumpBatValueSubscription;
        }
      }

      //kai_20230420 add to register _handleBluetoothProviderEvent here
      // mCMgr.mPump!.addListener(_handleBlueToothProviderEvent);
      debugPrint(
        '${TAG}kai:initState(): '
        'mCMgr.registerResponseCallbackListener(mCMgr.mPump!, '
        '_handleResponseCallback)',
      );
      //kai_20230615  let's backup callback here
      mPrevRspCallback = mCMgr.mPump!.getResponseCallbackListener();

      //kai_20230501   register ResponseCallback here
      mCMgr.registerResponseCallbackListener(
        mCMgr.mPump,
        _handleResponseCallback,
      );

      //kai_20240108  scan does not stop sometimes,

      // _stopScan();
      if (mCMgr.mPump!.mPumpflutterBlue != null) {
        log(':kai:initState():call mCMgr.mPump!.mPumpflutterBlue.stopScan()');
        mCMgr.mPump!.mPumpflutterBlue.stopScan();
      }

      if (_Csp1scanSubscription != null) {
        //kai_20240117 clear previous scanSubscription here
        log(':kai:initState():call _Csp1scanSubscription!.cancel()');
        _Csp1scanSubscription!.cancel();
        _Csp1scanSubscription = null;
      }
    } else {
      // Csp1flutterBlue = FlutterBluePlus.instance;
      Csp1flutterBlue =
          mCMgr.mPump!.mPumpflutterBlue = FlutterBluePlus.instance;
      Csp1devices = <BluetoothDevice>[];
    }

    //_startScan();

    //register callback for receiving change event from cspPreference
    // get selected pump type device name here Dexcom , csp-1, danaRS ,caremedi
    mPUMP_NAME = CspPreference.getString('pumpSourceTypeKey');
    debugPrint('$TAG:initState():mPUMP_NAME = $mPUMP_NAME');

    //get IJILog database and logs  here
    mIJILogDB = IJILogDB();
    mIJILogDB.getIJIDataBase();
/*
    if(_USE_TTS_PLAYBACK == true) { //tts instance
      mflutterTts = FlutterTts();
    }

 */

    if (_USE_AUDIO_PLAYBACK == true) {
      if (_USE_AUDIOCACHE == true) {
        //maudioCacheplayer = AudioCache();
        mAudioPlayer = CsaudioPlayer();
      } else {
        // maudioPlayer = AudioPlayer();
        mAudioPlayer = CsaudioPlayer();
      }
    }
  }

  @override
  void dispose() {
    debugPrint('$TAG:dispose(): _stopScan()');
    //kai_20230324 blocked due to below error
    // Error stopping scan: Looking up a deactivated widget's ancestor is unsafe.
    // I/flutter (12065): At this point the state of the widget's element tree is no longer stable.
    // I/flutter (12065): To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.
    // _stopScan();
    if (_USE_AUDIO_PLAYBACK) {
      // maudioPlayer.dispose();
      if (mAudioPlayer != null) {
        mAudioPlayer.release();
      } else {
        debugPrint(
            'PumpPage.dispose():kai:can not call mAudioPlayer.release() due to mAudioPlayer is null!!');
      }
    }

    //kai_20230420 add to unregister _handleBluetoothProviderEvent here
    // mCMgr.mPump!.removeListener(_handleBlueToothProviderEvent);
    // debugPrint('kai:dispose(): mCMgr.mPump!.removeListener(_handleBlueToothProviderEvent)');
    //kai_20230501   register ResponseCallback here
    mCMgr.unRegisterResponseCallbackListener(
      mCMgr.mPump!,
      _handleResponseCallback,
    );
    debugPrint(
      '${TAG}kai:dispose(): mCMgr.unRegisterResponseCallbackListener(mCMgr.mPump!, _handleResponseCallback))',
    );
    //kai_20230614 leave it
    // ResponseCallback? PrevRspCallback = mCMgr.mPump!.getResponseCallbackListener();
    if (mPrevRspCallback != null) {
      log(
        'kai:call mCMgr.registerResponseCallbackListener(mCMgr.mPump!, mPrevRspCallback!)',
      );
      mCMgr.registerResponseCallbackListener(mCMgr.mPump!, mPrevRspCallback!);
      mPrevRspCallback = null;
    }

    if (USE_TEST_CONNECTION_STATUS_CALLBACK) {
      //kai_20230703 let's check prev status connection callback exist here
      if (mCMgr.mPump!.ConnectionStatus == BluetoothDeviceState.disconnected) {
        if (connectionSubscription != null) {
          mCMgr.mPump!.unregisterPumpStateCallback();
          connectionSubscription = null;
        }
      }
    }

    super.dispose();
  }

  /*
   * @brief start scanning
   */
  Future<void> _startScan() async {
    try {
      debugPrint('$TAG:_startScan(): mounted = $mounted');
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

        if (mCMgr.mPump!.mPumpflutterBlue != null &&
            mCMgr.mPump!.mPumpflutterBlue.isScanning == true) {
          debugPrint(
            '$TAG:kai: _stopScan(): mounted = $mounted',
          );
          await _stopScan();
          if (_Csp1scanSubscription != null) {
            _Csp1scanSubscription!.cancel();
            _Csp1scanSubscription = null;
          }
        }

        if (_Csp1scanSubscription != null) {
          //kai_20230517 clear previous scanSubscription here
          log(':kai: call _Csp1scanSubscription!.cancel()');
          await _Csp1scanSubscription!.cancel();
          _Csp1scanSubscription = null;
        }

        if (_Csp1scanSubscription == null &&
            mCMgr.mPump!.mPumpflutterBlue != null) {
          debugPrint(
            '$TAG:kai: register scanResults.listen(): mounted = $mounted',
          );
          _Csp1scanSubscription =
              mCMgr.mPump!.mPumpflutterBlue.scanResults.listen((results) {
            debugPrint('$TAG:kai: call PumpflutterBlue!.scanResults.listen:');
            for (final r in results) {
              if (r.device.name.isNotEmpty) {
                debugPrint(
                  '${TAG}kai:_startScan :r.device.name(${r.device.name}), CspPreference.mPUMP_NAME = ${CspPreference.mPUMP_NAME},  r.device.id(${r.device.id})',
                );
              } else {
                //kai_20300404 test only
                if (_USE_TEST_SCAN == true) {
                  debugPrint(
                    '${TAG}kai: _startScan : Csp1devices!.add(${r.device.name}),  r.device.id(${r.device.id}), mounted = $mounted',
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
                      if (r.device.name
                          .toString()
                          .contains(CspPreference.mPUMP_NAME)) {
                        debugPrint(
                          '${TAG}kai: _startScan : Csp1devices!.add(${r.device.name}),  r.device.id(${r.device.id})',
                        );
                        mCMgr.mPump!.getScannedDeviceLists()!.add(r.device);
                      } else {
                        debugPrint('${TAG}kai: _startScan : not matched ');

                        //in case of danai  device name is serial number, so need to add here
                        if (CspPreference.mPUMP_NAME.isNotEmpty &&
                            CspPreference.mPUMP_NAME
                                .contains(DANARS_PUMP_NAME)) {
                          // if (r.device.name.toString().contains('XML'))
                          if (r.device.name.toString().length >= 10 &&
                              r.device.name.toLowerCase()[0] == 'x' &&
                              r.device.name.toLowerCase()[9] == 'i') {
                            mCMgr.mPump!.getScannedDeviceLists()!.add(r.device);
                          }
                          // mCMgr.mPump!.getScannedDeviceLists()!.add(r.device);
                        }
                        //kai_20300404 test only
                        else if (_USE_TEST_SCAN == true) {
                          mCMgr.mPump!.getScannedDeviceLists()!.add(r.device);
                        }
                      }
                    } else {
                      //kai_20300404 test only
                      if (_USE_TEST_SCAN == true) {
                        debugPrint(
                          '${TAG}kai: _startScan : Csp1devices!.add(${r.device.name}),  r.device.id(${r.device.id})',
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
                '$TAG:kai: call PumpflutterBlue!.scanResults.listen: mpumpdeviceLists is zero!!',
              );
            } else {
              debugPrint(
                '$TAG:kai: call PumpflutterBlue!.scanResults.listen: done : mpumpdeviceLists.length = ${mCMgr.mPump!.getScannedDeviceLists()!.length}',
              );
            }
          });
        } else {
          debugPrint(
            '$TAG:kai: failed to register scanResults.listen(): mounted = $mounted',
          );
        }

        if (mCMgr.mPump!.mPumpflutterBlue != null) {
          debugPrint(
            '$TAG:kai: PumpflutterBlue!.startScan(timeout: Duration(seconds: 5)): mounted = $mounted',
          );
          await mCMgr.mPump!.mPumpflutterBlue
              .startScan(timeout: const Duration(seconds: 5));
        }
      } else {
        if (Csp1devices != null) {
          Csp1devices!.clear();
        }

        if (mCMgr.mPump!.mPumpflutterBlue != null &&
            mCMgr.mPump!.mPumpflutterBlue.isScanning == true) {
          await _stopScan();
          if (_Csp1scanSubscription != null) {
            _Csp1scanSubscription!.cancel();
          }
        }

        if (_Csp1scanSubscription == null &&
            mCMgr.mPump!.mPumpflutterBlue != null) {
          _Csp1scanSubscription =
              mCMgr.mPump!.mPumpflutterBlue.scanResults.listen((results) {
            for (final r in results) {
              if (r.device.name.isNotEmpty) {
                debugPrint(
                  '${TAG}kai:_startScan :r.device.name(${r.device.name}), CspPreference.mPUMP_NAME = ${CspPreference.mPUMP_NAME},  r.device.id(${r.device.id})',
                );
              }

              if (Csp1devices != null && !Csp1devices!.contains(r.device)) {
                if (mounted) {
                  // Check if the widget is still mounted
                  setState(() {
                    if (r.device.name.isNotEmpty) {
                      if (r.device.name
                          .toString()
                          .contains(CspPreference.mPUMP_NAME)) {
                        debugPrint(
                          '${TAG}kai: _startScan : Csp1devices!.add(${r.device.name}),  r.device.id(${r.device.id})',
                        );
                        Csp1devices!.add(r.device);
                      } else {
                        //debugPrint('kai: _startScan : not matched ');
                      }
                    } else {
                      //kai_20230420 let's add device which do not have name also here
                      debugPrint('${TAG}kai: _startScan: no device name ');
                    }
                  });
                }
              }
            }
          });
        }

        if (mCMgr.mPump!.mPumpflutterBlue != null) {
          await mCMgr.mPump!.mPumpflutterBlue
              .startScan(timeout: const Duration(seconds: 5));
        }
      }
    } catch (ex) {
      log('${TAG}Error starting scan: $ex');
      //let's show pop up message as like "bluetooth should be activated first to scan device!!
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          if (DEBUG_MESSAGE_FLAG) {
            debugPrint('${TAG}Bluetooth not enabled !!');
          }
          // kai_20221125  let's show dialog with message "There is no scanned device at this time !!"
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
        });
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
        if (mCMgr.mPump!.mPumpflutterBlue != null) {
          await mCMgr.mPump!.mPumpflutterBlue.stopScan();
        }

        if (_Csp1scanSubscription != null) {
          _Csp1scanSubscription!.cancel();
          _Csp1scanSubscription = null;
        }
      } else {
        if (mCMgr.mPump!.mPumpflutterBlue != null) {
          await mCMgr.mPump!.mPumpflutterBlue.stopScan();
        }

        if (_Csp1scanSubscription != null) {
          _Csp1scanSubscription!.cancel();
          _Csp1scanSubscription = null;
        }
      }
    } catch (ex) {
      log('${TAG}Error stopping scan: $ex');
    }
  }

  /*
   * @brief get the scanned device lists
   */
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
            service.characteristics.forEach((characteristic) async {
              if (characteristic.uuid.toString().toLowerCase() ==
                  mRX_READ_UUID) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_RX_READ_CHARACTERISTIC = characteristic;
                await m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);
                m_RX_READ_CHARACTERISTIC!.value.listen((value) {
                  // kai_20230225 let's implement parser for received data or message sent from danaRS pump
                  // Handle incoming data here.
                  debugPrint('${TAG}Received data: $value');
                });
              } else if (characteristic.uuid.toString().toLowerCase() ==
                  mTX_WRITE_UUID) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_TX_WRITE_CHARACTERISTIC = characteristic;
              }
            });

            if (finddanaWRCharacteristic >= 2) {
              if (_USE_CSBLUETOOTH_PROVIDER == true) {
                mPump = device;
                mCMgr.mPump!.ConnectedDevice = device;
                // kai_20230225 register status change listener and Handle connection status changes.
                connectionSubscription =
                    mCMgr.mPump!.ConnectedDevice!.state.listen((state) {
                  if (state == BluetoothDeviceState.connected) {
                    debugPrint('${TAG}Connected to pump');
                  } else if (state == BluetoothDeviceState.disconnected) {
                    debugPrint('${TAG}Disconnected from pump');
                    // kai_20230205 let's clear used resource and unregister used listener here
                    if (_Csp1scanSubscription != null) {
                      _Csp1scanSubscription!.cancel();

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
  Future<void> SendMessage2Pump(String _data) async {
    if (m_TX_WRITE_CHARACTERISTIC != null) {
      await m_TX_WRITE_CHARACTERISTIC?.write(utf8.encode(_data));
    } else {
      debugPrint(
        '${TAG}kai: SendMessage2Pump(): failed m_TX_WRITE_CHARACTERISTIC is null',
      );
    }
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
            SendMessage2Pump(
              _cmdActionSyncLocalTime +
                  DateFormat('yyyy-MM-dd,HH:mm:ss').format(DateTime.now()),
            );
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint(
                '$TAG: call SendMessage2Pump(_cmdActionSyncLocalTime)',
              );
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Request = $_cmdActionSyncLocalTime\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));

            //firmware version
            SendMessage2Pump(_cmdFwVersion);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG: call SendMessage2Pump(_cmdFwVersion)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Request = $_cmdFwVersion\n$mPumpInsulinHistoryLog';
              });
            }

            await Future<void>.delayed(const Duration(seconds: 2));

            //send serial number request
            SendMessage2Pump(_cmdSerialNumber);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG: call SendMessage2Pump(_cmdSerialNumber)');
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
            SendMessage2Pump(_cmdBatLevel);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG: call SendMessage2Pump(_cmdBatLevel)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Request = $_cmdBatLevel\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
            //remained insulin amount
            SendMessage2Pump(_cmdRemainInsulinAmount);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint(
                '$TAG: call SendMessage2Pump(_cmdRemainInsulinAmount)',
              );
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Request = $_cmdRemainInsulinAmount\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
            //latest injected insulin amount
            SendMessage2Pump(_cmdInjectInsulin);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG: call SendMessage2Pump(_cmdInjectInsulin)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Request = $_cmdInjectInsulin\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
            //latest injected insulin time
            SendMessage2Pump(_cmdInjectTime);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG: call SendMessage2Pump(_cmdInjectTime)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Request = $_cmdInjectTime\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));

            //occlusion alert status
            SendMessage2Pump(_cmdOcclusionAlert);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint('$TAG: call SendMessage2Pump(_cmdOcclusionAlert)');
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Request = $_cmdOcclusionAlert\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
            //Insulin injection time interval
            SendMessage2Pump(_cmdInjectIntervalTime);
            if (DEBUG_MESSAGE_FLAG) {
              debugPrint(
                '$TAG: call SendMessage2Pump(_cmdInjectIntervalTime)',
              );
            }
            if (mounted) {
              // Check if the widget is still mounted
              setState(() {
                mPumpInsulinHistoryLog =
                    '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Request = $_cmdInjectIntervalTime\n$mPumpInsulinHistoryLog';
              });
            }
            await Future<void>.delayed(const Duration(seconds: 2));
          });

          // belows are configure items could be saved in storages and editable by user
          // Injection Interval Time, on/off, (one time timer)
          // Pressure sensor check timer interval, on/off  ( Remained Insulin Amount : periodic timer)
          // Solenoid Motor Status check timer interval, on/off ( Occlusion Alert Status : periodic timer)
          // Occlusion Alert timer interval, on/off ( one time timer repeatedly )
          // Low Battery Alert timer interval, on/off ( one time timer repeatedly )
          // Low Insulin Amount Alert timer interval, on/off ( one time timer repeatedly )
          // RTC time sync setting [ long _rtcCurrTime ]
          // Injection history items ( injected time, injection amount, remain amount )
          // typedef struct { uint64_t injectTime, uint8_t injectAmount, uint8_t remainAmount } InjectHistory_t;
        }
      }
    }
  }

  /*
   * @brief parsing the received battery level data thru the connected Pump device's RX read Battery characteristic
   */
  void _handlePumpBatLevelValue(List<int> value) {
    debugPrint('${TAG}_handlePumpBatLevelValue() is called ');
    if (value == null || value.isEmpty || value.isEmpty) {
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

  String HexToString(int byte) {
    return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  /*
   * @brief parsing the received data thru the connected Pump device's RX read characteristic
   */
  void handlePumpValue(List<int> value) {
    if (value == null || value.isEmpty) {
      debugPrint(
          '${TAG}kai: handlePumpValue(): value.isEmpty or value is null!! return');
      return;
    }
    debugPrint('${TAG}kai: handlePumpValue() is called: mounted(${mounted})');
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
          mCMgr.mCgm!.notifyListeners();

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
        try {
          receivedData =
              ascii.decode(value.where((byte) => byte <= 0x7f).toList());
        } on FormatException {
          // If both UTF-8 and ASCII decoding fail, handle the error here
          receivedData = "Error: Unable to decode as UTF-8 or ASCII";
        }
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
    else if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        String data;
        // Try to decode as UTF-8
        try {
          data = utf8.decode(value);
        } on FormatException {
          // If UTF-8 decoding fails, try ASCII decoding
          try {
            data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
            final LENGTH = value.length;
            if (LENGTH != data.length) {
              final hexString = value.map(HexToString).join(' ');
              //final decimalString = value.map((hex) => hex.toRadixString(10)).join(' ');
              data = hexString;
              debugPrint(
                  '${TAG}kai: handlePumpValue(): LENGTH != data.length : data(${data})');
            }
          } on FormatException {
            // If both UTF-8 and ASCII decoding fail, handle the error here
            // data = "Error: Unable to decode as UTF-8 or ASCII";
            final hexString = value.map(HexToString).join(' ');
            //final decimalString = value.map((hex) => hex.toRadixString(10)).join(' ');
            data = hexString;
          }
        }
        // Process decoded string
        log('${TAG}kai: handlePumpValue():decodedString = $data');

        //kai_20230217 showing IJILog Message sent from csp1
        if (data.contains(_cmdIJILogHeader)) {
          // example received message : "IJILog(6)1676635096,1,0.05,0"
          // index, time, type, data value, report
          // IJILog DB index 6
          // injection Time 1676635096
          // type 1(bolus) 2(basal) 3(occlusion alert) 4(low battery alert) 5(low reservoir alert)
          // data  xx.xx      xx.xx   OCLAL              BATLO                RIALO
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
          // let's covert the timestamp based on seconds & UTC time sent from CSP1
          // into miliseconds time by using DateTime class with set isUTC as true
          //String _time = DateFormat("yyyy/MM/dd-HH:mm:ss").format(DateTime.fromMillisecondsSinceEpoch(int.parse(injectTime)*1000));
          final _time = DateFormat('yyyy/MM/dd-HH:mm:ss').format(
            DateTime.fromMillisecondsSinceEpoch(
              int.parse(injectTime) * 1000,
              isUtc: true,
            ),
          );
          final typeValue = int.parse(type);

          data =
              '$_cmdIJILogHeader($index)$_time,${iJILogTypes[(typeValue - 1)]}'
              '($dataValue),$_alertReport($report)';
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
            '>>:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: Notify = $data\n$mPumpInsulinHistoryLog';

        //let's check the response of command we sent to csp-1 device
        if (data.contains(_cmdFwVersion)) {
          mPumpFWVersion = data.substring(_cmdFwVersion.length);
          //kai_20230926 update battery level
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.fw = mPumpFWVersion;
            //mCMgr.mPump!.notifyListeners();
            mCMgr.notifyListeners();
          }
        } else if (data.contains(_cmdSerialNumber)) {
          mSN = data.substring(_cmdSerialNumber.length);
          //kai_20230926 update battery level
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.SN = mSN;
            // mCMgr.mPump!.notifyListeners();
            mCMgr.notifyListeners();
          }
        } else if (data.contains(_cmdBatLevel)) {
          mPumpBatteryStatus = data.substring(_cmdBatLevel.length);
          //let's show low battery pop up if the value is <= 18
          final LowLevel = data.substring(_cmdBatLevel.length);
          final level = int.parse(LowLevel);
          //kai_20230926 update battery level
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.Battery = LowLevel;
            //mCMgr.mPump!.notifyListeners();
            mCMgr.notifyListeners();
          }
          if (level <= 18) {
            /* pop up window have a dismiss button which send "BZ1=0" to stop buzzer of the connected csp-1 pump
            and  also can stop the playback predefined alarm in application side
             */
            _showAlertDialogOnEvent(
              'Pump Low Battery $level%',
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
                DateTime.fromMillisecondsSinceEpoch(int.parse(mPumpInjectTime)));
            */
        } else if (data.contains(_cmdRemainInsulinAmount)) {
          mPumpInsulinRemain = data.substring(_cmdRemainInsulinAmount.length);
          //kai_20230926 update battery level
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.reservoir = mPumpInsulinRemain;
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
      });
    }
  }

  /**
   * @brief pump connectionstatus callback
   */
  void PumpStateCallback(BluetoothDeviceState state) {
    debugPrint(
      '${TAG}kai: PumpStateCallback(): mounted($mounted), mPumpdeviceState = $mPumpdeviceState,  state = $state'
      ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())}',
    );

    // if (USE_PUMPDANA_DEBUGMSG)
    {
      mPumpInsulinHistoryLog =
          'PumpStateCallback():mPumpdeviceState = $mPumpdeviceState, state = $state'
                  ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})\n' +
              mPumpInsulinHistoryLog;
      if (mounted) {
        setState(() {});
      }
    }

    if (mPumpdeviceState == state) {
      /*kai_20231101  sometimes we get the below status when we try to connect again after user disconnect
      // [onConnectionStateChange] status: 133 newState: 0
      // PumpStateCallback(): mounted(true), state = BluetoothDeviceState.disconnected, new state = BluetoothDeviceState.disconnected
      // in this case , if previous registered callback exist, let's cancel it here
      */
      if (mPumpdeviceState == BluetoothDeviceState.disconnected) {
        //let's bypass
      } else {
        if (mCMgr != null && mCMgr.mPump != null) {
          mCMgr.mPump!.ConnectionStatus = state;
        }

        debugPrint(
          '${TAG}kai: PumpStateCallback(): mounted($mounted),  return same state from connected to connected !!'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
        );
        return;
      }
    }

    switch (state) {
      case BluetoothDeviceState.connected:
        {
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.ConnectionStatus = state;
            debugPrint(
              '${TAG}kai:Connected to pump : mounted($mounted),ConnectionStatus(${mCMgr.mPump!.ConnectionStatus})'
              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
            );
          }

          if (mCMgr != null &&
              mCMgr.mPump != null &&
              mCMgr.mPump!.getConnectedDevice() != null) {
            if (CspPreference.mPUMP_NAME
                .toLowerCase()
                .contains('${DANARS_PUMP_NAME.toLowerCase()}')) {
              mCMgr.mPump!.ModelName = '$DANARS_PUMP_NAME';
            } else {
              mCMgr.mPump!.ModelName =
                  '${mCMgr.mPump!.getConnectedDevice()!.name.toString()}';
            }
            mCMgr.mPump!.notifyListeners();
            mCMgr.notifyListeners();
          }

          if (mounted) {
            // Check if the widget is still mounted
            setState(() {
              mPumpConnectionStatus = 'Connected';
              mPumpstateText = 'Connected';
              mPumpconnectButtonText = 'Disconnect';
              mPumpdeviceState = state;
              mCMgr.mPump!.ConnectionStatus = state;

              //kai_20240122 BELOW IS NEEDEDREALLY?
              //let's clear scan device list here
              /*
              if (mCMgr.mPump!.getScannedDeviceLists() != null) {
                mCMgr.mPump!.getScannedDeviceLists()!.clear();
              }
              */

              //let's set timer after 5 secs trigger to check RX characteristic and battery Notify
              Future.delayed(const Duration(seconds: 5), () async {
                if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER == null) {
                  debugPrint(
                    '${TAG}kai: register RX_Read characteristic for value listener due to auto reconnection ',
                  );
                  if (m_RX_READ_CHARACTERISTIC != null) {
                    //kai_20240122 i'm not sure that previous value listener still alive or not
                    // regardless of this value is NULL
                    // that's why cancel first again here
                    await m_RX_READ_CHARACTERISTIC!.value
                        .listen(handlePumpValue)
                        .cancel();

                    m_RX_READ_CHARACTERISTIC_VALUE_LISTENER =
                        m_RX_READ_CHARACTERISTIC!.value.listen(handlePumpValue);

                    try {
                      if (!m_RX_READ_CHARACTERISTIC!.isNotifying) {
                        debugPrint(
                          '${TAG}kai: register RX_Read characteristic set Notify due to auto reconnection ',
                        );

                        if (mCMgr != null &&
                            mCMgr.mPump != null &&
                            mCMgr.mPump!.isSetNotifyFailed == true) {
                          await m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);
                          mCMgr.mPump!.isSetNotifyFailed = false;
                          debugPrint(
                              '${TAG}kai:after 5 secs: PumpStateCallback(): set isSetNotifyFailed(false)'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                        }
                      } else {
                        //kai_20230515 workaround
                        if (_USE_FORCE_RX_NOTI_ENABLE == true) {
                          if (DisconnectedAfterConnection > 0) {
                            DisconnectedAfterConnection =
                                DisconnectedAfterConnection - 1;
                            if (DisconnectedAfterConnection < 0) {
                              DisconnectedAfterConnection = 0;
                            }
                            debugPrint(
                              '${TAG}kai: register RX_Read characteristic  Notify already enabled: due to auto reconnection ',
                            );

                            //kai_20240119
                            if (mCMgr != null &&
                                mCMgr.mPump != null &&
                                mCMgr.mPump!.isSetNotifyFailed == true) {
                              debugPrint(
                                '${TAG}kai: register RX_Read characteristic  set Notify enable again '
                                'due to isSetNotifyFailed(true) ',
                              );
                              await m_RX_READ_CHARACTERISTIC!
                                  .setNotifyValue(true);

                              mCMgr.mPump!.isSetNotifyFailed = false;
                              debugPrint(
                                '${TAG}kai:register RX_Read characteristic  set Notify enable again: isSetNotifyFailed(false) ',
                              );
                            }
                          }
                        }
                      }
                    } catch (ex) {
                      debugPrint(
                        'kai: BluetoothDeviceState.connected: '
                        'Error: $ex : isSetNotifyFailed(${mCMgr.mPump!.isSetNotifyFailed})'
                        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                      );
                    }
                  }
                }
              });
            });
          } else {
            //kai_20230616 added
            mPumpConnectionStatus = 'Connected';
            mPumpstateText = 'Connected';
            mPumpconnectButtonText = 'Disconnect';
            mPumpdeviceState = state;

            //let's clear scan device list here
            if (mCMgr != null && mCMgr.mPump != null) {
              mCMgr.mPump!.ConnectionStatus = state;
              if (mCMgr.mPump!.getScannedDeviceLists() != null) {
                mCMgr.mPump!.getScannedDeviceLists()!.clear();
              }
            }
          }
        }
        break;

      case BluetoothDeviceState.disconnected:
        {
          debugPrint(
            '${TAG}Disconnected from pump: mounted($mounted)'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
          );

          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.ModelName = '';
            mCMgr.mPump!.notifyListeners();
            mCMgr.notifyListeners();
          }

          if (_USE_FORCE_RX_NOTI_ENABLE == true) {
            DisconnectedAfterConnection = DisconnectedAfterConnection + 1;
          }

          final typePump = CspPreference.mPUMP_NAME;
          if (USE_DANAI_CHECK_CONNECTION_COMMAND_SENT) {
            debugPrint('${TAG}kai::PumpType($typePump)');
            //kai_20231228  let's send Pump Check command here after connection
            if (mCMgr.mPump! is PumpDanars) {
              debugPrint('${TAG}kai::disconnected: '
                  'call KeepConnectionStatusTimer.cancel()');
              (mCMgr.mPump as PumpDanars).KeepConnectionStatusTimer?.cancel();
              (mCMgr.mPump as PumpDanars).KeepConnectionStatusTimer = null;

              //kai_20240111 add to set 1 due to disconnected here
              (mCMgr.mPump as PumpDanars).issendPumpCheckAfterConnectFailed = 1;
              (mCMgr.mPump as PumpDanars).onRetrying = false;
              if (USE_CHECK_ENCRYPTION_ENABLED) {
                (mCMgr.mPump as PumpDanars).enabledStartEncryption = false;
              }
            }
          }

          if (mounted) {
            // Check if the widget is still mounted
            setState(() {
              mPumpConnectionStatus = 'Disconnected';
              mPumpstateText = 'Disconnected';
              mPumpconnectButtonText = 'Connect';
              mPumpdeviceState = state;
              mCMgr.mPump!.ConnectionStatus = state;
            });
          } else {
            //kai_20230616 added
            mPumpConnectionStatus = 'Disconnected';
            mPumpstateText = 'Disconnected';
            mPumpconnectButtonText = 'Connect';
            mPumpdeviceState = state;
            if (mCMgr != null && mCMgr.mPump != null) {
              mCMgr.mPump!.ConnectionStatus = state;
              mCMgr.mPump!.notifyListeners();
              mCMgr.notifyListeners();
            }
          }
          // kai_20230205 let's clear used resource and unregister used listener here
          if (_Csp1scanSubscription != null) {
            debugPrint(
              '${TAG}kai : disconnect: _Csp1scanSubscription!.cancel()',
            );
            _Csp1scanSubscription!.cancel();

            ///< scan result listener
          }

          //kai_20230310 if call below unregister status listener then auto reconnection status updating does not work .
          // so block it temporary
          if (FEATURE_STATUS_REGISTER_BY_USER == true) {
            if (connectionSubscription != null) {
              debugPrint(
                '${TAG}kai : disconnect: connectionSubscription!.cancel()',
              );
              connectionSubscription!.cancel();

              ///< connection status listener
            }

            if (mounted && mCMgr.mPump!.mPumpconnectionSubscription != null) {
              debugPrint(
                '${TAG}kai : disconnect: unregisterPumpStateCallback()',
              );
              mCMgr.mPump!.unregisterPumpStateCallback();
            } else if (mCMgr.mPump!.mPumpconnectionSubscription != null) {
              debugPrint(
                '${TAG}kai : mounted(false) disconnect: unregisterPumpStateCallback()',
              );
              mCMgr.mPump!.unregisterPumpStateCallback();
            }
          }

          if (m_RX_READ_CHARACTERISTIC != null) {
            debugPrint(
              '${TAG}kai : disconnect: m_RX_READ_CHARACTERISTIC!.value.listen((event) {}).cancel():mount = $mounted',
            );
            if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
              m_RX_READ_CHARACTERISTIC_VALUE_LISTENER!.cancel();
              m_RX_READ_CHARACTERISTIC_VALUE_LISTENER = null;

              if (mounted) {
                mCMgr.mPump!.pumpValueSubscription = null;
                debugPrint(
                  '${TAG}kai : disconnect: mCMgr.mPump!.pumpValueSubscription = null',
                );
              }
            }
          }

          if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
            debugPrint(
              '${TAG}kai : disconnect: m_RX_BATLEVEL_CHARACTERISTIC!.value.listen((event) {}).cancel():mount = $mounted',
            );
            if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER != null) {
              m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER!.cancel();
              m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER = null;
              if (mounted) {
                mCMgr.mPump!.pumpBatValueSubscription = null;
                debugPrint(
                  '${TAG}kai : disconnect: mCMgr.mPump!.pumpBatValueSubscription = null',
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
            mPumpstateText = 'Disconnecting';
            mPumpConnectionStatus = mPumpstateText;
            mPumpconnectButtonText = mPumpstateText;
            mPumpdeviceState = state;
            mCMgr.mPump!.ConnectionStatus = state;
          });
        } else {
          //kai_20230616
          mPumpstateText = 'Disconnecting';
          mPumpConnectionStatus = mPumpstateText;
          mPumpconnectButtonText = mPumpstateText;
          mPumpdeviceState = state;
          if (mCMgr != null && mCMgr.mPump != null) {
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
            mPumpstateText = 'Connecting';
            mPumpConnectionStatus = mPumpstateText;
            mPumpconnectButtonText = mPumpstateText;
            mPumpdeviceState = state;
            mCMgr.mPump!.ConnectionStatus = state;
          });
        } else {
          mPumpstateText = 'Connecting';
          mPumpConnectionStatus = mPumpstateText;
          mPumpconnectButtonText = mPumpstateText;
          mPumpdeviceState = state;
          if (mCMgr != null && mCMgr.mPump != null) {
            mCMgr.mPump!.ConnectionStatus = state;
            mCMgr.mPump!.notifyListeners();
            mCMgr.notifyListeners();
          }
        }

        debugPrint(
            '${TAG}kai:connecting or pairing:Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

        break;
    }
  }

  /*
   * @brief try to connect to the device that scanned by using predefined device name
   *        and find service and supported characteristics
   */
  Future<void> connectDiscovery(BluetoothDevice device) async {
    try {
      // ignore: unrelated_type_equality_checks
      debugPrint('${TAG}kai: start  connectDiscovery()'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      if (_USE_CSBLUETOOTH_PROVIDER == true) {
        if (mCMgr.mPump!.mPumpflutterBlue != null &&
            mCMgr.mPump!.mPumpflutterBlue.isScanning == true) {
          await mCMgr.mPump!.mPumpflutterBlue.stopScan();
        }
      } else {
        if (Csp1flutterBlue != null && Csp1flutterBlue!.isScanning == true) {
          await Csp1flutterBlue!.stopScan();
        }
      }

      //let's check current set pump type here
      final type = CspPreference.mPUMP_NAME;
      debugPrint('${TAG}kai: CspPreference.mPUMP_NAME = $type');
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

      if (USE_CHECK_PAIRED_DEV == true &&
          type.contains(DANARS_PUMP_NAME) &&
          (mCMgr.mPump! is PumpDanars)) {
        /*
        // check Bluetooth adaptor status first
        bool bluetoothState = await mCMgr.mPump!.mPumpflutterBlue.isOn;

        if (bluetoothState != BluetoothState.on) {
          // debugPrint('${TAG}kai:Bluetooth is not on.');
          // in case that Bluetooth is not activated then let's notify 
          bool btOn = await mCMgr.mPump!.mPumpflutterBlue.turnOn();
          if (!btOn) {
            debugPrint('${TAG}kai:Bluetooth is not on.');
            return;
          }

        }
	*/
        // check device bonding status here
        final isBonded = (await mCMgr.mPump!.mPumpflutterBlue.bondedDevices)
            .contains(device);

        debugPrint('${TAG}kai: isbonded($isBonded)');
      }

      debugPrint('${TAG}kai: connectDiscovery(): call device.connect()'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      //kai_20230522  if use auto: true then connection does not established in android M.
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
        // wait for the device bonding is complete here : timeout ( 30 secs)
        var secondsWaited = 0;

        while (!isBonded && secondsWaited < 30) {
          debugPrint(
              '${TAG}kai:Waiting for bonding...Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
          await Future<void>.delayed(Duration(seconds: 1));
          // check the device bonding status again here
          isBonded = (await mCMgr.mPump!.mPumpflutterBlue.bondedDevices)
              .contains(device);
          secondsWaited++;
        }

        if (!isBonded) {
          debugPrint('${TAG}kai:Timeout waiting for bonding.');
          // timeout and notify alert here
          return;
        } else {
          debugPrint('${TAG}kai: bonding is done.'
              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
        }
      }

      debugPrint(
        '${TAG}kai: connectDiscovery(): call device.discoverServices()'
        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
      );
      /* int mtu = await device.requestMtu(247);
      // MTU 요청이 성공적으로 완료됨
     log('MTU size set to: $mtu');
      */

      var finddanaWRCharacteristic = 0;
      final isfindDevice = await device.discoverServices().then((services) {
        //debugging service count
        var svcCnt = 0;
        var CharacterCnt = 0;
        for (final service in services) {
          svcCnt++;
          debugPrint(
            '${TAG}kai: cnt($svcCnt) serviceuuid = ${service.uuid.toString().toLowerCase()}',
          );

          if (FEATURE_CHECK_WR_CHARACTERISTIC != true) {
            service.characteristics.forEach((characteristic) async {
              CharacterCnt++;
              debugPrint(
                '${TAG}kai: cnt($CharacterCnt) characteruuid = ${characteristic.uuid.toString().toLowerCase()}',
              );
              if (characteristic.uuid.toString().toLowerCase() ==
                  mRX_READ_UUID.toLowerCase()) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_RX_READ_CHARACTERISTIC = characteristic;
                debugPrint('${TAG}kai: found m_RX_READ_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

                //check the characteristic have notify property and Notify is enabled first here
                if (m_RX_READ_CHARACTERISTIC!.properties.notify &&
                    m_RX_READ_CHARACTERISTIC!.descriptors.isNotEmpty) {
                  if (!m_RX_READ_CHARACTERISTIC!.isNotifying) {
                    //let's set notify enable here first
                    if (USE_CHECK_CONNECTION_STATUS) {
                      try {
                        debugPrint(
                          '${TAG}kai: call m_RX_READ_CHARACTERISTIC!.setNotifyValue(true)'
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                        );
                        await m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);

                        if (mCMgr != null && mCMgr.mPump != null) {
                          mCMgr.mPump!.isSetNotifyFailed = false;
                          debugPrint(
                              '${TAG}kai: set isSetNotifyFailed(false) after m_RX_READ_CHARACTERISTIC!.setNotifyValue(true)'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                        }
                      } catch (e) {
                        debugPrint(
                          '$TAG:kai: 1st m_RX_READ_CHARACTERISTIC notify set error: uuid =  ${m_RX_READ_CHARACTERISTIC!.uuid} $e'
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                        );

                        if (mCMgr != null && mCMgr.mPump != null) {
                          mCMgr.mPump!.isSetNotifyFailed = true;
                          debugPrint(
                              '${TAG}kai: Error set isSetNotifyFailed(true) after call m_RX_READ_CHARACTERISTIC!.setNotifyValue(true)'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                        }
                      }
                    }

                    //let's set Value listener here
                    try {
                      //kai_20230310 unregister listener first due to duplicated register notify operation occurred
                      // regardless of unregistering the listener when device is disconnected
                      //debugPrint('kai: force unregister previous registered lister before registering');
                      //m_RX_READ_CHARACTERISTIC!.value.listen((event) { }).cancel();

                      //kai_20240122 clear previous listener here
                      if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
                        await m_RX_READ_CHARACTERISTIC_VALUE_LISTENER!.cancel();
                        m_RX_READ_CHARACTERISTIC_VALUE_LISTENER = null;
                      }
                      m_RX_READ_CHARACTERISTIC_VALUE_LISTENER =
                          m_RX_READ_CHARACTERISTIC!.value.listen((value) {
                        // kai_20230225 let's implement parser for received data or message sent from connected pump
                        // Handle incoming data here.
                        debugPrint(
                          '${TAG}kai: call  handlePumpValue() : uuid(${m_RX_READ_CHARACTERISTIC!.uuid})'
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                        );
                        handlePumpValue(value);
                      });

                      if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
                        mCMgr.mPump!.pumpValueSubscription =
                            m_RX_READ_CHARACTERISTIC_VALUE_LISTENER;
                        debugPrint(
                          '${TAG}kai: 1 mCMgr.mPump!.pumpValueSubscription = m_RX_READ_CHARACTERISTIC_VALUE_LISTENER'
                          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                        );
                      }

                      //kai_20240121let's consider set retry after delay here
                      if (mCMgr.mPump!.isSetNotifyFailed == true) {
                        if (USE_CHECK_CONNECTION_STATUS) {
                          await Future<void>.delayed(
                              const Duration(milliseconds: 500), () async {
                            debugPrint(
                              '$TAG:kai: 2nd call m_RX_READ_CHARACTERISTIC!.setNotifyValue(true)'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                            );

                            await m_RX_READ_CHARACTERISTIC!
                                .setNotifyValue(true);
                            mCMgr.mPump!.isSetNotifyFailed = false;
                            debugPrint(
                              '$TAG:kai: complete 2nd call m_RX_READ_CHARACTERISTIC!.setNotifyValue(false)'
                              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                            );
                          });
                        } else {
                          await m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);
                          mCMgr.mPump!.isSetNotifyFailed = false;
                          debugPrint(
                            '$TAG:kai: complete 2nd call m_RX_READ_CHARACTERISTIC!.setNotifyValue(false)'
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
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
                        '$TAG:kai: 2nd call m_RX_READ_CHARACTERISTIC notify set error: uuid =  ${m_RX_READ_CHARACTERISTIC!.uuid} $e'
                        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                      );

                      //
                      if (mCMgr != null && mCMgr.mPump != null) {
                        mCMgr.mPump!.isSetNotifyFailed = true;
                        debugPrint(
                            '${TAG}kai: 2nd Error set isSetNotifyFailed(true) after call m_RX_READ_CHARACTERISTIC!.setNotifyValue(true)'
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                      }
                      //

                    }
                  }
                }
              }

              if (characteristic.uuid.toString().toLowerCase() ==
                  mTX_WRITE_UUID.toLowerCase()) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_TX_WRITE_CHARACTERISTIC = characteristic;
                debugPrint('${TAG}kai: found m_TX_WRITE_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
              }

              if (characteristic.uuid.toString().toLowerCase() ==
                  CSP_BATLEVEL_NOTIFY_CHARACTER_UUID.toLowerCase()) {
                finddanaWRCharacteristic = finddanaWRCharacteristic + 1;
                m_RX_BATLEVEL_CHARACTERISTIC = characteristic;
                debugPrint('${TAG}kai: found m_RX_BATLEVEL_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                //check the characteristic have notify property and Notify is enabled first here
                if (m_RX_BATLEVEL_CHARACTERISTIC!.properties.notify &&
                    m_RX_BATLEVEL_CHARACTERISTIC!.descriptors.isNotEmpty) {
                  if (!m_RX_BATLEVEL_CHARACTERISTIC!.isNotifying) {
                    try {
                      //kai_20230310 try to enable for register battery level characteristic notify
                      // but error comes up.
                      await m_RX_BATLEVEL_CHARACTERISTIC!.setNotifyValue(true);
                      debugPrint(
                        '${TAG}kai: set m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER '
                        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                      );
                      m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
                          m_RX_BATLEVEL_CHARACTERISTIC!.value.listen((value) {
                        // kai_20230225 let's implement parser for received data or message sent from connected pump
                        // Handle incoming data here.
                        debugPrint(
                          '${TAG}kai: call  _handlePumpBatLevelValue() : uuid(${m_RX_BATLEVEL_CHARACTERISTIC!.uuid})',
                        );
                        _handlePumpBatLevelValue(value);
                      });

                      if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER != null) {
                        mCMgr.mPump!.pumpBatValueSubscription =
                            m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
                        debugPrint(
                          '${TAG}kai: 1 : mCMgr.mPump!.pumpBatValueSubscription = m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER',
                        );
                      }
                      // set delay after setting
                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                    } catch (e) {
                      debugPrint(
                        '${TAG}kai:characteristic notify set error: uuid =  ${m_RX_BATLEVEL_CHARACTERISTIC!.uuid} $e'
                        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                      );
                    }
                  }
                }
              }
            });

            if (finddanaWRCharacteristic >= mFindCharacteristicMax) {
              if (_USE_CSBLUETOOTH_PROVIDER == true) {
                mCMgr.mPump!.ConnectedDevice = device;
                mPump = device;
                mPumpMacAddress = mPump!.id.toString();
                mPumpName = mPump!.name.toString();

                //kai_20230703 check previous register callback exit here
                if (mCMgr.mPump!.mPumpconnectionSubscription != null) {
                  mCMgr.mPump!.mPumpconnectionSubscription!.cancel();
                  mCMgr.mPump!.mPumpconnectionSubscription = null;
                }
                // kai_20230225 register status change listener and Handle connection status changes.
                mCMgr.mPump!.registerPumpStateCallback(PumpStateCallback);

                //backup the pump connection status listener instance here
                connectionSubscription =
                    mCMgr.mPump!.mPumpconnectionSubscription;

                if (m_RX_READ_CHARACTERISTIC != null) {
                  mCMgr.mPump!.PumpRxCharacteristic = m_RX_READ_CHARACTERISTIC;
                  debugPrint(
                    '${TAG}kai: mCMgr.mPump!.PumpRxCharacteristic = m_RX_READ_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }

                if (m_TX_WRITE_CHARACTERISTIC != null) {
                  mCMgr.mPump!.PumpTxCharacteristic = m_TX_WRITE_CHARACTERISTIC;
                  debugPrint(
                    '${TAG}kai: mCMgr.mPump!.PumpTxCharacteristic = m_TX_WRITE_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }

                if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null &&
                    mCMgr.mPump!.pumpValueSubscription == null) {
                  mCMgr.mPump!.pumpValueSubscription =
                      m_RX_READ_CHARACTERISTIC_VALUE_LISTENER;
                  debugPrint(
                    '${TAG}kai: 2 mCMgr.mPump!.pumpValueSubscription = m_RX_READ_CHARACTERISTIC_VALUE_LISTENER'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }

                if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
                  mCMgr.mPump!.PumpRXBatLvlCharacteristic =
                      m_RX_BATLEVEL_CHARACTERISTIC;
                  debugPrint(
                    '${TAG}kai: mCMgr.mPump!.PumpRXBatLvlCharacteristic = m_RX_BATLEVEL_CHARACTERISTIC'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }

                if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER != null) {
                  mCMgr.mPump!.pumpBatValueSubscription =
                      m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
                  debugPrint(
                    '${TAG}kai: 2 mCMgr.mPump!.pumpBatValueSubscription = m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER'
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
        log('kai: Error discovering services: $error'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

        // 예외 처리 로직 추가
        if (error is PlatformException &&
            error.code == 'set_notification_error') {
          // 특정 예외인 경우 다시 연결 시도
          if (mounted) {
            // Check if the widget is still mounted
            setState(() {
              mPumpConnectionStatus = 'Disconnected';
              mPumpstateText = 'Disconnected';
              mPumpconnectButtonText = 'Connect';
              mPumpdeviceState = BluetoothDeviceState.disconnected;
              mCMgr.mPump!.ConnectionStatus = mPumpdeviceState;
              _showToastMessage(
                context,
                'Connecting is not available at this time!!',
                'red',
                3,
              );
            });
          } else {
            //kai_20230616
            mPumpConnectionStatus = 'Disconnected';
            mPumpstateText = 'Disconnected';
            mPumpconnectButtonText = 'Connect';
            mPumpdeviceState = BluetoothDeviceState.disconnected;

            _showToastMessage(
              context,
              'Connecting is not available at this time!!',
              'red',
              3,
            );
            if (mCMgr != null && mCMgr.mPump != null) {
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
                  'Cannot discoverServices while device is not connected. State == BluetoothDeviceState.disconnected',
                )) {
          // 연결이 끊어진 상태인 경우 다시 연결 시도
          if (mounted) {
            // Check if the widget is still mounted
            setState(() {
              mPumpConnectionStatus = 'Disconnected';
              mPumpstateText = 'Disconnected';
              mPumpconnectButtonText = 'Connect';
              mPumpdeviceState = BluetoothDeviceState.disconnected;
              mCMgr.mPump!.ConnectionStatus = mPumpdeviceState;
              _showToastMessage(
                context,
                'Connecting is not available at this time!!',
                'red',
                3,
              );
            });
          } else {
            //kai_20230616 added
            mPumpConnectionStatus = 'Disconnected';
            mPumpstateText = 'Disconnected';
            mPumpconnectButtonText = 'Connect';
            mPumpdeviceState = BluetoothDeviceState.disconnected;
            if (mCMgr != null && mCMgr.mPump != null) {
              mCMgr.mPump!.ConnectionStatus = mPumpdeviceState;
              mCMgr.mPump!.notifyListeners();
              mCMgr.notifyListeners();
            }
            _showToastMessage(
              context,
              'Connecting is not available at this time!!',
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
        debugPrint(
            '$TAG:kai: connectDiscovery: there is no matched device !!!');
      } else {
        //let's request connected device info here
        final TypePump = CspPreference.mPUMP_NAME.toLowerCase();

        debugPrint(
            '$TAG:kai:isfindDevice($isfindDevice):connectDiscovery: there is matched device($TypePump) !!!'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
        if (TypePump.contains(
          BluetoothProvider.CareLevo_PUMP_NAME.toLowerCase(),
        )) {
          //let's set total reservoir amount here 200U = 2000uL = 2mL
          //( 1U = 10uL = 0.01mL )
          // show a dialog or direct sending it automatically
          mCMgr.mPump!.SetUpWizardMsg =
              'Please set the amount injected into the reservoir.\nAvailable '
              'range: 10 ~ 200U';
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
        } else if (TypePump.contains(
          BluetoothProvider.CSPumpDeviceName.toLowerCase(),
        )) {
          requestPumpInfo();
        } else if (TypePump.contains(
          BluetoothProvider.DANARS_PUMP_NAME.toLowerCase(),
        )) {
          debugPrint(
              '${TAG}kai::isfindDevice($isfindDevice):PumpType($TypePump)'
              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
          //kai_20231228  let's send Pump Check command here after connection
          if (mCMgr.mPump! is PumpDanars) {
            if (USE_DANAI_CHECK_CONNECTION_COMMAND_SENT) {
              if ((mCMgr.mPump as PumpDanars).onRetrying == false) {
                //reset the flag here first
                (mCMgr.mPump as PumpDanars).issendPumpCheckAfterConnectFailed =
                    0;

                //let's set timeout count
                if (USE_CHECK_CONNECTION_STATUS) {
                  final MaxWaitCnt = 50;

                  /// 5secs
                  var waitCnt = 0;
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
                    '${TAG}kai::isfindDevice($isfindDevice):onRetrying(false):call sendPumpCheckAfterConnect() again'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                (mCMgr.mPump as PumpDanars).sendPumpCheckAfterConnect();
              } else {
                debugPrint(
                    '${TAG}kai::isfindDevice($isfindDevice):onRetrying(true)'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
              }
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
      debugPrint('${TAG}kai: _disconnectDevice(): unregister Listener here'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

      if (m_RX_READ_CHARACTERISTIC != null) {
        debugPrint(
          '${TAG}kai : _disconnectDevice: m_RX_READ_CHARACTERISTIC!.value.listen((event) {}).cancel()',
        );
        if (m_RX_READ_CHARACTERISTIC_VALUE_LISTENER != null) {
          debugPrint(
            '${TAG}kai : _disconnectDevice: m_RX_READ_CHARACTERISTIC_VALUE_LISTENER.cancel()',
          );
          m_RX_READ_CHARACTERISTIC_VALUE_LISTENER!.cancel();
          m_RX_READ_CHARACTERISTIC_VALUE_LISTENER = null;

          if (_USE_CSBLUETOOTH_PROVIDER == true) {
            mCMgr.mPump!.pumpValueSubscription =
                m_RX_READ_CHARACTERISTIC_VALUE_LISTENER;
          }
        }
      }

      if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
        debugPrint(
          '${TAG}kai : _disconnectDevice: m_RX_BATLEVEL_CHARACTERISTIC!.value.listen((event) {}).cancel()',
        );
        if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER != null) {
          debugPrint(
            '${TAG}kai : _disconnectDevice: m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER.cancel()',
          );
          m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER!.cancel();
          m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER = null;

          if (_USE_CSBLUETOOTH_PROVIDER == true) {
            mCMgr.mPump!.pumpBatValueSubscription =
                m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
          }
        }
      }

      await device.disconnect();
    } catch (ex) {
      debugPrint('${TAG}kai:Error connecting to device: $ex'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
    }
  }

  /*
   * @brief show the lists that scanned device by using predefined device name
   */
  // Build the ListView of devices
  Widget _buildListView() {
    final listTiles = <ListTile>[];

    if (_USE_CSBLUETOOTH_PROVIDER == true) {
      if (mCMgr.mPump!.getScannedDeviceLists() != null) {
        for (final device in mCMgr.mPump!.getScannedDeviceLists()!) {
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
                  minimumSize:
                      MaterialStateProperty.all<Size>(const Size(60, 25)),
                  // backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  // shadowColor: MaterialStateProperty.all<Color>(Colors.grey),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    // color: Button_primarySolidColor,
                  ),
                ),
                onPressed: () => connectDiscovery(device),
              ),
            ),
          );
        }
      }
    } else {
      if (Csp1devices != null) {
        for (final device in Csp1devices!) {
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
                  minimumSize:
                      MaterialStateProperty.all<Size>(const Size(60, 25)),
                  // backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  // shadowColor: MaterialStateProperty.all<Color>(Colors.grey),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    // color: Button_primarySolidColor,
                  ),
                ),
                // onPressed: () => _connectToDevice(device),
                onPressed: () => connectDiscovery(device),
              ),
            ),
          );
        }
      }
    }

    return ListView(
      children: listTiles,
    );
  }

  /*
   * @brief show toast message which selected device type
   */
  void _showSelectionMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$item')));
  }

  /*
   * @brief show toast message on the center of the screen
   */
  void _showToastMsgProgressCenter(
    BuildContext context,
    String message,
    String ColorType,
    int showingTime,
  ) {
    var ShowingDuration = 3;
    var _color = Colors.blueAccent[700];
    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      ShowingDuration = showingTime;
    }

    switch (ColorType.toLowerCase()) {
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
      duration: Duration(seconds: ShowingDuration),
      backgroundColor: _color,
      // center position
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 300),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    final overlayState = Overlay.of(context)!;
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 50,
        left: MediaQuery.of(context).size.width / 2 - 50,
        child: Container(
          width: 100,
          height: 100,
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

    Timer(Duration(seconds: ShowingDuration), () {
      overlayEntry.remove();
    });
  }

  /*
   * @brief show toast message on the bottom of the screen
   */
  void _showToastMsgProgress(
    BuildContext context,
    String message,
    String ColorType,
    int showingTime,
  ) {
    var ShowingDuration = 3;
    var _color = Colors.blueAccent[700];

    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      ShowingDuration = showingTime;
    }

    switch (ColorType.toLowerCase()) {
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
      duration: Duration(seconds: ShowingDuration),
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
    /*
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 60,
        left: 0,
        right: 0,
        child: Container(
          width: 100,
          height: 100,
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

     */
    overlayState.insert(overlayEntry);

    Timer(Duration(seconds: ShowingDuration), () {
      overlayEntry.remove();
    });
  }

  void _showToastMessage(
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
              mAudioPlayer.playAlertOneTime('battery');
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
        content: Text(Msg),
        duration: Duration(seconds: ShowingDuration),
      ),
    );
  }

  Timer? debounceTimer;
  var DebounceDuration = 2;
  var ShowingDuration = 2;
  String lastMessage = '';

  void showToastMessageDebounce(
    BuildContext context,
    String newMessage,
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
              mAudioPlayer.playAlertOneTime('battery');
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
      debounceTimer = Timer(Duration(seconds: DebounceDuration), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _color,
            content: Text(newMessage),
            duration: Duration(seconds: ShowingDuration),
          ),
        );
        lastMessage = newMessage;
      });
    }
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

  /*
   * @brief show alert message dialog regard to low battery, occlusion, low reservoir
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
          debugPrint(
              'kai:PumpPage:_showAlertDialogOnEvent:mAudioPlayer is null::can not call mAudioPlayer.playAlert(message)');
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
              '${mCMgr.appContext!.l10n.alert}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          titlePadding: const EdgeInsets.all(0),
          content: Text(
            _alertmessage,
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
                //send "BZ1=0" to stop  buzzer in csp-1
                SendMessage2Pump('BZ2=0');
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
                    debugPrint(
                        'kai:PumpPage:_showAlertDialogOnEvent:mAudioPlayer is null::can not call mAudioPlayer!.stopAlert()');
                  }
                }

                Navigator.of(context).pop();
              },
              child: Text('${mCMgr.appContext!.l10n.dismiss}'),
            ),
          ],
        ),
      );
    } else {
      // in case that the dialog already activated on the screen, call setState() to update UI screen.
      setState(() {
        if (_key.currentState != null) {
          updateAlertMessage(_alertmessage);
        }
      });
    }
  }

  void updateAlertMessage(String message) {
    setState(() {
      this._alertmessage = message;
    });
  }

  void updateTXErrorMessage(String message) {
    setState(() {
      this._TxErrorMsg = message;
    });
  }

  void _showTXErrorMsgDialog(String title, String message) {
    final Title = title;
    updateTXErrorMessage(message);
    final Msg = _TxErrorMsg;

    // if (_key.currentContext == null)
    if (_USE_GLOBAL_KEY == true) {
      // create dialog and start alert playback onetime
      if (_USE_AUDIO_PLAYBACK == true) {
        if (mAudioPlayer != null) {
          if (mAudioPlayer.isPlaying == true) {
            mAudioPlayer.stop();
            mAudioPlayer.isPlaying = false;
          }
          //  mAudioPlayer!.playLowBatAlert();
          mAudioPlayer.playAlertOneTime('battery');
        } else {
          debugPrint(
              'kai:PumpPage:_showTXErrorMsgDialog:mAudioPlayer is null::can not call mAudioPlayer!.playAlertOneTime()');
        }
      }

      showDialog<BuildContext>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          // _USE_GLOBAL_KEY  // key: _key,
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
                fontSize: 16,
              ),
            ),
          ),
          titlePadding: const EdgeInsets.all(0),
          content: Text(
            Msg,
            style: const TextStyle(
              color: Colors.blue,
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
                if (_USE_AUDIO_PLAYBACK == true) {
                  if (mAudioPlayer != null) {
                    mAudioPlayer.stop();
                  } else {
                    debugPrint(
                        'kai:PumpPage:_showTXErrorMsgDialog:mAudioPlayer is null::can not call mAudioPlayer!.stop()');
                  }
                }
                //let's try it again here
                Navigator.of(context).pop();
              },
              child: Text('${mCMgr.appContext!.l10n.ok}'),
            ),
            TextButton(
              onPressed: () {
                if (_USE_AUDIO_PLAYBACK == true) {
                  if (mAudioPlayer != null) {
                    mAudioPlayer.stop();
                  } else {
                    debugPrint(
                        'kai:PumpPage:_showTXErrorMsgDialog:mAudioPlayer is null::can not call mAudioPlayer.stop()');
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text('${mCMgr.appContext!.l10n.dismiss}'),
            ),
          ],
        ),
      );
    } else {
      // in case that the dialog already activated on the screen, call setState() to update UI screen.
      setState(() {
        if (_key.currentState != null) {
          updateTXErrorMessage(message);
        }
      });
    }
  }

  void updateSetupWizardMessage(String message, String actionType) {
    setState(() {
      this._setupWizardMessage = message;
      this._ActionType = actionType;
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
    var HintStringTextField = 'Enter your input';

    switch (actionType) {
      case 'HCL_DOSE_CANCEL_REQ':
        enableTextField = false;
        HintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = 'Cancel injecting Dose';
        break;

      case 'PATCH_DISCARD_REQ':
        enableTextField = false;
        HintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = 'Discard Patch';
        break;

      case 'SAFETY_CHECK_REQ':
      case 'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST':
        enableTextField = false;
        HintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = 'Safety Check';
        break;

      case 'PATCH_INFO_REQ':
        enableTextField = false;
        HintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = 'Patch Info Request';
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
        HintStringTextField = 'Enter your input';
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
                fontSize: 16,
              ),
            ),
          ),
          titlePadding: const EdgeInsets.all(0),
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
                        // put reservoir injection amount here 1 ~ 300 U ( 2mL ~ 3mL )
                        final value = int.parse(inputText);
                        if (value > 300 || value < 1) {
                          _showToastMessage(
                            context,
                            'Please type available value again : 10 ~ 200',
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
                            'Sending Time and injected insulin amount($value)U ...',
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
                            context,
                            'Please type available value again : 0.5 ~ 25',
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
                            'Sending maximum bolus injection amount($inputText)U ...',
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
                            context,
                            'Please type available value again : 0.01 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          //kai_20230427 let's check isDoseInjectingNow is true
                          if (mCMgr.mPump!.isDoseInjectingNow == true) {
                            Navigator.of(context).pop();

                            ///< due to toast popup is showing behind the active dialog
                            _showToastMessage(
                              context,
                              'The pump is processing the previous dose infusion.\nPlease wait while processing is complete.',
                              'red',
                              0,
                            );
                            // ko : 펌프가 이전 도즈 주입을 처리중입니다.처리가 완료 될때 까지 잠시만 기다려 주세요.
                          } else {
                            CspPreference.setString(
                              CspPreference.pumpHclDoseInjectionKey,
                              inputText,
                            );
                            mCMgr.mPump!
                                .sendSetDoseValue(inputText, 0x00, null);
                            _showToastMessage(
                              context,
                              'Sending dose injection amount($inputText)U ...',
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
                          'kai: HCL_DOSE_CANCEL_REQ: enableTextField = $enableTextField',
                        );
                        if (enableTextField == false) {
                          mCMgr.mPump!.cancelSetDoseValue(0x00, null);
                          _showToastMessage(
                            context,
                            'Sending dose injection cancel request ...',
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
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
                              context,
                              'Please type available value again : 0.5 ~ 25',
                              'red',
                              0,
                            );
                          } else {
                            mCMgr.mPump!.cancelSetDoseValue(0x00, null);
                            _showToastMessage(
                              context,
                              'Sending dose injection cancel request ...',
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
                            'Sending discard patch request ...',
                            'blue',
                            0,
                          );
                          Navigator.of(context).pop();
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
                              context,
                              'Please type available value again : 0.5 ~ 25',
                              'red',
                              0,
                            );
                          } else {
                            mCMgr.mPump!.sendDiscardPatch(null);
                            _showToastMessage(
                              context,
                              'Sending discard patch request ...',
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
                            'Please type available value again : 0 ~ 1',
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
                            'Sending infusion info request ...',
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
                            'Sending safety check request ...',
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
                              'Please type available value again : 0 ~ 1',
                              'red',
                              0,
                            );
                          } else {
                            mCMgr.mPump!.sendSafetyCheckRequest(null);
                            _showToastMessage(
                              context,
                              'Sending safety check request ...',
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
                            'Please type available value again : 0 ~ 1',
                            'red',
                            0,
                          );
                        } else {
                          mCMgr.mPump!
                              .sendResetPatch(int.parse(inputText), null);
                          _showToastMessage(
                            context,
                            'Sending reset patch request ...',
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
                            'Sending patch info request ...',
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
                              'Please type available value again : 0.5 ~ 25',
                              'red',
                              0,
                            );
                          } else {
                            mCMgr.mPump!.sendPumpPatchInfoRequest(null);
                            _showToastMessage(
                              context,
                              'Sending patch info request ...',
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
              child: Text('${mCMgr.appContext!.l10n.ok}'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('${mCMgr.appContext!.l10n.cancel}'),
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
        PendingDlgMsg.add(Msg);
        PendingDlgTitle.add(Title);
        PendingDlgAction.add(ActionType);
        PenddingDialog_key_currentContextNULL++;
      }
    }
  }

  /*
   * @brief show input dialog for typing an device name for the CGM deivce type
   */
  void _showInputDialog(BuildContext context) {
    var inputText = '';
    showDialog<BuildContext>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${mCMgr.appContext!.l10n.enterAvalue}'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: InputDecoration(
                hintText: '${mCMgr.appContext!.l10n.enterAvalue}'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.cancel}'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.save}'),
              onPressed: () {
                //let's check inputText is empty first
                if (inputText.isNotEmpty) {
                  CspPreference.setString('cgmSourceTypeKey', inputText);
                  _showSelectionMessage(context, inputText);
                  mCMgr.changeCGM();

                  ///< update Cgm instance
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  /*
   * @brief show dialog which have several lists for CGM deivce type
   */
  void _showDialog(BuildContext context, String value) {
    final children = <Widget>[
      ListTile(
        title: const Text('1.Dexcom'),
        onTap: () {
          //let's update cspPreference here
          CspPreference.setString('cgmSourceTypeKey', 'Dexcom');
          _showSelectionMessage(context, 'Dexcom');
          mCMgr.changeCGM();
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('2.Libro'),
        onTap: () {
          CspPreference.setString('cgmSourceTypeKey', 'Libro');
          _showSelectionMessage(context, 'Libro');
          mCMgr.changeCGM();
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('3.i-sens'),
        onTap: () {
          CspPreference.setString('cgmSourceTypeKey', 'i-sens');
          _showSelectionMessage(context, 'i-sens');
          mCMgr.changeCGM();
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('4.Xdrip'),
        onTap: () {
          CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
          _showSelectionMessage(context, 'Xdrip');
          mCMgr.changeCGM();
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
          title: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Text(
              'Select CGM Type',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          //Text('Select CGM Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.cancel}'),
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
   * @brief show input dialog for typing an device name for the Pump deivce type
   */
  void _showInputDialogPump(BuildContext context) {
    var inputText = '';
    showDialog<BuildContext>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${mCMgr.appContext!.l10n.enterAvalue}'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: InputDecoration(
                hintText: '${mCMgr.appContext!.l10n.enterAvalue}'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.cancel}'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.save}'),
              onPressed: () async {
                //let's check inputText is empty first
                if (inputText.isNotEmpty) {
                  CspPreference.setString('pumpSourceTypeKey', inputText);
                  _showSelectionMessage(context, inputText);
                  await mCMgr.changePUMP();
                  //kai_20230519 let's call setResponse callback at the point of changing cgm instance
                  // because clearDeviceInfo is always called in this case.
                  mCMgr.registerResponseCallbackListener(
                    mCMgr.mPump!,
                    _handleResponseCallback,
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

  /*
  * @brief show Broadcasting Policynet Bouls
  */
  void _showDialogBroadcastingBolus(BuildContext context, String value) {
    var inputText = '';

    final children = <Widget>[
      Text(
        '${mCMgr.appContext!.l10n.destinationPkgName}'
        '${CspPreference.getString(CspPreference.destinationPackageName, defaultValue: 'com.kai.bleperipheral')}\n'
        '${mCMgr.appContext!.l10n.typeDestinationPkgName}.',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
      ),
      TextField(
        onChanged: (value) {
          inputText = value;
        },
        decoration: InputDecoration(
            hintText:
                '${CspPreference.getString(CspPreference.destinationPackageName, defaultValue: 'com.kai.bleperipheral')}'),
      ),
      ListTile(
        title: Text(mCMgr.appContext!.l10n.yes),
        onTap: () async {
          CspPreference.setBool(CspPreference.broadcastingPolicyNetBolus, true);
          if (inputText.isNotEmpty) {
            CspPreference.setString(
                CspPreference.destinationPackageName, inputText);
          }
          _showSelectionMessage(
              context,
              '${mCMgr.appContext!.l10n.yes}, '
              '${mCMgr.appContext!.l10n.broadcastingBolusTo} '
              '${CspPreference.getString(CspPreference.destinationPackageName, defaultValue: 'com.kai.bleperipheral')} '
              '${mCMgr.appContext!.l10n.isEnabled}');
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: Text(mCMgr.appContext!.l10n.no),
        onTap: () async {
          CspPreference.setBool(
              CspPreference.broadcastingPolicyNetBolus, false);
          _showSelectionMessage(
              context,
              '${mCMgr.appContext!.l10n.no}, '
              '${mCMgr.appContext!.l10n.broadcastingBolusTo} '
              '${CspPreference.getString(CspPreference.destinationPackageName, defaultValue: 'com.kai.bleperipheral')} '
              '${mCMgr.appContext!.l10n.isDisabled}');
          Navigator.pop(context);
        },
      )
    ];

    //let's show dialog here
    showDialog<BuildContext>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Text(
              '${mCMgr.appContext!.l10n.enableBroadcastingBolus}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          //title: Text('Select PUMP Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.cancel}'),
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
   * @brief show dialog which have several lists for Pump deivce type
   */
  void _showDialogPump(BuildContext context, String value) {
    final children = <Widget>[
      ListTile(
        title: const Text('1.dexcom'),
        onTap: () async {
          CspPreference.setString('pumpSourceTypeKey', 'Dexcom');
          _showSelectionMessage(context, 'Dexcom');
          await mCMgr.changePUMP();
          mCMgr.registerResponseCallbackListener(
            mCMgr.mPump!,
            _handleResponseCallback,
          );
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('2.dana-i'),
        onTap: () async {
          CspPreference.setString('pumpSourceTypeKey', 'Dana-i');
          _showSelectionMessage(context, 'Dana-i');
          await mCMgr.changePUMP();
          mCMgr.registerResponseCallbackListener(
            mCMgr.mPump!,
            _handleResponseCallback,
          );
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('3.caremedi'),
        onTap: () async {
          CspPreference.setString('pumpSourceTypeKey', 'CareLevo');
          _showSelectionMessage(context, 'CareLevo');
          await mCMgr.changePUMP();
          mCMgr.registerResponseCallbackListener(
            mCMgr.mPump!,
            _handleResponseCallback,
          );
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('4.csp-1'),
        onTap: () async {
          CspPreference.setString('pumpSourceTypeKey', 'csp-1');
          _showSelectionMessage(context, 'csp-1');
          await mCMgr.changePUMP();
          //kai_20230519 let's call setResponse callback at the point of changing cgm instance
          // because clearDeviceInfo is always called in this case.
          mCMgr.registerResponseCallbackListener(
            mCMgr.mPump!,
            _handleResponseCallback,
          );
          Navigator.pop(context);
        },
      ),
      ListTile(
        title: const Text('5.others'),
        onTap: () {
          _showInputDialogPump(context);
        },
      )
    ];

    //let's show dialog here
    showDialog<BuildContext>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Text(
              'Select PUMP Type',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          //title: Text('Select PUMP Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.cancel}'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showInputMessageDialog(BuildContext context) {
    var inputText = '';
    showDialog<BuildContext>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${mCMgr.appContext!.l10n.enterAvalue}'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: InputDecoration(
                hintText: '${mCMgr.appContext!.l10n.enterAvalue}'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.save}'),
              onPressed: () async {
                //let's check inputText is empty first
                if (inputText.isNotEmpty) {
                  if (inputText.contains('BAT:')) {
                    m_RX_BATLEVEL_CHARACTERISTIC =
                        mCMgr.mPump!.PumpRXBatLvlCharacteristic;

                    if (m_RX_BATLEVEL_CHARACTERISTIC != null &&
                        !m_RX_BATLEVEL_CHARACTERISTIC!.isNotifying) {
                      //let's set listener for value
                      m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
                          m_RX_BATLEVEL_CHARACTERISTIC!.value.listen((value) {
                        // kai_20230225 let's implement parser for received data or message sent from connected pump
                        debugPrint(
                          '${TAG}kai: send button: call  _handlePumpBatLevelValue() : uuid(${m_RX_BATLEVEL_CHARACTERISTIC!.uuid})',
                        );
                        _handlePumpBatLevelValue(value);
                      });

                      if (_USE_CSBLUETOOTH_PROVIDER == true) {
                        mCMgr.mPump!.pumpBatValueSubscription =
                            m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
                        debugPrint(
                          '${TAG}kai:send:  3 mCMgr.mPump!.pumpBatValueSubscription = m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER',
                        );
                      }

                      debugPrint('${TAG}kai: send BAT: Notify enabled ');
                      await m_RX_BATLEVEL_CHARACTERISTIC!.setNotifyValue(true);
                    } else {
                      if (m_RX_BATLEVEL_CHARACTERISTIC == null) {
                        debugPrint(
                          '${TAG}kai: send BAT: '
                          'm_RX_BATLEVEL_CHARACTERISTIC is null ',
                        );
                      } else {
                        if (!m_RX_BATLEVEL_CHARACTERISTIC!.isNotifying) {
                          debugPrint(
                            '${TAG}kai: send BAT: '
                            'm_RX_BATLEVEL_CHARACTERISTIC!.isNotifying '
                            'Åis false ',
                          );
                        }
                      }
                    }
                  }

                  //kai_20300411  test alert sound only
                  if (inputText.contains('ALERT=1')) {
                    await CsaudioPlayer().playLowBatAlert();
                  } else if (inputText.contains('ALERT=0')) {
                    await CsaudioPlayer().stop();
                  } else {
                    //kai_20230308 let's check RX characteristic Notify
                    //is enabled before send message
                    //Åto the connected device first
                    // in order to get the response form the connected device.
                    m_RX_READ_CHARACTERISTIC =
                        mCMgr.mPump!.pumpRxCharacteristic;

                    if (m_RX_READ_CHARACTERISTIC != null &&
                        !m_RX_READ_CHARACTERISTIC!.isNotifying) {
                      if (DEBUG_MESSAGE_FLAG) {
                        debugPrint(
                          '${TAG}send Button: set '
                          'm_RX_READ_CHARACTERISTIC.isNotifying as '
                          'Åenabled before send a message',
                        );
                      }
                      await m_RX_READ_CHARACTERISTIC!.setNotifyValue(true);
                      // Future<void>.delayed(const Duration(seconds: 2));
                    }

                    SendMessage2Pump(inputText);
                  }

                  _showSelectionMessage(context, inputText);
                  Navigator.pop(context);
                }
              },
            ),
            TextButton(
              child: Text('${mCMgr.appContext!.l10n.cancel}'),
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
   * @brief show received message sent from bluetoothProvider
   * this function will be called when an event received in bluetoothProvider
   * and can register callback by using BluetoothProvider.addListener(handlePumpEvent);
   *  and unregister by using BluetoothProvider.removeListener(handlePumpEvent);
   *   BluetoothProvider bluetoothProvider =
      Provider.of<BluetoothProvider>(context, listen: false);
      bluetoothProvider.removeListener(_handleEvent);
   */
  void _handleBlueToothProviderEvent() {
    // 변경 사항 처리하는 콜백 함수
    // setState(() {});
    debugPrint('${TAG}_handleBlueToothProviderEvent() is called');
    final _notifier = mCMgr.mPump!;
    if (_notifier.showSetUpWizardMsgDlg) {
      final Msg = _notifier.SetUpWizardMsg;
      const Title = 'Setup';
      final Type = _notifier.SetUpWizardActionType;
      _notifier
        ..showNoticeMsgDlg = false
        ..SetUpWizardMsg = ''

        ///< clear
        ..SetUpWizardActionType = '';
      _showSetupWizardMsgDialog(Title, Msg, Type);
    } else if (_notifier.showNoticeMsgDlg) {
      //let' clear variable here after copy them to buffer
      final Msg = _notifier.NoticeMsg;
      const Title = 'Notice';
      _notifier
        ..showNoticeMsgDlg = false
        ..NoticeMsg = '';

      ///< clear
      _showTXErrorMsgDialog(Title, Msg);
      /*
      showDialog<BuildContext>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Title),
          content: Text(Msg),
          actions: [
            TextButton(
              onPressed: () {
                _notifier.showNoticeMsgDlg = false;
                _notifier.NoticeMsg = '';  ///< clear
                Navigator.of(context).pop();
              },
              child: Text('Dismiss'),
            ),

          ],
        ),
      );
       */
    } else if (_notifier.showALertMsgDlg) {
      //let' clear variable here after copy them to buffer
      final Msg = _notifier.AlertMsg;
      final Title = '${mCMgr.appContext!.l10n.alert}';
      _notifier
        ..showALertMsgDlg = false
        ..AlertMsg = '';

      ///< clear
      ///
      _showTXErrorMsgDialog(Title, Msg);
      /*
      showDialog<BuildContext>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Title),
          content: Text(Msg),
          actions: [
            TextButton(
              onPressed: () {
                _notifier.showALertMsgDlg = false;
                _notifier.AlertMsg = '';  ///< clear
                Navigator.of(context).pop();
              },
              child: Text('Dismiss'),
            ),

          ],
        ),
      );
       */
    } else if (_notifier.showWarningMsgDlg) {
      //let' clear variable here after copy them to buffer
      final Msg = _notifier.WarningMsg;
      final Title = '${mCMgr.appContext!.l10n.warning}';
      _notifier
        ..showWarningMsgDlg = false
        ..WarningMsg = '';

      ///< clear
      _showTXErrorMsgDialog(Title, Msg);
      /*
      showDialog<BuildContext>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Title),
          content: Text(Msg),
          actions: [
            TextButton(
              onPressed: () {
                _notifier.showWarningMsgDlg = false;
                _notifier.WarningMsg = '';  ///< clear
                Navigator.of(context).pop();
              },
              child: Text('Dismiss'),
            ),

          ],
        ),
      );
       */
    } else if (_notifier.showTXErrorMsgDlg) {
      //let' clear variable here after copy them to buffer
      final Msg = _notifier.TXErrorMsg;
      final Title = '${mCMgr.appContext!.l10n.error}';
      _notifier
        ..showTXErrorMsgDlg = false
        ..TXErrorMsg = '';

      ///< clear
      _showTXErrorMsgDialog(Title, Msg);
    }
    //else
    {
      //let's update build of the widget
      if (_notifier.isScanning == false) {
        debugPrint(
          '${TAG}_handleBlueToothProviderEvent(): _notifier.isPumpScanning == false',
        );
        setState(() {
          //let's update variables here
          if (mCMgr.mPump!.fw.isNotEmpty) {
            mPumpFWVersion = mCMgr.mPump!.fw;
          }

          if (mCMgr.mPump!.Battery.isNotEmpty) {
            mPumpBatteryStatus = mCMgr.mPump!.Battery;
          }

          if (mCMgr.mPump!.reservoir.isNotEmpty) {
            mPumpInsulinRemain = mCMgr.mPump!.reservoir;
          }

          if (mCMgr.mPump!.bolusDeliveryValue.toString().isNotEmpty) {
            mPumpInsulinInject = mCMgr.mPump!.bolusDeliveryValue.toString();
          }

          // 0 means device does not connected at this time.
          if (mCMgr.mPump!.getLastBolusDeliveryTime() > 0) {
            mPumpInjectTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(
              DateTime.fromMillisecondsSinceEpoch(
                mCMgr.mPump!.getLastBolusDeliveryTime(),
              ),
            );
            //mPumpInjectTime = millisecondsToTime(mCMgr.mPump!.getLastBolusDeliveryTime());
          } else {
            log(
              '${TAG}kai:_handleBlueToothProviderEvent():mPumpInjectTime is 0',
            );
          }

          if (mCMgr.mPump!.getModelName().isNotEmpty) {
            mModelName = mCMgr.mPump!.getModelName();
          }

          if (mCMgr.mPump!.SN.isNotEmpty) {
            mSN = mCMgr.mPump!.SN;
          }

          if (mCMgr.mPump!.getConnectedTime().toString().isNotEmpty) {
            mFirstConnectionTime = mCMgr.mPump!.getConnectedTime().toString();
          }

          if (mCMgr.mPump!.PatchUseAvailableTime.isNotEmpty) {
            mPatchUseAvailableTime = mCMgr.mPump!.PatchUseAvailableTime;
          }

          if (mCMgr.mPump!.LogMessageView.isNotEmpty) {
            //mPumpInsulinHistoryLog = mCMgr.mPump!.LogMessageView;
            //kai_20231020 update received message here
            if (mCMgr.mPump!.LogMessageView.contains('<<')) {
              mCMgr.mPump!.LogMessageView =
                  mCMgr.mPump!.LogMessageView.substring(2);
              mPumpInsulinHistoryLog =
                  '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: '
                  '${mCMgr.mPump!.LogMessageView.toString()}\n$mPumpInsulinHistoryLog';
            } else if (mCMgr.mPump!.LogMessageView.contains('>>')) {
              mCMgr.mPump!.LogMessageView =
                  mCMgr.mPump!.LogMessageView.substring(2);
              mPumpInsulinHistoryLog =
                  '>>:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: '
                  'Notify = ${mCMgr.mPump!.LogMessageView.toString()}\n$mPumpInsulinHistoryLog';
            } else {
              mPumpInsulinHistoryLog =
                  '>>:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: '
                  'Notify = ${mCMgr.mPump!.LogMessageView.toString()}\n$mPumpInsulinHistoryLog';
            }
            //kai_20240108  clear mCMgr.mPump!.LogMessageView
            mCMgr.mPump!.LogMessageView = '';
          }

          /*
          mPumpConnectionStatus = 'Disconnected'; //l10n!.disconnected;
          mPumpInjectIntervalTime = ''; ///< minute
          mPumpOcclusionAlert = ''; //l10n!.normal; //  ///< alert, normal
          mPumpstateText = 'Disconnected'; //l10n!.disconnected; //
          mPumpconnectButtonText = 'Disconnect'; //l10n!.disconnect; //
           */
        });
      }
    }
  }

  /*
   * @breif show Warning message with audio playback
   */
  void WarningMsgDlg(String title, String Msg, String ColorType, int showTime) {
    var Title = '${mCMgr.appContext!.l10n.warning}';
    const Color _Color = Colors.red;

    if (showTime > 0) {
      //let's showToast Message with duration showTime
      _showToastMessage(context, Msg, ColorType, showTime);
      return;
    }

    if (title.isNotEmpty && title.isNotEmpty) {
      Title = title;
    }

    switch (ColorType) {
      case 'red':
        const Color _Color = Colors.red;
        break;

      case 'blue':
        const Color _Color = Colors.blue;
        break;

      case 'green':
        const Color _Color = Colors.green;
        break;

      default:
        const Color _Color = Colors.red;
        break;
    }

    // create dialog and start alert playback onetime
    if (_USE_AUDIO_PLAYBACK == true) {
      if (mAudioPlayer == null) {
        mAudioPlayer = CsaudioPlayer();
      }
      if (mAudioPlayer != null) {
        if (mAudioPlayer.isPlaying == true) {
          mAudioPlayer.stop();
          mAudioPlayer.isPlaying = false;
        }
        // mAudioPlayer.playLowBatAlert();
        // mAudioPlayer.loopAssetsAudio()
        mAudioPlayer.playAlert('battery');
        // mAudioPlayer.loopAssetsAudioOcclusion();
      } else {
        debugPrint(
            'kai:PumpPage:mAudioPlayer is null: can not call mAudioPlayer.loopAssetAudio()');
      }
    }
    showDialog<BuildContext>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        // _USE_GLOBAL_KEY //   key: _key,
        title: Container(
          decoration: const BoxDecoration(
            color: _Color,
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
              fontSize: 16,
            ),
          ),
        ),
        content: Text(
          Msg,
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
              //send "BZ1=0" to stop  buzzer in csp-1
              SendMessage2Pump('BZ2=0');
              //stop playback alert
              if (_USE_AUDIO_PLAYBACK == true) {
                if (mAudioPlayer != null) {
                  mAudioPlayer.stopAlert();
                  // mAudioPlayer.stopAssetsAudio();
                } else {
                  debugPrint(
                      'kai:PumpPage:mAudioPlayer is null: can not call mAudioPlayer.stopAssetsAudio()');
                }
              }

              Navigator.of(context).pop();
            },
            child: Text('${mCMgr.appContext!.l10n.dismiss}'),
          ),
        ],
      ),
    );
  }

  /*
   * @fn updateInsulinDeliveryPump(String bolus)
   * @brief update bolus data and emit it to server
   * @param[in] Glucose : String double bolus data
   */
  void updateInsulinDeliveryPump(String bolus) {
    if (FORCE_BGLUCOSE_UPDATE_FLAG) {
      final pumpInsulinDelivery = context.read<InputInsulinBloc>()
        ..add(
          InputInsulinValueChanged(value: double.parse(bolus)),
        );
      if (DEBUG_MESSAGE_FLAG) {
        debugPrint(
          'updateInsulinDeliveryPump: before status = '
          '${pumpInsulinDelivery.state.status.isValidated}',
        );
      }
      // pumpInsulinDelivery.add(InputInsulinSubmitted());  ///< updated by User
      pumpInsulinDelivery.add(
        const InputInsulinSubmitted(source: ReportSource.sensor),
      );

      ///< updated by sensor
    }
  }

  /*
   * @brief Handle ResponseCallback event sent from Pump or CGM
   *        if caller register this callback which should be implemented
   *        by using ConnectivityMgr.registerResponseCallbackListener(IDevice, ResponseCallback) then
   *        caller can receive an event delivered from Pump or Cgm and handle it.
   */
  void _handleResponseCallback(
    RSPType indexRsp,
    String message,
    String ActionType,
  ) {
    log('${TAG}kai:_handleResponseCallback() is called, mounted = ${mounted}');
    log(
      '${TAG}kai:RSPType($indexRsp)\nmessage($message)\nActionType($ActionType)',
    );
    final _notifier = mCMgr.mPump!;
    if (_notifier == null) {
      log(
        '${TAG}kai:_handleResponseCallback(): mCMgr.mPump is null!!: '
        'Cannot handle the response event!! ',
      );
      return;
    }

    switch (indexRsp) {
      case RSPType.PROCESSING_DONE:
        {
          // To do something here after receive the processing result
          if (ActionType == HCL_BOLUS_RSP_SUCCESS) {
            //kai_20230613 add to update insulin delivery chart and DB here
            if (mCMgr != null && mCMgr.mPump != null) {
              final insulDelivery = mCMgr.mPump!.bolusDeliveryValue;
              log(
                'kai:HCL_BOLUS_RSP_SUCCESS:'
                'bolusDeliveryValue(${insulDelivery.toString()}), '
                'call updateInsulinDeliveryPump()',
              );
              updateInsulinDeliveryPump(insulDelivery.toString());
            }
          }
        }
        break;

      case RSPType.TOAST_POPUP:
        {
          // Pump _notifier = mCMgr.mPump!;
          final Msg = message;
          final Title = '${mCMgr.appContext!.l10n.processing}';
          final Type = ActionType;
          _notifier
            ..showNoticeMsgDlg = false
            ..SetUpWizardMsg = ''

            ///< clear
            ..SetUpWizardActionType = '';

          //kai_20230512 let's call connectivityMgr.notifyListener() to notify bolus injection processing time & value
          // for consumer or selector page
          mCMgr.notifyListeners();

          //  _showSetupWizardMsgDialog(Title,Msg,Type);
          // if(_key.currentContext == null)
          if (_USE_GLOBAL_KEY == true) {
            _showToastMsgProgress(context, Msg, 'blue', int.parse(Type));
            //_showToastMsgProgressCenter(context,Msg,'blue',int.parse(Type));
          }
        }
        break;

      case RSPType.ALERT:
        if (_notifier.showALertMsgDlg) {
          final Msg = _notifier.AlertMsg;
          final Title = '${mCMgr.appContext!.l10n.alert}';
          _notifier
            ..showALertMsgDlg = false
            ..AlertMsg = '';

          ///< clear
          //  _showTXErrorMsgDialog(Title,Msg);
          // create dialog and start alert playback onetime
          WarningMsgDlg(Title, Msg, 'red', 5);
        }
        break;

      case RSPType.NOTICE:
        {
          log('${TAG}kai:NOTICE: show toast message ');
          final Msg = mCMgr.mPump!.NoticeMsg;
          final Type = ActionType;
          mCMgr.mPump!.showNoticeMsgDlg = false;
          mCMgr.mPump!.NoticeMsg = '';
          // _showToastMessage(context,Msg,'blue',int.parse(Type));
          showToastMessageDebounce(
              (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
              Msg,
              'blue',
              int.parse(Type));
          //kai_20240109 should call below to refresh changed variable on the Pump info of setting page.
          mCMgr.notifyListeners();
        }
        break;

      case RSPType.ERROR:
        if (_notifier.showTXErrorMsgDlg) {
          //let' clear variable here after copy them to buffer
          final Msg = _notifier.TXErrorMsg;
          final Title = '${mCMgr.appContext!.l10n.error}';
          _notifier
            ..showTXErrorMsgDlg = false
            ..TXErrorMsg = '';

          ///< clear
          _showTXErrorMsgDialog(Title, Msg);
        }
        break;

      case RSPType.WARNING:
        if (_notifier.showWarningMsgDlg) {
          final Msg = _notifier.WarningMsg;
          final Title = '${mCMgr.appContext!.l10n.warning}';
          _notifier.showWarningMsgDlg = false;
          //  _notifier.WarningMsg = '';  ///< clear

          //kai_20230512 let's call connectivityMgr.notifyListener() to notify bolus injection processing time & value
          // for consumer or selector page
          mCMgr.notifyListeners();

          //  _showTXErrorMsgDialog(Title,Msg);
          // create dialog and start alert playback onetime
          WarningMsgDlg(Title, Msg, 'red', 0);
        }
        break;

      case RSPType.SETUP_INPUT_DLG:
        {
          // Pump _notifier = mCMgr.mPump!;
          final Msg = message;
          final Title = '${mCMgr.appContext!.l10n.setup}';
          final Type = ActionType;
          _notifier
            ..showNoticeMsgDlg = false
            ..SetUpWizardMsg = ''

            ///< clear
            ..SetUpWizardActionType = '';
          _showSetupWizardMsgDialog(Title, Msg, Type);
        }
        break;

      case RSPType.SETUP_DLG:
        {
          //Pump _notifier = mCMgr.mPump!;
          final Msg = message;
          final Title = '${mCMgr.appContext!.l10n.setup}';
          final Type = ActionType;
          _notifier
            ..showNoticeMsgDlg = false
            ..SetUpWizardMsg = ''

            ///< clear
            ..SetUpWizardActionType = '';
          _showSetupWizardMsgDialog(Title, Msg, Type);
        }
        break;

      case RSPType.UPDATE_SCREEN:
        {
          //update screen, redraw
          setState(() {
            //kai_20230502
            log('${TAG}kai:UPDATE_SCREEN: redraw Screen widgits ');
          });
        }
        break;
      case RSPType.MAX_RSPTYPE:
        // TODO: Handle this case.
        break;
    }

    //kai_20230501 let's update UI variables shown on the screen
    //let's update build of the widget
    if (_notifier.isScanning == false) {
      debugPrint(
        '${TAG}_handleResponseCallback(): _notifier.isPumpScanning == false',
      );
      setState(() {
        //let's update variables here
        if (_notifier.fw.isNotEmpty) {
          mPumpFWVersion = mCMgr.mPump!.fw;
        }

        if (_notifier.Battery.isNotEmpty) {
          mPumpBatteryStatus = mCMgr.mPump!.Battery;
        }

        if (_notifier.reservoir.isNotEmpty) {
          mPumpInsulinRemain = mCMgr.mPump!.reservoir;
        }

        if (_notifier.bolusDeliveryValue.toString().isNotEmpty) {
          mPumpInsulinInject = mCMgr.mPump!.bolusDeliveryValue.toString();
        }

        // 0 means device does not connected at this time.
        if (_notifier.getLastBolusDeliveryTime() > 0) {
          mPumpInjectTime = DateFormat('yyyy/MM/dd HH:mm:ss').format(
            DateTime.fromMillisecondsSinceEpoch(
              mCMgr.mPump!.getLastBolusDeliveryTime(),
            ),
          );
          //mPumpInjectTime = millisecondsToTime(mCMgr.mPump!.getLastBolusDeliveryTime());
        } else {
          log('${TAG}kai:_handleResponseCallback():mPumpInjectTime is 0');
        }

        if (_notifier.getModelName().isNotEmpty) {
          mModelName = mCMgr.mPump!.getModelName();
        }

        if (_notifier.SN.isNotEmpty) {
          mSN = mCMgr.mPump!.SN;
        }

        if (_notifier.getConnectedTime().toString().isNotEmpty) {
          mFirstConnectionTime = mCMgr.mPump!.getConnectedTime().toString();
        }

        if (_notifier.PatchUseAvailableTime.isNotEmpty) {
          mPatchUseAvailableTime = mCMgr.mPump!.PatchUseAvailableTime;
        }

        if (_notifier.LogMessageView.isNotEmpty) {
          //mPumpInsulinHistoryLog = mCMgr.mPump!.LogMessageView;
          //kai_20231020 update received message here
          if (mCMgr.mPump!.LogMessageView.contains('<<')) {
            mCMgr.mPump!.LogMessageView =
                mCMgr.mPump!.LogMessageView.substring(2);
            mPumpInsulinHistoryLog =
                '<<:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: '
                '${mCMgr.mPump!.LogMessageView.toString()}\n$mPumpInsulinHistoryLog';
          } else if (mCMgr.mPump!.LogMessageView.contains('>>')) {
            mCMgr.mPump!.LogMessageView =
                mCMgr.mPump!.LogMessageView.substring(2);
            mPumpInsulinHistoryLog =
                '>>:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: '
                'Notify = ${mCMgr.mPump!.LogMessageView.toString()}\n$mPumpInsulinHistoryLog';
          } else {
            mPumpInsulinHistoryLog =
                '>>:${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}: '
                'Notify = ${mCMgr.mPump!.LogMessageView.toString()}\n$mPumpInsulinHistoryLog';
          }
          //kai_20240108  clear mCMgr.mPump!.LogMessageView
          log('${TAG}kai:_handleResponseCallback():_notifier.LogMessageView.isNotEmpty');
          mCMgr.mPump!.LogMessageView = '';
        }

        /*
          mPumpConnectionStatus = 'Disconnected'; //l10n!.disconnected;
          mPumpInjectIntervalTime = ''; ///< minute
          mPumpOcclusionAlert = ''; //l10n!.normal; //  ///< alert, normal
          mPumpstateText = 'Disconnected'; //l10n!.disconnected; //
          mPumpconnectButtonText = 'Disconnect'; //l10n!.disconnect; //
           */
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select PUMP Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_USE_CSBLUETOOTH_PROVIDER == true) {
                if (mounted &&
                    mCMgr.mPump!.ConnectionStatus ==
                        BluetoothDeviceState.disconnected) {
                  // Check if the widget is still mounted
                  setState(() {
                    if (DEBUG_MESSAGE_FLAG) {
                      debugPrint('${TAG}Pump is disconnected !!');
                    }
                    // kai_20221125  let's show dialog with message "There is no scanned device at this time !!"
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
                          'There is no connected PUMP device.\nTry to connect to a device first, please',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  });
                } else {
                  _showInputMessageDialog(context);
                }
              } else {
                if (mounted &&
                    mPumpdeviceState != BluetoothDeviceState.connected) {
                  // Check if the widget is still mounted
                  setState(() {
                    if (DEBUG_MESSAGE_FLAG) {
                      debugPrint('${TAG}Pump is disconnected !!');
                    }
                    // kai_20221125  let's show dialog with message "There is no scanned device at this time !!"
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
                          'There is no connected PUMP device.\nTry to connect to a device first, please',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  });
                } else {
                  _showInputMessageDialog(context);
                }
              }
            },
          ),
          PopupMenuButton(
            onSelected: (value) {
              switch (value) {
                /*
                  case 'CGM_Type':
                    _showDialog(context,value);
                    break;
                   */
                case 'UseBroadcastBolus':
                  _showDialogBroadcastingBolus(context, value as String);
                  break;
                case 'PUMP_Type':
                  _showDialogPump(context, value as String);
                  break;
                case 'IJILog_View':
                  //  IJILogChart(logs: mIJILogDB.getLogs());
                  /*   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => IJILogChart(logs: mIJILogDB.getLogs())),
                  );
                */
                  //let's Navigation push to keep current page status
                  Navigator.push<MaterialPageRoute>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IJILogViewPage(),
                    ),
                  );

                  break;

                case 'Low_Battery_Alert':
                  if (_USE_AUDIO_PLAYBACK) {
                    _showAlertDialogOnEvent('$value 18 %');
                  }
                  break;

                case 'Occlusion_Alert':
                  if (_USE_AUDIO_PLAYBACK) {
                    _showAlertDialogOnEvent(value.toString());
                  }
                  break;

                case 'SET_TIME_REQ':
                  {
                    const message =
                        'Please set amount of injected reservoir.\nAvailable range: 10 ~ 200U';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'SET_TIME_REQ',
                    );
                  }
                  break;

                case 'INFUSION_THRESHOLD_REQ':
                  {
                    const message =
                        'Please type the maximum insulin injection to patch.\nAvailable range: 0.5 ~ 25U';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'INFUSION_THRESHOLD_REQ',
                    );
                  }
                  break;

                case 'SAFETY_CHECK_REQ':
                  {
                    const message =
                        'Please perform a safety check for pump condition and air removal.\nProceed it?';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'SAFETY_CHECK_REQ',
                    );
                    // INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST
                  }
                  break;

                case 'HCL_DOSE_REQ':
                  {
                    const message =
                        'Please type amount of insulin injection to patch.\nAvailable range: 0.01 ~ 25U';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'HCL_DOSE_REQ',
                    );
                  }
                  break;

                case 'HCL_DOSE_CANCEL_REQ':
                  {
                    const message =
                        'Can stop the Dose injection sent just before.\nProceed it?';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'HCL_DOSE_CANCEL_REQ',
                    );
                  }
                  break;

                case 'PATCH_DISCARD_REQ':
                  {
                    const message =
                        'Can replace the patch.\nDo you really want to proceed it?';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'PATCH_DISCARD_REQ',
                    );
                  }
                  break;

                case 'PATCH_RESET_REQ':
                  {
                    const message =
                        'Can reset the patch.\nAvailable option range: 0 ~ 1';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'PATCH_RESET_REQ',
                    );
                  }
                  break;

                case 'INFUSION_INFO_REQ':
                  {
                    const message =
                        'Can request infusion status info to the Patch.\nAvailable option range: 0 ~ 1';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'INFUSION_INFO_REQ',
                    );
                  }
                  break;

                case 'PATCH_INFO_REQ':
                  {
                    const message =
                        'Can request patch infomation to the patch.\nProceed it?';
                    _showSetupWizardMsgDialog(
                      'Setup',
                      message,
                      'PATCH_INFO_REQ',
                    );
                  }
                  break;

                case 'DANAI_CHECK_PUMP':
                  {
                    final type = CspPreference.mPUMP_NAME;
                    if (type.toLowerCase().contains(
                          BluetoothProvider.DANARS_PUMP_NAME.toLowerCase(),
                        )) {
                      log('${TAG}kai::PumpType(${type.toLowerCase()})');
                      //kai_20231228  let's send Pump Check command here after connection
                      if (mCMgr.mPump! is PumpDanars) {
                        debugPrint('${TAG}kai::call sendPumpCheckAfterConnect()'
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                        (mCMgr.mPump as PumpDanars).sendPumpCheckAfterConnect();

                        ///< null check

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('send Dana-i pump check(0x00)')));
                      } else {
                        debugPrint(
                            '${TAG}kai::skip to call sendPumpCheckAfterConnect()'
                            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('cannot send Dana-i pump check(0x00)')));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'cannot send Dana-i pump check(0x00) due to current selected pump is not Dana-i')));
                    }
                  }
                  break;

                case 'DANAI_START_ENCRYPTION':
                  {
                    final type = CspPreference.mPUMP_NAME;
                    if (type.toLowerCase().contains(
                          BluetoothProvider.DANARS_PUMP_NAME.toLowerCase(),
                        )) {
                      log('${TAG}kai::PumpType(${type.toLowerCase()})');
                      //kai_20231228  let's send Pump Check command here after connection
                      if (mCMgr.mPump! is PumpDanars) {
                        log('${TAG}kai::call sendStartEncryptionCommand()');
                        (mCMgr.mPump as PumpDanars)
                            .sendStartEncryptionCommand();

                        ///< null check

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'send Dana-i startEncryption(0x01,0x00,0x0E1404)')));
                      } else {
                        log('${TAG}kai::skip to call sendStartEncryptionCommand()');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'cannot send Dana-i startEncryption(0x01,0x00,0x0E1404)')));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'cannot send Dana-i startEncryption(0x01,0x00,0x0E1404) due to current selected pump is not Dana-i')));
                    }
                  }

                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              /*
                PopupMenuItem(
                  value: 'CGM_Type',
                  child: Text('CGM Type'),
                ),
              */
              const PopupMenuItem(
                value: 'UseBroadcastBolus',
                child: Text('Broadcasting Bolus'),
              ),
              const PopupMenuItem(
                value: 'PUMP_Type',
                child: Text('PUMP Type'),
              ),
              const PopupMenuItem(
                value: 'IJILog_View',
                child: Text('IJILog View'),
              ),
              const PopupMenuItem(
                value: 'Low_Battery_Alert',
                child: Text('Low Battery Alert'),
              ),
              const PopupMenuItem(
                value: 'Occlusion_Alert',
                child: Text('Occlusion Alert'),
              ),
              const PopupMenuItem(
                value: 'SET_TIME_REQ',
                child: Text('Sync Time & Date'),
              ),
              const PopupMenuItem(
                value: 'INFUSION_THRESHOLD_REQ',
                child: Text('Set Bolus Max Injection'),
              ),
              const PopupMenuItem(
                value: 'SAFETY_CHECK_REQ',
                child: Text('Safety Check'),
              ),
              const PopupMenuItem(
                value: 'HCL_DOSE_REQ',
                child: Text('Set Dose'),
              ),
              const PopupMenuItem(
                value: 'HCL_DOSE_CANCEL_REQ',
                child: Text('Cancel Dose'),
              ),
              const PopupMenuItem(
                value: 'PATCH_DISCARD_REQ',
                child: Text('Discard patch'),
              ),
              const PopupMenuItem(
                value: 'INFUSION_INFO_REQ',
                child: Text('Infusion Info'),
              ),
              const PopupMenuItem(
                value: 'PATCH_RESET_REQ',
                child: Text('Reset Patch Info'),
              ),
              const PopupMenuItem(
                value: 'PATCH_INFO_REQ',
                child: Text('Request Patch Info'),
              ),
              const PopupMenuItem(
                  value: 'DANAI_CHECK_PUMP', child: Text('Dana-i Pump Check')),
              const PopupMenuItem(
                  value: 'DANAI_START_ENCRYPTION',
                  child: Text('Dana-i Start Encryption')),
            ],
          )
        ],
      ),
      body: Container(
        // color: Colors.grey.shade300,
        padding: const EdgeInsets.all(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //kai_20230445  add scrollview due to overflow
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*
                Expanded(
                child:
                    // Name , battery status, connectionstatus, remained Insulin amount, Injected insulin amount,
                    Insulin injection Time , occlusion alert,

                    Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                       /* Text('Device: $mPumpName'),
                        Text('MacID: $mPumpMacAddress'),
                       */
                        Text((mounted && context.read<BluetoothProvider>().
                        pumpConnectedDevice != null
                            && context.read<BluetoothProvider>().
                            pumpConnectedDevice!.name.isNotEmpty) ?
                             'Device: ${context.read<BluetoothProvider>().
                             pumpConnectedDevice!.name}' : 'Device: None'
                        ),
                        Text((mounted && context.read<BluetoothProvider>().
                        pumpConnectedDevice != null
                            && context.read<BluetoothProvider>().
                            pumpConnectedDevice!.id.toString().isNotEmpty) ?
                              'MacID: ${context.read<BluetoothProvider>().
                              pumpConnectedDevice!.id.toString()}' : 
                              'MacID: None'
                        ),
                      ],
                    ),
                  ),
                */

                  //  Expanded(
                  //  child:
                  Text(
                    (mounted &&
                            mCMgr.mPump!.getConnectedDevice() != null &&
                            mCMgr.mPump!.getConnectedDevice()!.name.isNotEmpty)
                        ? 'Device: ${mCMgr.mPump!.getConnectedDevice()!.name}\nID: ${mCMgr.mPump!.getConnectedDevice()!.id.toString()} , F/W: $mPumpFWVersion'
                        : 'Device: None',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  //   ),

                  /*
                  Text((mounted && context.read<BluetoothProvider>().
                  pumpConnectedDevice != null
                      && context.read<BluetoothProvider>().
                      pumpConnectedDevice!.id.toString().isNotEmpty) ?
                  'MacID: ${context.read<BluetoothProvider>().
                  pumpConnectedDevice!.id.toString()}' : 'MacID: None'
                  ),
                  Text('F/W: $mPumpFWVersion',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),),
                 */

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Battery: $mPumpBatteryStatus %',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      /*OutlinedButton*/ ElevatedButton(
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all<Size>(
                            const Size(60, 25),
                          ),
                          // backgroundColor:
                          // MaterialStateProperty.all<Color>(Colors.white),
                          // shadowColor:
                          // MaterialStateProperty.all<Color>(Colors.grey),
                        ),
                        onPressed: () async {
                          if (_USE_CSBLUETOOTH_PROVIDER == true) {
                            if (mounted &&
                                mCMgr.mPump!.ConnectionStatus ==
                                    BluetoothDeviceState.connected) {
                              m_RX_BATLEVEL_CHARACTERISTIC =
                                  mCMgr.mPump!.PumpRXBatLvlCharacteristic;
                              if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
                                if (!m_RX_BATLEVEL_CHARACTERISTIC!
                                    .isNotifying) {
                                  m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
                                      mCMgr.mPump!.pumpBatValueSubscription;
                                  if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER ==
                                      null) {
                                    m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
                                        m_RX_BATLEVEL_CHARACTERISTIC!.value
                                            .listen(_handlePumpBatLevelValue);

                                    if (_USE_CSBLUETOOTH_PROVIDER == true) {
                                      mCMgr.mPump!.pumpBatValueSubscription =
                                          m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
                                    }
                                  }
                                  await m_RX_BATLEVEL_CHARACTERISTIC!
                                      .setNotifyValue(true);
                                  //let's send command "BAT:" to the connected device here
                                  SendMessage2Pump(_cmdBatLevel);
                                } else {
                                  if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER !=
                                      null) {
                                    await m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER!
                                        .cancel();
                                    m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
                                        null;
                                    if (_USE_CSBLUETOOTH_PROVIDER == true) {
                                      mCMgr.mPump!.pumpBatValueSubscription =
                                          m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER;
                                    }
                                  }
                                  if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
                                    await m_RX_BATLEVEL_CHARACTERISTIC!
                                        .setNotifyValue(false);
                                    setState(() {
                                      mPumpBatteryStatus = '';
                                    });
                                  }
                                }
                              }
                            } else {
                              if (mounted) {
                                // Check if the widget is still mounted
                                setState(() {
                                  if (DEBUG_MESSAGE_FLAG) {
                                    debugPrint(
                                      '${TAG}battery read button does not working !!',
                                    );
                                  }
                                  // kai_20221125  let's show dialog with message "There is no scanned device at this time !!"
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
                                        'There is no connected PUMP device.\nTry to connect to a device first, please',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              }
                            }
                          } else {
                            if (mounted &&
                                mPumpdeviceState ==
                                    BluetoothDeviceState.connected) {
                              if (m_RX_BATLEVEL_CHARACTERISTIC != null) {
                                if (!m_RX_BATLEVEL_CHARACTERISTIC!
                                    .isNotifying) {
                                  m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER ??=
                                      m_RX_BATLEVEL_CHARACTERISTIC!.value
                                          .listen(_handlePumpBatLevelValue);
                                  await m_RX_BATLEVEL_CHARACTERISTIC!
                                      .setNotifyValue(true);
                                  //let's send command "BAT:" to the connected
                                  //device here
                                  SendMessage2Pump(_cmdBatLevel);
                                } else {
                                  if (m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER !=
                                      null) {
                                    await m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER!
                                        .cancel();
                                    m_RX_BATLEVEL_CHARACTERISTIC_VALUE_LISTENER =
                                        null;
                                  }
                                  await m_RX_BATLEVEL_CHARACTERISTIC!
                                      .setNotifyValue(false);
                                  setState(() {
                                    mPumpBatteryStatus = '';
                                  });
                                }
                              }
                            } else {
                              if (mounted) {
                                // Check if the widget is still mounted
                                setState(() {
                                  if (DEBUG_MESSAGE_FLAG) {
                                    debugPrint(
                                      '${TAG}battery read button does '
                                      'not working !!',
                                    );
                                  }
                                  // kai_20221125  let's show dialog with
                                  //message "There is no scanned device at
                                  //this time !!"
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
                                        'There is no connected PUMP '
                                        'device.\nTry to connect to a '
                                        'device first, please',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              }
                            }
                          }
                        },
                        child: Text(
                          (m_RX_BATLEVEL_CHARACTERISTIC != null &&
                                  m_RX_BATLEVEL_CHARACTERISTIC!.isNotifying)
                              ? 'Read Off'
                              : 'Read On',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Text('Connection Status : $mPumpConnectionStatus'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* Connection Sattus */
                      // Text('Status: $mPumpConnectionStatus'),
                      Text(
                        (mounted &&
                                mCMgr.mPump!.ConnectionStatus ==
                                    BluetoothDeviceState.connected)
                            ? 'Status: Connected'
                            : (mounted &&
                                    mCMgr.mPump!.ConnectionStatus ==
                                        BluetoothDeviceState.disconnected)
                                ? 'Status: Disconnected'
                                : (mounted &&
                                        mCMgr.mPump!.ConnectionStatus ==
                                            BluetoothDeviceState.connecting)
                                    ? 'Status: Connecting'
                                    : (mounted &&
                                            mCMgr.mPump!.ConnectionStatus ==
                                                BluetoothDeviceState
                                                    .disconnecting)
                                        ? 'Status: Disconnecting'
                                        : 'Status: Disconnected',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      /* connect/ disconnect button */
                      /*OutlinedButton*/ ElevatedButton(
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all<Size>(
                            const Size(60, 25),
                          ),
                          // backgroundColor:
                          // MaterialStateProperty.all<Color>(Colors.white),
                          //  shadowColor:
                          // MaterialStateProperty.all<Color>(Colors.grey),
                        ),
                        onPressed: () {
                          if (_USE_CSBLUETOOTH_PROVIDER == true) {
                            if (mounted &&
                                mCMgr.mPump!.ConnectionStatus ==
                                    BluetoothDeviceState.connected) {
                              /* try to disconnect if device is connected */
                              if (mCMgr.mPump!.ConnectionStatus != null) {
                                _disconnectDevice(
                                  mCMgr.mPump!.getConnectedDevice()!,
                                );
                              } else {
                                debugPrint(
                                  '${TAG}mCMgr.mPump!.ConnectionStatus '
                                  'is invalid!!',
                                );
                              }
                            } else if (mounted &&
                                mCMgr.mPump!.ConnectionStatus ==
                                    BluetoothDeviceState.disconnected) {
                              /* try to connect if device is disconnected */
                              if (mCMgr.mPump!.ConnectionStatus != null &&
                                  mCMgr.mPump!.getConnectedDevice() != null) {
                                // _connectToDevice(mPump!);
                                connectDiscovery(
                                  mCMgr.mPump!.getConnectedDevice()!,
                                );
                              } else {
                                if (mounted) {
                                  // Check if the widget is still mounted
                                  setState(() {
                                    if (DEBUG_MESSAGE_FLAG) {
                                      debugPrint('${TAG}mPump is Empty !!');
                                    }
                                    // kai_20221125  let's show dialog with
                                    //message "There is no scanned device at
                                    // this time !!"
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
                                          'There is no scanned PUMP device in '
                                          'the list at this time.\nSearch '
                                          'device first in order for the '
                                          'connection, please',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                }
                              }
                            } else {
                              debugPrint(
                                '${TAG}mCMgr.mPump!.ConnectionStatus '
                                'is connecting or disconnecting!!',
                              );
                            }
                          } else {
                            if (mPumpdeviceState ==
                                BluetoothDeviceState.connected) {
                              /* try to disconnect if device is connected */
                              if (mPump != null) {
                                _disconnectDevice(mPump!);
                              } else {
                                debugPrint('${TAG}mPump is Null!!');
                              }
                            } else if (mPumpdeviceState ==
                                BluetoothDeviceState.disconnected) {
                              /* try to connect id devie is disconnected */
                              if (mPump != null) {
                                // _connectToDevice(mPump!);
                                connectDiscovery(mPump!);
                              } else {
                                if (mounted) {
                                  // Check if the widget is still mounted
                                  setState(() {
                                    if (DEBUG_MESSAGE_FLAG) {
                                      debugPrint('${TAG}mPump is Empty !!');
                                    }
                                    // kai_20221125  let's show dialog with
                                    //message "There is no scanned device at
                                    //this time !!"
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
                                          'There is no scanned PUMP device '
                                          'in the list at this time.\nSearch '
                                          'device first in order for the '
                                          'connection, please',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                }
                              }
                            } else {
                              debugPrint(
                                '${TAG}mPumpdeviceState is '
                                'connecting or disconnecting!!',
                              );
                            }
                          }
                        },
                        child: Text(
                          mPumpconnectButtonText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Text('Occlusion Alert : $mPumpOcclusionAlert'),
                  Text(
                    'Reservoir: $mPumpInsulinRemain U'
                    ' ,Insulin: $mPumpInsulinInject U',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  /*
                  Text('Insulin: $mPumpInsulinInject ml',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),),
                  */
                  Text(
                    'Latest Delivery Time: $mPumpInjectTime',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              thickness: 0.5,
              color: Colors.grey,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'View History Log',
                  style: TextStyle(
                    color: Button_primarySolidColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // if select the button then start scan and
                    // add the detecetd device into the lists
                    if (mounted) {
                      // Check if the widget is still mounted
                      setState(() {
                        mPumpInsulinHistoryLog = '';
                        if (mCMgr != null && mCMgr.mPump != null) {
                          mCMgr.mPump!.NoticeMsg = '';
                          mCMgr.mPump!.LogMessageView = '';
                          mCMgr.mPump!.AlertMsg = '';
                          mCMgr.mPump!.WarningMsg = '';
                        }
                      });
                    }
                  },
                  /*
                  style: ElevatedButton.styleFrom(
                    primary: Button_primarySolidColor, // background
                    onPrimary: Colors.white, // foreground
                  ),
                   */
                  style: ButtonStyle(
                    minimumSize:
                        MaterialStateProperty.all<Size>(const Size(60, 25)),
                    //backgroundColor:
                    //MaterialStateProperty.all<Color>(Colors.white),
                    //shadowColor:
                    //MaterialStateProperty.all<Color>(Colors.grey),
                  ),
                  child: const Text(
                    'clear',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      // color: Button_primarySolidColor,
                    ),
                  ),
                ),
              ],
            ),
            // Log View screen
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  mPumpInsulinHistoryLog,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),

            const Divider(
              color: Colors.grey,
            ),
            const Expanded(
              child: Text(
                '1.Select  PUMP Type.\n2.Scan and connect the device to delivery the calculated insulin value to the PUMP periodically.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  //color: Button_primarySolidColor,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(
                mCMgr.mPump!.isScanning == true ? Icons.stop : Icons.search,
              ),
              label: const Text(
                'Search PUMP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  //color: Button_primarySolidColor,
                ),
              ),
              style: ButtonStyle(
                minimumSize:
                    MaterialStateProperty.all<Size>(const Size(60, 25)),
                // backgroundColor:
                // MaterialStateProperty.all<Color>(Colors.white),
                // shadowColor: MaterialStateProperty.all<Color>(Colors.grey),
              ),
              onPressed:
                  mCMgr.mPump!.isScanning == true ? _stopScan : _startScan,
            ),
            Expanded(
              child: (mCMgr.mPump!.getScannedDeviceLists() != null &&
                      mCMgr.mPump!.getScannedDeviceLists()!.isEmpty)
                  ? const Center(
                      child: Text(
                        'No devices found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    )
                  : _buildListView(),
              // (Csp1devices != null && Csp1devices!.isEmpty) ?
              //Center( child: Text('No devices found'),) : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }
}

mixin PendingDlgMsg {
  late String title;
  late String message;
  late String actionType;
}

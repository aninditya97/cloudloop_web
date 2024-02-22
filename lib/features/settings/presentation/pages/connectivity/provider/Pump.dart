// Pump class
/*
 * @brief the class Pump is implemented for the IPump interface
 */
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/settings/domain/entities/xdrip_data.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/CareLevoCmd.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/IPump.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Utilities.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/serviceUuid.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

//============================   test debug flag here  =========================//
const bool USE_DEBUG_MESSAGE = true;
//kai_20230419 just testing caremedi max bolus injection threshold
// we have to disable inthe commercial release
const bool _USE_TEST_SET_MAX_BOLUS_THRESHOLD = false;
//==============================================================================//

class Pump extends ChangeNotifier implements IPump {
  //kai_20230908 need BuildContext for supporting multi language
  late BuildContext mContext;

  final String TAG = 'Pump:';
  // IDevice, IPump interface implementation
  late FlutterBluePlus mPumpflutterBlue;

  ///< flutter blue plus instance
  String mBOLUS_SERVICE = serviceUUID.CareLevoSERVICE_UUID;

  ///< current set pump bolus service UUID
  String mRX_READ_UUID = serviceUUID.CareLevoRX_CHAR_UUID;

  ///< current set pump RX characteristic UUID
  String mTX_WRITE_UUID = serviceUUID.CareLevoTX_CHAR_UUID;

  ///< current set pump TX characteristic UUID
  String mRX_READ_BATTERY_UUID = serviceUUID.CSP_BATLEVEL_NOTIFY_CHARACTER_UUID;

  ///< current set pump RX Battery characteristic UUID
  String mPUMP_NAME = serviceUUID.CareLevo_PUMP_NAME;

  ///< current set pump device name
  int mFindCharacteristicMax = 2;

  ///< current pump's supported characteristics for each type
  StreamSubscription<bool>? _PumpScanningSubscription = null;

  ///< current set pump scanning status callback listener
  StreamSubscription<BluetoothDeviceState>? mPumpconnectionSubscription = null;

  ///< handle the connected pump device connection status
  StreamSubscription<List<int>>? _pumpValueSubscription = null;

  /// pump device data listener
  StreamSubscription<List<int>>? _pumpBatValueSubscription = null;

  ///< pump battery data listener
  BluetoothCharacteristic? _PumpTxCharacteristic = null;

  ///< current set pump TX characteristic instance
  BluetoothCharacteristic? _PumpRxCharacteristic = null;

  ///< current set pump RX characteristic instance
  BluetoothCharacteristic? _PumpRXBatLvlCharacteristic = null;

  ///< current set pump RX Battery characteristic instance

  //================================   attribute here ==========================//
  bool _isScanning = false;

  ///< scanning status
  BluetoothDeviceState _ConnectionStatus = BluetoothDeviceState.disconnected;

  ///< connection status
  List<BluetoothDevice> _Devices = [];

  ///< scanned device lists
  BluetoothDevice? _ConnectedDevice;

  ///< connected device
  String _ModelName = '';

  ///< Model Name
  String _ManufacturerName = '';

  ///< Manufacturer Name
  String _fw = '';

  ///< firmware
  String _SN = '';

  ///< serial number
  String _VC = '';

  ///< valid code
  String _Battery = '';

  ///< battery status
  int _ConnectedTime = 0;

  final XdripData? _collectBloodGlucose = null;

  ///< first connected time
  List<BluetoothService> _services = [];

  ///< connected device's service
  ///
  double bolusDeliveryValue = 0;
  double lastBolusDeliveryValue = 0;
  ReportSource source = ReportSource.user;

  ///<  bolus delivery value
  int lastBolusDeliveryTime = 0;

  ///< latest bolus delivered time

  ///< reservoir
  String _reservoir = '';
  String get reservoir => _reservoir;
  set reservoir(String value) {
    _reservoir = value;
    //notifyListeners();
  }

  String _PatchUseAvailableTime = '';

  ///< 패치 사용 가능 남은 시간
  String get PatchUseAvailableTime => _PatchUseAvailableTime;
  set PatchUseAvailableTime(String value) {
    _PatchUseAvailableTime = value;
    //notifyListeners();
  }

  int _refillTime = 0;

  ///<  refill reservoir time
  int getrefillTime() {
    _refillTime = CspPreference.getInt(CspPreference.refillTimePumpKey);
    return _refillTime;
  }

  set refillTime(int value) {
    _refillTime = value;
    CspPreference.setInt(CspPreference.refillTimePumpKey, value);
  }

  //================  additional variable get/set method here ==================//
  ResponseCallback? _Responselistener;
  //kai_20230802 add to common response listener for all cgm
  ResponseCallback? _DefaultResponselistener;

  ///< listen a response sent from Pump and notify a message to caller

  /*
   * @brief flags that check the careLevo patch set time report response is received.
   */
  bool SET_TIME_RSP_responseReceived = false,
      INFUSION_THRESHOLD_RSP_responseReceived = false;
  int SET_TIME_RSP_retryCnt = 0, INFUSION_THRESHOLD_RSP_retryCnt = 0;
  int MAX_RETRY = 2;
  int SET_TIME_RSP_TIMEOUT = 5;
  bool _isDoseInjectingNow = false;

  ///< blocking to send dose until previous request complete
  bool get isDoseInjectingNow => _isDoseInjectingNow;
  set isDoseInjectingNow(bool value) {
    _isDoseInjectingNow = value;
    /*
    if(value == true) {
      notifyListeners();
    }
     */
  }

  //kai_20230420 notice, alert, warning message variable here and
  // notify the change to widget thru registered callback
  bool _showNoticeMsgDlg = false;
  bool get showNoticeMsgDlg => _showNoticeMsgDlg;
  set showNoticeMsgDlg(bool value) {
    _showNoticeMsgDlg = value;
    if (value == true) {
      notifyListeners();
    }
  }

  String _NoticeMsg = '';
  String get NoticeMsg => _NoticeMsg;
  set NoticeMsg(String value) {
    _NoticeMsg = value;
    //notifyListeners();
  }

  bool _showWarningMsgDlg = false;
  bool get showWarningMsgDlg => _showWarningMsgDlg;
  set showWarningMsgDlg(bool value) {
    _showWarningMsgDlg = value;
    if (value == true) {
      notifyListeners();
    }
  }

  String _WarningMsg = '';
  String get WarningMsg => _WarningMsg;
  set WarningMsg(String value) {
    _WarningMsg = value;
    //notifyListeners();
  }

  bool _showALertMsgDlg = false;
  bool get showALertMsgDlg => _showALertMsgDlg;
  set showALertMsgDlg(bool value) {
    _showALertMsgDlg = value;
    if (value == true) {
      notifyListeners();
    }
  }

  String _AlertMsg = '';
  String get AlertMsg => _AlertMsg;
  set AlertMsg(String value) {
    _AlertMsg = value;
    //notifyListeners();
  }

  // let's toast message to user when the request command is not sent to the pump
  bool _showTXErrorMsgDlg = false;
  bool get showTXErrorMsgDlg => _showTXErrorMsgDlg;
  set showTXErrorMsgDlg(bool value) {
    _showTXErrorMsgDlg = value;
    if (value == true) {
      notifyListeners();
    }
  }

  String _TXErrorMsg = '';
  String get TXErrorMsg => _TXErrorMsg;
  set TXErrorMsg(String value) {
    _TXErrorMsg = value;
    //notifyListeners();
  }

  bool _showSetUpWizardMsgDlg = false;
  bool get showSetUpWizardMsgDlg => _showSetUpWizardMsgDlg;
  set showSetUpWizardMsgDlg(bool value) {
    _showSetUpWizardMsgDlg = value;
    if (value == true) {
      notifyListeners();
    }
  }

  String _SetUpWizardMsg = '';
  String get SetUpWizardMsg => _SetUpWizardMsg;
  set SetUpWizardMsg(String value) {
    _SetUpWizardMsg = value;
    //notifyListeners();
  }

  String _SetUpWizardActionType = '';
  String get SetUpWizardActionType => _SetUpWizardActionType;
  set SetUpWizardActionType(String value) {
    _SetUpWizardActionType = value;
    //notifyListeners();
  }

  /*
   * @brief show patch response message or Reported Info on the screen
   *
   */
  String _LogMessageView = '';
  String get LogMessageView => _LogMessageView;
  set LogMessageView(String value) {
    _LogMessageView = value;
    notifyListeners();
  }

  /*
  *@brief check the write characteristic notify is enabled or not
   */
  bool _isSetNotifyFailed = false;
  bool get isSetNotifyFailed => _isSetNotifyFailed;
  set isSetNotifyFailed(bool value) {
    _isSetNotifyFailed = value;
  }

  //==================== Attribute get / set methods here  =====================//
  bool get isScanning => _isScanning;

  ///< scanning status
  BluetoothDeviceState get ConnectionStatus => _ConnectionStatus;

  ///<
  List<BluetoothDevice> get Devices => _Devices;
  BluetoothDevice? get ConnectedDevice => _ConnectedDevice;
  String get fw => _fw;
  String get SN => _SN;
  String get VC => _VC;
  String get Battery => _Battery;
  int get ConnectedTime => _ConnectedTime;

  set isScanning(bool value) {
    _isScanning = value;
  }

  set ConnectionStatus(BluetoothDeviceState value) {
    _ConnectionStatus = value;
  }

  set Devices(List<BluetoothDevice> value) {
    _Devices = value;
  }

  set ConnectedDevice(BluetoothDevice? value) {
    _ConnectedDevice = value;
  }

  set fw(String value) {
    _fw = value;
  }

  set SN(String value) {
    _SN = value;
  }

  set VC(String value) {
    _VC = value;
  }

  set Battery(String value) {
    _Battery = value;
  }

  set ConnectedTime(int value) {
    _ConnectedTime = value;
  }

  set services(List<BluetoothService> value) {
    _services = value;
  }

  StreamSubscription<List<int>>? get pumpValueSubscription =>
      _pumpValueSubscription;
  set pumpValueSubscription(StreamSubscription<List<int>>? value) {
    _pumpValueSubscription = value;
  }

  StreamSubscription<List<int>>? get pumpBatValueSubscription =>
      _pumpBatValueSubscription;
  set pumpBatValueSubscription(StreamSubscription<List<int>>? value) {
    _pumpBatValueSubscription = value;
  }

  BluetoothCharacteristic? get pumpRxCharacteristic => _PumpRxCharacteristic;
  BluetoothCharacteristic? get pumpTxCharacteristic => _PumpTxCharacteristic;
  BluetoothCharacteristic? get PumpRXBatLvlCharacteristic =>
      _PumpRXBatLvlCharacteristic;
  set PumpRxCharacteristic(BluetoothCharacteristic? value) {
    _PumpRxCharacteristic = value;
  }

  set PumpTxCharacteristic(BluetoothCharacteristic? value) {
    _PumpTxCharacteristic = value;
  }

  set PumpRXBatLvlCharacteristic(BluetoothCharacteristic? value) {
    _PumpRXBatLvlCharacteristic = value;
  }

  set ModelName(String value) {
    _ModelName = value;
  }
  //================================   creator  ================================//

  Pump(this.mContext) {
    _init();
  }

  Future<void> _init() async {
    //register scan status listener here
    mPumpflutterBlue = FlutterBluePlus.instance;
    _PumpScanningSubscription =
        mPumpflutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      debugPrint('${TAG}Pump.isScanning = $_isScanning');
      notifyListeners();
      setResponseMessage(RSPType.UPDATE_SCREEN, 'update Screen', UPDATE_SCREEN);
    });

    // cspPreference.initPrefs();
  }

  //===========================   supported methods here  ======================//
  @override
  Future<List<BluetoothDevice>?> startScan(int timeout) async {
    debugPrint('${TAG}kai:startScan:enter');
    if (timeout < 1) {
      timeout = 5;
    }
    // check device lists are not empty then let's clear it before starting scan
    if (_Devices != null && _Devices.isNotEmpty) {
      debugPrint('${TAG}kai:startScan:clear Devices list');
      _Devices.clear();
    }

    if (_isScanning == true) {
      debugPrint('${TAG}kai:startScan:stop the previous scanning');
      if (mPumpflutterBlue != null) {
        await mPumpflutterBlue.stopScan();
      } else {
        mPumpflutterBlue = FlutterBluePlus.instance;
        await mPumpflutterBlue.stopScan();
      }
    }
    _isScanning = true;

    debugPrint('${TAG}kai:startScan:start with 5secs timeout');
    /*FlutterBluePlus.instance*/ mPumpflutterBlue
        .scan(timeout: Duration(seconds: timeout))
        .listen((scanResult) {
      if (scanResult.device.name != null) {
        //let's check scanned device is not exist in the _Devices list first.
        if (!_Devices.contains(scanResult.device)) {
          // check the scanned device name is
          // matched for the specified name second
          if (scanResult.device.name.contains(CspPreference.mPUMP_NAME)) {
            debugPrint(
              '${TAG}kai:startScan:Devices.add(${scanResult.device.name}), '
              'id(${scanResult.device.id})',
            );
            _Devices.add(scanResult.device);
            notifyListeners();
          } else {
            debugPrint(
              '${TAG}kai:startScan:name(${scanResult.device.name}), '
              'id(${scanResult.device.id})',
            );
          }
        }
      }
    }).onDone(() {
      _isScanning = false;
      debugPrint('${TAG}kai:startScan:done');
      notifyListeners();
    });

    debugPrint('${TAG}kai:startScan:exit');
    return _Devices;
  }

  @override
  void stopScan() {
    // ...
    debugPrint('${TAG}kai:stopScan');
    FlutterBluePlus.instance.stopScan();
  }

  @override
  Future<void> connectToDevice(BluetoothDevice device) async {
    // ...
    try {
      if (mPumpflutterBlue.isScanning == true) {
        await mPumpflutterBlue.stopScan();
      }
      //let's check current set pump type here
      final type = CspPreference.mPUMP_NAME;
      debugPrint('${TAG}kai:cspPreference.mPUMP_NAME = $type');

      if (type.contains(serviceUUID.CSP_PUMP_NAME)) {
        mBOLUS_SERVICE = serviceUUID.CSP_SERVICE_UUID;
        mRX_READ_UUID = serviceUUID.CSP_RX_READ_CHARACTER_UUID;
        mTX_WRITE_UUID = serviceUUID.CSP_TX_WRITE_CHARACTER_UUID;
        mPUMP_NAME = serviceUUID.CSP_PUMP_NAME;
        mRX_READ_BATTERY_UUID = serviceUUID.CSP_BATLEVEL_NOTIFY_CHARACTER_UUID;
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: pumptype = $type');
      } else if (type.contains(serviceUUID.CareLevo_PUMP_NAME)) {
        mBOLUS_SERVICE = serviceUUID.CareLevoSERVICE_UUID;
        mRX_READ_UUID = serviceUUID.CareLevoRX_CHAR_UUID;
        mTX_WRITE_UUID = serviceUUID.CareLevoTX_CHAR_UUID;
        mPUMP_NAME = serviceUUID.CareLevo_PUMP_NAME;
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: pumptype = $type');
      } else if (type.contains(serviceUUID.DANARS_PUMP_NAME)) {
        mBOLUS_SERVICE = serviceUUID.DANARS_BOLUS_SERVICE;
        mRX_READ_UUID = serviceUUID.DANARS_READ_UUID;
        mTX_WRITE_UUID = serviceUUID.DANARS_WRITE_UUID;
        mPUMP_NAME = serviceUUID.DANARS_PUMP_NAME;
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: pumptype = $type');
      } else if (type.contains(serviceUUID.Dexcom_PUMP_NAME)) {
        mBOLUS_SERVICE = serviceUUID.DexcomSERVICE_UUID;
        mRX_READ_UUID = serviceUUID.DexcomRX_CHAR_UUID;
        mTX_WRITE_UUID = serviceUUID.DexcomTX_CHAR_UUID;
        mPUMP_NAME = serviceUUID.Dexcom_PUMP_NAME;
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: pumptype = $type');
      } else {
        mBOLUS_SERVICE = serviceUUID.CSP_SERVICE_UUID;
        mRX_READ_UUID = serviceUUID.CSP_RX_READ_CHARACTER_UUID;
        mTX_WRITE_UUID = serviceUUID.CSP_TX_WRITE_CHARACTER_UUID;
        mRX_READ_BATTERY_UUID = serviceUUID.CSP_BATLEVEL_NOTIFY_CHARACTER_UUID;
        mPUMP_NAME = serviceUUID.CSP_PUMP_NAME;
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: pumptype = $type');
      }

      if (USE_AUTO_CONNECTION == true) {
        await device.connect();
      } else {
        await device.connect(autoConnect: false);
      }
      _services = await device.discoverServices();
      _ConnectedDevice = device;
      _ConnectionStatus = BluetoothDeviceState.connected;
      _ConnectedTime = DateTime.now().millisecondsSinceEpoch;
      //let's find RX/TX characteristic here
      var findCharacteristic = 0;

      ///< clear

      for (final service in _services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              mTX_WRITE_UUID.toLowerCase()) {
            findCharacteristic = findCharacteristic + 1;
            _PumpTxCharacteristic = characteristic;
          } else if (characteristic.uuid.toString().toLowerCase() ==
              mRX_READ_UUID.toLowerCase()) {
            findCharacteristic = findCharacteristic + 1;
            _PumpRxCharacteristic = characteristic;
          } else if (characteristic.uuid.toString().toLowerCase() ==
              mRX_READ_BATTERY_UUID.toLowerCase()) {
            findCharacteristic = findCharacteristic + 1;
            _PumpRXBatLvlCharacteristic = characteristic;
          }
        }
        /*
        if(findCharacteristic > mFindCharacteristicMax)
        {
          break;
        }
         */
      }

      if (findCharacteristic >= mFindCharacteristicMax) {
        //kai_20240122  cancel previous listener if exist
        unregisterPumpStateCallback();
        //register connection status listener here
        registerPumpStateCallback(pumpConnectionStatus);
        // mPumpconnectionSubscription = _ConnectedDevice!.state.listen((event) { });
        //enable notify of the RX and register RX data value listener here
        //check the characteristic have notify property and Notify is enabled first here
        if (_PumpRxCharacteristic!.properties.notify &&
            _PumpRxCharacteristic!.descriptors.isNotEmpty) {
          if (!_PumpRxCharacteristic!.isNotifying) {
            try {
              await _PumpRxCharacteristic!.setNotifyValue(true);
              isSetNotifyFailed = false;
            } catch (e) {
              debugPrint(
                '$TAG:kai:characteristic notify set error: uuid =  ${_PumpRxCharacteristic!.uuid} $e'
                ':isSetNotifyFailed($isSetNotifyFailed)',
              );
            }
          }
        }
        //_PumpRxCharacteristic!.setNotifyValue(true);
        //kai_20240122  cancel previous listener if exist
        await unregisterPumpValueListener();
        registerPumpValueListener(handlePumpValue);
        /* _PumpRxCharacteristic!.value.listen((value) {
            handlePumpValue(value);
          });
         */
        await Future<void>.delayed(const Duration(milliseconds: 500));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('${TAG}Error connecting to device: $e');
    }
  }

  @override
  Future<void> disconnectFromDevice() async {
    // ...
    try {
      if (_ConnectedDevice == null) {
        throw Exception('PUMP device not connected');
      }
      await _ConnectedDevice?.disconnect();
      _ConnectedDevice = null;
      _ConnectionStatus = BluetoothDeviceState.disconnected;
      notifyListeners();
      //kai_20230621  separate type of disconnection [ from user action / from device away ]
      setResponseMessage(
        RSPType.UPDATE_SCREEN,
        'disconnected',
        'DISCONNECT_PUMP_FROM_USER_ACTION',
      );
    } catch (e) {
      log('${TAG}Error disconnect from device : $e');
    }
  }

  @override
  Future<List<BluetoothService>?> discoverServices() async {
    // ...
    if (_services.isEmpty) {
      try {
        if (_ConnectedDevice == null) {
          throw Exception('PUMP device not connected');
        }
        final services = await _ConnectedDevice!.discoverServices();
        _services = services;
      } catch (e) {
        log('${TAG}Error finding characteristic: $e');
        return null;
      }
    }
    return _services;
  }

  @override
  BluetoothDevice? getConnectedDevice() {
    // ...
    return _ConnectedDevice;
  }

  @override
  String getFirmwareVersion() {
    // ...
    return _fw;
  }

  @override
  String getSerialNumber() {
    // ...
    return _SN;
  }

  @override
  String getVerificationCode() {
    // ...
    return _VC;
  }

  @override
  String getBatteryLevel() {
    // ...
    return _Battery;
  }

  @override
  XdripData? getCollectBloodGlucose() {
    // ...
    return _collectBloodGlucose;
  }

  @override
  int getConnectedTime() {
    // ...
    return _ConnectedTime;
  }

  @override
  Future<List<BluetoothCharacteristic>?> discoverCharacteristics(
    BluetoothService service,
  ) async {
    // TODO: implement discoverCharacteristics
    try {
      final characteristics = service.characteristics;
      return characteristics;
    } catch (e) {
      log('${TAG}Error discovering characteristics: $e');
      return null;
    }
  }

  @override
  Future<BluetoothCharacteristic?> getCharacteristic(String uuid) async {
    try {
      if (_ConnectedDevice == null) {
        throw Exception('PUMP device not connected');
      }
      final services = await _ConnectedDevice!.discoverServices();
      for (final service in services) {
        final characteristics = service.characteristics;
        for (final characteristic in characteristics) {
          if (characteristic.uuid == uuid) {
            return characteristic;
          }
        }
      }
      throw Exception('Characteristic not found');
    } catch (e) {
      log('${TAG}Error finding characteristic: $e');
      return null;
    }
  }

  //=======================  IPump interface implementation ====================//
  @override
  double getBolusDeliveryValue() {
    // ...
    return bolusDeliveryValue;
  }

  @override
  void setBolusDeliveryValue(double _value) {
    bolusDeliveryValue = _value;
    notifyListeners();
  }

  @override
  double getLastBolusDeliveryValue() {
    // ...
    return lastBolusDeliveryValue;
  }

  @override
  void setLastBolusDeliveryValue(double _value) {
    lastBolusDeliveryValue = _value;
    notifyListeners();
  }

  @override
  int getLastBolusDeliveryTime() {
    // ...
    return lastBolusDeliveryTime;
  }

  @override
  void setInsulinSource(ReportSource _value) {
    source = _value;
    notifyListeners();
  }

  @override
  ReportSource getInsulinSource() {
    // ...
    return source;
  }

  @override
  void setLastBolusDeliveryTime(int _value) {
    lastBolusDeliveryTime = _value;
    notifyListeners();
  }

  Future<void> SetForceRXNotify() async {
    if (pumpRxCharacteristic != null) {
      try {
        //// let's check the ReadCharacteristic Setnotify is enabled or not here
        /*
        List<int> value = await pumpRxCharacteristic!.read();
        bool isEnabled = value.isNotEmpty && value[0] == 0x01;
       // bool isEnabled = value.isNotEmpty && ((value[0] & 0x01) > 0 || (value[0] & 0x02) > 0);
*/
        if (!pumpRxCharacteristic!.isNotifying || isSetNotifyFailed == true) {
          debugPrint(
            '${TAG}kai:SetForceRXNotify():PumpRxCharacteristic!.isNotifying(${pumpRxCharacteristic!.isNotifying})'
            ', isSetNotifyFailed($isSetNotifyFailed)'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
          );

          //let's check it again
          if (isSetNotifyFailed == true) {
            await pumpRxCharacteristic!.setNotifyValue(true);
            isSetNotifyFailed = false;
          }

          debugPrint(
            '${TAG}kai:SetRXNotify();success set notify, let update  isSetNotifyFailed($isSetNotifyFailed)'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
          );
        } else {
          if (isSetNotifyFailed == true) {
            debugPrint(
              '${TAG}kai:SetForceRXNotify():pumpRxCharacteristic!.isNotifying == true,'
              'isSetNotifyFailed($isSetNotifyFailed)'
              ', but force set enable !!'
              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
            );

            await pumpRxCharacteristic!.setNotifyValue(true);
            //let's update flag here to retry alter
            isSetNotifyFailed = false;
          } else {
            debugPrint(
              '${TAG}kai:SetForceRXNotify():pumpRxCharacteristic!.isNotifying == true,'
              'isSetNotifyFailed($isSetNotifyFailed)!!'
              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
            );
          }
        }
      } catch (e) {
        //let's update flag here to retry alter
        isSetNotifyFailed = true;
        debugPrint(
          '${TAG}kai:SetRXNotify();failed set notify, update  isSetNotifyFailed($isSetNotifyFailed)'
          ': uuid =  ${pumpRxCharacteristic!.uuid} $e'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
        );
      }
    }
  }

  /*
   * @brief send current time and injected reservoir amount to Pump
   * composited data records is as below;
   * cmd(1byte:0x11)
   * time(6byte:yymmddhhmmss)
   * injected reservoir amount(2byte:100단위,1~10 단위)
   * HCL Mode (1byte): 0x00 (passive mode), 0x01 (HCL By App), 0x02 (HCL By Patch)
   *
   * after sending request, wait for the response from Pump
   * @param[in] ReservoirAmount : injected reservoir amount
   * @param[in] HclMode : 0x00 (passive mode), 0x01 (HCL By App), 0x02 (HCL By Patch)
   */
  @override
  Future<void> SendSetTimeReservoirRequest(
    int ReservoirAmount,
    int HclMode,
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement SendSetTimeReservoirRequest
    try {
      //int SET_TIME_REQ = 0x11;
      //int SET_TIME_RSP = 0x71;  ///< response for the SET_TIME_REQ sent from connected Pump device
      //put command 1 byte
      var waitCallback = false;
      final sendBytes = <int>[CareLevoCmd.SET_TIME_REQ];
      // get current time
      final dateTimeString =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final TemprefillTime = DateTime.now().millisecondsSinceEpoch;

      ///<kai_20231011 update refill time here
      final dateTime = DateTime.parse(dateTimeString);
      final year = dateTime.year - 2000;
      final month = dateTime.month;
      final day = dateTime.day;
      final hour = dateTime.hour;
      final minute = dateTime.minute;
      final second = dateTime.second;
      //put datetime info 6 bytes
      sendBytes.addAll([year, month, day, hour, minute, second]);
      //put reservoir amount 2bytes , ex:250U => 0x02,0x32
      final data1Per100unit = ReservoirAmount ~/ 100;
      final data2Per10to1 = ReservoirAmount % 100;
      sendBytes
        ..addAll([data1Per100unit, data2Per10to1])
        //put HCL Mode 1 byte
        ..addAll([HclMode]);

      // 최종 송신할 바이트 배열을 characteristic.write 메서드를 사용하여 전송
      if (characteristic != null) {
        await characteristic.write(sendBytes);
        waitCallback = true;
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
          waitCallback = true;
        } else {
          log('${TAG}Failed to send set time request !!');
          TXErrorMsg = mContext.l10n
              .sendSetTimeRequestNotAvailable; //'Requesting time date setting is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }

      // we have to check the response sent from Pump
      //let's just set timer which have timeout after 5 secs here
      // 5초 타이머 설정
      if (waitCallback == true) {
        Future.delayed(Duration(seconds: SET_TIME_RSP_TIMEOUT), () {
          if (!SET_TIME_RSP_responseReceived) {
            // 응답이 오지 않았을 경우 처리
            log(
              "${TAG}SET_TIME_RSP Response not received!!; let's try to send SET_TIME_REQ again!! ",
            );
            SET_TIME_RSP_retryCnt += 1;
            if (SET_TIME_RSP_retryCnt < MAX_RETRY) {
              //let's show dialog which provide an option that user select to try it again
              // or retry it automatically
              SendSetTimeReservoirRequest(
                ReservoirAmount,
                HclMode,
                characteristic,
              );
            } else {
              log(
                '${TAG}SET_TIME_RSP Response not received : retry failed!!; timeout!! ',
              );
              SET_TIME_RSP_retryCnt = 0;

              ///< clear
              SET_TIME_RSP_responseReceived = false;

              ///< clear
              TXErrorMsg = mContext.l10n.sendSetTimeRequestNotResponding;
              // 'Patch does not responding for setting time date at this time. Retry it?';
              showTXErrorMsgDlg = true;
            }
          } else {
            log('${TAG}SET_TIME_RSP Response received!! ');
            SET_TIME_RSP_retryCnt = 0;

            ///< clear
            SET_TIME_RSP_responseReceived = false;

            ///< clear

            //kai_20230501 let's save first set reservoir here
            reservoir = ReservoirAmount.toString();
            refillTime = TemprefillTime;
            notifyListeners();

            //kai_20230422  let's send pump patch information request PATCH_INFO_REQ(0x33) to the pump here
            sendPumpPatchInfoRequest(null);
          }
        });
      }
    } catch (e) {
      debugPrint('${TAG}Error SendSetTimeReservoirRequest: $e');
    }
  }

  /*
   * @brief cansel dose injection
   */
  @override
  Future<void> cancelSetDoseValue(
    int mode,
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement cancelSetDoseValue
    try {
      // Mode (1 byte): HCL 통합 주입(0x00).
      //교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
      //요청 시 입력한 모드 그대로 입력
      // REQ	MODE
      // 0x68	0x00
      final sendBytes = <int>[CareLevoCmd.HCL_DOSE_CANCEL_REQ, mode];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send dose cancel request !!');
          TXErrorMsg = mContext.l10n.sendingDoseCancelRequestNotAvailable;
          //'Sending dose cancel request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error cancelSetDoseValue: $e');
    }
  }

  /*
   * @brief send application status change indication to the patch
   *        in case of changing the status of mobile app from forground to bacground vice versa.
   */
  @override
  Future<void> sendAppStatusChangeIndication(
    int status,
    int StopTimerValue,
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendAppStatusChangeIndication
    try {
      // Length 3, CMD: 0x39
      // Status: 0x00 (foreground  background), 0x01 (Background  foreground)
      // Time: 사용자가 설정한 주입 중단 결정 타이머 (1시간 ~ 24 시간, 0이면 사용 안함 의미임)
      // ㈜ 타임아웃 시 펌프 중단 및 경고 메시지 전송)
      final sendBytes = <int>[CareLevoCmd.APP_STATUS_IND];

      ///< 0x39

      if (status == 0x01) {
        sendBytes.addAll([0x01]);
      } else {
        sendBytes.addAll([0x00]);
      }

      if (StopTimerValue > 24 || StopTimerValue < 1) {
        sendBytes.addAll([0x00]);
      } else {
        sendBytes.addAll([StopTimerValue]);
      }

      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send app status change indication !!');
          TXErrorMsg = mContext.l10n.sendingAppStatusChangeNotAvailable;
          // 'Sending app status change indication is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendAppStatusChangeIndication: $e');
    }
  }

  /*
   * @brief send buzzer change request
   */
  @override
  Future<void> sendBuzzerChangeRequest(
    bool BuzzerOnOff,
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendBuzzerChangeRequest
    try {
      // 부저 사용 설정 변경 요청 (스마트폰 앱  패치 장치)
      // 송신 조건: 설정 메뉴의 부저 사용 중지/사용 설정을 사용자가 변경하면 본 메시지가 송신된다.
      // Length 2, CMD: 0x18
      // USE_FLAG: 부저 울림 여부 (0x01 부저 울림, 0x00 부저 사용 안함)
      // * 기본 값은 미 사용임
      // CMD	USE_FLAG
      // 0x18	0x01
      // Action: 수신한 패치는 buzzer-use_flag 가 1이면 주의와 알림 발생 시 부저를 사용하고, 0 이면 경고 발생 시 부저만 사용한다.
      final sendBytes = <int>[CareLevoCmd.BUZZER_CHANGE_REQ];

      ///< 0x18

      if (BuzzerOnOff == true) {
        sendBytes.addAll([0x01]);
      } else {
        sendBytes.addAll([0x00]);
      }

      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send buzzer change request !!');
          TXErrorMsg = mContext.l10n.sendingBuzzerChangeNotAvailable;
          // 'Sending buzzer change request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendBuzzerChangeRequest: $e');
    }
  }

  /*
   * @brief send buzzer check request
   */
  @override
  Future<void> sendBuzzerCheck(BluetoothCharacteristic? characteristic) async {
    // TODO: implement sendBuzzerCheck
    try {
      final sendBytes = <int>[CareLevoCmd.BUZZER_CHECK_REQ];

      ///< 0x37
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send buzzer check request !!');
          TXErrorMsg = mContext.l10n.sendingBuzzerCheckNotAvailable;
          //'Sending buzzer check request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendBuzzerCheck: $e');
    }
  }

  /*
   * @brief send cannular insert ack to the pump
   */
  @override
  Future<void> sendCannularInsertAck(
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendCannularInsertAck
    try {
      // 케뉼라 삽입 보고 수신 확인 (스마트폰 앱  패치 장치): CANNULAR_INSERT_ACK (0x19)
      // Length 1, RSP: 0x19
      // Result (1 byte): SUCCESS 0, FAIL 1
      // 송신 조건: 앱에서 안점 점검 절차 후 기저 주입 시도 전 상태에서
      // 수신한 “케뉼라 삽입 보고” 메시지 (CANNULAR_INSERT_RPT) 에 대헤 확인 메시지로 본 메시지를 송신한다.
      // ACK	RSLT
      // 0x19	0x00
      // Action: 패치가 5초 이내 본 확인 메시지를 수신하지 못한 경우,
      // 패치 장치는 캐뉼라 삽입 보고 메시지 “CANNULAR_INSERT_RPT”를 재 송신한다

      final sendBytes = <int>[CareLevoCmd.CANNULAR_INSERT_ACK];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send cannular insert ack request !!');
          TXErrorMsg = mContext.l10n.sendingCannularInsertAckNotAvailable;
          // 'Sending cannular insert ack is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendCannularInsertAck: $e');
    }
  }

  /*
   * @brief send cannular status request to the pump
   */
  @override
  Future<void> sendCannularStatusRequest(
    BluetoothCharacteristic characteristic,
  ) async {
    // TODO: implement sendCannularStatusRequest
    try {
      // CANNULAR_STATUS_REQ
      // 캐뉼라 삽입 상태 요청: CANNULAR_STATUS_REQ (0x1A)
      // (주) CureStream APP 에서는 삽입 상태 요청 버튼이 없으므로 이 메시지를 사용하지 않고,
      // 안전 점검이 종료되면 패치에서 자동으로 캐뉼라 삽입 보고를 수행한다.
      // 캐뉼라 삽입 상태 요청 (앱  패치 장치): CANNULAR_STATUS (0x79)
      // 송신 조건: 사용자가 앱에서 “바늘 삽입 점검” 버튼을 클릭하면 패치로 본 메시지가 송신된다.
      // Length 2, CMD: 0x1A
      // DATA (1 byte): Reserved field for future use
      // RPT	DATA
      // 0x1A	0x00
      //
      // Action: 본 메시지를 수신한 패치는 캐뉼라 인지 상태 플래그를 보고 RESULT 값을 설정하여
      // 앱으로 1.9항의 캐뉼라 삽입 보고 (CANNULAR_INSERT_RPT) 메시지를 송신한다.
      // 캐뉼라 삽입 보고 메시지의 결과치가 실패로 오는 경우,
      // 앱은 경고 부저를 울리고 바늘 삽입 실패 내용과 부착 중인 패치를 폐기하라는
      // 알림 팝업을 띄워 부착 실패한 패치의 페기를 유도한다.
      final sendBytes = <int>[CareLevoCmd.CANNULAR_STATUS_REQ, 0x00];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send cannular status request !!');
          TXErrorMsg = mContext.l10n.sendingCannularStatusNotAvailable;
          // 'Requesting cannular status is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendCannularStatusRequest: $e');
    }
  }

  /*
   * @brief send discard patch request
   */
  @override
  Future<void> sendDiscardPatch(BluetoothCharacteristic? characteristic) async {
    // TODO: implement sendDiscardPatch
    try {
      final sendBytes = <int>[CareLevoCmd.PATCH_DISCARD_REQ];

      ///< 0x36
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send discard patch request !!');
          TXErrorMsg = mContext.l10n.sendingDiscardPatchNotAvailable;
          //  'Sending discard patch request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendDiscardPatch: $e');
    }
  }

  /*
   * @brief send reset patch request
   */
  Future<void> sendResetPatch(
    int mode,
    BluetoothCharacteristic? characteristic,
  ) async {
    final sendBytes = <int>[CareLevoCmd.PATCH_RESET_REQ, mode];

    ///< 0x3F
    if (characteristic != null) {
      await characteristic.write(sendBytes);
    } else {
      if (_PumpTxCharacteristic != null) {
        if (USE_FORCE_ENABE_RXNOTIFY) {
          SetForceRXNotify();
        }
        await _PumpTxCharacteristic!.write(sendBytes);
      } else {
        log('${TAG}Failed to send reset patch request !!');
        TXErrorMsg = mContext.l10n.sendingResetPatchRequestNotAvailable;
        // 'Sending reset patch request is not available at this time. Retry it?';
        showTXErrorMsgDlg = true;
      }
    }
  }

  /*
   * @brief send current Infusion status request
   * @param[in] type 0x00: current infusion status, 0x01: insulin remain amount
   */
  @override
  Future<void> sendInfusionInfoRequest(
    int type,
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendInfusionInfoRequest
    try {
      if (type < 0x00 || type > 0x03) {
        return;
      }

      final sendBytes = <int>[CareLevoCmd.INFUSION_INFO_REQ, type];

      ///< 0x31
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send Infusion Info Request !!');
          TXErrorMsg = mContext.l10n.sendingInfusionInfoRequestNotAvailable;
          // 'Sending Infusion Info Request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendInfusionInfoRequest: $e');
    }
  }

  /*
   * @brief send Mac address request
   */
  @override
  Future<void> sendMacAddrRequest(
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendMacAddrRequest
    try {
      final sendBytes = <int>[CareLevoCmd.MAC_ADDR_REQ];

      ///< 0x3b
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send Mac Address request !!');
          TXErrorMsg = mContext.l10n.sendingMacAddressRequestNotAvailable;
          // 'Sending Mac Address request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendMacAddrRequest: $e');
    }
  }

  /*
   * @brief send pump patch info request to the pump
   */
  @override
  Future<void> sendPumpPatchInfoRequest(
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendPumpPatchInfoRequest
    try {
      final sendBytes = <int>[CareLevoCmd.PATCH_INFO_REQ];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          debugPrint('${TAG}kai:send PATCH_INFO_REQ !!');

          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send PumpInfoRequest !!');
          TXErrorMsg = mContext.l10n.requestPatchInfoNotAvailable;
          //  'Requesting patch info. is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendPumpPatchInfoRequest: $e');
    }
  }

  /*
   * @brief send safety check request to pump
   */
  @override
  Future<void> sendSafetyCheckRequest(
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendSafetyCheckRequest
    try {
      //안전점검 요청 (스마트폰 앱  패치 장치): SAFETY_CHECK_REQ
      // 송신 조건: 새 패치 부착과정으로 앱에서 패치와 블루투스 연결 후,
      // 안내에 따라 패치 부착한 후에 앱 화면 하단의 안점점검 버튼을 누르면 본 메시지가 송신된다.
      // Length 1, CMD: 0x12
      // CMD
      // 0x12
      // Action: 안점점검 요청을 받으면 패치 장치는 인슐린을 주사바늘 입구까지 이동시키는 프라이밍(Priming) 작업을 시작한다.
      // 프라이밍 전에 안전 점검 과정으로 온도와 압력을 축정하여 사용 범위를 벗어 나면 안전 점검 실패로 안전 점검 완료 메시지를 송신한다.
      // 프라이밍 시는 압력 센서 기본 값 설정을 위해 펌프 구동 시 각 펄스 볼륨 별로 압력을 측정하여 초기 값을 저장한다.
      final sendBytes = <int>[CareLevoCmd.SAFETY_CHECK_REQ];
      // 최종 송신할 바이트 배열을 characteristic.write 메서드를 사용하여 전송
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send safety check request !!');
          TXErrorMsg = mContext.l10n.requestSafetyCheckNotAvailable;
          //  'Requesting safety check is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendSafetyCheckRequest: $e');
    }
  }

  /*
   * @brief send Bolus/Dose delivery value to the pump
   * @param[in] dataString : bolus dose value, example: 5.25U
   * @param[in] mode : total dose injection(0x00), (Correction Bolus) 0x01, (Meal bolus) 0x02
   */
  @override
  Future<void> sendSetDoseValue(
    String value,
    int mode,
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendSetDoseValue
    try {
      // 송신조건: “HCLBy APP” 모드에서 기저와 볼러스 주입이 통합된 자동 모드에서 주입할 인슐린 총량을 주입하기위해 사용된다.
      // 송신 조건2: “HCL By App” 모드에서 교정 볼러스 주입 제어 알고리즘에 의한 교정 볼러스 계산기 주입 값을
      // 가감한 최종 교정 볼러스 주입량이 있으면 본 메시지를 패치로 전송한다.
      // Length 4, REQ: 0x67
      // Mode (1 byte): HCL 통합 주입(0x00).
      //               교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
      // 주입량 (2 byte): DOSE_I (정수), DOSE_D (소수점 X 100)
      // Ex) 5.25 U  0x05 0x19
      // 요청한 주입량이 사용자 설정한 최대 볼러스 량보다 크면 실패 (Cause 0x04 DATA_OVER_FLOW) 로 응답함 (HCL_BOLUS_RSP)
      // REQ	MODE	DOSE_I	DOSE_D
      // 0x67	0x00	0x05	0x19
      // 문자열을 바이트 배열로 변환
      // List<int> dataBytes = utf8.encode(dataString);
      // 0x67 뒤에 변환한 데이터 값을 추가하여 최종 송신할 바이트 배열 생성
      final sendBytes = <int>[CareLevoCmd.HCL_DOSE_REQ];
      // 0.05 값을 소숫점 앞자리 1 byte와 소숫점 뒷자리 1 byte로 변환하여 dataBytes에 추가
      if (!value.contains('.')) {
        // 입력된 문자열에 소수점이 없는 경우
        value = '$value.0';
      }
      final floatValue = double.parse(value);

      final intValue = floatValue.toInt(); // 정수 부분을 추출합니다.
      final decimalValue = floatValue - intValue; // 소수 부분을 추출합니다.
      final DOSEI = intValue & 0xFF; // 정수 부분의 마지막 1바이트를 추출합니다.
      final DOSED =
          (decimalValue * 100).toInt() & 0xFF; // 소수 부분의 마지막 1바이트를 추출합니다.
      sendBytes.addAll([mode, DOSEI, DOSED]);
      /*
        int intValue = (floatValue * 100).round();
        sendBytes.addAll([mode,intValue >> 8, intValue & 0xFF]);
         */

      // 2023-04-10 17:52:13 값을 각각 1 byte로 변환하여 dataBytes에 추가
      //String dateTimeString = '2023-04-10 17:52:13';
      // 전송할 현재 시간 정보를 얻어온다
      /*String dateTimeString = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
        DateTime dateTime = DateTime.parse(dateTimeString);
        int year = dateTime.year - 2000;
        int month = dateTime.month;
        int day = dateTime.day;
        int hour = dateTime.hour;
        int minute = dateTime.minute;
        int second = dateTime.second;
        sendBytes.addAll([year, month, day, hour, minute, second]);
     */

      //kai_20240107 let's block setDose in case of injection is on going...
      if (isDoseInjectingNow) {
        NoticeMsg = mContext.l10n.blockSendSetDose;
        showNoticeMsgDlg = true;
        setResponseMessage(
          RSPType.NOTICE,
          NoticeMsg,
          '3',
        );
        return;
      }

      // 최종 송신할 바이트 배열을 characteristic.write 메서드를 사용하여 전송
      if (characteristic != null) {
        await characteristic.write(sendBytes);
        /////kai_20230427 update insulin delivery amount here
        //BolusDeliveryValue = value + 'U';
        //BolusDeliveryValue = floatValue;  /// U
        setBolusDeliveryValue(floatValue);
      } else {
        if (_PumpTxCharacteristic != null) {
          //kai_20230513 sometimes, app does not receive the response from Pump
          //due to RX characteristic's Notify is not enabled after reconnected
          //but actually Notify is disabled regardless of isNotifying is true
          //that's why we force to enable it here
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
          /////kai_20230427 update insulin delivery amount here
          // BolusDeliveryValue = value + 'U';
          // BolusDeliveryValue = floatValue;  /// U
          setBolusDeliveryValue(floatValue);
        } else {
          log('${TAG}Failed to send dose request !!');
          TXErrorMsg = mContext.l10n.sendingDoseRequestNotAvailable;
          // 'Sending dose request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendSetDoseValue: $e');
      NoticeMsg = mContext.l10n.sendingDoseRequestNotAvailable;
      showNoticeMsgDlg = true;
      setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
    }
  }

  /*
   * @breif set max bolus injection threshold
   * @param[in] value : input range: 0.5 ~ 25 U
   * @param[in] type  ; 0x01 Max injection amount
   */
  @override
  Future<void> sendSetMaxBolusThreshold(
    String value,
    int type,
    BluetoothCharacteristic? characteristic,
  ) async {
    var waitCallback = false;
    // Length 4, CMD: 0x17 TYPE: 최대 주입 량 (0x01)
    // Data (4 byte):
    // - TYPE: 최대 주입 량 설정 (0x01)
    // - 최대 볼러스 주입 량 (U, 2 byte: 정수+ 소수점 X 100) : 입력 범위 0.5 ~ 25 U
    // Ex) 5.5 U  0x05 0x32
    //
    // CMD	TYPE	MAX_DI	MAX_DD
    // 0x17	0x01	0x05	0x32
    //
    // Action: 패치는 최대 볼러스 주입 량를 갱신한다.
    // 볼러스 주입  연장 볼러스 주입 실행 시 최대 볼러스 주입 량 임계치 이하인지 확인 후 실행한다.
    // 임계치 확인은 인슐린 과다 주입에 의한 저 혈당 쇼크를 방지하기 위해 반드시 필요한 기능이다.
    final sendBytes = <int>[CareLevoCmd.INFUSION_THRESHOLD_REQ];
    // 0.05 값을 소숫점 앞자리 1 byte와 소숫점 뒷자리 1 byte로 변환하여 sendBytes에 추가

    try {
      if (!value.contains('.')) {
        // 입력된 문자열에 소수점이 없는 경우
        value = '$value.0';
      }
      final floatValue = double.parse(value);
      /* int MAX_DI = (floatValue / 100).toInt();
      int MAX_DD = (floatValue % 100).toInt();
      */
      final intValue = floatValue.toInt(); // 정수 부분을 추출합니다.
      final decimalValue = floatValue - intValue; // 소수 부분을 추출합니다.
      final MAXDI = intValue & 0xFF; // 정수 부분의 마지막 1바이트를 추출합니다.
      final MAXDD =
          (decimalValue * 100).toInt() & 0xFF; // 소수 부분의 마지막 1바이트를 추출합니다.
      // List<int> buff = [MAX_DI, MAX_DD]; // 두 개의 바이트를 리스트로 묶어줍니다.
      sendBytes.addAll([type, MAXDI, MAXDD]);
      if (characteristic != null) {
        await characteristic.write(sendBytes);
        waitCallback = true;
      } else {
        if (_PumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          await _PumpTxCharacteristic!.write(sendBytes);
          waitCallback = true;
        } else {
          log(
            '${TAG}Failed to send set max bolus injection amount request !!',
          );
          TXErrorMsg = mContext.l10n.requestMaxDoseInjectionNotAvailable;
          // 'Requesting max bolus injection amount setting is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }

      // set timer with 5 secs here to check we got the response sent from pmp
      if (waitCallback == true) {
        Future.delayed(Duration(seconds: SET_TIME_RSP_TIMEOUT), () {
          if (!INFUSION_THRESHOLD_RSP_responseReceived) {
            // 응답이 오지 않았을 경우 처리
            log(
              "${TAG}INFUSION_THRESHOLD_RSP Response not received!!; let's try to send INFUSION_THRESHOLD_REQ again!! ",
            );
            INFUSION_THRESHOLD_RSP_retryCnt += 1;
            if (INFUSION_THRESHOLD_RSP_retryCnt < MAX_RETRY) {
              sendSetMaxBolusThreshold(value, type, characteristic);
            } else {
              log(
                '${TAG}INFUSION_THRESHOLD_RSP Response not received : retry failed!!; timeout!! ',
              );
              INFUSION_THRESHOLD_RSP_retryCnt = 0;

              ///< clear
              INFUSION_THRESHOLD_RSP_responseReceived = false;

              ///< clear
            }
          } else {
            log('${TAG}INFUSION_THRESHOLD_RSP Response received!! ');
            INFUSION_THRESHOLD_RSP_retryCnt = 0;

            ///< clear
            INFUSION_THRESHOLD_RSP_responseReceived = false;

            ///< clear

          }
        });
      }
    } on FormatException catch (e) {
      log(
        '${TAG}Error: Invalid float format or cannot convert string to float. Details: $e',
      );
    } catch (e) {
      log('${TAG}Error: An unexpected error occurred. Details: $e');
    }
  }

  /*
   * @brief send message to the Pump device
   */
  @override
  Future<void> sendDataToPumpDevice(String data) async {
    // TODO: implement sendDataToPumpDevice
    try {
      // Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      final bytes = data.codeUnits;
      if (USE_FORCE_ENABE_RXNOTIFY) {
        SetForceRXNotify();
      }
      await _PumpTxCharacteristic!.write(bytes);
    } catch (e) {
      debugPrint(TAG + '>>Error sendDataToPumpDevice: $e');
      LogMessageView = '>>Error sendDataToPumpDevice: $e';
      NoticeMsg = LogMessageView;
      showNoticeMsgDlg = true;
      // setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
      setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
    }
  }

  @override
  void registerPumpBatLvlValueListener(Function(List<int> p1) listener) {
    // TODO: implement registerPumpBatLvlValueListener
    if (_PumpRXBatLvlCharacteristic != null) {
      _pumpBatValueSubscription =
          _PumpRXBatLvlCharacteristic!.value.listen((value) {
        listener(value);
      });
    } else {
      debugPrint(
        '${TAG}registerPumpBatLvlValueListener():_PumpRXBatLvlCharacteristic is NULL',
      );
    }
  }

  @override
  void registerPumpStateCallback(
    void Function(BluetoothDeviceState p1) callback,
  ) {
    // TODO: implement registerPumpStateCallback
    if (_ConnectedDevice == null) {
      debugPrint('${TAG}registerPumpStateCallback():_pumpDevice is NULL');
    } else {
      debugPrint('registerPumpStateCallback():is called');
      mPumpconnectionSubscription = _ConnectedDevice!.state.listen(callback);
    }
  }

  @override
  void registerPumpValueListener(Function(List<int> p1) listener) {
    // TODO: implement registerPumpValueListener
    if (_PumpRxCharacteristic != null) {
      _pumpValueSubscription = _PumpRxCharacteristic!.value.listen((value) {
        listener(value);
      });
    } else {
      debugPrint(
        '${TAG}registerPumpValueListener():_PumpRxCharacteristic is NULL',
      );
    }
  }

  @override
  void unregisterPumpBatLvlValueListener() {
    // TODO: implement unregisterPumpBatLvlValueListener
    debugPrint('${TAG}unregisterPumpBatLvlValueListener():is called');
    if (_pumpBatValueSubscription != null) {
      _pumpBatValueSubscription!.cancel();
      _pumpBatValueSubscription = null;
    }
  }

  @override
  void unregisterPumpStateCallback() {
    // TODO: implement unregisterPumpStateCallback
    debugPrint('${TAG}unregisterPumpStateCallback():is called');
    mPumpconnectionSubscription?.cancel();
    mPumpconnectionSubscription = null;
  }

  @override
  Future<void> unregisterPumpValueListener() async {
    // TODO: implement unregisterPumpValueListener
    debugPrint('${TAG}unregisterPumpValueListener():is called');
    if (_pumpValueSubscription != null) {
      await _pumpValueSubscription!.cancel();
      _pumpValueSubscription = null;
    }
  }

  @override
  Future<void> pumpBatteryNotify() async {
    // TODO: implement pumpBatteryNotify
  }

  @override
  void pumpConnectionStatus(BluetoothDeviceState state) {
    // TODO: implement pumpConnectionStatus to monitor the connection status change event
    if (_ConnectionStatus == state) {
      // if connection status is same then ignore
      return;
    }

    switch (state) {
      case BluetoothDeviceState.connected:
        {
          _ConnectionStatus = state;
          debugPrint('${TAG}kai:Connected to pump');

          //let's set timer after 5 secs trigger to check RX characteristic and battery Notify
          Future.delayed(const Duration(seconds: 5), () async {
            //if _pumpValueSubscription is not registered then register here
            if (_pumpValueSubscription == null) {
              debugPrint(
                '${TAG}kai: register RX_Read characteristic for value listener due to auto reconnection ',
              );
              if (_PumpRxCharacteristic != null) {
                registerPumpValueListener(handlePumpValue);
                if (!_PumpRxCharacteristic!.isNotifying) {
                  debugPrint(
                    '${TAG}kai: register RX_Read characteristic set Notify due to auto reconnection ',
                  );
                  if (isSetNotifyFailed == true) {
                    await _PumpRxCharacteristic!.setNotifyValue(true);
                    isSetNotifyFailed = false;
                  }
                } else {
                  debugPrint(
                    '${TAG}kai: register RX_Read characteristic  Notify already enabled: due to auto reconnection ',
                  );
                  if (isSetNotifyFailed == true) {
                    await _PumpRxCharacteristic!.setNotifyValue(true);
                    isSetNotifyFailed = false;
                  }
                }
              }
            }
          });
        }
        break;

      case BluetoothDeviceState.connecting:
        _ConnectionStatus = state;
        debugPrint('${TAG}Connecting from pump');
        break;

      case BluetoothDeviceState.disconnected:
        {
          _ConnectionStatus = state;
          //kai_20230621 need to update status
          notifyListeners();
          setResponseMessage(
            RSPType.UPDATE_SCREEN,
            'disconnected',
            'DISCONNECT_FROM_DEVICE_PUMP',
          );
          debugPrint('${TAG}Disconnected from pump');
          // kai_20230205 let's clear used resource and unregister used listener here
          if (_PumpScanningSubscription != null) {
            _PumpScanningSubscription!.cancel();
            _PumpScanningSubscription = null;

            ///< scan result listener
          }

          if (mPumpconnectionSubscription != null) {
            // mPumpconnectionSubscription!.cancel();
            ///< connection status listener
            unregisterPumpStateCallback();
          }

          if (_PumpRxCharacteristic != null) {
            //  _PumpRxCharacteristic!.value.listen((event) {}).cancel();
            //  _PumpRxCharacteristic = null;
            ///< value change listener
            unregisterPumpValueListener();
          }

          if (_PumpRXBatLvlCharacteristic != null) {
            // _PumpRXBatLvlCharacteristic!.value.listen((event) {}).cancel();
            // _PumpRXBatLvlCharacteristic = null;
            ///< battery level value change listener
            unregisterPumpBatLvlValueListener();
          }
        }
        break;

      case BluetoothDeviceState.disconnecting:
        _ConnectionStatus = state;
        debugPrint('${TAG}Disconnecting from pump');
        break;
    }
  }

  @override
  void handlePumpValue(List<int> value) {
    // TODO: must implement handlePumpValue here to handle the received data sent from the pump device.
    if (value == null || value.isEmpty) {
      return;
    }

    final pumpname = CspPreference.mPUMP_NAME.isEmpty
        ? serviceUUID.CSP_PUMP_NAME
        : CspPreference.mPUMP_NAME;
    debugPrint('${TAG}kai:handlePumpValue:current set pump name = $pumpname');
    switch (pumpname) {
      case serviceUUID.CareLevo_PUMP_NAME:
        handleCaremediPump(value);
        break;

      case serviceUUID.CSP_PUMP_NAME:
        handleCsp1Pump(value);
        break;

      case serviceUUID.DANARS_PUMP_NAME:
        handleDanaiPump(value);
        break;

      case serviceUUID.Dexcom_PUMP_NAME:
        break;

      default:
        break;
    }
  }

  //=====================   extra functions  ===================================//
  /*
   * @brief check received data is encoded by using ascii
   */
  bool isAscii(List<int> bytes) {
    for (final byte in bytes) {
      if (byte < 0x00 || byte > 0x7f) {
        return false;
      }
    }
    return true;
  }

  /*
   * @brief convert byte to hex
   */
  String toHexString(int byte) {
    return byte.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  //=======================  parser for the received data ======================//

  /*
   * @brief handler to parse the received data sent from the connected pump patch device
   */
  void handleDanaiPump(List<int> value) {}

  void handleCsp1Pump(List<int> value) {
    handleCaremediPump(value);
  }

  void handleCaremediPump(List<int> value) {
    // handle pump value
    if (value == null || value.isEmpty || value.isEmpty) {
      // 예외 처리
      log(
        '${TAG}kai: handleCaremediPump(): cannot handle due to no input data,  return',
      );
      return;
    }

    final LENGTH = value.length;
    final hexString = value.map(toHexString).join(' ');
    final decimalString = value
        .map((hex) => hex.toRadixString(10))
        .join(' '); // 10진수로 변환하고 join으로 스트링으로 변환
    if (USE_DEBUG_MESSAGE) {
      log('${TAG}kai: data length = $LENGTH');
      log('${TAG}kai : hexString value = $hexString');
      log('${TAG}kai : decimalString value = $decimalString');
    }

    // Process decoded string
    final buffer = List<int>.from(value);
    final code = buffer[0];
    log('${TAG}handleCaremediPump is called : code = $code');

    switch (code) {
      case CareLevoCmd.SET_TIME_RSP:

        ///< 0x71
        {
          //Result (1 byte): SUCCESS 0, FAIL 1
          if (buffer[1] == 0) {
            SET_TIME_RSP_responseReceived = true;
            log('${TAG}SET_TIME_RSP: success: ');
            SetUpWizardMsg = mContext.l10n
                .setTimeRequestComplete; //'Set time request is complete!!';
            SetUpWizardActionType = 'SET_TIME_RSP_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              SET_TIME_RSP_SUCCESS,
            );
            //let's send SAFETY_CHECK_REQ here
            //kai_20230926 added
            CspPreference.setBool(CspPreference.pumpSetTimeReqDoneKey, true);
          } else {
            SET_TIME_RSP_responseReceived = true;
            log('${TAG}SET_TIME_RSP: failed: ');
            SetUpWizardMsg = mContext.l10n
                .setTimeRequestComplete; //'Set time request is complete!!';
            SetUpWizardActionType = 'SET_TIME_RSP_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              SET_TIME_RSP_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.PATCH_INFO_RPT1:
        {
          // . 송신 조건:
          // 조건 1) 패치 정보 조회 요청을 받으면 패치 정보보고 메시지 1,2 로 나누어
          // 모델명, 로트번호, 그리고 제조번호, 펌웨어 버전, 패치 시작 시간을 보고한다.
          // 조건 2) 패치가 앱과 연결된 후 현재 첫 메시지인 “시간 설정 요청 (SET_TIME_REQ)” 메시지를 수신하여
          // 날자와 시간을 설정한 후 응답 메시지를 보내고, 이후 즉시 미리 패치 정보보고 메시지1,2를 차례로 송신한다.
          // 즉 미리 패치의 모델명, 로드번호, 제조번호, 펌웨어 버전, 부팅 시간 정보를 앱으로 송신한다.
          //  . Length 16, RPT1 0x93,
          //    Result (1 byte): SUCCESS 0, FAIL 1 (정보 없음)
          //  . Data (14 byte):
          //     모델명 (6 byte, ascii): ex) CM100K  0x43 0x4D 0x31 0x30 0x30 0x4B
          //     로트 번호 (8 byte, ascii): ex) CM210901  0x43 0x4d 0x32 0x31 0x30 0x39 0x30 0x30
          // RPT	RSLT	MD1	MD2	MD3	MD4	MD5	MD6	LN1	LN2	LN3	LN4	LN5
          // 0x93	0x00	0x43	0x4D	0x31	0x30	0x30	0x4B	0x43	0x4D	0x32	0x31	0x30
          // LN6	LN7	LN8
          // 0x39	0x30	0x30
          // . Action: SUCCESS Result로 본 메시지를 수신하면 앱은 패치 정보를 표시하고,
          // FAIL 로 수신한 경우는 각 패치 정보에 “NO Data” 로 표시한다.
          // 시간 정보 설정 시 수신한 패치 정보는 앱에서 미리 저장하였다가,
          // 사용자가 메뉴에서 요청 시 새로 요청하지 않고 기 저장된 정보로 표시한다.
          if (buffer[1] == 0) {
            var subList = value.sublist(2, 8);

            ///< 모델명 (6 byte, ascii)
            final modelName = ascii.decode(subList);

            ///<
            subList = value.sublist(8);

            ///< 모델명 (6 byte, ascii)
            final rootNumber = ascii.decode(subList);

            ///< lot number : product code + manufactured date : CS230926
            /*
              String modelName = data.substring(2,8); ///< length 6 byte  : 2 ~ 7
              String rootNumber = data.substring(8 /*,15 */); ///< length 8 byte
               */
            //kai_20230427 let's update infoms.
            _ModelName = modelName.toString();
            VC = rootNumber.toString();
            notifyListeners();

            log(
              '${TAG}PATCH_INFO_RPT1:Model = $modelName, routeNumber = $rootNumber',
            );
            SetUpWizardMsg =
                '${mContext.l10n.patchInfoModel} = $modelName, ${mContext.l10n.routeNumber} = $rootNumber';
            // 'Patch Info: Model = $modelName, routeNumber = $rootNumber';
            SetUpWizardActionType = 'PATCH_INFO_RPT1_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_INFO_RPT1_SUCCESS,
            );
          } else {
            log('${TAG}PATCH_INFO_RPT1:failed: No Data !!');
            SetUpWizardMsg = mContext.l10n.patchInfoRequestNotComplete;
            // 'Patch Info request is not complete at this time.\nRetry it later!!';
            SetUpWizardActionType = 'PATCH_INFO_RPT1_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_INFO_RPT1_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.PATCH_INFO_RPT2:
        {
          //  . Length 18, RPT 0x94,
          //    Result (1 byte): SUCCESS 0, FAIL 1 (정보 없음)
          //  . Data (30 byte):
          //
          //     모델명 (6 byte, ascii): ex) CM100K  0x43 0x4D 0x31 0x30 0x30 0x4B
          //     로트 번호 (8 byte, ascii): ex) CM210901  0x43 0x4d 0x32 0x31 0x30 0x39 0x30 0x30
          //     제조 번호 (8 byte, ascii): ex) 21000001  0x32 0x31 0x30 0x30 0x30 0x30 0x30 0x31
          //     펌웨어 버전 (3 byte, ascii): ex) 2.3.0  0x32 0x33 0x30
          //     부팅 날짜/시간 (5 byte, integer): ex) 2021. 11.30, 09: 23  0x15 0x0b 0x1e, 0x09 0x17
          // RPT	RSLT	MN1	MN2	MN3	MN4	MN5	MN6	MN7	MN8
          // 0x94	0x00	0x32	0x31	0x30	0x30	0x30	0x30	0x30	0x31
          //
          // VER1	VER2	VER3	YEAR	MON	DAY	HOUR	MIN
          // 0x32	0x33	0x30	0x15	0x0b	0x1e	0x09	0x17
          //
          // . Action: SUCCESS Result로 본 메시지를 수신하면 앱은 패치 정보를 표시하고,
          // FAIL 로 수신한 경우는 각 패치 정보에 “NO Data” 로 표시한다.
          // 시간 정보 설정 시 수신한 패치 정보는 앱에서 미리 저장하였다가,
          // 사용자가 메뉴에서 요청 시 새로 요청하지 않고 기 저장된 정보로 표시한다.
          if (buffer[1] == 0) {
            var subList = value.sublist(2, 10);

            ///< 제조 번호 (8 byte, ascii)
            final sn = ascii.decode(subList);

            ///< 펌웨어 버전 (3 byte, ascii) >
            subList = value.sublist(10, 11);

            ///< maj (1 byte, ascii)
            final fwMaj = ascii.decode(subList);
            subList = value.sublist(11, 12);

            ///< minor (1 byte, ascii)
            final fwMir = ascii.decode(subList);
            subList = value.sublist(12, 13);

            ///< patch (1 byte, ascii)
            final fwPatch = ascii.decode(subList);

            ///< 부팅 날짜/시간 (5 byte, integer): ex) 2021. 3011., 09: 23  0x15 0x0b 0x1e, 0x09 0x17 >
            subList = value.sublist(13, value.length);
            final bootTimeDate =
                subList.map((hex) => hex.toRadixString(10)).join(' ');
            log(
              '${TAG}bootTimeDate = $bootTimeDate',
            ); //decimalString have 2bytes characters, so we  put index per 2 bytes

            final year = subList[0].toInt();
            final month = subList[1].toInt();
            final day = subList[2].toInt();
            final hour = subList[3].toInt();
            final minute = subList[4].toInt();

            //kai_20230427 let's update informs.  fw, serial number, first connected Timedate here
            fw = '$fwMaj.$fwMir.$fwPatch';
            SN = sn.toString();
            final ConnectedTimeString = '20$year/$month/$day $hour:$minute:00';
            // DateTime dateTime = DateTime.parse(ConnectedTimeString); // 문자열을 DateTime으로 변환
            //int timeInMilliseconds = dateTime.millisecondsSinceEpoch; // DateTime을 밀리 초로 변환
            ConnectedTime = timeToMilliseconds(hour, minute, 0);
            notifyListeners();
            /*  convert example reverse case
                int timeInMilliseconds = 1684099037000;
                DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeInMilliseconds);
                String formattedDate = "${dateTime.year}/${_addLeadingZero(dateTime.month)}/${_addLeadingZero(dateTime.day)} ${_addLeadingZero(dateTime.hour)}:${_addLeadingZero(dateTime.minute)}:${_addLeadingZero(dateTime.second)}";
               log(formattedDate); // 출력: "2023/04/29 16:17:17"
             */

            //kai_20230427  save info periodically here
            LogMessageView =
                'model name:$_ModelName, serial number:$SN\nfirmware version:$fw, routeNumber:$VC\nfirst connection time:$ConnectedTimeString\n';
            /*  LogMessageView = '모델명:' + _ModelName + ', 제조번호:' + SN + '\n'
                + '펌웨어버전:' + fw + ', 루트번호:' + VC + '\n'
                + '최초연결시간:' + ConnectedTimeString + '\n'; */
            //notifyListeners();

            debugPrint(
              '${TAG}PATCH_INFO_RPT2:SN = $sn, f/w ver. = $fwMaj.$fwMir.$fwPatch Booting TimeDate = 20$year/$month/$day $hour:$minute',
            );

            SetUpWizardMsg =
                '${mContext.l10n.patchInfo}: ${mContext.l10n.serialNumber} = $sn, ${mContext.l10n.firmwareVersion} = $fwMaj.$fwMir.$fwPatch ${mContext.l10n.bootingTimeDate} = 20$year/$month/$day $hour:$minute';
            //'Patch Info: SN = $sn, f/w ver. = $fwMaj.$fwMir.$fwPatch Booting TimeDate = 20$year/$month/$day $hour:$minute';
            SetUpWizardActionType = 'PATCH_INFO_RPT2_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_INFO_RPT2_SUCCESS,
            );

            //let's send THRESHOLD_SETUP_REQ(0x17)  when we get this response from pump
            //actually this operation should be proceed by user action thru setting option UI
            //let's send THRESHOLD_SETUP_REQ(0x17)  when we get this response from pump
            if (_USE_TEST_SET_MAX_BOLUS_THRESHOLD == true) {
              var maxValue = CspPreference.getString(
                  CspPreference.pumpMaxInfusionThresholdKey);
              log(
                '${TAG}kai: call sendSetMaxBolusThreshold($maxValue, 0x01, NULL)',
              );
              if (maxValue == null || maxValue.isEmpty || maxValue.isEmpty) {
                maxValue = '25';
              }
              sendSetMaxBolusThreshold(maxValue, 0x01, null);
            } else {
              SetUpWizardMsg =
                  '${mContext.l10n.pleaseTypeMaxInsulinInjection}:0.5 ~ 25U';
              //'Please type the maximum insulin injection to patch.\nAvailable range: 0.5 ~ 25U';
              SetUpWizardActionType = 'INFUSION_THRESHOLD_REQ';
              showSetUpWizardMsgDlg = true;
              setResponseMessage(
                RSPType.SETUP_INPUT_DLG,
                SetUpWizardMsg,
                INFUSION_THRESHOLD_REQ,
              );
            }
          } else {
            log('${TAG}PATCH_INFO_RPT2:failed: No Data !!');
            SetUpWizardMsg = mContext.l10n.patchInfoSecondRequestNotComplete;
            //  'Patch Info second request is not complete at this time.\nRetry it later!!';
            SetUpWizardActionType = 'PATCH_INFO_RPT2_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_INFO_RPT2_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.SAFETY_CHECK_RSP:

        ///< 0x72 상태 체크 응답
        {
          //Length 4, RSP: 0x72,
          // . Result: SUCCESS 0, 인슐린 부족 1, 펌프 이상 2, 전압 낮음 3, 안전 점검 요청 응답 4
          //  (주) 패치는 안전 점검 요청 메시지에 대한 수신 응답으로 result 0x04 로 즉시 보내며, 안전 점검 종료 후에 다시 성공/실패 원인 값으로 다시 응답 메시지를 보낸다.
          //
          // . 채워진 인슐린 총량(2byte): (100 U ~ 300 U: 3mL) -> 100단위, 10단위
          //  ex) 300 U (3mL)  0x03, 00x00 / 250U (2mL)  0x02, 0x32
          // ㈜ 1 U: 인슐린 주입 기본 단위로 1 U = 10 uL (마이크로 리터임 = 0.01mL)
          //
          // RSP	RSLT	IN_VOL1	IN_VOL2
          // 0x72	0x00	0x02	0x32
          //
          // . Action: 패치 장치는 프라이밍 진행 후 센서가 인식한 채워진 인슐린 총량 값을 응답메시지에 추가하여 전송한다.
          // (cf, 패치에서 센싱이 안되면, 앱에서 사용자가 입력하게 변경해야 함).
          // 이 후 패치는 이 총량 값에서 주입이 진행될 때 마다 토출량을 차감하여 잔여량을 계산, 보관한다.
          //  수신 받은 앱은 이 값을 첫 상태 표시 화면의 인슐린 잔여량에 표시한다.
          if (buffer[1] == 0) {
            final divider100 = buffer[2].toInt() * 100;
            final remain10to1 = buffer[3].toInt();
            final ReservoirAmount = divider100 + remain10to1;
            final RAmL = ReservoirAmount / 100;
            log(
              '${TAG}SAFETY_CHECK_RSP:Reservoir = ${ReservoirAmount}U, (${RAmL}mL)',
            );
            //kai_20230427 let's update infoms.
            reservoir = ReservoirAmount.toString();
            notifyListeners();

            //let's update received value to the reservoir amount here
            SetUpWizardMsg =
                '${mContext.l10n.checkSafetyCompleteReservior} = ${ReservoirAmount}U, (${RAmL}mL)';
            //  'Check Safety request is complete.\nReservoir = ${ReservoirAmount}U, (${RAmL}mL)';
            SetUpWizardActionType = 'SAFETY_CHECK_RSP_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              SAFETY_CHECK_RSP_SUCCESS,
            );
          } else if (buffer[1] == 1) {
            reservoir = 'Low insulin!!';
            notifyListeners();
            log('${TAG}SAFETY_CHECK_RSP:1 Low insulin !!');
            SetUpWizardMsg = mContext.l10n
                .checkSafetyNotCompleteLowInsulin; //'Check Safety is not complete:Low insulin!!';
            SetUpWizardActionType = 'SAFETY_CHECK_RSP_LOW_INSULIN';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              SAFETY_CHECK_RSP_LOW_INSULIN,
            );
          } else if (buffer[1] == 2) {
            log('${TAG}SAFETY_CHECK_RSP:2 Abnormal Pump !!');
            SetUpWizardMsg = mContext.l10n
                .checkSafetyNotCompleteAbnormalPump; //'Check Safety is not complete:Abnormal Pump!!';
            SetUpWizardActionType = 'SAFETY_CHECK_RSP_ABNORMAL_PUMP';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              SAFETY_CHECK_RSP_ABNORMAL_PUMP,
            );
          } else if (buffer[1] == 3) {
            _Battery = 'Low Battery !!';
            notifyListeners();
            log('${TAG}SAFETY_CHECK_RSP:3 Low voltage !!');
            SetUpWizardMsg = mContext.l10n
                .checkSafetyNotCompleteLowVoltage; //'Check Safety is not complete:Low voltage!!';
            SetUpWizardActionType = 'SAFETY_CHECK_RSP_LOW_VOLTAGE';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              SAFETY_CHECK_RSP_LOW_VOLTAGE,
            );
          } else if (buffer[1] == 4) {
            log('${TAG}SAFETY_CHECK_RSP:4 1st response !!');
            SetUpWizardMsg = mContext.l10n.gotResponseFirstSafetyCheck;
            //  'Got response for the First Check Safety Request!!';
            SetUpWizardActionType = 'SAFETY_CHECK_RSP_GOT_1STRSP';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              SAFETY_CHECK_RSP_GOT_1STRSP,
            );
          } else {
            log('${TAG}SAFETY_CHECK_RSP: failed !!');
            SetUpWizardMsg = mContext.l10n.noResopnseSafetyCheck;
            //  'There is no response for Check Safety Request at this time!!';
            SetUpWizardActionType = 'SAFETY_CHECK_RSP_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              SAFETY_CHECK_RSP_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.INFUSION_THRESHOLD_RSP:

        ///< 0x77
        {
          //인슐린 주입 임계치 설정 완료 (패치 장치  스마트폰 앱): INFUSION_THRESHOLD_RSP
          //  . Length 3, RSP: 0x77
          // . Result (1 byte): SUCCESS 0, FAIL 1
          //
          // RSP	TYPE	RSLT
          // 0x77	0x01	0x00
          if (buffer[2] == 0) {
            INFUSION_THRESHOLD_RSP_responseReceived = true;
            log(
              '${TAG}INFUSION_THRESHOLD_RSP:set bolus max injection threshold success !!',
            );

            //let's send Safety check request here
            if (_USE_TEST_SET_MAX_BOLUS_THRESHOLD == true) {
              log('${TAG}kai: call sendSafetyCheckRequest(null)');
              sendSafetyCheckRequest(null);
            } else {
              SetUpWizardMsg = mContext.l10n.performInfusionThresholdPriming;
              //  'Please perform a safety check for pump condition and air removal.\nProceed it?';
              // 펌프 상태, 공기 제거를 위한 안전 점검을 진행해 주세요
              SetUpWizardActionType =
                  'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST';
              showSetUpWizardMsgDlg = true;
              setResponseMessage(
                RSPType.SETUP_DLG,
                SetUpWizardMsg,
                INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST,
              );
            }
          } else {
            INFUSION_THRESHOLD_RSP_responseReceived = true;
            log(
              '${TAG}INFUSION_THRESHOLD_RSP:set bolus max injection threshold failed !!',
            );
            SetUpWizardMsg =
                mContext.l10n.setBolusMaxInjectionThresholdNotComplete;
            //  'set bolus max injection threshold is not complete at this time.\nRetry it later!!';
            SetUpWizardActionType = 'INFUSION_THRESHOLD_RSP_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              INFUSION_THRESHOLD_RSP_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.INFUSION_INFO_RPT:
        {
          /// 송신 조건:
          /// case 1) 주입 현황 요청 메시지 수신 시
          //  Case 2) 앱과 블루투스가 재 연결된 경우 본 메시지를 앱으로 송신한다.
          // Length 20, RPT: 0x91,
          // Sub ID: 주입 현황 요청 응답(0x00), 잔여량 요청 응답(0x01), 30분단위 보고 (0x02), 재 연결 보고(0x03)
          // 패치 사용 시간 2 byte (hr, min) – ex) 23 hr 59 min  0x17 0x3b
          // 인슐린 잔여량 3 byte(정수1 (100단위), 정수2 (10~1 단위), 소수점)
          // ex) 145.85 U  0x01 0x2d 0x55
          // 오늘 총 주입량 4 byte: 기저 총 주입량 (2 byte)정수, 소수점
          //                       ex) 8.20 U  0x08 0x14
          //                      볼러스 총 주입량 (2 byte)정수, 소숫점
          //                       ex) 34.15 U   0x22 0x0f
          // ㈜ 인슐린 잔여량 값은 300U 이상 패치 개발을 고려하여 2 바이트에서 3 바이트로 확장 설계함
          // 펌프 상태 (1 byte): 펌프 대기 0, 프라이밍 1, 펌프 구동 중  2, 펌프 고장 3
          // ㈜ 펌프 상태가 주입 중 (0) 인 경우만 아래 5 바이트, 주입 모드 및 주입 경과 시간 존재함
          // 주입 모드 (1 byte): 기초 1, 일시 기초 2, 즉시 볼러스(교정볼러스 포함) 3, 연장 볼러스 4
          // 모드별 주입 데이터: 주입 데이터는 주입 속도 위주 모드와 총 주입량 위주 모드로 분류됨
          //
          //  Case 1) 기초/임시기저/연장 볼러스 주입 (8 byte):
          //  . 주입모드 별 주입 기간 (2 byte): 시 (TIME1), 분 (TIME2)
          // Ex) 2시간 30분 -> 0x02, 0x1E
          // . 기저 주입량 (BU_I, BU_D 소수점 X 100)
          //               Ex) 32.25 U -> 0x1E, 0x19
          // . 주입 경과 시간 (시 BA_H, 분 BA-M, 초 BA_S)
          //               Ex) 경과 시간 1시간 30분 20초    0x01 0x1E, 0x14
          //
          // RPT	Sub ID	T_H	T_M	RU_I1	RU_I2	RU_D	BAU_I	BAU_D	BOU_I	BOU_D
          // 0x91	0x00	0x17	0x3b	0x01	0x2d	0x55	0x08	0x14	0x22	0x0f
          //
          // P_ST	MD	TIME1	TIME2	BU_I	BU_D	BA_H 	BA_M   	BA_S
          // 0x00	0x02	0x02	0x1E	0x1E	0x14	0x01	0x1E	0x00
          //
          // Case 2) 즉시 볼러스 주입 (5 byte):
          // . 볼러스 주입 소요 기간 (2 byte):  분 (TIME1), 초 (TIME2)
          // Ex) 10분 20초 소요  -> 0x00, 0x0A, 0x14
          // . 볼러스 주입량 (BU_I, BU_D 소수점 X 100)
          //               Ex) 32.25 U -> 0x1E, 0x19
          // . 볼러스 주입 경과 시간 (시 BA_H, 분 BA-M, 초 BA_S)
          //               Ex) 경과 시간 5분 20초    0x00 0x05, 0x14
          // 볼러스 주입량 2 byte, 주입 소요시간(시/분/초) 3 byte
          //           Ex) 10.5 U, 7분 24 초   0x0a 0x32, 0x00, 0x07, 0x18
          // RPT	Sub ID	T_H	T_M	RU_I1	RU_I2	RU_D	BAU_I	BAU_D	BOU_I	BOU_D
          // 0x91	0x00	0x17	0x3b	0x01	0x2d	0x55	0x08	0x14	0x22	0x0f
          //
          // P_ST	MD	TIME1	TIME2	BU_I	BU_D	BA_H 	BA_M   	BA_S
          // 0x00	0x03	0x00	0x0A	0x1E	0x14	0x00	0x07	0x18
          // . Action; 주입 현황을 받은 앱은 홈 화면의 패치 구동 상태 데이터를 갱신한다.
          //  ㈜ 패치에서 주입 현황 메시지는 30분 단위로 매시 정각 / 매시 30분 시각에 자동 보고된다.

          //let's check received data exist first here
          // buffer[2],[3] : 패치 사용 시간 2 byte (hr, min)
          // buffer[4],[5],[6] : 인슐린 잔여량 3 byte(정수1 (100단위), 정수2 (10~1 단위), 소수점)
          // buffer[7],[8],[9],[10] : 오늘 총 주입량 4 byte: 기저 총 주입량 (2 byte)정수, 소수점
          // buffer[11] : 펌프 상태 (1 byte): 펌프 대기 0, 프라이밍 1, 펌프 구동 중  2, 펌프 고장 3
          // buffer[12] : 주입 모드 (1 byte): 기초 1, 일시 기초 2, 즉시 볼러스(교정볼러스 포함) 3, 연장 볼러스 4
          // 모드별 주입 데이터: 주입 데이터는 주입 속도 위주 모드와 총 주입량 위주 모드로 분류됨
          // - 기초1/임시기저2/연장 볼러스 주입4 (8 byte)
          // buffer[13],[14],[15],[16],[17],[18],[19]  시/분/값1,값2/시/분/초
          // P_ST	 MD	TIME1	TIME2	BU_I	BU_D	BA_H 	BA_M   	BA_S
          // 0x00	0x02	0x02	0x1E	0x1E	0x14	0x01	0x1E	0x00
          //
          // - 즉시 볼러스 주입3 (5 byte) : 볼러스 주입량 2 byte, 주입 소요시간(시/분/초) 3 byte
          // buffer[13],[14],[15],[16],[17]
          //  Ex) 10.5 U, 7분 24 초   0x0a 0x32, 0x00, 0x07, 0x18
          //  P_ST	 MD	 TIME1	TIME2	BU_I	BU_D	BA_H 	BA_M  BA_S
          //  0x00	0x03	0x00	0x0A	0x1E	0x14	0x00	0x07	0x18

          // 0x91||Sub ID 0x00||패치 사용 시간 2 byte ||인슐린 잔여량 3 byte||오늘 총 주입량 4 byte(기저/볼루스)||
          // 펌프 상태 (1 byte)||주입 모드 (1 byte)||주입모드 별 주입 기간 (2 byte)||기저 주입량(2byte)||주입 경과 시간(3byte)||
          //                                    ||볼러스 주입 소요 기간(2 byte)||볼러스 주입량(2byte)||볼러스 주입 경과 시간(3 byte)||

          var subList = value.sublist(2, 4);
          final hour = subList[0];
          final min = subList[1];

          subList = value.sublist(4, 7);
          final per100 = subList[0];
          final per10to1 = subList[1];
          final afterpoint = subList[2];

          subList = value.sublist(7, 11);
          final BasalBeforePoint = subList[0];
          final BasalAfterPoint = subList[1];
          final BolusBeforePoint = subList[2];
          final BolusAfterPoint = subList[3];

          subList = value.sublist(11, 13);
          final StatusPump = subList[0];
          final InjectMode = subList[1];

          subList = value.sublist(13, 20);
          final injectPeriodHour = subList[0];
          final injectPeriodMin = subList[1];
          final injectAmountBeforePoint = subList[2];
          final injectAmountAfterPoint = subList[3];
          final injectSpendTimeHour = subList[4];
          final injectSpendTimeMin = subList[5];
          final injectSpendTimeSec = subList[6];

          final ShowInfusionInfoReportMsg =
              '${mContext.l10n.patchUseTime} = ${hour}h${min}m\n${mContext.l10n.remainInsulin} = $per100$per10to1.${afterpoint}U\n${mContext.l10n.totalInjectionVolume} = ${mContext.l10n.basal} $BasalBeforePoint.${BasalAfterPoint}U, ${mContext.l10n.bolus} $BolusBeforePoint.${BolusAfterPoint}U\n${mContext.l10n.pumpStatus} = ${(StatusPump == 0) ? '${mContext.l10n.standby}' : (StatusPump == 1) ? '${mContext.l10n.priming}' : (StatusPump == 2) ? '${mContext.l10n.running}' : (StatusPump == 3) ? '${mContext.l10n.breakdown}' : ' '}\n${mContext.l10n.injectionMode} = ${(InjectMode == 0) ? '${mContext.l10n.basal}' : (InjectMode == 1) ? '${mContext.l10n.temporaryBasal}' : (InjectMode == 2) ? '${mContext.l10n.immediateBolus}' : (InjectMode == 3) ? '${mContext.l10n.extensionBolus}' : ' '}\n${mContext.l10n.infusionPeriod} = ${injectPeriodHour}h ${injectPeriodMin}m \n${mContext.l10n.injectionVolume} = $injectAmountBeforePoint.${injectAmountAfterPoint}U\n${mContext.l10n.injectionResultTime} = ${injectSpendTimeHour}h ${injectSpendTimeMin}m ${injectSpendTimeSec}s';
          //  'patch use time= ${hour}h${min}m\nremaining insulin = $per100$per10to1.${afterpoint}U\ntotal injection volume = basal $BasalBeforePoint.${BasalAfterPoint}U, bolus $BolusBeforePoint.${BolusAfterPoint}U\npump status = ${(StatusPump == 0) ? 'standby' : (StatusPump == 1) ? 'priming' : (StatusPump == 2) ? 'running' : (StatusPump == 3) ? 'breakdown' : ' '}\ninjection mode = ${(InjectMode == 0) ? 'basal' : (InjectMode == 1) ? 'temporary basal' : (InjectMode == 2) ? 'immediate bolus' : (InjectMode == 3) ? 'extension bolus' : ' '}\ninfusion period = ${injectPeriodHour}h ${injectPeriodMin}m \ninjection volume = $injectAmountBeforePoint.${injectAmountAfterPoint}U\ninjection result time = ${injectSpendTimeHour}h ${injectSpendTimeMin}m ${injectSpendTimeSec}s';
/*
          String ShowInfusionInfoReportMsg = '패치사용시간= ' + hour.toString() + '시간'
              + min.toString() + '분\n'
              + '인슐린 잔여량 = ' + per100.toString() + per10to1.toString() + '.' + afterpoint.toString() + 'U\n'
              + '총 주입량 = 기저 ' + BasalBeforePoint.toString() + '.' + BasalAfterPoint.toString() + 'U'
              + ', 볼루스 ' + BolusBeforePoint.toString() + '.' + BolusAfterPoint.toString() + 'U\n'
              + '펌프상태 = ' + ((StatusPump == 0) ? '대기'
              : (StatusPump == 1) ? '프라이밍'
              : (StatusPump == 2) ? '구동중'
              : (StatusPump == 3) ? '고장' : ' ')
              + '\n'
              + '주입 모드 = ' + ((InjectMode == 0) ? '기초'
              : (InjectMode == 1) ? '일시기초'
              : (InjectMode == 2) ? '즉시 볼러스'
              : (InjectMode == 3) ? '연장 볼러스'
              : ' ')
              + '\n'
              + '주입 기간 = ' + injectPeriodHour.toString() + '시간 '
              + injectPeriodMin.toString() + '분 '
              + '\n'
              + '주입량 = ' + injectAmountBeforePoint.toString() + '.'
              + injectAmountAfterPoint.toString() + 'U'
              + '\n'
              + '주입결과시간 = ' + injectSpendTimeHour.toString() + '시간 '
              + injectSpendTimeMin.toString() + '분 '
              + injectSpendTimeSec.toString() + '초';
*/
          //kai_20230427  save info periodically here
          /*  convert example reverse case
                  String _addLeadingZero(int value) {
                    return value.toString().padLeft(2, '0');
                  }
                int timeInMilliseconds = ConnectedTime;
                DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeInMilliseconds);
                String ConnectedTimeString = "${dateTime.year}/${_addLeadingZero(dateTime.month)}/${_addLeadingZero(dateTime.day)} ${_addLeadingZero(dateTime.hour)}:${_addLeadingZero(dateTime.minute)}:${_addLeadingZero(dateTime.second)}";
              // log(formattedDate); // 출력: "2023/04/29 16:17:17"
             */
          //kai_20231124 add to check the case that receive the response with 0x04 from csp1 after injection
          //if (buffer[1] != 4)
          LogMessageView =
              '${mContext.l10n.modelName}:$_ModelName, ${mContext.l10n.serialNumber}:$SN\n${mContext.l10n.firmwareVersion}:$fw, ${mContext.l10n.routeNumber}:$VC\n${mContext.l10n.firstConnectTime}:${CvtMiliSecsToTimeDateFormat(ConnectedTime)}\n$ShowInfusionInfoReportMsg';
          //  'model name:$_ModelName, serial number:$SN\nfirmware version:$fw, routeNumber:$VC\nfirst connection time:${CvtMiliSecsToTimeDateFormat(ConnectedTime)}\n$ShowInfusionInfoReportMsg';
          /*
          LogMessageView = '모델명:' + _ModelName + ', 제조번호:' + SN + '\n'
              + '펌웨어버전:' + fw + ', 루트번호:' + VC + '\n'
              + '최초연결시간:' + CvtMiliSecsToTimeDateFormat(ConnectedTime) + '\n'
              + ShowInfusionInfoReportMsg;
          */
          if (buffer[1] == 0)

          ///< 주입 현황 요청 응답(0x00)
          {
            //kai_20230427 let's update variable
            PatchUseAvailableTime =
                '$hour${mContext.l10n.hour}$min${mContext.l10n.mins}';
            reservoir = '$per100$per10to1.$afterpoint';
            notifyListeners();
            /*
            //kai_20230501 Total delivered value
            BolusDeliveryValue = double.parse(injectAmountBeforePoint.toString() + '.'
                + injectAmountAfterPoint.toString());  //  + 'U';
            //Total delivered time value
            LastBolusDeliveryTime = timeToMilliseconds(injectSpendTimeHour,injectSpendTimeMin,injectSpendTimeSec);
            /* latestDeliveryTime = injectSpendTimeHour.toString() + '시간 '
                + injectSpendTimeMin.toString() + '분 '
                + injectSpendTimeSec.toString() + '초';
            */
           */
            log('${TAG}INFUSION_INFO_RPT:success !!');
            SetUpWizardMsg =
                '${mContext.l10n.infusionInfoReport}\n$ShowInfusionInfoReportMsg';
            //'Infusion info report\n$ShowInfusionInfoReportMsg';
            SetUpWizardActionType = 'INFUSION_INFO_RPT_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              INFUSION_INFO_RPT_SUCCESS,
            );
          } else if (buffer[1] == 1)

          ///< 잔여량 요청 응답(0x01)
          {
            PatchUseAvailableTime =
                '$hour${mContext.l10n.hour}$min${mContext.l10n.mins}';
            reservoir = '$per100$per10to1.$afterpoint';
            notifyListeners();
            /*
            //kai_20230501 Total delivered value & Total delivered time value
            BolusDeliveryValue = double.parse(injectAmountBeforePoint.toString() + '.'
                + injectAmountAfterPoint.toString());  //  + 'U';
            LastBolusDeliveryTime = timeToMilliseconds(injectSpendTimeHour,injectSpendTimeMin,injectSpendTimeSec);
           */
            SetUpWizardMsg =
                '${mContext.l10n.infusionInfoReport}\n$ShowInfusionInfoReportMsg'; //'Infusion info report\n$ShowInfusionInfoReportMsg';
            SetUpWizardActionType = 'INFUSION_INFO_RPT_REMAIN_AMOUNT';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              INFUSION_INFO_RPT_REMAIN_AMOUNT,
            );
          } else if (buffer[1] == 2)

          ///< 30분단위 보고 (0x02)
          {
            PatchUseAvailableTime =
                '$hour${mContext.l10n.hour}$min${mContext.l10n.mins}';
            reservoir = '$per100$per10to1.$afterpoint';
            notifyListeners();
            /*
            //kai_20230501 Total delivered value & Total delivered time value
            BolusDeliveryValue = double.parse(injectAmountBeforePoint.toString() + '.'
                + injectAmountAfterPoint.toString());  //  + 'U';
            LastBolusDeliveryTime = timeToMilliseconds(injectSpendTimeHour,injectSpendTimeMin,injectSpendTimeSec);
           */
            SetUpWizardMsg =
                '${mContext.l10n.infusionInfoReport}\n$ShowInfusionInfoReportMsg'; //'Infusion info report\n$ShowInfusionInfoReportMsg';
            SetUpWizardActionType = 'INFUSION_INFO_RPT_30MIN_REPEATEDLY';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              INFUSION_INFO_RPT_30MIN_REPEATEDLY,
            );
          } else if (buffer[1] == 3)

          ///< 재 연결 보고(0x03)
          {
            PatchUseAvailableTime =
                '$hour${mContext.l10n.hour}$min${mContext.l10n.mins}';
            reservoir = '$per100$per10to1.$afterpoint';
            notifyListeners();
            /*
            //kai_20230501 Total delivered value & Total delivered time value
            BolusDeliveryValue = double.parse(injectAmountBeforePoint.toString() + '.'
                + injectAmountAfterPoint.toString());  //  + 'U';
            LastBolusDeliveryTime = timeToMilliseconds(injectSpendTimeHour,injectSpendTimeMin,injectSpendTimeSec);
           */
            log(
              '${TAG}INFUSION_INFO_RPT:success 0x03:reconnected between app and patch!',
            );
            SetUpWizardMsg =
                '${mContext.l10n.infusionInfoReport}\n${mContext.l10n.patchConnectionEstablished}';
            //  'Infusion info report\nPatch connection was established again!!';
            SetUpWizardActionType = 'INFUSION_INFO_RPT_RECONNECTED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              INFUSION_INFO_RPT_RECONNECTED,
            );
          } else if (buffer[1] == 4)

          ///kai_20231124 add to update reservoir amount sent from Csp1
          {
            PatchUseAvailableTime =
                '$hour${mContext.l10n.hour}$min${mContext.l10n.mins}';
            reservoir = '$per100$per10to1.$afterpoint';
            notifyListeners();
          }
        }
        break;

      case CareLevoCmd.HCL_BOLUS_RSP:

        ///<  HCL  주입 응답
        {
          // MODE: 요청 시 모드 값 입력
          // . RESULT: SUCCESS 0x00, FAIL 0x01 (현재 주입 중 상태 또는 펌프 구동 불가 상태),
          //              DATA_OVERFLOW 0x04 (최대 볼러스 량보다 큰 경우, 또는 0)
          // . 소요 시간 : 분 (EXP_TIME_M), 초 (EXP_TIME_S)
          //
          // RSP	MODE	RESULT	EXP_TIME_M	EXP_TIME_S
          // 0xD7	0x00	0x00	      0x02	     0x05
          if (buffer[2] == 0) {
            //본 메시지를 수신한 앱은 소요 시간이 적용된 주입 진행바를 띄우고 진행  상태를 실시간 색깔로 표시한다.
            //또한 주입 시간 동안 새로운 주입 요청을 막아야 한다.
            //예를 들어 5분 주기로 주입을 제어하는 경우,
            //총 주입 시간이 5분을 초과하면 5분 후 새로운 주입 요청은 못하게 하여야 하며,
            //요청 시 패치는 “FAIL” 로 응답하여 Reject 한다.
            //success, then let's check the spent time to inject bolus in pump side
            //at this point app should showing progress status as like progress bar
            log(
              '${TAG}bolus injection expected spend time = ${buffer[3].toInt()}min ${buffer[4].toInt()}sec',
            );

            //kai_20230427 let's set timer flag with timeout value which is based on the response duration time.
            final timeout = buffer[3].toInt() * 60 + buffer[4].toInt();
            log(
              '${TAG}kai: bolus injection expected spend time = ${buffer[3].toInt()}min ${buffer[4].toInt()}sec, set _isInjectingNow = true and block additional sending Dose until the timeout($timeout)',
            );

            SetUpWizardMsg =
                '${mContext.l10n.onInjectionBolus} ${buffer[3].toInt()}${mContext.l10n.mins} ${buffer[4].toInt()}${mContext.l10n.second}';
            //   'On injecting Bolus...\nExpected spend time is ${buffer[3].toInt()}min ${buffer[4].toInt()}sec';
            SetUpWizardActionType = 'HCL_BOLUS_RSP_SUCCESS';
            showSetUpWizardMsgDlg = true;
            // setResponseMessage(RSPType.SETUP_DLG,SetUpWizardMsg,HCL_BOLUS_RSP_SUCCESS);
            final ShowingTimeOut = timeout.toString();
            // LastBolusDeliveryTime = DateTime.now().millisecondsSinceEpoch;  ///< save the start injection time here
            /*
            DateTime now = DateTime.now();
            DateTime time = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
           log('kai:HCL_BOLUS_RSP current time = ' + DateFormat("yyyy/MM/dd HH:mm:ss").format(now)
            + ' , time.millisecondsSinceEpoch = ' + time.millisecondsSinceEpoch.toString()
            + ' , time = '
            + DateFormat("yyyy/MM/dd HH:mm:ss").format(DateTime.fromMillisecondsSinceEpoch(time.millisecondsSinceEpoch,isUtc: true))
            );
            */
            setLastBolusDeliveryTime(DateTime.now().millisecondsSinceEpoch);
            setResponseMessage(
              RSPType.TOAST_POPUP,
              SetUpWizardMsg,
              ShowingTimeOut,
            );

            _isDoseInjectingNow = true;
            Future.delayed(Duration(seconds: timeout), () {
              debugPrint(
                '${TAG}kai: release blocked dose request!!: _isDoseInjectingNow = false',
              );
              _isDoseInjectingNow = false;
              //kai_20230506 let's notify SendSetDose processing result to the caller here
              setResponseMessage(
                RSPType.PROCESSING_DONE,
                'Dose_Injection_Done',
                HCL_BOLUS_RSP_SUCCESS,
              );
            });
          } else if (buffer[2] == 1) {
            //fail
            log(
              '${TAG}HCL_BOLUS_RSP:failed to inject bolus due to injecting is ongoing or status of pump is abnormal!!',
            );
            SetUpWizardMsg = mContext.l10n.failInjectionBolus;
            //   'Failed to inject bolus due to injecting is ongoing or status of pump is abnormal at this time.';
            SetUpWizardActionType = 'HCL_BOLUS_RSP_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              HCL_BOLUS_RSP_FAILED,
            );
          } else if (buffer[2] == 4) {
            log(
              '${TAG}HCL_BOLUS_RSP: failed to inject bolus due to DATA_OVERFLOW(${buffer[2].toInt()})!!',
            );
            SetUpWizardMsg =
                '${mContext.l10n.faileInjectionDataOverflow}(${buffer[2].toInt()})!!';
            //  'Failed to inject bolus due to DATA_OVERFLOW(${buffer[2].toInt()})!!';
            SetUpWizardActionType = 'HCL_BOLUS_RSP_OVERFLOW';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              HCL_BOLUS_RSP_OVERFLOW,
            );
          } else {
            log(
              '${TAG}HCL_BOLUS_RSP: failed to inject bolus due to error(${buffer[2].toInt()})!!',
            );
          }
        }
        break;

      case CareLevoCmd.HCL_BOLUS_CANCEL_RSP:
        {
          // RESULT: SUCCESS 0x00, FAIL 0x01 (주입 중이 아닌 경우)
          //  주입량 (현재까지 주입된 량, 2바이트): DSOE_I, DOSE_D
          //
          // RSP	MODE	RESULT	DOSE_I	DOSE_D
          // 0xD8	0x00	 0x00	    0x03	  0x05
          if (buffer[2] == 0) {
            log(
              '${TAG}injected bolus amount = ${buffer[3].toInt()}.${buffer[4].toInt()}ml',
            );
            SetUpWizardMsg =
                '${mContext.l10n.cancelInjectionBolusAmout} = ${buffer[3].toInt()}.${buffer[4].toInt()}ml';
            //  'Cancel injecting bolus amount = ${buffer[3].toInt()}.${buffer[4].toInt()}ml';
            SetUpWizardActionType = 'HCL_BOLUS_CANCEL_RSP_SUCCESS';
            showSetUpWizardMsgDlg = true;
            //kai_20230427 release blocking dose request flag here
            if (isDoseInjectingNow == true) {
              isDoseInjectingNow = false;
            }

            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              HCL_BOLUS_CANCEL_RSP_SUCCESS,
            );
          } else {
            log(
              '${TAG}HCL_BOLUS_CANCEL_RSP:failed to cancel bolus injection!!',
            );
            SetUpWizardMsg =
                '${mContext.l10n.failCancelInjectionBolus}(${buffer[3].toInt()}.${buffer[4].toInt()}ml)';
            //  'failed to cancel bolus injection(${buffer[3].toInt()}.${buffer[4].toInt()}ml)';
            SetUpWizardActionType = 'HCL_BOLUS_CANCEL_RSP_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              HCL_BOLUS_CANCEL_RSP_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.CANNULAR_INSERT_RPT:
        {
          // 캐뉼라 삽입 보고 (패치 장치  스마트폰 앱): CANNULAR_INSERT_RPT (0x79)
          //
          // . 송신 조건: 제어 모듈에서 케뉼라 삽입이 센싱되면 앱으로 본 메시지가 송신된다.
          //
          // . Length 2, CMD: 0x79
          //
          // . Result (1 byte): 성공 0 (0x00), 실패 1 (0x01) -> 실패 경고음 송출
          //
          //
          // RPT	RESULT
          // 0x79	0x00
          //
          // . Action: 성공을 수신한 앱은 바늘 삽입 성공 및 패치 부착 성공을 화면에 표시한다.
          // 앱은 반드시 패치로 “CANNULAR_INSERT_ACK (0x19)” 메시지를 송신하여야 한다.
          // 이후 앱은 HCL 통합 자동 주입을 진행한다.
          if (buffer[1] == 0) {
            log('${TAG}CANNULAR_INSERT_RPT:success !!');
            SetUpWizardMsg = mContext.l10n.cannularInsertionSuccess;
            //  'Cannular insertion success and patch attachment success!!';
            SetUpWizardActionType = 'CANNULAR_INSERT_RPT_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              CANNULAR_INSERT_RPT_SUCCESS,
            );
            sendCannularInsertAck(null);
          } else {
            log(
              '${TAG}CANNULAR_INSERT_RPT:failed to insert cannular needle!!',
            );
            SetUpWizardMsg = mContext.l10n.cannularInsertionNotComplete;
            //  'Inserting cannular is not complete at this time.\nRetry it later!!';
            SetUpWizardActionType = 'CANNULAR_INSERT_RPT_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              CANNULAR_INSERT_RPT_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.CANNULAR_INSERT_RSP:
        {
          // 다.	캐뉼라 삽입 보고 확인 응답 (패치 장치  스마트폰 앱): CANNULAR_INSERT_RSP(0x7A)
          //
          // . Length 1, RSP: 0x7A
          // . Result (1 byte): SUCCESS 0
          //
          // . 송신 조건: 패치에서 수신한 “케뉼라 삽입 보고 확인” 메시지 (CANNULAR_INSERT_ACK) 에 대헤
          // 응답 메시지로 본 메시지를 송신한다.
          //
          // RSP	RSLT
          // 0x7A	0x00
          //
          // . Action: 본 메시지를 수신한 앱은
          // 다음 절차로 기저주입 프로그램 요청 “BASAL_PROGRAM_REQ1/2” 메시지 송신을 시작한다
          if (buffer[1] == 0) {
            log('${TAG}CANNULAR_INSERT_RSP:success !!');
            SetUpWizardMsg =
                mContext.l10n.patchIsReadyNow; //'Patch is ready now!!';
            SetUpWizardActionType = 'CANNULAR_INSERT_RSP_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              CANNULAR_INSERT_RSP_SUCCESS,
            );
          } else {
            log(
              '${TAG}CANNULAR_INSERT_RSP:failed to insert cannular needle!!',
            );
            SetUpWizardMsg = mContext.l10n.cannularInsertionNotComplete;
            //   'Inserting Cannular is not complete.\nRetry it later!!';
            SetUpWizardActionType = 'CANNULAR_INSERT_RSP_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              CANNULAR_INSERT_RSP_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.PATCH_WARNING_RPT:
        {
          // 송신 조건: 패치 부착 중, 펌프 막힘 감지된 경우, 인슐린 잔여량이 없는 경우
          // (eg. 2U 이하, 정확한 값은 추후 약물백의 dead volume 고려), 사용 시간이 종료된 경우,
          // 그리고 배터리가 20% 미만으로 떨어진 경우에 본 메시지가 앱으로 송신된다.
          //
          // . Length 3, RPT: 0xa1
          //  . CAUSE: 펌프 막힘(토출 안됨) 0, 인슐린 고갈 1, 사용시간 종료 2, 배터리 없음(20% 미만)
          //  3, , 온도초과 (섭씨 5~40 도 밖 온도)  4, 앱 장기 미사용 5, BLE 연결 안됨 6, 주입 시작 못함 7,
          // 주입 정지 재개 오류 8
          //
          //  . (Warning CAUSE 정리)
          // -	0x00 : 주입구 막힘
          // -	0x01 : 인슐린 없음
          // -	0x02 : 패치 사용 시간 만료
          // -	0x03 : 배터리 없음 (참조: 자사는 발생 가능성 없음)
          // -	0x04 : 부적합 온도
          // -	0x05 : 앱 장기 미사용 (APP_STATUS_REQ 수신 후 app_use2 T/O 시)
          // -	0x06 : BLE 연결 안됨 (patch_connect T/O 시, 참조: 페치 자체 원인값 -> 앱 전송 못함)
          // -	0x07 : 기저주입 시작못함 (basal_monitor T/O 시)
          // -	0x08 : 경고 미사용 (ALERT CAUSE: 주입임시중지 재개 오류)
          // -	0x09 : 경고는 미사용 (NOTI CAUSE: 패치 점검 알림)
          // -	0x0A : 연장된 패치 사용 시간 만료
          // -	0x0C : 펌프 오류(주입구 막힘 포함) PUMP_ERROR
          //  . VALUE: 펌프 오류  제외한 나머지의 잔여 값(인슐린 잔여량, 시간, 배터리 레벨)
          //
          //  ㈜ 경고 메시지 송신 후 패치는 경고 부저 울리고, 1분 뒤 경고 메시지 1회 재 송부함.
          //
          // RPT	CAUSE	VALUE
          // 0xa1	0x01	0x0a
          //
          // . Action: 본 메시지를 수신한 앱은 해당 원인 (Cause)의 경고 팝업과 함께 스마트 폰에서도 경고 부저를 울린다.
          // 그리고 패치 교체 메뉴를 띄워 패치 폐기 절차를 진행한다.
          if (buffer[1] == 0x00) {
            //clogged inlet, occlusion
            _WarningMsg =
                mContext.l10n.occlusionAlert; //'Occlusion(clogged inlet)!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x01) {
            // No insulin
            _WarningMsg =
                '${mContext.l10n.noInsulin}(${buffer[2].toInt()}ml)!!';
            //'No insulin(${buffer[2].toInt()}ml)!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x02) {
            // Patch usage timeout
            _WarningMsg =
                '${mContext.l10n.patchUsageTimeout}(${buffer[2].toInt()}h)!!';
            //'Patch usage timeout(${buffer[2].toInt()}h)!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x03) {
            // No Battery
            _WarningMsg = '${mContext.l10n.noBattery}(${buffer[2].toInt()}%)!!';
            //'No battery(${buffer[2].toInt()}%)!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x04) {
            // unsuitable temperature
            _WarningMsg =
                '${mContext.l10n.unsuitableTemperature}(${buffer[2].toInt()}C)!!';
            //'Unsuitable temperature(${buffer[2].toInt()}C)!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x05) {
            // Long-term inactivity of the app
            _WarningMsg = mContext.l10n.longtermInactivityOfTheApp;
            //'Long-term inactivity of the app!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x06) {
            // BLE not connected
            _WarningMsg = mContext.l10n.bleNotConnected;
            //'BLE not connected!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x07) {
            // Basal infusion failed to start
            _WarningMsg = mContext.l10n.basalInfusionFailedToStart;
            //'Basal infusion failed to start!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x08) {
            // Warning not used (ALERT CAUSE: injection pause resume error)
            /* _WarningMsg = 'Warning not used!!';
            showWarningMsgDlg = true;*/
          } else if (buffer[1] == 0x09) {
            // Warning not used (NOTI CAUSE: patch check notice)
            /* _WarningMsg = 'Warning not used!!';
            showWarningMsgDlg = true;*/
          } else if (buffer[1] == 0x0a) {
            // Extended Patch Timeout Expires
            _WarningMsg =
                '${mContext.l10n.extendedPatchTimeoutExpires}(${buffer[2].toInt()}h)!!';
            //  'Extended Patch Timeout Expires(${buffer[2].toInt()}h)!!';
            showWarningMsgDlg = true;
          } else if (buffer[1] == 0x0c) {
            // Pump error (including blocked inlet)
            _WarningMsg = mContext.l10n.pumpError; //'Pump error!!';
            showWarningMsgDlg = true;
          }

          setResponseMessage(RSPType.WARNING, _WarningMsg, PATCH_WARNING_RPT);
        }

        break;

      case CareLevoCmd.PATCH_ALERT_RPT:
        {
          // 송신조건: 인슐린 부족 임박(e.g 3U~10U), 사용 시간 종료 임박(1 hr), 배터리 부족 (10%)
          // 등의 주의 임계치에 도달하면 본 메시지를 송신한다.
          //
          // . Length 3, RPT: 0xa2
          // . CAUSE: 인슐린 부족 임박 1, 사용 시간 종료 임박 2, 배터리 부족 (10% 이하) 3, 온도 이상 4
          //           앱 장기 미사용 5, BLE 연결 안됨 6, 주입 시작 못함 7, 주입 정지 재개 오류 8,
          //           연장된 사용 시간 주의 임계치 도달 10
          //
          // (Alert CAUSE 정리)
          // -	0x01 : 인슐린 잔여량 적음
          // -	0x02 : 패치 사용기간 주의
          // -	0x03 : 배터리 주의 임계치 도달
          // -	0x04 : 부적합 온도 접근 (참조: 현재 미사용)
          // -	0x05 : 앱 장기 미사용 (APP_STATUS_REQ 수신 후 app_use1 T/O 시)
          // -	0x06 : BLE 연결 안됨 (patch_connect T/O 시, 참조: 페치 자체 원인값 -> 앱 전송 못함)
          // -	0x07 : 기저주입 시작못함 (basal_monitor T/O 시)
          // -	0x08 : 주입임시중지 재개 오류((사용자 설정 재개 시간 infusion resume T/O) )
          // -	0x09 : 주의는 미사용 (NOTI CAUSE: 패치 점검 알림)
          // -	0x0A : 연장된 패치 사용 시간 주의
          //
          // . VALUE: 임계치 도달 값  Type 1) 인슐린 잔여량 (ex. 10U),
          //                                      Type 2) 배터리 잔량 (30%),
          //                                      Type 3) 패치 폐기 시간 임박 (1 hr)
          //                                      Type 4) 연장된 패치 폐기 시간 임박(1 hr)
          //
          // RPT	CAUSE	VALUE
          // 0xa2	0x01	0x14
          //
          // . Action: 본 메시지를 수신한 앱은 각 CAUSE 별 수신 임계치 값을 가지고 주의 팝업을 발생시킨다.
          // 주의 팝업을 본 사용자는 곧 패치 교체 시기가 도래함을 알고 미리 교체를 준비를 대비한다.
          if (buffer[1] == 0x01) {
            // No insulin
            AlertMsg =
                '${mContext.l10n.lowInsulinLevels}(${buffer[2].toInt()}ml)!!';
            //'low insulin levels(${buffer[2].toInt()}ml)!!';
            showALertMsgDlg = true;
          } else if (buffer[1] == 0x02) {
            // Patch usage timeout
            AlertMsg =
                '${mContext.l10n.payAttentionToPatchUsagePeriod}(${buffer[2].toInt()}h)!!';
            //  'Pay attention to patch usage period(${buffer[2].toInt()}h)!!';
            showALertMsgDlg = true;
          } else if (buffer[1] == 0x03) {
            // No Battery
            AlertMsg =
                '${mContext.l10n.batteryCautionThresholdReached}(${buffer[2].toInt()}%)!!';
            //'Battery caution threshold reached(${buffer[2].toInt()}%)!!';
            showALertMsgDlg = true;
            Battery = buffer[2].toString();
          } else if (buffer[1] == 0x04) {
            // unsuitable temperature
            AlertMsg =
                '${mContext.l10n.unsuitableTemperatureApproach}(${buffer[2].toInt()}C)!!';
            //  'Unsuitable Temperature Approach(${buffer[2].toInt()}C)!!';
            showALertMsgDlg = true;
          } else if (buffer[1] == 0x05) {
            // Long-term inactivity of the app
            AlertMsg = mContext.l10n.longtermInactivityOfTheApp;
            //'Long-term inactivity of the app!!';
            showALertMsgDlg = true;
          } else if (buffer[1] == 0x06) {
            // BLE not connected
            AlertMsg = mContext.l10n.bleNotConnected;
            //'BLE not connected!!';
            showALertMsgDlg = true;
          } else if (buffer[1] == 0x07) {
            // Basal infusion failed to start
            AlertMsg = mContext.l10n.basalInfusionFailedToStart;
            //'Basal infusion failed to start!!';
            showALertMsgDlg = true;
          } else if (buffer[1] == 0x08) {
            // Warning not used (ALERT CAUSE: injection pause resume error)
            AlertMsg = mContext.l10n.infusionPauseResumeError;
            //'Infusion Pause Resume Error!!';
            showALertMsgDlg = true;
          } else if (buffer[1] == 0x09) {
            // Warning not used (NOTI CAUSE: patch check notice)
            /* AlertMsg = 'Warning not used!!';
            showALertMsgDlg = true;*/
          } else if (buffer[1] == 0x0a) {
            // Extended Patch Timeout Expires
            AlertMsg =
                '${mContext.l10n.bewareOfExtendedPatchUsageTimes}(${buffer[2].toInt()}h)!!';
            // 'Beware of extended patch usage times(${buffer[2].toInt()}h)!!';
            showALertMsgDlg = true;
          }

          setResponseMessage(RSPType.ALERT, AlertMsg, PATCH_ALERT_RPT);
        }
        break;

      case CareLevoCmd.PATCH_NOTICE_RPT:
        {
          // ((Notice CAUSE 정리)
          // -	0x01 : 인슐린 잔여량 임계치 도달
          // -	0x02 : 패치 사용시간 임계치 도달
          // -	0x03 : 배터리 알림 임계치 도달
          // -
          // -	0x09 : 패치 점검 알림 (패치 부착 후 90분, inspection timer T/O)
          // -	0x0A:: 앱 시간 동기화 알림
          // -	0x0B: 볼러스 주입 후 혈당 측정
          // -
          // . VALUE1: 임계치 도달 값  Cause 1) 인슐린 잔여 임계치 (10U ~ 50U)
          // Cause 2) 사용시간 임계치 (ex. 4 hr),
          //                           Cause 3) 배터리 잔여량 (40%)
          // . VALUE2: COUNT/TIMER_ID  Cause 0x0A) 동기화 메시지 Sequence Number (COUNT)
          //  Cause 0x0B) 혈당측정 알림 타이머 구분자 (TIMER_ID)
          // RPT	CAUSE	VALUE
          // 0xa3	0x02	0x04
          //
          //
          // (주1) Cause 0x0A (앱 시간 동가화 알림): 패치는 앱과 연결 후
          // 시간 동기화 메시지 “SET_TIME_REQ” 수신 시부터 10분 주기로 원인 값 “0x0A”와 Count 값을 채워 송신하여야 한다.
          // 이 때의 VALUE 값은 1부터 하나씩 증가되어 채워 보낸다.
          //
          // RPT	CAUSE	VALUE
          // 0xa3	0x0A	COUNT
          //
          //
          //
          // (주2) Cause 0x0B (볼러스 주입 후 혈당 측정 알림):
          // 혈당 측정 알림 요청(GLUCOSE_TIMER_REQ) 메시지에 대한 패치에서의 측정 알림 NOTICE 메시지로
          // 아래의 값을 채워 송신하여야 한다.
          // 이 때의 VALUE 값은 “GLUCOSE_MEASURE_REQ” 시 보낸 타이머 구분자(TIMER_ID)이다.
          //
          // RPT	CAUSE	VALUE
          // 0xa3	0x0B	TIMER_ID
          //
          //
          // . Action: 본 메시지를 수신한 앱은 각 CAUSE 별 수신 알림 임계치 값을 가지고 알림 팝업을 발생시킨다.
          //  Cause 가 “볼러스 주입 후 혈당 측정(0x0B)” 이면 앱은 혈당 측정 안내 팝업을 띄워 알려준다.

          if (buffer[1] == 1) {
            //kai_20230427 let's update variable
            reservoir = buffer[2].toInt().toString();
            // Insulin balance threshold reached
            // 인슐린 잔여량 임계치 도달

            log(
              '${TAG}PATCH_NOTICE_RPT:1 Insulin balance threshold reached (${buffer[2].toInt()}U)',
            );
            /*  NoticeMsg = '인슐린 잔여량 임계치 도달 (' + buffer[2].toInt().toString() + 'U)';
            showNoticeMsgDlg = true;
            setResponseMessage(RSPType.NOTICE,NoticeMsg,PATCH_NOTICE_RPT);
           */
            SetUpWizardMsg =
                '${mContext.l10n.insulinBalanceThresholdReached} (${buffer[2].toInt()}U)';
            // 'Insulin balance threshold reached (${buffer[2].toInt()}U)';
            SetUpWizardActionType = 'PATCH_NOTICE_RPT';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_NOTICE_RPT,
            );
          } else if (buffer[1] == 2) {
            log(
              '${TAG}PATCH_NOTICE_RPT:2 Patch usage time threshold reached (${buffer[2].toInt()}hour)',
            );
            /* NoticeMsg = '패치 사용시간 임계치 도달 (' + buffer[2].toInt().toString() + 'hour)';
            showNoticeMsgDlg = true;
            setResponseMessage(RSPType.NOTICE,NoticeMsg,PATCH_NOTICE_RPT);
            */
            PatchUseAvailableTime =
                '${mContext.l10n.patchUsageTimeThresholdReached} (${buffer[2].toInt()}${mContext.l10n.hour})';
            //  'Patch usage time threshold reached (${buffer[2].toInt()}시간)';

            SetUpWizardMsg =
                '${mContext.l10n.patchUsageTimeThresholdReached} (${buffer[2].toInt()}${mContext.l10n.hour})';
            // 'Patch usage time threshold reached (${buffer[2].toInt()}hour)';
            SetUpWizardActionType = 'PATCH_NOTICE_RPT';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_NOTICE_RPT,
            );
          } else if (buffer[1] == 3) {
            log(
              '${TAG}PATCH_NOTICE_RPT:3 Battery notification threshold reached (${buffer[2].toInt()}%)',
            );
            /*NoticeMsg = '배터리 알림 임계치 도달 (' + buffer[2].toInt().toString() + '%)';
            showNoticeMsgDlg = true;
            setResponseMessage(RSPType.NOTICE,NoticeMsg,PATCH_NOTICE_RPT);
            */
            //kai_20230427 let's update variable
            Battery = buffer[2].toInt().toString();
            notifyListeners();

            SetUpWizardMsg =
                '${mContext.l10n.batteryNotificationThresholdReached} (${buffer[2].toInt()}%)';
            // 'Battery notification threshold reached (${buffer[2].toInt()}%)';
            SetUpWizardActionType = 'PATCH_NOTICE_RPT';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_NOTICE_RPT,
            );
          } else if (buffer[1] == 9) {
            log(
              '${TAG}PATCH_NOTICE_RPT:9 patch check notification (90 minutes after patch application, inspection timer T/O)',
            );
            /* NoticeMsg = '패치 점검 알림 (패치 부착 후 90분, inspection timer T/O)';
            showNoticeMsgDlg = true;
            setResponseMessage(RSPType.NOTICE,NoticeMsg,PATCH_NOTICE_RPT);
            */
            SetUpWizardMsg = mContext.l10n.patchCheckNotification;
            //  'patch check notification (90 minutes after patch application, inspection timer T/O)';
            SetUpWizardActionType = 'PATCH_NOTICE_RPT';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_NOTICE_RPT,
            );
          } else if (buffer[1] == 0xa) {
            log(
              '${TAG}PATCH_NOTICE_RPT:10 App time sync notification (${buffer[2].toInt()})count',
            );
            /* NoticeMsg = '앱 시간 동기화 알림 ('+ buffer[2].toInt().toString() + ')count';
            showNoticeMsgDlg = true;
            setResponseMessage(RSPType.NOTICE,NoticeMsg,PATCH_NOTICE_RPT);
            */
            SetUpWizardMsg =
                '${mContext.l10n.appTimeSyncNotification}(${buffer[2].toInt()})count';
            //   'App time sync notification (${buffer[2].toInt()})count';
            SetUpWizardActionType = 'PATCH_NOTICE_RPT';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_NOTICE_RPT,
            );
          } else if (buffer[1] == 0xb) {
            log(
              '${TAG}PATCH_NOTICE_RPT:11 Notification of blood glucose measurement after bolus injection (${buffer[2].toInt()})TimerID',
            );
            /*NoticeMsg = '볼러스 주입 후 혈당 측정 알림 ('+ buffer[2].toInt().toString() + ')TimerID';
            showNoticeMsgDlg = true;
            setResponseMessage(RSPType.NOTICE,NoticeMsg,PATCH_NOTICE_RPT);
             */
            SetUpWizardMsg =
                '${mContext.l10n.notificationOfBloodGlucoseMeasurementAfterBolusInjection} (${buffer[2].toInt()})TimerID';
            //'Notification of blood glucose measurement after bolus injection (${buffer[2].toInt()})TimerID';
            SetUpWizardActionType = 'PATCH_NOTICE_RPT';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_NOTICE_RPT,
            );
          }
        }
        break;

      case CareLevoCmd.BUZZER_CHECK_RSP:
        {
          /// Length 2, RSP: 0x97, RESULT
          if (buffer[1] == 0) {
            log('${TAG}BUZZER_CHECK_RSP:success !!');
            SetUpWizardMsg = mContext.l10n.requestingBuzzerCheckIsComplete;
            //'Requesting buzzer check is complete!!';
            SetUpWizardActionType = 'BUZZER_CHECK_RSP_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              BUZZER_CHECK_RSP_SUCCESS,
            );
          } else {
            log('${TAG}BUZZER_CHECK_RSP:failed to check buzzer !!');
            SetUpWizardMsg = mContext.l10n.requestingBuzzerCheckIsNotAvailable;
            // 'Requesting buzzer check is not available at this time.\nRetry it later!!';
            SetUpWizardActionType = 'BUZZER_CHECK_RSP_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              BUZZER_CHECK_RSP_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.BUZZER_CHANGE_RSP:
        {
          /// Length 1, RSP: 0x78
          // . Result (1 byte): SUCCESS 0, FAIL 1 (패치가 삽입 감지 못한 경우)
          //
          // RSP	RSLT
          // 0x78	0x00
          if (buffer[1] == 0) {
            log('${TAG}BUZZER_CHANGE_RSP:success !!');
            SetUpWizardMsg = mContext.l10n.requestingBuzzerChangeIsComplete;
            //'Requesting buzzer change is complete!!';
            SetUpWizardActionType = 'BUZZER_CHANGE_RSP_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              BUZZER_CHANGE_RSP_SUCCESS,
            );
          } else {
            log('${TAG}BUZZER_CHANGE_RSP:failed to change buzzer !!');
            TXErrorMsg = mContext.l10n.requestingBuzzerChangeIsNotAvailable;
            // 'Requesting buzzer change is not available at this time.\nRetry it later!!';
            showTXErrorMsgDlg = true;
            setResponseMessage(
              RSPType.ERROR,
              TXErrorMsg,
              BUZZER_CHANGE_RSP_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.APP_STATUS_ACK:
        {
          // Length 2, ACK: 0x99, STATUS (APP_STATUS_IND 시 앱에서 통보 받은 값 세팅함: 0 or 1)
          //
          // ACK	STATUS
          // 0x99	0x00
          if (buffer[1] == 0) {
            log('${TAG}APP_STATUS_ACK:success !!');
          } else {
            log('${TAG}APP_STATUS_ACK:failed to check app status !!');
          }
        }
        break;

      case CareLevoCmd.MAC_ADDR_RPT:
        {
          // Length 7, RPT 0x9B,
          //
          //  . Data (6 byte): MAC Address -> 6바이트 HEXA 값임
          //   (ex. Silicon Labs chip: 0x80 0x4B 0x50 0x6F 0xDC 0x61)
          //
          // RPT	ADDR1	ADDR2	ADDR3	ADDR4	ADDR5	ADDR6
          // 0x9B	0x80	0x4B	0x50	0x6F	0xDC	0x61

        }
        break;

      case CareLevoCmd.ALARM_CLEAR_RSP:
        {
          // . Length 4, RSP: 0xA7
          // . SUB ID: ALERT Alarm (0xA2) 또는 NOTICE (0xA3) - 해소할 알람 (ALERT 또는 NOTICE)
          // . CAUSE: 해소할 주의와 알림의 해당 원인 값
          // . RESULT: SUCCESS (0x00), FAIL(0x01)
          //
          //
          // RSP	SUB ID	CAUSE	RESULT
          // 0xA7	0xA2	0x01	0x00
          if (buffer[1] == 0) {
            log('${TAG}ALARM_CLEAR_RSP:success !!');
            if (buffer[2] == 0xa2) {
              // clear alarm
            } else if (buffer[2] == 0xa3) {
              // clear notice
            }
          } else {
            log('${TAG}ALARM_CLEAR_RSP:failed to clear alarm !!');
          }
        }
        break;

      case CareLevoCmd.PATCH_DISCARD_RSP:
        {
          // Length 2, RSP: 0x95, RESULT
          //
          // RSP	RSLT
          // 0x96	0x00
          if (buffer[1] == 0) {
            log('${TAG}PATCH_DISCARD_RSP:success !!');
            SetUpWizardMsg = mContext.l10n.discardPatchIsComplete;
            //'Discard patch is complete!!';
            SetUpWizardActionType = 'PATCH_DISCARD_RSP_SUCCESS';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_DISCARD_RSP_SUCCESS,
            );
            //kai_20230926 added
            CspPreference.setBool(CspPreference.pumpSetTimeReqDoneKey, false);
            refillTime = 0;

            ///<clear refill time here
          } else {
            log('${TAG}PATCH_DISCARD_RSP:failed to discard patch !!');
            SetUpWizardMsg = mContext.l10n.requestingDiscardPatchIsNotAvailable;
            // 'Requesting discard patch is not available at this time. Retry it?';
            SetUpWizardActionType = 'PATCH_DISCARD_RSP_FAILED';
            showSetUpWizardMsgDlg = true;
            setResponseMessage(
              RSPType.SETUP_DLG,
              SetUpWizardMsg,
              PATCH_DISCARD_RSP_FAILED,
            );
          }
        }
        break;

      case CareLevoCmd.PATCH_RESET_RPT:
        {
          // Length 2, RSP: 0x9F, MODE
          // Mode: 요청 시 받은 모드
          // 0x00 -> 패치의 Bonding list, NVM 삭제 후 리셋
          // 0x01 -> 패치의 Bonding list, NVM Data 유지 상태 리셋
          // RSP	MODE
          // 0x96	0x00
          if (buffer[1] == 0) {
            log('${TAG}PATCH_RESET_RPT:success !!');
            SetUpWizardMsg = mContext.l10n.resetPatchMode0IsComplete;
            //'Reset Patch mode 0 is complete!!';
            SetUpWizardActionType = 'PATCH_RESET_RPT_SUCCESS_MODE0';
            showSetUpWizardMsgDlg = true;
          } else if (buffer[1] == 1) {
            log('${TAG}PATCH_RESET_RPT:success !!');
            SetUpWizardMsg = mContext.l10n.resetPatchMode1IsComplete;
            //'Reset Patch mode 1 is complete!!?';
            SetUpWizardActionType = 'PATCH_RESET_RPT_SUCCESS_MODE1';
            showSetUpWizardMsgDlg = true;
          }

          //kai_20230926 added
          CspPreference.setBool(CspPreference.pumpSetTimeReqDoneKey, false);
          refillTime = 0;

          ///<clear refill time here
        }
        break;
    }
  }

  /*
   * @brief register ResponseCallback to handle a response message sent from pump
   */
  @override
  void setResponseCallbackListener(ResponseCallback callback) {
    // TODO: implement setResponseCallbackListener
    this._Responselistener = callback;
  }

  @override
  void releaseResponseCallbackListener() {
    // TODO: implement setResponseCallbackListener
    this._Responselistener = null;
  }

  /*
   * @brief get ResponseCallback listener
   */
  @override
  ResponseCallback? getResponseCallbackListener() {
    return _Responselistener;
  }

  /**
   * @brief default Response Callback Listener as common
   */
  void setDefaultResponseCallbackListener(ResponseCallback callback) {
    log('${TAG}kai:setDefaultResponseCallbackListener() is called');
    this._DefaultResponselistener = callback;
  }

  void releaseDefaultResponseCallbackListener() {
    log('${TAG}kai:releaseDefaultResponseCallbackListener() is called');
    this._DefaultResponselistener = null;
  }

  /*
   * @brief notify the response message sent from pump to caller by using the callback that caller registered
   */
  void setResponseMessage(RSPType indexRsp, String message, String ActionType) {
    if (_Responselistener != null) {
      _Responselistener!(indexRsp, message, ActionType);
    } else {
      if (_DefaultResponselistener != null) {
        log('kai:setResponseMessage():call _DefaultResponselistener');
        _DefaultResponselistener!(indexRsp, message, ActionType);
      } else {
        debugPrint('kai:setResponseMessage():_Responselistener is null');
        notifyListeners();

        ///< kai_20230614 let's notify an event to mCMgr.mPump!.addListener()
      }
    }
  }

  @override
  List<BluetoothDevice>? getScannedDeviceLists() {
    // TODO: implement getScannedDeviceLists
    return Devices;
  }

  @override
  String getManufacturerName() {
    // TODO: implement getManufacturerName
    return _ManufacturerName;
  }

  @override
  String getModelName() {
    // TODO: implement getModelName
    return _ModelName;
  }

  @override
  void clearDeviceInfo() {
    // TODO: implement clearDeviceInfo
    log('${TAG}clearDeviceInfo() is called');
    _isScanning = false;

    ///< scanning status
    _ConnectionStatus = BluetoothDeviceState.disconnected;

    ///< connection status
    _Devices.clear();

    ///< scanned device lists
    _ConnectedDevice = null;

    ///< connected device
    _ModelName = '';

    ///< Model Name
    _ManufacturerName = '';

    ///< Manufacturer Name
    _fw = '';

    ///< firmware
    _SN = '';

    ///< serial number
    _VC = '';

    ///< valid code
    _Battery = '';

    ///< battery status
    _ConnectedTime = 0;

    ///< first connected time
    _services.clear();

    ///< connected device's service
    ///
    bolusDeliveryValue = 0.0;

    lastBolusDeliveryValue = 0.0;

    ///<  bolus delivery value
    lastBolusDeliveryTime = 0;

    refillTime = 0;
    PatchUseAvailableTime = '0';
    reservoir = '0.0';

    //kai_20230519 let's release response callback listener when instance is changed
    // and call setResponse callback at the point of changing cgm instance as like menu options in PumpPage.dart
    releaseResponseCallbackListener();

    // let's call notify to update screen UI
    notifyListeners();
  }

  void changeNotifier() {
    notifyListeners();
  }
}

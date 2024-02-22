// Cgm class
/*
 * @brief the class Cgm is implemented for the ICgm interface
 */
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:developer';

import 'package:cloudloop_mobile/features/settings/domain/entities/xdrip_data.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ICgm.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Utilities.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/serviceUuid.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

//=========================  test flag here  ===================================//
const bool USE_DEBUG_MESSAGE = true;
//kai_20230519  if use simulation by using virtual cgm app then set true here,
//others set false;
const bool USE_SIMULATION_THRU_VIRTUAL_CGM = true;
//kai_20230529  add to use device name matching feature during scanning for
//Cgm peripheral
const bool USE_DEVICE_NAME_MATCHING = true;
//cgm set notify delay
const bool USE_CGM_SETNOTIFYDELAY = true;
//=========================  const variable here  ==============================//
//kai_20230804  let's delay time to set Notify for a characteristic.
const int NotifySetDelayTime = 1000;
//==============================================================================//

class Cgm extends ChangeNotifier implements ICgm {
  final String TAG = 'Cgm:';
  // IDevice, Icgm interface implementation
  FlutterBluePlus mCGMflutterBlue = FlutterBluePlus.instance;
  String mBOLUS_SERVICE = serviceUUID.CGMService_UUID;

  ///< current set cgm service UUID
  String mRX_READ_UUID = serviceUUID.Control_UUID;

  ///< current set cgm RX characteristic UUID
  String mTX_WRITE_UUID = serviceUUID.Control_UUID;

  ///< current set cgm TX characteristic UUID
  String mRXTX_AUTHENTICATION_UUID = serviceUUID.Authentication_UUID;

  ///< current set cgm RX TX Authentication characteristic UUID
  String mCGM_NAME = serviceUUID.DEXCOM_CGM_NAME;

  ///< current set cgm device name
  int mFindCharacteristicMax = 2;

  ///< current pump's supported characteristics for each type
  ///
  StreamSubscription<bool>? _cgmScanningSubscription = null;

  ///< current set cgm scanning status callback listener
  StreamSubscription<BluetoothDeviceState>? mCgmconnectionSubscription = null;

  ///< handle the connected cgm device connection status
  StreamSubscription<List<int>>? _cgmValueSubscription = null;

  StreamSubscription<List<int>>? get cgmValueSubscription =>
      _cgmValueSubscription;

  /// cgm device data listener
  StreamSubscription<List<int>>? _cgmAuthenValueSubscription = null;

  StreamSubscription<List<int>>? get cgmAuthenValueSubscription =>
      _cgmAuthenValueSubscription;

  set cgmValueSubscription(StreamSubscription<List<int>>? value) {
    _cgmValueSubscription = value;
  }

  ///< cgm battery data listener
  BluetoothCharacteristic? _CgmTxCharacteristic = null;

  ///< current set cgm TX characteristic instance
  BluetoothCharacteristic? _CgmRxCharacteristic = null;

  ///< current set cgm RX characteristic instance
  BluetoothCharacteristic? _CgmRXTXAuthenCharacteristic = null;

  BluetoothCharacteristic? get CgmRxCharacteristic => _CgmRxCharacteristic;

  ///< current set cgm RX TX Authen characteristic instance
  //===============   attribute here =====================//
  bool _iscgmscanning = false;

  ///< scanning status
  BluetoothDeviceState _cgmConnectionStatus = BluetoothDeviceState.disconnected;

  ///< connection status
  List<BluetoothDevice> _cgmDevices = [];

  ///< scanned device lists
  BluetoothDevice? _cgmConnectedDevice;

  ///< connected device
  String _cgmModelName = '';

  set cgmModelName(String value) {
    _cgmModelName = value;
  }

  ///< Model Name
  String _cgmManufacturerName = '';

  ///< Manufacturer Name
  String _cgmfw = '';

  ///< firmware
  String _cgmSN = '';

  ///< serial number
  String _cgmVC = '';

  ///< valid code
  String _cgmBattery = '';

  ///< battery status
  int _cgmConnectedTime = 0;

  XdripData? _collectBloodGlucose;

  int _lastBloodGlucoseValue = 0;

  final List<int> _bloodGlucoseHistoryList = [];

  final List<String> _receivedTimeHistoryList = [];

  final List<double> _iobCalculateHistoryList = [];

  ///< first connected time
  List<BluetoothService> _services = [];

  ///< connected device's service
  ///
  int _cgmBGlucoseValue = 0;

  ///< cgm bloodglucose value
  int _lastTimeBGReceived = 0;

  ///< latest received time

  int _transmitterInsertTime = 0;

  ///< CGM transmitter insert time
  int gettransmitterInsertTime() {
    _transmitterInsertTime =
        CspPreference.getInt(CspPreference.transmitterInsertTimeKey);
    return _transmitterInsertTime;
  }

  set transmitterInsertTime(int value) {
    _transmitterInsertTime = value;
    CspPreference.setInt(CspPreference.transmitterInsertTimeKey, value);
  }

  int _lastCalibrationTime = 0;

  ///< CGM transmitter last calibration time
  int getlastCalibrationTime() {
    _lastCalibrationTime =
        CspPreference.getInt(CspPreference.lastCalibrationTimeKey);
    return _lastCalibrationTime;
  }

  set lastCalibrationTime(int value) {
    _lastCalibrationTime = value;
    CspPreference.setInt(CspPreference.lastCalibrationTimeKey, value);
  }

  //================  additional variable get/set method here ==================//
  ResponseCallback? _Responselistener;
  //kai_20230802 add to common response listener for all cgm
  ResponseCallback? _DefaultResponselistener;

  ///< listen a response sent from Cgm and notify a message to caller

  //=================  methods here  =====================//
  bool get iscgmscanning => _iscgmscanning;

  ///< scanning status
  BluetoothDeviceState get cgmConnectionStatus => _cgmConnectionStatus;

  ///< cgm connection status
  List<BluetoothDevice> get cgmDevices => _cgmDevices;

  ///< scanned cgm device lists
  BluetoothDevice? get cgmConnectedDevice => _cgmConnectedDevice;

  ///< connected cgm device
  String get cgmfw => _cgmfw;

  ///< cgm firmware version
  String get cgmSN => _cgmSN;

  ///< serial number
  String get cgmVC => _cgmVC;

  ///< valid code
  String get cgmBattery => _cgmBattery;

  ///< cgm battery
  int get cgmConnectedTime => _cgmConnectedTime;

  ///< cgm first connected time

  set iscgmscanning(bool value) {
    _iscgmscanning = value;
  }

  set cgmConnectionStatus(BluetoothDeviceState value) {
    _cgmConnectionStatus = value;
  }

  set cgmDevices(List<BluetoothDevice> value) {
    _cgmDevices = value;
  }

  set cgmConnectedDevice(BluetoothDevice? value) {
    _cgmConnectedDevice = value;
  }

  set cgmfw(String value) {
    _cgmfw = value;
  }

  set cgmSN(String value) {
    _cgmSN = value;
  }

  set cgmVC(String value) {
    _cgmVC = value;
  }

  set cgmBattery(String value) {
    _cgmBattery = value;
  }

  set cgmConnectedTime(int value) {
    _cgmConnectedTime = value;
  }

  set services(List<BluetoothService> value) {
    _services = value;
  }

  //================================   creator  ================================//
  Cgm() {
    _init();
  }

  Future<void> _init() async {
    //register scan status listener here
    mCGMflutterBlue = FlutterBluePlus.instance;
    _cgmScanningSubscription = mCGMflutterBlue.isScanning.listen((isScanning) {
      iscgmscanning = isScanning;
      debugPrint('${TAG}Cgm.iscgmscanning = $iscgmscanning');
      notifyListeners();
      setResponseMessage(
        RSPType.UPDATE_SCREEN,
        'cgm update screen',
        'CGM_SCAN_UPDATE',
      );
    });
    // cspPreference.initPrefs();
  }

  @override
  Future<List<BluetoothDevice>?> startScan(int timeout) async {
    // ...
    if (timeout < 1) {
      timeout = 5;
    }

    // check device lists are not empty then let's clear it before starting scan
    if (_cgmDevices != null && _cgmDevices.isNotEmpty) {
      debugPrint('${TAG}kai:startScan:clear cgmDevices list');
      _cgmDevices.clear();
    }

    if (_iscgmscanning == true) {
      debugPrint('${TAG}kai:startScan:stop the previous scanning');
      if (mCGMflutterBlue != null) {
        await mCGMflutterBlue.stopScan();
      } else {
        mCGMflutterBlue = FlutterBluePlus.instance;
        await mCGMflutterBlue.stopScan();
      }
    }

    _iscgmscanning = true;
    /*FlutterBluePlus.instance*/
    mCGMflutterBlue
        .scan(timeout: Duration(seconds: timeout))
        .listen((scanResult) {
      if (scanResult.device.name != null) {
        //let's check specified device name here for each manufacturer
        /* example
        Dexcom G5 ( refer to ths G5CollectionService.java implementation )
        G5 use authCharacteristic (read: notify, write ) for authentication
        , controlCharacteristic( read: Notify, write ) for get sensor Data
        for the handle the received data , refer to the 
        processRxCharacteristic() implementation

        String transmitterIdLastTwo = 
        Extensions.lastTwoCharactersOfString(defaultTransmitter.transmitterId);
        filters.add(new ScanFilter.Builder().setDeviceName("Dexcom" + 
        transmitterIdLastTwo).build());

        if (device.getName() != null) {
                String transmitterIdLastTwo = 
                Extensions.lastTwoCharactersOfString
                (defaultTransmitter.transmitterId);
                String deviceNameLastTwo = 
                Extensions.lastTwoCharactersOfString(device.getName());
                if (transmitterIdLastTwo.toUpperCase().equals
                (deviceNameLastTwo.toUpperCase())) {
                    connectToDevice(device);
                }
            }
        */

        if (USE_DEVICE_NAME_MATCHING == true) {
          if (!_cgmDevices.contains(scanResult.device)) {
            if (scanResult.device.name.contains(CspPreference.mCGM_NAME)) {
              log(
                '${TAG}kai:startScan:'
                '_cgmDevices.add(${scanResult.device.name}), '
                'id(${scanResult.device.id})',
              );
              _cgmDevices.add(scanResult.device);
              notifyListeners();
            }
          }
        } else {
          _cgmDevices.add(scanResult.device);
          notifyListeners();
        }
      }
    }).onDone(() {
      _iscgmscanning = false;
      notifyListeners();
    });

    return _cgmDevices;
  }

  @override
  void stopScan() {
    // ...
    FlutterBluePlus.instance.stopScan();
  }

  @override
  Future<void> connectToDevice(BluetoothDevice device) async {
    // ...
    try {
      if (mCGMflutterBlue.isScanning == true) {
        await mCGMflutterBlue.stopScan();
      }
      //let's check current set pump type here
      final type = CspPreference.mCGM_NAME;
      debugPrint('${TAG}kai:cspPreference.mCGM_NAME = $type');

      if (type.contains(serviceUUID.DEXCOM_CGM_NAME)) {
        mBOLUS_SERVICE = serviceUUID.CGMService_UUID;

        ///< current set cgm service UUID
        mRX_READ_UUID = serviceUUID.Control_UUID;

        ///< current set cgm RX characteristic UUID
        mTX_WRITE_UUID = serviceUUID.Control_UUID;

        ///< current set cgm TX characteristic UUID
        mRXTX_AUTHENTICATION_UUID = serviceUUID.Authentication_UUID;

        ///< current set cgm RX TX Authentication characteristic UUID
        mCGM_NAME = serviceUUID.DEXCOM_CGM_NAME;

        ///< current set cgm device name
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: cgmtype = $type');
      } else if (type.contains(serviceUUID.ISENSE_CGM_NAME)) {
        mBOLUS_SERVICE = serviceUUID.CGMService_UUID;

        ///< current set cgm service UUID
        mRX_READ_UUID = serviceUUID.Control_UUID;

        ///< current set cgm RX characteristic UUID
        mTX_WRITE_UUID = serviceUUID.Control_UUID;

        ///< current set cgm TX characteristic UUID
        mRXTX_AUTHENTICATION_UUID = serviceUUID.Authentication_UUID;

        ///< current set cgm RX TX Authentication characteristic UUID
        mCGM_NAME = serviceUUID.DEXCOM_CGM_NAME;

        ///< current set cgm device name
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: cgmtype = $type');
      } else {
        mBOLUS_SERVICE = serviceUUID.CGMService_UUID;

        ///< current set cgm service UUID
        mRX_READ_UUID = serviceUUID.Control_UUID;

        ///< current set cgm RX characteristic UUID
        mTX_WRITE_UUID = serviceUUID.Control_UUID;

        ///< current set cgm TX characteristic UUID
        mRXTX_AUTHENTICATION_UUID = serviceUUID.Authentication_UUID;

        ///< current set cgm RX TX Authentication characteristic UUID
        mCGM_NAME = serviceUUID.DEXCOM_CGM_NAME;

        ///< current set cgm device name
        mFindCharacteristicMax = 2;
        debugPrint('${TAG}kai: cgmtype = $type');
      }

      debugPrint('${TAG}kai: connectToDevice(): call device.connect()');
      //kai_20230522  if use auto: true then connection does not established in android M.
      // i don't know why it happened
      if (USE_AUTO_CONNECTION == true) {
        // await device.connect();
        //kai_20230612 <start>
        Future<bool>? returnValue;
        await device.connect(autoConnect: true).timeout(
          const Duration(milliseconds: 10000),
          onTimeout: () {
            //타임아웃 발생
            //returnValue를 false로 설정
            returnValue = Future.value(false);
            debugPrint('kai:device.connect() timeout failed');
            notifyListeners();
            setResponseMessage(
              RSPType.UPDATE_SCREEN,
              'TimeoutToConnect',
              'TIMEOUT_CONNECT_TO_DEVICE_CGM',
            );
          },
        ).then((data) async {
          if (returnValue == null) {
            //returnValue가 null이면 timeout이 발생한 것이 아니므로 연결 성공
            debugPrint('connection successful');
            debugPrint(
              '${TAG}kai: connectToDevice(): call device.discoverServices()',
            );

            var findCharacteristic = 0;

            ///< clear
            final isfindDevice =
                await device.discoverServices().then((_services) async {
              if (USE_DEBUG_MESSAGE == true) {
                debugPrint(
                  '${TAG}kai: connectToDevice(): _services().length = '
                  '${_services.length}',
                );
              }
              var cnt = 0;

              for (final service in _services) {
                service.characteristics.forEach((characteristic) async {
                  cnt++;
                  if (USE_DEBUG_MESSAGE == true) {
                    log(
                      'kai:index($cnt):characteristic.uuid.toString()'
                      '.toLowerCase() = '
                      '${characteristic.uuid.toString().toLowerCase()}',
                    );
                    log(
                      'kai:index($cnt):mTX_WRITE_UUID.toLowerCase() = '
                      '${mTX_WRITE_UUID.toLowerCase()}',
                    );
                    log(
                      'kai:index($cnt):mRX_READ_UUID.toLowerCase() = '
                      '${mRX_READ_UUID.toLowerCase()}',
                    );
                    log(
                      'kai:index($cnt):mRXTX_AUTHENTICATION_UUID.toLowerCase() '
                      '= ${mRXTX_AUTHENTICATION_UUID.toLowerCase()}',
                    );
                    log(
                      'kai:index($cnt):findCharacteristic = '
                      '${findCharacteristic.toString()}',
                    );
                  }
                  if (characteristic.uuid.toString().toLowerCase() ==
                      mTX_WRITE_UUID.toLowerCase()) {
                    findCharacteristic = findCharacteristic + 1;
                    log(
                      '${TAG}findCharacteristic('
                      '$findCharacteristic):_CgmTxCharacteristic',
                    );
                    _CgmTxCharacteristic = characteristic;
                    //kai_20230520   add TX ==  RX case ( read/write/Notify together )
                    if (mTX_WRITE_UUID.toLowerCase() ==
                        mRX_READ_UUID.toLowerCase()) {
                      findCharacteristic = findCharacteristic + 1;
                      log(
                        '${TAG}RX=TX:findCharacteristic('
                        '$findCharacteristic):_CgmRxCharacteristic',
                      );
                      _CgmRxCharacteristic = characteristic;

                      //enable notify of the RX and register RX data value
                      //listener here
                      //check the characteristic have notify property and
                      //Notify is enabled first here
                      if (_CgmRxCharacteristic != null) {
                        if (_CgmRxCharacteristic!.properties.notify
                            //&& _CgmRxCharacteristic!.descriptors.isNotEmpty
                            ) {
                          //kai_20230620 move here due to that sometime
                          //does not called
                          log(
                            '${TAG}kai:RX=TX:call registerCgmValueListener '
                            '(handleCgmValue)',
                          );
                          registerCgmValueListener(handleCgmValue);

                          if (!_CgmRxCharacteristic!.isNotifying) {
                            try {
                              log(
                                '${TAG}kai:RX=TX:set '
                                '_CgmRxCharacteristic!.isNotifying is true',
                              );
                              await _CgmRxCharacteristic!.setNotifyValue(true);
                            } catch (e) {
                              debugPrint(
                                '${TAG}kai:RX=TX: _CgmRxCharacteristic notify '
                                'set error: uuid =  '
                                '${_CgmRxCharacteristic!.uuid} $e',
                              );
                            }
                          } else {
                            log(
                              '${TAG}kai:RX=TX:already '
                              '_CgmRxCharacteristic!.isNotifying is true',
                            );
                          }
                        } else {
                          log(
                            '${TAG}kai:RX=TX:do not have Notify property '
                            'in _CgmRxCharacteristic',
                          );
                        }

                        if (!_CgmRxCharacteristic!.descriptors.isNotEmpty) {
                          log(
                            '${TAG}kai:RX=TX:descriptor is empty '
                            'in _CgmRxCharacteristic',
                          );
                        }

                        //_CgmRxCharacteristic!.setNotifyValue(true);
                        //log(TAG + 'kai:RX=TX:call
                        //registerCgmValueListener(handleCgmValue)');
                        // registerCgmValueListener(handleCgmValue);
                        /* _CgmRxCharacteristic!.value.listen((value) {
                            handleCgmValue(value);
                          });
                        */
                        // await Future<void>.delayed(const
                        //Duration(milliseconds: 500));
                      } else {
                        log(
                          '${TAG}kai:RX=TX:_CgmRxCharacteristic!.'
                          'properties.notify is no & .descriptors.isEmpty',
                        );
                      }
                    }
                  } else if (characteristic.uuid.toString().toLowerCase() ==
                      mRX_READ_UUID.toLowerCase()) {
                    findCharacteristic = findCharacteristic + 1;
                    log(
                      '${TAG}findCharacteristic($findCharacteristic):'
                      '_CgmRxCharacteristic',
                    );
                    _CgmRxCharacteristic = characteristic;

                    //enable notify of the RX and register RX data
                    //value listener here
                    //check the characteristic have notify property
                    //and Notify is enabled first here
                    if (_CgmRxCharacteristic != null) {
                      if (_CgmRxCharacteristic!.properties.notify
                          // && _CgmRxCharacteristic!.descriptors.isNotEmpty
                          ) {
                        //_CgmRxCharacteristic!.setNotifyValue(true);
                        registerCgmValueListener(handleCgmValue);
                        /* _CgmRxCharacteristic!.value.listen((value) {
                          handleCgmValue(value);
                          });
                        */

                        if (!_CgmRxCharacteristic!.isNotifying) {
                          try {
                            log(
                              '${TAG}kai:set _CgmRxCharacteristic!.isNotifying '
                              'is true',
                            );
                            await _CgmRxCharacteristic!.setNotifyValue(true);
                          } catch (e) {
                            debugPrint(
                              '${TAG}kai: _CgmRxCharacteristic notify set '
                              'error: uuid =  ${_CgmRxCharacteristic!.uuid} $e',
                            );
                          }
                        } else {
                          log(
                            '${TAG}kai:already '
                            '_CgmRxCharacteristic!.isNotifying is true',
                          );
                        }
                      } else {
                        log(
                          '${TAG}kai:do not have Notify property in '
                          '_CgmRxCharacteristic',
                        );
                      }

                      if (!_CgmRxCharacteristic!.descriptors.isNotEmpty) {
                        log(
                          '${TAG}kai:descriptor is empty in '
                          '_CgmRxCharacteristic',
                        );
                      }

                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                    } else {
                      log(
                        '${TAG}kai:_CgmRxCharacteristic!.properties.notify is '
                        'no & .descriptors.isEmpty',
                      );
                    }
                  } else if (characteristic.uuid.toString().toLowerCase() ==
                      mRXTX_AUTHENTICATION_UUID.toLowerCase()) {
                    findCharacteristic = findCharacteristic + 1;
                    log(
                      '${TAG}findCharacteristic($findCharacteristic):'
                      '_CgmRXTXAuthenCharacteristic',
                    );
                    _CgmRXTXAuthenCharacteristic = characteristic;
                  }
                });

                if (findCharacteristic >= mFindCharacteristicMax) {
                  _cgmConnectedDevice = device;
                  _cgmConnectionStatus = BluetoothDeviceState.connected;
                  _cgmConnectedTime = DateTime.now().millisecondsSinceEpoch;
                  _cgmModelName = device.name;
                  notifyListeners();

                  //register connection status listener here
                  registerCgmStateCallback(CgmConnectionStatus);
                  // mCgmconnectionSubscription =
                  // _ConnectedDevice!.state.listen((event) { });

                  //register cgm authentication Rx TX characteristic
                  // value listener and set notify as enable here
                  if (_CgmRXTXAuthenCharacteristic != null) {
                    if (_CgmRXTXAuthenCharacteristic!.properties.notify
                        //&& _CgmRXTXAuthenCharacteristic!.
                        //descriptors.isNotEmpty
                        ) {
                      //_CgmRXTXAuthenCharacteristic!.setNotifyValue(true);
                      registerCgmAuthenValueListener(handleCgmAuthenValue);
                      /* _CgmRXTXAuthenCharacteristic!.value.listen((value) {
                        handleCgmAuthenValue(value);
                          });
                      */

                      if (!_CgmRXTXAuthenCharacteristic!.isNotifying) {
                        try {
                          log(
                            '${TAG}kai:set '
                            '_CgmRXTXAuthenCharacteristic!.isNotifying is true',
                          );
                          await _CgmRXTXAuthenCharacteristic!
                              .setNotifyValue(true);
                        } catch (e) {
                          debugPrint(
                            '$TAG _CgmRXTXAuthenCharacteristic notify set '
                            'error: uuid =  '
                            '${_CgmRXTXAuthenCharacteristic!.uuid} $e',
                          );
                        }
                      } else {
                        log(
                          '${TAG}kai:already '
                          '_CgmRXTXAuthenCharacteristic!.isNotifying is true',
                        );
                      }

                      if (!_CgmRXTXAuthenCharacteristic!
                          .descriptors.isNotEmpty) {
                        log(
                          '${TAG}kai:descriptor is empty in '
                          '_CgmRXTXAuthenCharacteristic',
                        );
                      }
                    } else {
                      log(
                        '${TAG}kai:do not have Notify property in '
                        '_CgmRXTXAuthenCharacteristic',
                      );
                    }
                  } else {
                    log(
                      '${TAG}kai:_CgmRXTXAuthenCharacteristic!.properties.'
                      'notify is no & .descriptors.isEmpty',
                    );
                  }

                  notifyListeners();
                  setResponseMessage(
                    RSPType.UPDATE_SCREEN,
                    'connected',
                    'CONNECT_TO_DEVICE_CGM',
                  );

                  return true;
                }
              }
              return false;
            }).catchError((dynamic error) {
              log('kai: CGM Error discovering services: $error');
              return false;
            });

            if (!isfindDevice) {
              debugPrint(
                '$TAG: connectToDevice:discovery: there is no matched device !',
              );
            } else {
              //kai_20230521
              debugPrint(
                '$TAG: connectToDevice: call sendBooldGlucoseRequestCgm() !!!',
              );
              await sendBooldGlucoseRequestCgm(null);
            }

            returnValue = Future.value(true);
          }
        });
        //<end>
      } else {
        // await device.connect(autoConnect: false);
        //kai_20230612 <start>
        Future<bool>? returnValue;
        await device.connect(autoConnect: false).timeout(
          const Duration(milliseconds: 10000),
          onTimeout: () {
            //타임아웃 발생
            //returnValue를 false로 설정
            returnValue = Future.value(false);
            debugPrint('kai:device.connect(autoConnect: false) timeout failed');
            notifyListeners();
            setResponseMessage(
              RSPType.UPDATE_SCREEN,
              'TimeoutToConnect',
              'TIMEOUT_CONNECT_TO_DEVICE_CGM',
            );
            //연결 상태 disconnected로 변경
            //setBleConnectionState(BluetoothDeviceState.disconnected);
          },
        ).then((data) async {
          if (returnValue == null) {
            //returnValue가 null이면 timeout이 발생한 것이 아니므로 연결 성공
            debugPrint('connection successful');
            debugPrint(
              '${TAG}kai: connectToDevice(autoConnect: false): call '
              'device.discoverServices()',
            );

            var findCharacteristic = 0;

            ///< clear
            final isfindDevice =
                await device.discoverServices().then((_services) async {
              if (USE_DEBUG_MESSAGE == true) {
                debugPrint(
                  '${TAG}kai: connectToDevice(): _services().length = '
                  '${_services.length}',
                );
              }
              var cnt = 0;

              for (final service in _services) {
                service.characteristics.forEach((characteristic) async {
                  cnt++;
                  if (USE_DEBUG_MESSAGE == true) {
                    log(
                      'kai:index($cnt):characteristic.uuid.toString().'
                      'toLowerCase() = '
                      '${characteristic.uuid.toString().toLowerCase()}',
                    );
                    log(
                      'kai:index($cnt):mTX_WRITE_UUID.toLowerCase() = '
                      '${mTX_WRITE_UUID.toLowerCase()}',
                    );
                    log(
                      'kai:index($cnt):mRX_READ_UUID.toLowerCase() = '
                      '${mRX_READ_UUID.toLowerCase()}',
                    );
                    log(
                      'kai:index($cnt):mRXTX_AUTHENTICATION_UUID.toLowerCase() '
                      '= ${mRXTX_AUTHENTICATION_UUID.toLowerCase()}',
                    );
                    log(
                      'kai:index($cnt):findCharacteristic = '
                      '${findCharacteristic.toString()}',
                    );
                  }
                  if (characteristic.uuid.toString().toLowerCase() ==
                      mTX_WRITE_UUID.toLowerCase()) {
                    findCharacteristic = findCharacteristic + 1;
                    log(
                      '${TAG}findCharacteristic($findCharacteristic):'
                      '_CgmTxCharacteristic',
                    );
                    _CgmTxCharacteristic = characteristic;
                    //kai_20230520   add TX ==  RX case ( read/write/Notify together )
                    if (mTX_WRITE_UUID.toLowerCase() ==
                        mRX_READ_UUID.toLowerCase()) {
                      findCharacteristic = findCharacteristic + 1;
                      log(
                        '${TAG}RX=TX:findCharacteristic($findCharacteristic):'
                        '_CgmRxCharacteristic',
                      );
                      _CgmRxCharacteristic = characteristic;

                      //enable notify of the RX and register RX data value
                      //listener here
                      //check the characteristic have notify property and
                      //Notify is enabled first here
                      if (_CgmRxCharacteristic != null) {
                        if (_CgmRxCharacteristic!.properties.notify
                            //&& _CgmRxCharacteristic!.descriptors.isNotEmpty
                            ) {
                          //kai_20230620 move here due to that sometime does
                          //not called
                          log(
                            '${TAG}kai:RX=TX:call registerCgmValueListener '
                            '(handleCgmValue)',
                          );
                          registerCgmValueListener(handleCgmValue);

                          if (!_CgmRxCharacteristic!.isNotifying) {
                            try {
                              log(
                                '${TAG}kai:RX=TX:set '
                                '_CgmRxCharacteristic!.isNotifying is true',
                              );
                              if (USE_CGM_SETNOTIFYDELAY == true) {
                                //kai_20230804 blocked await due to the case that setnotify9true)'s response doee not get back from cgm device
                                _CgmRxCharacteristic!.setNotifyValue(true);
                                await Future<void>.delayed(
                                  const Duration(
                                      milliseconds: NotifySetDelayTime),
                                );
                              } else {
                                await CgmRxCharacteristic!.setNotifyValue(true);
                              }
                            } catch (e) {
                              debugPrint(
                                '${TAG}kai:RX=TX: _CgmRxCharacteristic notify '
                                'set error: uuid =  '
                                '${_CgmRxCharacteristic!.uuid} $e',
                              );
                            }
                          } else {
                            log(
                              '${TAG}kai:RX=TX:already '
                              '_CgmRxCharacteristic!.isNotifying is true',
                            );
                          }
                        } else {
                          log(
                            '${TAG}kai:RX=TX:do not have Notify property '
                            'in _CgmRxCharacteristic',
                          );
                        }

                        if (!_CgmRxCharacteristic!.descriptors.isNotEmpty) {
                          log(
                            '${TAG}kai:RX=TX:descriptor is empty in '
                            '_CgmRxCharacteristic',
                          );
                        }

                        //_CgmRxCharacteristic!.setNotifyValue(true);
                        //log(TAG + 'kai:RX=TX:call
                        //registerCgmValueListener(handleCgmValue)');
                        // registerCgmValueListener(handleCgmValue);
                        /* _CgmRxCharacteristic!.value.listen((value) {
                            handleCgmValue(value);
                          });
                        */
                        // await Future<void>.delayed(const
                        //Duration(milliseconds: 500));
                      } else {
                        log(
                          '${TAG}kai:RX=TX:_CgmRxCharacteristic!.properties.'
                          'notify is no & .descriptors.isEmpty',
                        );
                      }
                    }
                  } else if (characteristic.uuid.toString().toLowerCase() ==
                      mRX_READ_UUID.toLowerCase()) {
                    findCharacteristic = findCharacteristic + 1;
                    log(
                      '${TAG}findCharacteristic($findCharacteristic):'
                      '_CgmRxCharacteristic',
                    );
                    _CgmRxCharacteristic = characteristic;

                    //enable notify of the RX and register RX data value
                    //listener here
                    //check the characteristic have notify property and
                    //Notify is enabled first here
                    if (_CgmRxCharacteristic != null) {
                      if (_CgmRxCharacteristic!.properties.notify
                          // && _CgmRxCharacteristic!.descriptors.isNotEmpty
                          ) {
                        //_CgmRxCharacteristic!.setNotifyValue(true);
                        registerCgmValueListener(handleCgmValue);
                        /* _CgmRxCharacteristic!.value.listen((value) {
                          handleCgmValue(value);
                          });
                        */

                        if (!_CgmRxCharacteristic!.isNotifying) {
                          try {
                            log(
                              '${TAG}kai:set _CgmRxCharacteristic!.isNotifying '
                              'is true',
                            );
                            if (USE_CGM_SETNOTIFYDELAY == true) {
                              //kai_20230804 blocked await due to the case that setnotify9true)'s response doee not get back from cgm device
                              _CgmRxCharacteristic!.setNotifyValue(true);
                              await Future<void>.delayed(
                                const Duration(
                                    milliseconds: NotifySetDelayTime),
                              );
                            } else {
                              await _CgmRxCharacteristic!.setNotifyValue(true);
                            }
                          } catch (e) {
                            debugPrint(
                              '${TAG}kai: _CgmRxCharacteristic notify set '
                              'error: uuid =  ${_CgmRxCharacteristic!.uuid} $e',
                            );
                          }
                        } else {
                          log(
                            '${TAG}kai:already '
                            '_CgmRxCharacteristic!.isNotifying is true',
                          );
                        }
                      } else {
                        log(
                          '${TAG}kai:do not have Notify property in '
                          '_CgmRxCharacteristic',
                        );
                      }

                      if (!_CgmRxCharacteristic!.descriptors.isNotEmpty) {
                        log(
                          '${TAG}kai:descriptor is empty in '
                          '_CgmRxCharacteristic',
                        );
                      }

                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                    } else {
                      log(
                        '${TAG}kai:_CgmRxCharacteristic!.properties.notify is '
                        'no & .descriptors.isEmpty',
                      );
                    }
                  } else if (characteristic.uuid.toString().toLowerCase() ==
                      mRXTX_AUTHENTICATION_UUID.toLowerCase()) {
                    findCharacteristic = findCharacteristic + 1;
                    log(
                      '${TAG}findCharacteristic($findCharacteristic):'
                      '_CgmRXTXAuthenCharacteristic',
                    );
                    _CgmRXTXAuthenCharacteristic = characteristic;
                  }
                });

                if (findCharacteristic >= mFindCharacteristicMax) {
                  _cgmConnectedDevice = device;
                  _cgmConnectionStatus = BluetoothDeviceState.connected;
                  _cgmConnectedTime = DateTime.now().millisecondsSinceEpoch;
                  _cgmModelName = device.name;
                  notifyListeners();

                  //register connection status listener here
                  registerCgmStateCallback(CgmConnectionStatus);
                  // mCgmconnectionSubscription = _ConnectedDevice!.state.
                  // listen((event) { });

                  //register cgm authentication Rx TX characteristic value
                  // listener and set notify as enable here
                  if (_CgmRXTXAuthenCharacteristic != null) {
                    if (_CgmRXTXAuthenCharacteristic!.properties.notify
                        //&& _CgmRXTXAuthenCharacteristic!.descriptors.isNotEmpty
                        ) {
                      //_CgmRXTXAuthenCharacteristic!.setNotifyValue(true);
                      registerCgmAuthenValueListener(handleCgmAuthenValue);
                      /* _CgmRXTXAuthenCharacteristic!.value.listen((value) {
                        handleCgmAuthenValue(value);
                          });
                      */

                      if (!_CgmRXTXAuthenCharacteristic!.isNotifying) {
                        try {
                          log(
                            '${TAG}kai:set '
                            '_CgmRXTXAuthenCharacteristic!.isNotifying is true',
                          );

                          if (USE_CGM_SETNOTIFYDELAY == true) {
                            //kai_20230804 blocked await due to the case that setnotify9true)'s response doee not get back from cgm device
                            _CgmRXTXAuthenCharacteristic!.setNotifyValue(true);
                            await Future<void>.delayed(
                              const Duration(milliseconds: NotifySetDelayTime),
                            );
                          } else {
                            await _CgmRXTXAuthenCharacteristic!
                                .setNotifyValue(true);
                          }

                          log('${TAG}kai: after call _CgmRXTXAuthenCharacteristic!.setNotifyValue(true)');
                        } catch (e) {
                          debugPrint(
                            '$TAG _CgmRXTXAuthenCharacteristic notify set '
                            'error: uuid = '
                            '${_CgmRXTXAuthenCharacteristic!.uuid} $e',
                          );
                        }
                      } else {
                        log(
                          '${TAG}kai:already '
                          '_CgmRXTXAuthenCharacteristic!.isNotifying is true',
                        );
                      }

                      if (!_CgmRXTXAuthenCharacteristic!
                          .descriptors.isNotEmpty) {
                        log(
                          '${TAG}kai:descriptor is empty in '
                          '_CgmRXTXAuthenCharacteristic',
                        );
                      }
                    } else {
                      log(
                        '${TAG}kai:do not have Notify property in '
                        '_CgmRXTXAuthenCharacteristic',
                      );
                    }
                  } else {
                    log(
                      '${TAG}kai:_CgmRXTXAuthenCharacteristic!.properties.'
                      'notify is no & .descriptors.isEmpty',
                    );
                  }

                  notifyListeners();
                  setResponseMessage(
                    RSPType.UPDATE_SCREEN,
                    'connected',
                    'CONNECT_TO_DEVICE_CGM',
                  );

                  return true;
                }
              }
              return false;
            }).catchError((dynamic error) {
              debugPrint('$TAG:kai: CGM Error discovering services: $error');
              return false;
            });

            if (!isfindDevice) {
              debugPrint(
                '$TAG:kai:connectToDevice:discovery: there is no matched device!!',
              );
            } else {
              //kai_20230521
              debugPrint(
                '$TAG:kai:connectToDevice: call sendBooldGlucoseRequestCgm() !!!',
              );
              await sendBooldGlucoseRequestCgm(null);
            }

            returnValue = Future.value(true);
          }
        });
        //<end>
      }
    } catch (e) {
      debugPrint('${TAG}kai:Error connecting to device: $e');
    }

    debugPrint('${TAG}kai: end connectToDevice !!!');
  }

  @override
  Future<void> disconnectFromDevice() async {
    // ...
    await _cgmConnectedDevice?.disconnect();
    _cgmConnectedDevice = null;
    _cgmConnectionStatus = BluetoothDeviceState.disconnected;
    notifyListeners();
    // setResponseMessage(RSPType.UPDATE_SCREEN, 'disconnected',
    // 'DISCONNECT_FROM_DEVICE_CGM');
    //kai_20230621  separate type of disconnection [ from user action / from device away ]
    setResponseMessage(
      RSPType.UPDATE_SCREEN,
      'disconnected',
      'DISCONNECT_FROM_USER_ACTION',
    );
  }

  @override
  Future<List<BluetoothService>?> discoverServices() async {
    // ...
    return _services;
  }

  @override
  BluetoothDevice? getConnectedDevice() {
    // ...
    return _cgmConnectedDevice;
  }

  @override
  String getFirmwareVersion() {
    // ...
    return _cgmfw;
  }

  @override
  String getSerialNumber() {
    // ...
    return _cgmSN;
  }

  @override
  String getVerificationCode() {
    // ...
    return _cgmVC;
  }

  @override
  String getBatteryLevel() {
    // ...
    return _cgmBattery;
  }

  @override
  int getConnectedTime() {
    // ...
    return _cgmConnectedTime;
  }

  @override
  XdripData? getCollectBloodGlucose() {
    // ...
    return _collectBloodGlucose;
  }

  @override
  Future<List<BluetoothCharacteristic>?> discoverCharacteristics(
    BluetoothService service,
  ) async {
    // TODO: implement discoverCharacteristics
    try {
      final characteristics = await service.characteristics;
      return characteristics;
    } catch (e) {
      log('${TAG}Error discovering characteristics: $e');
      return null;
    }
  }

  @override
  Future<BluetoothCharacteristic?> getCharacteristic(String uuid) async {
    try {
      if (_cgmConnectedDevice == null) {
        throw Exception('CGM device not connected');
      }
      final services = await _cgmConnectedDevice!.discoverServices();
      for (final service in services) {
        final characteristics = await service.characteristics;
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

  // ICgm interface implementation
  @override
  int getBloodGlucoseValue() {
    // ...
    return _cgmBGlucoseValue;
  }

  @override
  int getLastTimeBGReceived() {
    // ...
    return _lastTimeBGReceived;
  }

  @override
  void setBloodGlucoseValue(int _value) {
    _cgmBGlucoseValue = _value;
  }

  @override
  int getLastBloodGlucose() {
    return _lastBloodGlucoseValue;
  }

  @override
  void setLastBloodGlucose(int _value) {
    _lastBloodGlucoseValue = _value;
  }

  @override
  void setCollectBloodGlucose(XdripData _value) {
    _collectBloodGlucose = _value;
  }

  @override
  void setLastTimeBGReceived(int _value) {
    _lastTimeBGReceived = _value;
  }

  @override
  void setBloodGlucoseHistoryList(int initial, int _value) {
    if (initial == 1) {
      _bloodGlucoseHistoryList.add(_value);
    } else {
      _bloodGlucoseHistoryList.insert(0, _value);
    }
  }

  @override
  List<int> getBloodGlucoseHistoryList() {
    return _bloodGlucoseHistoryList;
  }

  @override
  void setRecievedTimeHistoryList(int initial, String _value) {
    if (initial == 1) {
      _receivedTimeHistoryList.add(_value);
    } else {
      _receivedTimeHistoryList.insert(0, _value);
    }
  }

  @override
  List<String> getRecievedTimeHistoryList() {
    return _receivedTimeHistoryList;
  }

  @override
  void setIobCalculateHistoryList(double initial, double _value) {
    if (initial == 1) {
      _iobCalculateHistoryList.add(_value);
    } else {
      _iobCalculateHistoryList.insert(0, _value);
    }
  }

  @override
  List<double> getIobCalculateHistoryList() {
    return _iobCalculateHistoryList;
  }

  set cgmManufacturerName(String value) {
    _cgmManufacturerName = value;
  }

  @override
  void releaseResponseCallbackListener() {
    // TODO: implement releaseResponseCallbackListener
    log('${TAG}kai:releaseResponseCallbackListener() is called');
    this._Responselistener = null;
  }

  @override
  void setResponseCallbackListener(ResponseCallback callback) {
    // TODO: implement setResponseCallbackListener
    log('${TAG}kai:setResponseCallbackListener() is called');
    this._Responselistener = callback;
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
   * @brief notify the response message sent from Cgm to caller by using the callback that caller registered
   */
  void setResponseMessage(RSPType indexRsp, String message, String ActionType) {
    if (_Responselistener != null) {
      _Responselistener!(indexRsp, message, ActionType);
    } else {
      if (_DefaultResponselistener != null) {
        _DefaultResponselistener!(indexRsp, message, ActionType);
      } else {
        debugPrint('${TAG}kai:setResponseMessage():_Responselistener is null');
        notifyListeners();

        ///< kai_20230614 let's notify an event to mCMgr.mPump!.addListener()
      }
    }
  }

  @override
  List<BluetoothDevice>? getScannedDeviceLists() {
    // TODO: implement getScannedDeviceLists
    return cgmDevices;
  }

  @override
  String getManufacturerName() {
    // TODO: implement getManufacturerName
    return _cgmManufacturerName;
  }

  @override
  String getModelName() {
    // TODO: implement getModelName
    return _cgmModelName;
  }

  @override
  void clearDeviceInfo() {
    // TODO: implement clearDeviceInfo
    log('${TAG}clearDeviceInfo() is called');
    _iscgmscanning = false;

    ///< scanning status
    _cgmConnectionStatus = BluetoothDeviceState.disconnected;

    ///< connection status
    _cgmDevices.clear();

    ///< scanned device lists
    _cgmConnectedDevice = null;

    ///< connected device
    _cgmModelName = '';

    ///< Model Name
    _cgmManufacturerName = '';

    ///< Manufacturer Name
    _cgmfw = '';

    ///< firmware
    _cgmSN = '';

    ///< serial number
    _cgmVC = '';

    ///< valid code
    _cgmBattery = '';

    ///< battery status
    _cgmConnectedTime = 0;

    ///< first connected time
    _services.clear();

    ///< connected device's service
    ///
    _cgmBGlucoseValue = 0;

    ///< cgm bloodglucose value
    _lastTimeBGReceived = 0;

    ///< latest received time

    //kai_20230519 let's release response callback listener
    //when instance is changed
    //and call setResponse callback at the point of changing cgm instance as
    //like menu options in cgmPage.dart
    releaseResponseCallbackListener();
    // let's call notify to update screen UI
    notifyListeners();
  }

  void registerCgmAuthenValueListener(Function(List<int> p1) listener) {
    // TODO: implement registerCgmAuthenValueListener
    if (_CgmRXTXAuthenCharacteristic != null) {
      debugPrint('${TAG}registerCgmAuthenValueListener():is called');
      _cgmAuthenValueSubscription =
          _CgmRXTXAuthenCharacteristic!.value.listen((value) {
        listener(value);
      });
    } else {
      debugPrint(
        '${TAG}registerCgmAuthenValueListener():_CgmRXTXAuthenCharacteristic is NULL',
      );
    }
  }

  void registerCgmStateCallback(
    void Function(BluetoothDeviceState p1) callback,
  ) {
    // TODO: implement registerCgmStateCallback
    if (_cgmConnectedDevice == null) {
      debugPrint(
        '${TAG}registerCgmStateCallback():_cgmConnectedDevice is NULL',
      );
    } else {
      debugPrint('${TAG}registerCgmStateCallback():is called');
      mCgmconnectionSubscription = _cgmConnectedDevice!.state.listen(callback);
    }
  }

  void registerCgmValueListener(Function(List<int> p1) listener) {
    // TODO: implement registerCgmValueListener
    if (_CgmRxCharacteristic != null) {
      debugPrint('${TAG}registerCgmValueListener():is called');
      _cgmValueSubscription = _CgmRxCharacteristic!.value.listen((value) {
        listener(value);
      });
    } else {
      debugPrint(
        '${TAG}registerCgmValueListener():_CgmRxCharacteristic is NULL',
      );
    }
  }

  void unregisterCgmAuthenValueListener() {
    // TODO: implement unregisterCgmAuthenValueListener
    debugPrint('${TAG}unregisterCgmAuthenValueListener():is called');
    if (_cgmAuthenValueSubscription != null) {
      _cgmAuthenValueSubscription!.cancel();
      _cgmAuthenValueSubscription = null;
    }
  }

  void unregisterCgmStateCallback() {
    // TODO: implement unregisterCgmStateCallback
    debugPrint('${TAG}unregisterCgmStateCallback():is called');
    mCgmconnectionSubscription?.cancel();
    mCgmconnectionSubscription = null;
  }

  Future<void> unregisterCgmValueListener() async {
    // TODO: implement unregisterCgmValueListener
    debugPrint('${TAG}unregisterCgmValueListener():is called');
    if (_cgmValueSubscription != null) {
      await _cgmValueSubscription!.cancel();
      _cgmValueSubscription = null;
    }
  }

  void CgmConnectionStatus(BluetoothDeviceState state) {
    // TODO: implement CgmConnectionStatus to monitor the connection status change event
    if (_cgmConnectionStatus == state) {
      // if connection status is same then ignore
      return;
    }

    switch (state) {
      case BluetoothDeviceState.connected:
        {
          _cgmConnectionStatus = state;
          debugPrint('${TAG}Connected to Cgm');
          if (getConnectedDevice() != null) {
            cgmModelName = getConnectedDevice()!.name.toString();
          }
          notifyListeners();

          //let's set timer after 5 secs trigger to check RX
          //characteristic and battery Notify
          Future.delayed(const Duration(seconds: 5), () async {
            //if _pumpValueSubscription is not registered then register here
            if (_cgmValueSubscription == null) {
              debugPrint(
                '${TAG}kai: register RX_Read characteristic for value listener '
                'due to auto reconnection ',
              );
              if (_CgmRxCharacteristic != null) {
                registerCgmValueListener(handleCgmValue);
                if (!_CgmRxCharacteristic!.isNotifying) {
                  debugPrint(
                    '${TAG}kai: register RX_Read characteristic set Notify due '
                    'to auto reconnection ',
                  );
                  await _CgmRxCharacteristic!.setNotifyValue(true);
                } else {
                  debugPrint(
                    '${TAG}kai: register RX_Read characteristic  Notify '
                    'already enabled: due to auto reconnection ',
                  );
                  await _CgmRxCharacteristic!.setNotifyValue(true);
                }
              }
            }
          });
        }
        break;

      case BluetoothDeviceState.connecting:
        _cgmConnectionStatus = state;
        debugPrint('${TAG}Connecting from Cgm');
        break;

      case BluetoothDeviceState.disconnected:
        {
          _cgmConnectionStatus = state;
          cgmModelName = '';
          //kai_20230621 need to update status
          //_cgmConnectedDevice = null;
          notifyListeners();
          setResponseMessage(
            RSPType.UPDATE_SCREEN,
            'disconnected',
            'DISCONNECT_FROM_DEVICE_CGM',
          );

          debugPrint('${TAG}Disconnected from Cgm');
          // kai_20230205 let's clear used resource and unregister used
          // listener here
          if (_cgmScanningSubscription != null) {
            _cgmScanningSubscription!.cancel();
            _cgmScanningSubscription = null;

            ///< scan result listener
          }

          if (mCgmconnectionSubscription != null) {
            // mCgmconnectionSubscription!.cancel();
            ///< connection status listener
            unregisterCgmStateCallback();
          }

          if (_CgmRxCharacteristic != null) {
            //  _CgmRxCharacteristic!.value.listen((event) {}).cancel();
            //  _CgmRxCharacteristic = null;
            ///< value change listener
            unregisterCgmValueListener();
          }

          if (_CgmRXTXAuthenCharacteristic != null) {
            // _CgmRXTXAuthenCharacteristic!.value.listen((event) {}).cancel();
            // _CgmRXTXAuthenCharacteristic = null;
            ///< Authentication value change listener
            unregisterCgmAuthenValueListener();
          }
        }
        break;

      case BluetoothDeviceState.disconnecting:
        _cgmConnectionStatus = state;
        debugPrint('${TAG}Disconnecting from Cgm');
        break;
    }
  }

/*
 * @brief should implement this function to 
 * handle the received data sent from CGM
 */
  void handleCgmValue(List<int> value) {
    // TODO: must implement handleCgmValue here to
    //handle the received data sent from the Cgm device.
    debugPrint('${TAG}kai:handleCgmValue:is called');
    if (value.isEmpty) {
      debugPrint(
        '${TAG}kai:handleCgmValue:cannot handle due to no input data,  return',
      );
      return;
    }

    //kai_20230519 let's check received data is json object format first here
    if (USE_SIMULATION_THRU_VIRTUAL_CGM == true) {
      String receivedData;
      // Try to decode as UTF-8
      try {
        receivedData = utf8.decode(value);
        debugPrint('${TAG}kai:handleCgmValue():receivedData = $receivedData');
        final dynamic decodedValue = json.decode(receivedData);
        if (decodedValue is Map<String, dynamic>) {
          // JSON 객체일 경우 필요한 처리 수행
          final receivedJsonObj = decodedValue;
          debugPrint('${TAG}kai:handleCgmValue():find json format');
          // 필드 값 추출
          /*
          String glucoseValue = receivedJsonObj['glucose'].toString();
          String timestampValue = receivedJsonObj['timestamp'].toString();
          String rawValue = receivedJsonObj['raw'].toString();
          String directionValue = receivedJsonObj['direction'].toString();
          String sourceValue = receivedJsonObj['source'].toString();
          */
          final glucoseValue = receivedJsonObj['g'].toString();
          //String timestampValue = receivedJsonObj['t'].toString();
          //String sourceValue = receivedJsonObj['s'].toString();

          // 추출한 필드 값을 활용하여 원하는 작업 수행
          const sourceValue = 'virtualCgm';
          final timeDate =
              int.parse(DateTime.now().millisecondsSinceEpoch.toString());
          // int timeDate = int.parse(timestampValue);
          setLastTimeBGReceived(timeDate);
          //kai_20230509 if Glucose have floating point as like double " 225.0 "
          //then convert the value to int exclude ".0" by using floor()
          // mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
          setBloodGlucoseValue(double.parse(glucoseValue).floor());
          cgmModelName = sourceValue;
          // ...
          notifyListeners();

          //let's notify updating to the registered client cgm widgit
          setResponseMessage(
            RSPType.UPDATE_SCREEN,
            'New Blood Glucose',
            'NEW_BLOOD_GLUCOSE',
          );
          return;
        } else {
          // JSON 객체가 아닐 경우 처리
          debugPrint('${TAG}kai:handleCgmValue():no json format');
          // ...
        }
      } on FormatException {
        debugPrint('${TAG}kai:handleCgmValue():FormatException');
        // If UTF-8 decoding fails, try ASCII decoding
        receivedData =
            ascii.decode(value.where((byte) => byte <= 0x7f).toList());
      }
    }

    final cgmname = CspPreference.mCGM_NAME.isEmpty
        ? serviceUUID.DEXCOM_CGM_NAME
        : CspPreference.mCGM_NAME;
    debugPrint('${TAG}kai:handleCgmValue:current set Cgm name = $cgmname');
    switch (cgmname) {
      case serviceUUID.DEXCOM_CGM_NAME:
        handleDexcomG5_6(value);
        break;

      case serviceUUID.ISENSE_CGM_NAME:
        handleIsenseCgm(value);
        break;

      default:
        handleDexcomG5_6(value);
        break;
    }
  }

  //=======================  parser for the received data ======================//
  /*
   * @brief Controller characteristic which have the properties [read/write(notify)]
   *        handler to parse the received data sent from the connected cgm device
   *        should implement this function
   */
  void handleDexcomG5_6(List<int> value) {
    // handle cgm dexcomG5 ~6 value
    if (value.isEmpty) {
      // 예외 처리
      log(
        '${TAG}kai: handleDexcomG5_6(): cannot handle due to no input data, '
        'return',
      );
      return;
    }

    final length = value.length;
    final hexString = value.map(toHexString).join(' ');
    final decimalString = value
        .map((hex) => hex.toRadixString(10))
        .join(' '); // convert decimal and convert String by using join
    if (USE_DEBUG_MESSAGE) {
      log('${TAG}kai: data length = $length');
      log('${TAG}kai : hexString value = $hexString');
      log('${TAG}kai : decimalString value = $decimalString');
    }

    // Process decoded string
    final buffer = List<int>.from(value);
    final code = buffer[0];
    log('${TAG}handleDexcomG5_6 is called : code = $code');

    switch (code) {
      default:
        break;
    }
  }

  void handleIsenseCgm(List<int> value) {
    if (value.isEmpty) {
      // 예외 처리
      log(
        '${TAG}kai: handleIsenseCgm(): cannot handle due to no input data, '
        'return',
      );
      return;
    }

    final length = value.length;
    final hexString = value.map(toHexString).join(' ');
    final decimalString = value
        .map((hex) => hex.toRadixString(10))
        .join(' '); // convert decimal and convert String by using join
    if (USE_DEBUG_MESSAGE) {
      log('${TAG}kai: data length = $length');
      log('${TAG}kai : hexString value = $hexString');
      log('${TAG}kai : decimalString value = $decimalString');
    }

    // Process decoded string
    final buffer = List<int>.from(value);
    final code = buffer[0];
    log('${TAG}handleIsenseCgm is called : code = $code');

    switch (code) {
      default:
        break;
    }
  }

  /*
   * @brief Authentication characteristic which have the properties [read/write(notify)]
   *        handler to parse the authentication received 
   *        data sent from Cgm device
   */
  void handleCgmAuthenValue(List<int> value) {
    if (value.isEmpty) {
      // 예외 처리
      log(
        '${TAG}kai: handleCgmAuthenValue(): cannot handle due to no input '
        'data, return',
      );
      return;
    }

    final LENGTH = value.length;
    final hexString = value.map(toHexString).join(' ');
    final decimalString = value
        .map((hex) => hex.toRadixString(10))
        .join(' '); // convert decimal and convert String by using join
    if (USE_DEBUG_MESSAGE) {
      log('${TAG}kai: data length = $LENGTH');
      log('${TAG}kai : hexString value = $hexString');
      log('${TAG}kai : decimalString value = $decimalString');
    }

    // Process decoded string
    final buffer = List<int>.from(value);
    final code = buffer[0];
    log('${TAG}handleCgmAuthenValue is called : code = $code');

    switch (code) {
      default:
        break;
    }
  }

  BluetoothCharacteristic? get cgmRXTXAuthenCharacteristic =>
      _CgmRXTXAuthenCharacteristic;

  set cgmAuthenValueSubscription(StreamSubscription<List<int>>? value) {
    _cgmAuthenValueSubscription = value;
  }

  Future<void> setForceRXNotify() async {
    if (_CgmTxCharacteristic != null) {
      try {
        if (!_CgmTxCharacteristic!.isNotifying) {
          log(
            '${TAG}SetForceRXNotify():_CgmTxCharacteristic!.isNotifying '
            '== false',
          );
          await _CgmTxCharacteristic!.setNotifyValue(true);
        } else {
          log(
            '${TAG}SetForceRXNotify():_CgmTxCharacteristic!.isNotifying '
            '== true, but force set enable !!',
          );
          //await _CgmTxCharacteristic!.setNotifyValue(true);
        }
      } catch (e) {
        log(
          '${TAG}SetRXNotify();characteristic notify set error: uuid = '
          '${_CgmTxCharacteristic!.uuid} $e',
        );
      }
    }
  }

  Future<void> sendDataToCgmDevice(String data) async {
    // TODO: implement sendDataToCgmDevice
    try {
      // Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      final bytes = data.codeUnits;
      if (USE_FORCE_ENABE_RXNOTIFY) {
        setForceRXNotify();
      }
      await _CgmTxCharacteristic!.write(bytes);
    } catch (e) {
      debugPrint('${TAG}Error sendDataToCgmDevice: $e');
    }
  }

  Future<void> sendBooldGlucoseRequestCgm(
    BluetoothCharacteristic? characteristic,
  ) async {
    // TODO: implement sendBooldGlucoseRequestCgm
    try {
      final sendBytes = <int>[0x30];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_CgmTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            setForceRXNotify();
            //Future.delayed(const Duration(seconds:2));
          }
          await _CgmTxCharacteristic!.write(sendBytes);
        } else {
          log('${TAG}Failed to send sendBooldGlucoseRequestCgm !!');
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error sendBooldGlucoseRequestCgm: $e');
      //kai_20230523 let's retry it again
/*
      //Future.delayed(const Duration(seconds: 3));
      Future.delayed(const Duration(seconds: 3), () async {
        List<int> sendBytes = [0x30];
        try {
          await _CgmTxCharacteristic!.write(sendBytes);
        }catch (e){
          debugPrint(TAG + 'Error retry sendBooldGlucoseRequestCgm: $e');
        }
      });
*/

    }
  }

  void changeNotifier() {
    notifyListeners();
  }
}

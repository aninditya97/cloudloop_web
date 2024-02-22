import 'dart:async';
import 'dart:convert';
import 'dart:developer';
//kai_20240127  import 'dart:ffi';
import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

/*
 * @brief kai_20230304
*        BluetoothProvide class provide several APIs and can be used in other pages by using get instance. *
*       if you want to register callback for a value listerner of the RX characteristic
*        then use the API as below example *
*       1. get the instance :  BluetoothProvider _bluetoothProvider = BluetoothProvider();
 *
 *  class _PumpDataPageState extends State<PumpDataPage> {
    BluetoothProvider _bluetoothProvider = BluetoothProvider();
    List<int> _pumpData = [];

    @override
    void initState() {
    super.initState();
    _bluetoothProvider.connectToPump();
    _bluetoothProvider.registerPumpValueListener((value) {
    setState(() {
    _pumpData = value;
    });
    });
    }

    @override
    void dispose() {
    super.dispose();
    _bluetoothProvider.disconnectDevices();
    _bluetoothProvider.unregisterPumpValueListener();
    }

    }
 *
 */
const bool FEATURE_CHECK_WR_CHARACTERISTIC = false;
const bool USE_DEBUG_MESSAGE = true;
const bool _USE_SCAN_IN_INIT_STATE = false;
/*
 * @brief USE_VALUE_SUBSCRIPTION_REGISTER_CALLBACK:
 *        If you want to register a callback which will be called when a data is received
 *        from bluetooth RX characteristic for CGM or PUMP and can update the data in the page widget,
 *         then define this feature as true.
 */
const bool USE_VALUE_SUBSCRIPTION_REGISTER_CALLBACK = true;
//kai_20230419 just testing caremedi max bolus injection threshold
// we have to disable inthe commercial release
const bool _USE_TEST_SET_MAX_BOLUS_THRESHOLD = false;

class BluetoothProvider with ChangeNotifier {
  late FlutterBluePlus mCGMflutterBlue;
  late FlutterBluePlus mPumpflutterBlue;

  BluetoothCharacteristic? _cgmAuthCharacteristic;

  ///< dexcom G5 authentication RX/TX
  BluetoothCharacteristic? _cgmControlCharacteristic;

  ///< dexcom G5 control RX/TX
  BluetoothCharacteristic? _cgmRxCharacteristic;

  ///< read data from cgm
  BluetoothCharacteristic? _cgmTxCharacteristic;

  ///< write data to cgm
  BluetoothCharacteristic? _cgmRXBatLvlCharacteristic;

  ///< Battery level from cgm

  BluetoothCharacteristic? _PumpRxCharacteristic;
  BluetoothCharacteristic? _PumpTxCharacteristic;
  BluetoothCharacteristic? _PumpRXBatLvlCharacteristic;

  // ignore: non_constant_identifier_names
  FlutterBluePlus get CGMflutterBlue => mCGMflutterBlue;
  FlutterBluePlus get PumpflutterBlue => mPumpflutterBlue;

  BluetoothCharacteristic? get cgmAuthCharacteristic => _cgmAuthCharacteristic;
  BluetoothCharacteristic? get cgmControlCharacteristic =>
      _cgmControlCharacteristic;
  BluetoothCharacteristic? get cgmRxCharacteristic => _cgmRxCharacteristic;
  BluetoothCharacteristic? get cgmTxCharacteristic => _cgmTxCharacteristic;
  BluetoothCharacteristic? get cgmRxBatLvlCharacteristic =>
      _cgmRXBatLvlCharacteristic;

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

  // xdrip cgm UUID
  //Transmitter Service UUIDs
  static final DeviceInfo = Guid('0000180A-0000-1000-8000-00805F9B34FB');
  //iOS uses FEBC?
  static final Advertisement = Guid('0000FEBC-0000-1000-8000-00805F9B34FB');
  static final CGMService = Guid('F8083532-849E-531C-C594-30F1F86A4EA5');
  static final ServiceB = Guid('F8084532-849E-531C-C594-30F1F86A4EA5');
  //DeviceInfoCharacteristicUUID, Read, DexcomUN
  static final ManufacturerNameString =
      Guid('00002A29-0000-1000-8000-00805F9B34FB');
  //CGMServiceCharacteristicUUID
  static final Communication = Guid('F8083533-849E-531C-C594-30F1F86A4EA5');
  static final Control =
      Guid('F8083534-849E-531C-C594-30F1F86A4EA5'); // Tx characteristic
  static final Authentication =
      Guid('F8083535-849E-531C-C594-30F1F86A4EA5'); //Rx characteristic
  static final ProbablyBackfill = Guid('F8083536-849E-531C-C594-30F1F86A4EA5');
  //ServiceBCharacteristicUUID
  static final CharacteristicE = Guid('F8084533-849E-531C-C594-30F1F86A4EA5');
  static final CharacteristicF = Guid('F8084534-849E-531C-C594-30F1F86A4EA5');
  //CharacteristicDescriptorUUID
  static final CharacteristicUpdateNotification =
      Guid('00002902-0000-1000-8000-00805F9B34FB');

  /*
   * @brief CGM Device UUID
   */
  static final cgmServiceUuidGUID = CGMService;
  static const String cgmServiceUuid = 'F8083532-849E-531C-C594-30F1F86A4EA5';
  static const String cgmAuthCharacteristicTxRxUuid =
      'F8083534-849E-531C-C594-30F1F86A4EA5';

  ///< Authentication
  static const String cgmControlCharacteristicTxRxUuid =
      'F8083535-849E-531C-C594-30F1F86A4EA5';

  ///< Control
  static const String cgmBatNotifyCharacteristicUuid =
      '0002a18-0002-1000-8000-00805f9b34fb';

  /*
   * @Pump curestream Pump UUID
   */
  static final pumpServiceUuidGUID =
      Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  static const String pumpServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  ///< sending data from app to csp
  static const String pumpCharacteristicRXUuid =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  ///< receiving data from csp to app
  static const String pumpCharacteristicTXUuid =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  ///< sending data from app to csp
  static const String pumpBatNotifyCharacteristicUuid =
      '00002a19-0000-1000-8000-00805f9b34fb';

  ///< receiving battery level data from csp
  static const String CSPumpDeviceName = 'csp-';
  /*
   * @brief danaRS Pump UUID
   */
  static const String DANARS_BOLUS_SERVICE =
      '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String DANARS_READ_UUID = '0000fff1-0000-1000-8000-00805f9b34fb';
  static const String DANARS_WRITE_UUID =
      '0000fff2-0000-1000-8000-00805f9b34fb';
  static const String DANARS_BAT_NOTIFY_UUID =
      '0000fff3-0000-1000-8000-00805f9b34fb';
  static const String DANARS_PUMP_NAME = 'Dana-i';

  ///< dana-i5

  /*
   * @brief caremedi pump UUID
   *
   */
  static const String CareLevoSERVICE_UUID =
      'e1b40001-ffc4-4daa-a49b-1c92f99072ab';

  ///< pump service uuid
  static const String CareLevoRX_CHAR_UUID =
      'e1b40003-ffc4-4daa-a49b-1c92f99072ab';

  ///< pump send msg to app
  static const String CareLevoTX_CHAR_UUID =
      'e1b40002-ffc4-4daa-a49b-1c92f99072ab';

  ///< pump receive msg from app
  /*
  static const String  CareLevoSERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"; ///< pump service uuid
  static const String  CareLevoRX_CHAR_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; ///< pump send msg to app
  static const String  CareLevoTX_CHAR_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; ///< pump receive msg from app
  */
  static const String CareLevo_PUMP_NAME = 'CareLevo'; //'CM100K';

  static const String cgmDeviceName = 'Dexcom';
  static const String pumpDeviceName = 'csp-1';
  String mPUMP_NAME = '';
  String mCGM_NAME = '';

  /*
   * @brief cgm device data listener
   */
  StreamSubscription<List<int>>? _cgmControlValueSubscription = null;
  StreamSubscription<List<int>>? _cgmAuthValueSubscription = null;
  StreamSubscription<List<int>>? _cgmBatValueSubscription = null;

  /*
   * @brief pump device data listener
   */
  StreamSubscription<List<int>>? _pumpValueSubscription = null;
  StreamSubscription<List<int>>? _pumpBatValueSubscription = null;

  /*
   * @brief data listener for connected cgm device
   *        can receive the data or message sent from the connected cgm device
   */
  StreamSubscription<List<int>>? get cgmControlValueSubscription =>
      _cgmControlValueSubscription;

  set cgmControlValueSubscription(StreamSubscription<List<int>>? value) {
    _cgmControlValueSubscription = value;
  }

  /*
   * @brief data listener for connected cgm device
   *        can receive the auth data or message 
   *        sent from the connected cgm device
   */
  StreamSubscription<List<int>>? get cgmAuthValueSubscription =>
      _cgmAuthValueSubscription;

  set cgmAuthValueSubscription(StreamSubscription<List<int>>? value) {
    _cgmAuthValueSubscription = value;
  }

  /*
   * @brief data listener for connected cgm device
   *        can receive the battery level or 
   *        message sent from the connected cgm device
   */
  StreamSubscription<List<int>>? get cgmBatValueSubscription =>
      _cgmBatValueSubscription;

  set cgmBatValueSubscription(StreamSubscription<List<int>>? value) {
    _cgmBatValueSubscription = value;
  }

  /*
   * @brief data listener for connected pump device
   *        can receive the data or message sent from the connected pump device
   */
  StreamSubscription<List<int>>? get pumpValueSubscription =>
      _pumpValueSubscription;

  set pumpValueSubscription(StreamSubscription<List<int>>? value) {
    _pumpValueSubscription = value;
  }

  /*
   * @brief battery level listener for connected pump device
   *        can receive the level or message sent from the connected pump device
   */
  StreamSubscription<List<int>>? get pumpBatValueSubscription =>
      _pumpBatValueSubscription;

  set pumpBatValueSubscription(StreamSubscription<List<int>>? value) {
    _pumpBatValueSubscription = value;
  }

  /*
   * @brief cgm device name
   *        get/set connected cgm device
   */
  BluetoothDevice? _cgmDevice;
  BluetoothDevice? get cgmConnectedDevice => _cgmDevice;
  set SetcgmConnectedDevice(BluetoothDevice value) {
    _cgmDevice = value;
  }

  /*
   * @breif pump device name
   *        get/set connected pump device
   */
  BluetoothDevice? _pumpDevice;
  BluetoothDevice? get pumpConnectedDevice => _pumpDevice;
  set SetpumpConnectedDevice(BluetoothDevice value) {
    _pumpDevice = value;
  }

  /*
   * @breif get scanned cgm device lists
   */
  List<BluetoothDevice> cgmdeviceLists = <BluetoothDevice>[];
  List<BluetoothDevice> get mcgmdeviceLists => cgmdeviceLists;
  /*
   * @breif get scanned pump device lists
   */
  List<BluetoothDevice> pumpdeviceLists = <BluetoothDevice>[];
  List<BluetoothDevice> get mpumpdeviceLists => pumpdeviceLists;

  // Handle connection status changes.
  /*
   * @brief handle the connected pump device connection status
   */
  StreamSubscription<BluetoothDeviceState>? mPumpconnectionSubscription;
  // Handle connection status changes.
  /*
   * @brief handle the connected cgm device connection status
   */
  StreamSubscription<BluetoothDeviceState>? mCgmconnectionSubscription;

  /*
   * @brief cgm scanning status callback listener
   */
  StreamSubscription<bool>? _CgmScanningSubscription = null;
  /*
   * @brief pump scanning status callback listener
   */
  StreamSubscription<bool>? _PumpScanningSubscription = null;

  /*
   * @brief scan status flag for cgm
   */
  bool _isCgmScanning = false;
  bool get isCgmScanning => _isCgmScanning;
  // set isCgmScanning(value) {
  //   _isCgmScanning = value;
  // }

  /*
   * @brief scan status flag for pump
   */
  bool _isPumpScanning = false;
  bool get isPumpScanning => _isPumpScanning;
  set isPumpScanning(bool value) {
    _isPumpScanning = value;
  }

  /*
   * @brief save/get current connection status
   */
  BluetoothDeviceState mCgmConnectionState = BluetoothDeviceState.disconnected;
  BluetoothDeviceState mPumpConnectionState = BluetoothDeviceState.disconnected;
  BluetoothDeviceState get cgmConnectionState => mCgmConnectionState;
  BluetoothDeviceState get pumpConnectionState => mPumpConnectionState;

  static bool getBatteryStatusNow = false;
  static int last_transmitter_timestamp = 0;
  static bool getVersionDetails = true; // try to load firmware version details
  static bool getBatteryDetails = true; // try to load battery info details
  // static late Transmitter defaultTransmitter;
  // AuthStatusRxMessage? authStatus = null;
  // AuthRequestTxMessage? authRequest = null;
  static const int BATTERY_READ_PERIOD_MS =
      1000 * 60 * 60 * 12; // how often to poll battery data (12 hours)
  int? timeInMillisecondsOfLastSuccessfulSensorRead =
      DateTime.now().millisecondsSinceEpoch;
  static int static_last_timestamp = 0;
  static const int G6_SCALING = 34;
  static const String G5_BATTERY_MARKER = 'g5-battery-';
  static const String G5_BATTERY_LEVEL_MARKER = 'g5-battery-level-';
  static const String G5_BATTERY_FROM_MARKER = 'g5-battery-from';
  static const int G5_LOW_BATTERY_WARNING_DEFAULT = 300;
  static const int G6_LOW_BATTERY_WARNING_DEFAULT = 290;
  // updated by updateBatteryWarningLevel(), accessed by Ob1DexTransmitterBattery
  static int LOW_BATTERY_WARNING_LEVEL = G5_LOW_BATTERY_WARNING_DEFAULT;
  bool isBondedOrBonding = false;
  bool isBonded = false;
  static bool static_is_bonded = false;
  static const bool tryPreBondWithDelay =
      false; // prebond with delay seems to help
  bool isIntialScan = true;
  static const bool ignoreLocalBondingState =
      false; // don't try to bond gives: GATT_ERR_UNLIKELY but no more 133s
  static const bool useKeepAlive = true; // add some delays with 133 errors
  static const bool delayOnBond =
      false; // delay while bonding also gives ERR_UNLIKELY but no more 133s
  static const bool tryOnDemandBondWithDelay = true; // bond when requested

  //============= caremedi pump related variable here ================//
  static const int SET_TIME_REQ = 0x11;
  static const int SET_TIME_RSP = 0x71;

  ///< response for the SET_TIME_REQ sent from connected Pump device
  static const int SAFETY_CHECK_REQ = 0x12;

  ///<  안전점검 요청
  static const int SAFETY_CHECK_RSP = 0x72;

  ///< Result: SUCCESS 0, 인슐린 부족 1, 펌프 이상 2, 전압 낮음 3, 안전 점검 요청 응답 4
  static const int INFUSION_THRESHOLD_REQ = 0x17;

  ///<  인슐린 주입 임계치 설정 요청(Type 1)
  static const int INFUSION_THRESHOLD_RSP = 0x77;
  static const int INFUSION_INFO_REQ = 0x31;

  ///< 주입 현황 조회 요청 (스마트폰 앱  패치 장치)
  /// 송신 조건: 사용자가 앱에서 홈화면으로 이동한 경우, 앱 동작 상 홈 화면 가기로 자동 이동하는 경우,
  /// 그리고 앱의 주기적인 홈 화면 업데이트 타이머에 의해 본 메시지가 패치로 송신된다.
  /// Length 2, CMD: 0x31
  /// Sub ID: 주입 현황 조회 요청 (0x00), 인슐린 잔여량 요청 (0x01)
  /// CMD	 Sub ID
  /// 0x31	0x00
  /// Action: 주입 현황 조회 요청을 받은 패치는 현재 주입 중인 주입 펌프 상태와 잔여량, 주입 모드, 주입 속도 등의 값을
  /// 다음의 주입 현황 조회 응답 메시지로 앱으로 송신한다.
  static const int INFUSION_INFO_RPT = 0x91;

  ///< 주입 현황 조회 보고 (패치 장치  스마트폰 앱)
  static const int HCL_DOSE_REQ = 0x67;

  ///< HCL 주입 요청
  static const int HCL_BOLUS_RSP = 0xD7;
  static const int HCL_DOSE_CANCEL_REQ = 0x68;

  ///< HCL 주입 취소 요청
  static const int HCL_BOLUS_CANCEL_RSP = 0xD8;
  static const int PATCH_INFO_REQ = 0x33;

  ///< 	패치 정보 조회 요청 (스마트폰 앱  패치 장치)
  static const int PATCH_INFO_RPT1 = 0x93;

  ///< 패치 정보 보고1 (패치 장치  스마트폰 앱): PATCH_INFO_RPT1 (모델명, 로트번호 송부)
  static const int PATCH_INFO_RPT2 = 0x94;

  ///< 패치 정보 보고2 (패치 장치  스마트폰 앱): PATCH_INFO_RPT2 (제조번호,펌웨어버전,부팅 시간)
  static const int CANNULAR_STATUS_REQ = 0x1a;

  ///<
  //static const int CANNULAR_STATUS = (0x79);
  static const int CANNULAR_INSERT_RPT = 0x79;
  static const int CANNULAR_INSERT_ACK = 0x19;
  static const int CANNULAR_INSERT_RSP = 0x7A;
  static const int PATCH_WARNING_RPT = 0xa1;
  static const int PATCH_ALERT_RPT = 0xa2;
  static const int PATCH_NOTICE_RPT = 0xa3;
  static const int PATCH_DISCARD_REQ = 0x36;

  ///< 	패치 폐기 요청 (스마트폰 앱  패치 장치)
  /// 패치 디바이스에서 패치 폐기를 수신하면 즉시 펌프 중지와 주입 프로그램도 모두 삭제하고,
  /// 기 설정 중인 경고/주의/알림 타이머를 모두 삭제한 후 폐기 완료 메시지를 송신한 후 폐기를 알리는 부저를 울린다.
  /// 앱으로는 아래의 패치 폐기 완료 메시지를 송신한다.
  /// 참고) 패치 폐기 응답 시 패치 연결 정보는 초기화 되어 재 연결이 가능하다.
  /// (테스트 모드에서 동일 패치로 계속 연결하여 시험시 유용함)
  static const int PATCH_DISCARD_RSP = 0x96;

  ///<  패치 폐기 완료 메시지 (패치 장치  스마트폰 앱):
  /// RSP	RSLT
  // 0x96	0x00
  static const int BUZZER_CHECK_REQ = 0x37;

  ///< 패치 부저 점검 요청 (스마트폰 앱  패치 장치)
  /// 메뉴 중 패치 관리에 “알람 점검 서브 메뉴를 클릭하면 본 메시지를 송신한다.
  //  송신 후 앱은 스마트 폰의 부저 울림도 확인하여야 한다.
  /// Length 1,
  /// CMD
  /// 0x37
  static const int BUZZER_CHECK_RSP = 0x97;
  static const int BUZZER_CHANGE_REQ = 0x18;
  static const int BUZZER_CHANGE_RSP = 0x88;
  static const int APP_STATUS_IND = 0x39;

  ///< 앱 상태 통보 메시지 : 앱 상태 통보 (스마트폰 앱  패치 장치)
  /// 앱이 Foreground 나 Background 로의 상태 천이 시 본 메시지를 패치로 송신
  /// Status: 0x00 (foreground  background), 0x01 (Background  foreground)
  /// Action: Status 0x00 을 받으면 주입감시 타이머를 구동하고, 0x01을 받으면 주입 감시 타이머를 중지한다
  /// 주입감시 타이머 Timeout 처리: 첫 타임아웃이면 주의 메시지를 송부한 후 다시 주입감시 타이머를 구동한다.
  /// 두번째 타임아웃이면 주입을 차단하고 경고 메시지를 송부한다.
  /// 두번째 타이머 값은 30분으로 설정한다. 즉 주의 메시지 송신 후 30분 내 앱 사용 재개 없으면 경고 및 주입 차단함.
  /// 주의/경고, 펌프 중단 메시지에 Cause 값 추가 정의 (앱 장기 미사용 5)
  /// IND	  STATUS	TIME
  /// 0x39	0x00	0x06
  static const int APP_STATUS_ACK = 0x99;

  ///< 앱 상태 수신 확인  메시지 (패치 장치  스마트폰 앱)
  ///  Length 2, ACK: 0x99, STATUS (APP_STATUS_IND 시 앱에서 통보 받은 값 세팅함: 0 or 1)
  ///  ACK	STATUS
  ///  0x99	0x00
  static const int MAC_ADDR_REQ = 0x3b;

  ///< MAC Address 조회 요청 (스마트폰 앱  패치 장치)
  static const int MAC_ADDR_RPT = 0x9b;

  ///< MAC Address 보고(패치 장치  스마트폰 앱):
  /// Data (6 byte): MAC Address -> 6바이트 HEXA 값임
  /// RPT 	ADDR1	ADDR2	ADDR3	ADDR4	ADDR5	ADDR6
  //  0x9B	0x80	0x4B	0x50	0x6F	0xDC	0x61
  static const int ALARM_CLEAR_REQ = 0x47;

  ///< 알람/알림 해소 요청 (스마트폰 앱  패치 장치):
  static const int ALARM_CLEAR_RSP = 0xa7;

  ///< 알람/알림 해소 응답 (패치 장치  스마트폰 앱):
  static const int PATCH_RESET_REQ = 0x3F;

  ///< 패치 리셋 위한 명령어 (스마트폰 앱 -> 패치 장치): 2 바이트
  /// Length 2, CMD: 0x3F
  /// CMD  | MODE
  /// 0x3F | 0x00
  //  Mode: 0x00 -> 패치의 Bonding list, NVM 삭제 후 리셋
  //        0x01 -> 패치의 Bonding list, NVM Data 유지 상태 리셋
  static const int PATCH_RESET_RPT = 0x9F;

  ///< 패치리셋 응답 ( 패치 장치 -> 스마트폰 앱)
  // Length 2, RPT: 0x9F
  // RPT  | MODE
  // 0x9F | 0x00
  // Mode: 요청 시 받은 모드
  // 0x00 -> 패치의 Bonding list, NVM 삭제 후 리셋
  // 0x01 -> 패치의 Bonding list, NVM Data 유지 상태 리셋

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

  // let's toast message to user when the request
  // command is not sent to the pump
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
   * @brief variables that cgm and pump have
   *        common
   *        dependent for CGM and PUMP
   */
  //====  common variables  => let's move to abstract IDevice class later ======//
  String _ModelName = '';
  String get ModelName => _ModelName;
  set ModelName(String value) {
    _ModelName = value;
  }

  String _SerialNo = '';
  String get SerialNo => _SerialNo;
  set SerialNo(String value) {
    _SerialNo = value;
  }

  String _ValidCode = '';
  String get ValidCode => _ValidCode;
  set ValidCode(String value) {
    _ValidCode = value;
  }

  String _FWVersion = '';
  String get FWVersion => _FWVersion;
  set FWVersion(String value) {
    _FWVersion = value;
  }

  String _BatLevel = '';
  String get BatLevel => _BatLevel;
  set BatLevel(String value) {
    _BatLevel = value;
  }

  String _ConnectionStatus = '';

  ///< connected/disconnected
  String get ConnectionStatus => _ConnectionStatus;
  set ConnectionStatus(String value) {
    _ConnectionStatus = value;
  }

  String _FirstConnectedTime = '';

  ///< first connection time
  String get FirstConnectedTime => _FirstConnectedTime;
  set FirstConnectedTime(String value) {
    _FirstConnectedTime = value;
  }

  String _latestDeliveryTime = '';

  ///< latest CGM BloodGlucose receive time , latest PUMP Insulin delivery time
  String get latestDeliveryTime => _latestDeliveryTime;
  set latestDeliveryTime(String value) {
    _latestDeliveryTime = value;
  }

  //=======  dependent for CGM => let's move to abstract ICGM class later ======//
  String _BloodGlucose = '';
  String get BloodGlucose => _BloodGlucose;
  set BloodGlucose(String value) {
    _BloodGlucose = value;
  }

  //=====  dependent for PUMP  => let's move to abstract IPUMP class later =====//
  ///< reservoir
  String _reservoir = '';
  String get reservoir => _reservoir;
  set reservoir(String value) {
    _reservoir = value;
  }

  String _InsulinDelivery = '';

  ///< Bolus, Basal, Dose
  String get InsulinDelivery => _InsulinDelivery;
  set InsulinDelivery(String value) {
    _InsulinDelivery = value;
    notifyListeners();
  }

  String _PatchUseAvailableTime = '';

  ///< 패치 사용 가능 남은 시간
  String get PatchUseAvailableTime => _PatchUseAvailableTime;
  set PatchUseAvailableTime(String value) {
    _PatchUseAvailableTime = value;
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

  //==================================================================//

  BluetoothProvider() {
    _init();
  }

  /*
   * kai_20230304
   * @description :  _init()
   * This code tracks the Bluetooth status through the flutterBlue.state attribute.
   * The state attribute returns a Stream<BluetoothState> type.
   * A Stream is an object that returns data asynchronously.
   * The firstWhere method waits until it finds the first element that meets the condition in the Stream.
   * In this case, it searches for the first element that satisfies the condition state == BluetoothState.on.
   * BluetoothState.on is an enum that represents whether Bluetooth is on or not.
   * Finally, the await keyword makes the program wait until the firstWhere method returns a result.
   * Therefore, this code waits until the Bluetooth status becomes BluetoothState.on, and
   * then executes the next line of code.
   */
  Future<void> _init() async {
    CspPreference.initPrefs();
    if (USE_DEBUG_MESSAGE) {
      mPUMP_NAME = CspPreference.getString('pumpSourceTypeKey');
      debugPrint('init():initState():mPUMP_NAME = $mPUMP_NAME');
      mCGM_NAME = CspPreference.getString('cgmSourceTypeKey');
      debugPrint('init():initState():mCGM_NAME = $mCGM_NAME');
    }

    // get default transmitter here
    // defaultTransmitter =
    //     new Transmitter(CspPreference.getString(CspPreference.dex_txid));

    //_startScan();
    // get cgm and pump bluetooth instance here
    // register BEL Scan status listener for cgm and pump here
    mCGMflutterBlue = FlutterBluePlus.instance;
    _CgmScanningSubscription = mCGMflutterBlue.isScanning.listen((isScanning) {
      _isCgmScanning = isScanning;
      debugPrint(
        'kai: init():mCGMflutterBlue._isCgmScanning = $isScanning',
      );
      notifyListeners();
    });

    mPumpflutterBlue = FlutterBluePlus.instance;
    _PumpScanningSubscription =
        mPumpflutterBlue.isScanning.listen((isScanning) {
      _isPumpScanning = isScanning;
      debugPrint(
        'kai: init():mPumpflutterBlue._isPumpScanning = $isScanning',
      );
      notifyListeners();
    });

    if (_USE_SCAN_IN_INIT_STATE == true) {
      // if this flag is enabled, then try to scanning device in case of bluetooth is on
      await mCGMflutterBlue.state
          .firstWhere((state) => state == BluetoothState.on);
      await mPumpflutterBlue.state
          .firstWhere((state) => state == BluetoothState.on);

      await scanForDevices();
    }
  }

  /*
   * @brief scan the peripheral cgm and pump device
   *        and save the scanned cgm/pump device lists
   *        and save the connected cgm/pump device
   */
  Future<void> scanForDevices() async {
    final cgmDevices = await mCGMflutterBlue.connectedDevices;
    cgmdeviceLists = cgmDevices;

    /// kai_20230323 backup scanned device lists

    if (cgmDevices.isNotEmpty) {
      final device = cgmDevices.first;
      _cgmDevice = device;

      ///< kai_20230304 backup connected cgm device
      await _connectCgm(device);
    } else {
      final cgmResult = await mCGMflutterBlue
          .scan(
            timeout: const Duration(seconds: 4),
            //   withServices: [cgmServiceUuidGUID],
            scanMode: ScanMode.lowLatency,
          )
          // .firstWhere((result) => result.device.name.contains(cgmDeviceName));
          .firstWhere(
            (result) => result.device.name.contains(
              CspPreference.mCGM_NAME.isEmpty
                  ? cgmDeviceName
                  : CspPreference.mCGM_NAME,
            ),
          );
      final cgmDevice = cgmResult.device;
      _cgmDevice = cgmDevice;

      ///< kai_20230304 backup connected cgm device
      await _connectCgm(cgmDevice);
    }

    final pumpDevices = await mPumpflutterBlue.connectedDevices;
    pumpdeviceLists = pumpDevices;

    /// kai_20230323 backup scanned pump device lists

    if (pumpDevices.isNotEmpty) {
      final device = pumpDevices.first;
      _pumpDevice = device;

      ///< kai_20230304 backup connected pump device
      await _connectPump(device);
    } else {
      final pumpResult = await mPumpflutterBlue
          .scan(
            timeout: const Duration(seconds: 4),
            // withServices: [pumpServiceUuidGUID],
            scanMode: ScanMode.lowLatency,
          )
          // .firstWhere((result) => result.device.name.contains(pumpDeviceName));
          .firstWhere(
            (result) => result.device.name.contains(
              CspPreference.mPUMP_NAME.isEmpty
                  ? pumpDeviceName
                  : CspPreference.mPUMP_NAME,
            ),
          );
      final pumpDevice = pumpResult.device;
      _pumpDevice = pumpDevice;

      ///< kai_20230304 backup connected pump device
      await _connectPump(pumpDevice as BluetoothDevice);
    }
    notifyListeners();
  }

  /*
   * @brief try to connect to the selected device and
   *        find the control characteristic that can receive a data from the connected cgm device
   *        and auth characteristic which can handshaking authentication with the connected cgm device.
   *        and battery level characteristic which notify the battery level to the application.
   */
  Future<void> _connectCgm(BluetoothDevice device) async {
    if (FEATURE_CHECK_WR_CHARACTERISTIC != true) {
      try {
        await device.connect(autoConnect: false);
        final services = await device.discoverServices();
        var findCharacteristic = 0;

        ///< clear
        /*
        final service = services.firstWhere((s) => s.uuid == cgmServiceUuid);
        _cgmTxCharacteristic = service.characteristics.firstWhere((c) => c.uuid == cgmCharacteristicTXUuid);
        _cgmRxCharacteristic = service.characteristics.firstWhere((c) => c.uuid == cgmCharacteristicRXUuid);
        _cgmRXBatLvlCharacteristic = service.characteristics.firstWhere((c) => c.uuid == cgmBatNotifyCharacteristicUuid);
         */
        for (final service in services) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == cgmControlCharacteristicTxRxUuid) {
              ///< control characteristic
              findCharacteristic = findCharacteristic + 1;
              _cgmControlCharacteristic = characteristic;
            } else if (characteristic.uuid == cgmAuthCharacteristicTxRxUuid) {
              ///< authentication characteristic
              findCharacteristic = findCharacteristic + 1;
              _cgmAuthCharacteristic = characteristic;
            } else if (characteristic.uuid == cgmBatNotifyCharacteristicUuid) {
              ///< battery Level characteristic
              findCharacteristic = findCharacteristic + 1;
              _cgmRXBatLvlCharacteristic = characteristic;
            }
          }
          if (findCharacteristic > 2) {
            break;
          }
        }

        if (findCharacteristic >= 2) {
          if (_cgmControlCharacteristic != null) {
            if (_cgmControlCharacteristic!.properties.notify &&
                !_cgmControlCharacteristic!.isNotifying) {
              _cgmControlCharacteristic!.setNotifyValue(true);
            }

            if (USE_VALUE_SUBSCRIPTION_REGISTER_CALLBACK != true) {
              _cgmControlCharacteristic!.value.listen((value) {
                // _handleCgmValue(value);
              });
            }
          }

          if (_cgmAuthCharacteristic != null) {
            if (_cgmAuthCharacteristic!.properties.notify &&
                !_cgmAuthCharacteristic!.isNotifying) {
              _cgmAuthCharacteristic!.setNotifyValue(true);
            }

            if (USE_VALUE_SUBSCRIPTION_REGISTER_CALLBACK != true) {
              _cgmAuthCharacteristic!.value.listen((value) {
                if (CspPreference.mCGM_NAME.toLowerCase().contains('dexcom')) {
                  // processOnCharacteristicRead(value);
                } else {
                  // _handleCgmValue(value);
                }
              });
            }
          }

          if (_cgmRXBatLvlCharacteristic != null) {
            if (_cgmRXBatLvlCharacteristic!.properties.notify &&
                !_cgmRXBatLvlCharacteristic!.isNotifying) {
              _cgmRXBatLvlCharacteristic!.setNotifyValue(true);
            }

            if (USE_VALUE_SUBSCRIPTION_REGISTER_CALLBACK != true) {
              _cgmRXBatLvlCharacteristic!.value.listen((value) {
                // _handleCgmValue(value);
              });
            }
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error connecting to device: $e');
      }
    }
  }

  /*
   * @brief try to connect to the selected device and
   *        find the control characteristic that can receive a data from the connected pump device
   *        and tx characteristic which can send a message or data to the connected pump device.
   *        and battery level characteristic which notify the battery level to the application.
   */
  Future<void> _connectPump(BluetoothDevice device) async {
    if (FEATURE_CHECK_WR_CHARACTERISTIC != true) {
      try {
        await device.connect(autoConnect: false);
        final services = await device.discoverServices();
        var findCharacteristic = 0;

        ///< clear
        /*
        final service = services.firstWhere((s) => s.uuid == pumpServiceUuid);
        final characteristic = service.characteristics.firstWhere((c) => c.uuid == pumpCharacteristicRXUuid);
        _PumpRxCharacteristic = characteristic;
         */
        for (final service in services) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == pumpCharacteristicTXUuid) {
              findCharacteristic = findCharacteristic + 1;
              _PumpTxCharacteristic = characteristic;
            } else if (characteristic.uuid == pumpCharacteristicRXUuid) {
              findCharacteristic = findCharacteristic + 1;
              _PumpRxCharacteristic = characteristic;
            } else if (characteristic.uuid == pumpBatNotifyCharacteristicUuid) {
              findCharacteristic = findCharacteristic + 1;
              _PumpRXBatLvlCharacteristic = characteristic;
            }
          }
          if (findCharacteristic > 2) {
            break;
          }
        }

        if (findCharacteristic >= 2) {
          _PumpRxCharacteristic!.setNotifyValue(true);
          if (USE_VALUE_SUBSCRIPTION_REGISTER_CALLBACK != true) {
            _PumpRxCharacteristic!.value.listen((value) {
              // handlePumpValue(value);
            });
          }
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error connecting to device: $e');
      }
    }
  }

  /*
   * @brief get dexcom g5, g6 firmware
   */
  Uint8List getStoredFirmwareBytes(String transmitterId) {
    if (transmitterId.length != 6) return Uint8List(0);
    return CspPreference.getBytes('g5-firmware-$transmitterId');
  }

  /*
   * @brief set dexcom g5, g6 firmware
   */
  bool setStoredFirmwareBytes(
    String transmitterId,
    Uint8List data,
    bool fromBluetooth,
  ) {
    if (fromBluetooth) {
      debugPrint('Store: VersionRX dbg: ${data.buffer}');
    }

    if (transmitterId.length != 6) {
      return false;
    }
    if (data.length < 10) {
      return false;
    }
    CspPreference.setBytes(CspPreference.g5_firmware_ + transmitterId, data);

    return true;
  }

  /*
   * @brief set dexcom g5, g6 firmware from wear sync
   */
  // from wear sync
  bool setStoredFirmwareByte(String transmitterId, Uint8List data) {
    return setStoredFirmwareBytes(transmitterId, data, false);
  }

  /*
   * @brief get dexcom g5, g6 firmware details
   */
  // bool haveFirmwareDetails() {
  // return (defaultTransmitter.transmitterId.length == 6 &&
  //     getStoredFirmwareBytes(defaultTransmitter.transmitterId).length >= 10);
  // }

  /*
   * @brief update dexcom g5, g6 battery level
   */
  static void updateBatteryWarningLevel() {
    LOW_BATTERY_WARNING_LEVEL =
        CspPreference.getStringToInt('g5-battery-warning-level');
  }

  /*
   * @brief set dexcom g5, g6 battery level
   */
  bool setStoredBatteryBytes(String transmitterId, List<int> data) {
    debugPrint('Store: BatteryRX dbg: $data');
    if (transmitterId.length != 6) return false;
    if (data.length < 10) return false;
    updateBatteryWarningLevel();
    // final BatteryInfoRxMessage batteryInfoRxMessage =
    //     BatteryInfoRxMessage(data);
    // debugPrint("Saving battery data: " + batteryInfoRxMessage.toString());
    //PersistentStore.setBytes(G5_BATTERY_MARKER + transmitterId, data);
    //PersistentStore.setLong(G5_BATTERY_FROM_MARKER + transmitterId, JoH.tsl());

    // TODO logic also needs to handle battery replacements of same transmitter id
    final oldLevel = CspPreference.getStringToInt(
      G5_BATTERY_LEVEL_MARKER.toString() + transmitterId,
    );
    // if ((batteryInfoRxMessage.voltagea < oldLevel) || (oldLevel == 0)) {
    //   if (batteryInfoRxMessage.voltagea < LOW_BATTERY_WARNING_LEVEL) {
    /*
        if (JoH.pratelimit("g5-low-battery-warning", 40000)) {
          final loud = !PowerStateReceiver.is_power_connected();
          JoH.showNotification(
            "G5 Battery Low",
            "G5 Transmitter battery has dropped to: ${batteryInfoRxMessage.voltagea} it may fail soon",
            null,
            770,
            NotificationChannels.LOW_TRANSMITTER_BATTERY_CHANNEL,
            loud,
            loud,
            null,
            null,
            null,
          );
        }
        */
    // }
    // CspPreference.setLong(G5_BATTERY_LEVEL_MARKER.toString() + transmitterId,
    //     batteryInfoRxMessage.voltagea);
    // }

    return true;
  }

  /*
   * @brief get dexcom g5, g6 current battery level
   */
  // bool haveCurrentBatteryStatus() {
  //   return (defaultTransmitter.transmitterId.length == 6 &&
  //       (int.parse(defaultTransmitter.transmitterId) < BATTERY_READ_PERIOD_MS));
  // }

  /*
   * @brief Sends the disconnect tx message to our bt device.
   */
  // Sends the disconnect tx message to our bt device.
  Future<void> doDisconnectMessage() async {
    debugPrint('doDisconnectMessage() start');
    if (_cgmControlCharacteristic != null &&
        _cgmControlCharacteristic!.properties.notify) {
      await _cgmControlCharacteristic!.setNotifyValue(false);

      if (_cgmControlCharacteristic!.properties.write ||
          _cgmControlCharacteristic!.properties.writeWithoutResponse) {
        // final DisconnectTxMessage disconnectTx = new DisconnectTxMessage();
        // _cgmControlCharacteristic!.write(disconnectTx.byteSequence);
      }
    }
    // disconnectCgmDevices();
    debugPrint('doDisconnectMessage() finished');
  }

  /*
   * @brief Sends the version request message to our bt device.
   */
  Future<void> doVersionRequestMessage() async {
    debugPrint('doVersionRequestMessage() start');

    if (_cgmControlCharacteristic != null &&
        _cgmControlCharacteristic!.properties.notify &&
        !_cgmControlCharacteristic!.isNotifying) {
      await _cgmControlCharacteristic!.setNotifyValue(true);
      if (_cgmControlCharacteristic!.properties.write ||
          _cgmControlCharacteristic!.properties.writeWithoutResponse) {
        // final VersionRequestTxMessage versionTx = new VersionRequestTxMessage();
        // _cgmControlCharacteristic!.write(versionTx.byteSequence);
      }
    }
    debugPrint('doVersionRequestMessage() finished');
  }

  /*
   * @brief Sends the battery info request message to our bt device.
   */
  Future<void> doBatteryInfoRequestMessage() async {
    debugPrint('doBatteryInfoMessage() start');

    if (_cgmControlCharacteristic != null &&
        _cgmControlCharacteristic!.properties.notify &&
        !_cgmControlCharacteristic!.isNotifying) {
      await _cgmControlCharacteristic!.setNotifyValue(true);
      if (_cgmControlCharacteristic!.properties.write ||
          _cgmControlCharacteristic!.properties.writeWithoutResponse) {
        // final BatteryInfoTxMessage batInfoTxMsg = new BatteryInfoTxMessage();
        // _cgmControlCharacteristic!.write(batInfoTxMsg.byteSequence);
      }
    }
    debugPrint('doBatteryInfoMessage() finished');
  }

  /*
   * @brief get dexcom G5, G6 for using preference
   */
  static bool usingG6() {
    return CspPreference.getBooleanDefaultFalse('using_g6');
  }

  /*
   * @brief process New Transmitter data from dexcom G5, G6
   */
  void processNewTransmitterData(
    int rawData,
    int filteredData,
    int sensorBatteryLevel,
    int captureTime,
  ) {
    // final TransmitterData? transmitterData = TransmitterData.create1(
    // rawData, filteredData, sensorBatteryLevel, captureTime);
    // if (transmitterData == null) {
    //   debugPrint("TransmitterData.create failed: Duplicate packet");
    //   return;
    // } else {
    //   timeInMillisecondsOfLastSuccessfulSensorRead = captureTime as int?;
    // }
    /*
    Sensor sensor = Sensor.currentSensor();
    if (sensor == null) {
      Log.e(TAG, "setSerialDataToTransmitterRawData: No Active Sensor, Data only stored in Transmitter Data");
      return;
    }

    //TODO : LOG if unfiltered or filtered values are zero

    Sensor.updateBatteryLevel(sensor, transmitterData.sensor_battery_level);
    debugPrint("timestamp create: "+ transmitterData.timestamp.toString());
*/
    //   BgReading.create(transmitterData.raw_data, transmitterData.filtered_data, this, transmitterData.timestamp);

    // debugPrint("Dex raw_data " + transmitterData.raw_data.toString()); //KS
    // debugPrint(
    //     "Dex filtered_data " + transmitterData.filtered_data.toString()); //KS
    // debugPrint("Dex sensor_battery_level " +
    //     transmitterData.sensor_battery_level.toString()); //KS
    // debugPrint("Dex timestamp " + transmitterData.timestamp.toString()); //KS

    // static_last_timestamp = transmitterData.timestamp as Long;
  }

  /*
   * @brief process Rx data from dexcom G5, G6
   */
  void processRxCharacteristic(List<int> value) {
    String data;
    // Try to decode as UTF-8
    try {
      data = utf8.decode(value);
    } on FormatException {
      // If UTF-8 decoding fails, try ASCII decoding
      data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
    }
    // Process decoded string
    //print('kai::decodedString = ' + data);
    /*
    String data = utf8.decode(value, allowMalformed: true);
   // String firstByte = data.substring(0,1);
     */

    final buffer = value;
    final firstByte = buffer[0];
    // List<int> bytes = data.codeUnits;

    debugPrint('processRxCharacteristic()');
    debugPrint('Received opcode = $firstByte');
    debugPrint('value = $data');

    if (firstByte == 0x2f) {
      final bytes = Uint8List.fromList(utf8.encode(data));
      // SensorRxMessage sensorRx = new SensorRxMessage(bytes);

      // sensorData buffer init as zero here
      final sensorData = ByteData.view(bytes.buffer);
      sensorData.buffer.asUint8List().setAll(0, buffer);

      const sensorBatteryLevel = 0;
      // if (sensorRx.status == TransmitterStatus.BRICKED) {
      //   //TODO Handle this in UI/Notification
      //   sensorBatteryLevel = 206; //will give message "EMPTY"
      // } else if (sensorRx.status == TransmitterStatus.LOW) {
      //   sensorBatteryLevel = 209; //will give message "LOW"
      // } else {
      //   sensorBatteryLevel = 216; //no message, just system status "OK"
      // }

      debugPrint(
        'Got data OK : '
        '${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );

      // debugPrint('SUCCESS!! unfiltered: ' +
      //     sensorRx.unfiltered.toString() +
      //     ' timestamp: ' +
      //     sensorRx.timestamp.toString() +
      //     ' ' +
      //     (sensorRx.timestamp / 86400).toString() +
      //     ' days');
      // if (sensorRx.unfiltered == 0) {
      //   debugPrint(
      //       "Transmitter sent raw sensor value of 0 !! This isn't good. " +
      //           DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now()));
      // }

      // last_transmitter_timestamp = sensorRx.timestamp;
      // if ((getVersionDetails) && (!haveFirmwareDetails())) {
      //   doVersionRequestMessage();
      // } else if ((getBatteryDetails) &&
      //     (getBatteryStatusNow || !haveCurrentBatteryStatus())) {
      //   doBatteryInfoRequestMessage();
      // } else {
      //   doDisconnectMessage();
      // }

      //   final bool g6 = usingG6();
      //   processNewTransmitterData(
      //       g6 ? sensorRx.unfiltered * G6_SCALING : sensorRx.unfiltered,
      //       g6 ? sensorRx.filtered * G6_SCALING : sensorRx.filtered,
      //       sensorBatteryLevel,
      //       DateTime.now() as Long);
      // } else if (firstByte == GlucoseRxMessage.opcode) {
      //   Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      //   GlucoseRxMessage glucoseRx = new GlucoseRxMessage(bytes);
      //   debugPrint(
      //       "SUCCESS!! glucose unfiltered: " +
      //        glucoseRx.unfiltered.toString());
      //   doDisconnectMessage();
      //   processNewTransmitterData(glucoseRx.unfiltered,
      //   glucoseRx.filtered, 216,
      //       DateTime.now() as Long);
      // } else if (firstByte == VersionRequestRxMessage.opcode) {
      //   Uint8List bytes = Uint8List.fromList(utf8.encode(data));

      //   if (!setStoredFirmwareBytes(
      //       defaultTransmitter.transmitterId, bytes, true)) {
      //     debugPrint("Could not save out firmware version!");
      //   }
      //   doDisconnectMessage();
      // } else if (firstByte == BatteryInfoRxMessage.opcode) {
      //   Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      //   if (!setStoredBatteryBytes(defaultTransmitter.transmitterId, bytes))
      //   {
      //     debugPrint("Could not save out battery data!");
      //   }
      //   getBatteryStatusNow = false;
      //   doDisconnectMessage();
      // } else {
      //   debugPrint("processRxCharacteristic(): unexpected opcode: " +
      //       firstByte.toString() +
      //       " (have not disconnected!)");
      // }

      // debugPrint("processRxCharacteristic(): finished!!");
    }

    /*
   * @brief get Transmitter details
   */
    void getTransmitterDetails() {
      // debugPrint("Transmitter: " + CspPreference.getString("dex_txid"));
      // defaultTransmitter = new
      // Transmitter(CspPreference.getString("dex_txid"));
      final previousBondedState = isBonded;
      isBondedOrBonding = false;
      isBonded = false;
      static_is_bonded = false;
      if (mCGMflutterBlue == null) {
        debugPrint('No bluetooth adapter');
        return;
      }
      if (_cgmDevice != null && _cgmDevice!.name.isNotEmpty) {
        // final String transmitterIdLastTwo = Extensions.lastTwoCharactersOfString(
        // defaultTransmitter.transmitterId);
        // final String deviceNameLastTwo = Extensions.lastTwoCharactersOfString(
        // _cgmDevice!.name.toLowerCase().toString());

        // if (transmitterIdLastTwo == deviceNameLastTwo) {
        //   isBondedOrBonding = true;
        //   isBonded = true;
        //   static_is_bonded = true;
        //   if (!previousBondedState)
        //     debugPrint("Device is now detected as bonded!");
        //   // TODO should we break here for performance?
        // } else {
        //   isIntialScan = true;
        // }
      }

      if (previousBondedState && !isBonded) {
        debugPrint('Device is no longer detected as bonded!');
      }
      debugPrint(
        'getTransmitterDetails() result: '
        'Bonded? $isBondedOrBonding${isBonded ? ' localed '
            'bonded' : ' not locally bonded'}',
      );
    }

    /*
   * @brief crypt key for dexcom G5, G6 transmitter auth handshaking
   */
    List<int>? cryptKey() {
      // if (defaultTransmitter.transmitterId.length != 6) {
      //  log(
      //       'cryptKey: Wrong transmitter id length!:
      // ${defaultTransmitter.transmitterId.length}');
      //   return null;
      // }

      // try {
      //   String keyString =
      //       '00${defaultTransmitter.transmitterId}
      // 00${defaultTransmitter.transmitterId}';
      //   return utf8.encode(keyString);
      // } catch (e) {
      //  log(e);
      // }
      return null;
    }

    /*
   * @brief calculate hash for auth between dexcom G5, G6 and application
   */
    Uint8List? calculateHash(Uint8List? data) {
      if (data == null || data.length != 8) {
        log('Decrypt Data length should be exactly 8.');
        return null;
      }

      final list = cryptKey();
      final Uint8List? key = Uint8List.fromList(list!);
      if (key == null) {
        return null;
      }

      final doubleData = Uint8List(16);
      final bd = doubleData.buffer.asByteData();
      for (var i = 0; i < 8; i++) {
        doubleData[i] = data[i];
        doubleData[i + 8] = data[i];
      }

      /*

    try {
      final aesCipher = aes.AesCrypt("ecb", "pkcs7");
      aesCipher.setAesKey(key);
      Uint8List aesBytes = aesCipher.encryptData(doubleData);

      return aesBytes.sublist(0, 8);
    } catch (e) {
      debugPrint(e.toString());
    }

     */

      final aesBytes = sha1.convert(doubleData) as Uint8List;
      return aesBytes.sublist(0, 8);
/*
    var cipher = AES(key);
    var aesBytes = cipher.encrypt(doubleData);
    return aesBytes.sublist(0, 8);

 */
    }

    /*
   * @brief performs bonding between dexcom G5, G6 and application
   */
    void performBondWrite() async {
      debugPrint('performBondWrite() started');

      if (_cgmAuthCharacteristic == null) {
        debugPrint('mGatt was null when trying to write bondRequest');
        return;
      }

      // final bondRequest = BondRequestTxMessage();
      // _cgmAuthCharacteristic!.write(bondRequest.byteSequence);

      if (delayOnBond) {
        debugPrint('Delaying before bond');
        await Future.delayed(const Duration(milliseconds: 1000), () {});
        debugPrint('Delay finished');
      }
/*
    final deviceAddress = _cgmAuthCharacteristic!.deviceId;
    final device = BluetoothDevice(deviceAddress);

        final device = BluetoothDevice.fromAddress(deviceAddress);

   log('Connecting to the device...');
    await device.connect();
   log('Connected to the device');

   log('Requesting pairing...');
    final pairingRequest = BluetoothPairingRequest(device: device);
    final pairingResult = await pairingRequest.pair();

    if (pairingResult) {
      debugPrint('Pairing successful');
      isBondedOrBonding = true;
    } else {
      debugPrint('Pairing failed');
      isBondedOrBonding = false;
    }


 */
      debugPrint('performBondWrite() finished');
    }

    /*
   * @brief process read characteristic data from dexcom G5, G6
   */
    Future<void> processOnCharacteristicRead(List<int> value) async {
      // handle CGM auth processing
      String data;
      // Try to decode as UTF-8
      try {
        data = utf8.decode(value);
      } on FormatException {
        // If UTF-8 decoding fails, try ASCII decoding
        data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
      }
      // Process decoded string
      //log('kai::decodedString = ' + data);
      /*
    String data = utf8.decode(value, allowMalformed: true);
    // String firstByte = data.substring(0,1);
     */

      final buffer = value;
      final code = buffer[0];
      // List<int> bytes = data.codeUnits;

      // switch (code) {
      //   case 5:
      //     Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      //     authStatus = new AuthStatusRxMessage(bytes);
      //     if (authStatus!.authenticated == 1 &&
      //         authStatus!.bonded == 1 &&
      //         !isBondedOrBonding) {
      //       debugPrint("Special bonding test case!");

      //       if (tryPreBondWithDelay) {
      //         debugPrint("Trying prebonding with delay!");
      //         isBondedOrBonding = true;
      //         if (_cgmDevice != null) {
      //           //_cgmDevice.createBond();
      //           // _cgmDevice!.connect(4,true);
      //           await _cgmDevice!.connect(autoConnect: false);
      //         }

      //         Future.delayed(const Duration(milliseconds: 1600), () async {
      //           debugPrint("Prebond delay finished");
      //           //waitFor(1600);
      //           getTransmitterDetails(); // try to refresh on the off-chance
      //         });
      //       }
      //     }

      //     if (authStatus!.authenticated == 1 &&
      //         authStatus!.bonded == 1 &&
      //         (isBondedOrBonding || ignoreLocalBondingState)) {
      //       // TODO check bonding logic here and above
      //       isBondedOrBonding = true; // statement has no effect?
      //       getSensorData();
      //     } else if ((authStatus!.authenticated == 1 &&
      //             authStatus!.bonded == 2) ||
      //         (authStatus!.authenticated == 1 &&
      //             authStatus!.bonded == 1 &&
      //             !isBondedOrBonding)) {
      //       debugPrint("Let's Bond! " +
      //           (isBondedOrBonding ? "locally bonded" : "not locally bonded"));

      //       if (useKeepAlive) {
      //         debugPrint("Trying keepalive..");

      //         final KeepAliveTxMessage keepAliveRequest =
      //             new KeepAliveTxMessage(25);
      //         if (_cgmAuthCharacteristic != null) {
      //           _cgmAuthCharacteristic!.write(keepAliveRequest.byteSequence);
      //         }
      //       } else {
      //         /*
      //         performBondWrite(characteristic);

      //          */
      //       }
      //     } else {
      //       debugPrint("Transmitter NOT already authenticated");
      //       sendAuthRequestTxMessage();
      //     }

      //     break;

      //   case 3:
      //     {
      //       Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      //       AuthChallengeRxMessage authChallenge =
      //           new AuthChallengeRxMessage(bytes);
      //       if (authRequest == null) {
      //         authRequest = new AuthRequestTxMessage(getTokenSize());
      //       }

      //       debugPrint('tokenHash ${authChallenge.tokenHash}');
      //       debugPrint('singleUse ${calculateHash(authRequest!.singleUseToken)}');

      //       Uint8List? challengeHash = calculateHash(authChallenge.challenge);
      //       debugPrint("challenge hash" + challengeHash.toString());
      //       if (challengeHash != null) {
      //         debugPrint("Transmitter try auth challenge");
      //         AuthChallengeTxMessage authChallengeTx =
      //             new AuthChallengeTxMessage(challengeHash);
      //         debugPrint(
      //             "Auth Challenge: " + authChallengeTx.byteSequence.toString());
      //         if (_cgmAuthCharacteristic != null &&
      //             _cgmAuthCharacteristic!.properties.notify &&
      //             !_cgmAuthCharacteristic!.isNotifying) {
      //           await _cgmAuthCharacteristic!.setNotifyValue(true);
      //           if (_cgmAuthCharacteristic!.properties.write ||
      //               _cgmAuthCharacteristic!.properties.writeWithoutResponse) {
      //             _cgmAuthCharacteristic!.write(authChallengeTx!.byteSequence!);
      //           }
      //         }
      //       }
      //     }
      //     break;

      //   default:
      //     {
      //       if ((code == 7) && (delayOnBond)) {}

      //       if ((code == 7) && (tryOnDemandBondWithDelay)) {}

      //       debugPrint("Read code: " +
      //           code.toString() +
      //           " - Transmitter NOT already authenticated?");
      //       sendAuthRequestTxMessage();
      //     }
      //     break;
      // }

      // debugPrint("OnCharacteristic READ finished ");
    }

    /*
   * @brief process cgm data from connected cgm device
   */
    void _handleCgmValue(List<int> value) {
      // handle CGM value
      String data;
      // Try to decode as UTF-8
      try {
        data = utf8.decode(value);
      } on FormatException {
        // If UTF-8 decoding fails, try ASCII decoding
        data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
      }
      // Process decoded string
      //print('kai::decodedString = ' + data);
      /*
    String data = utf8.decode(value, allowMalformed: true);
     */
    }

// CGM related functions
// ...
    /*
   * @brief register cgm control characteristic value listener
   *        to get an data or message sent from the connected cgm device.
   */
    void registerCgmControlValueListener(Function(List<int>) listener) {
      if (_cgmControlCharacteristic != null) {
        _cgmControlValueSubscription =
            _cgmControlCharacteristic!.value.listen((value) {
          listener(value);
        });
      } else {
        debugPrint(
          'registerCgmControlValueListener():_cgmControlCharacteristic is NULL',
        );
      }
    }

    /*
   * @brief unregister cgm control characteristic value listener
   *        to get an data or message sent from the connected cgm device.
   */
    void unregisterCgmControlValueListener() {
      debugPrint('unregisterCgmControlValueListener():is called');
      if (_cgmControlValueSubscription != null) {
        _cgmControlValueSubscription!.cancel();
        _cgmControlValueSubscription = null;
      }
    }

    /*
   * @brief register cgm auth characteristic value listener
   *        to get an auth data or message sent from the connected cgm device.
   */
    void registerCgmAUthValueListener(Function(List<int>) listener) {
      if (_cgmAuthCharacteristic != null) {
        _cgmAuthValueSubscription =
            _cgmAuthCharacteristic!.value.listen((value) {
          listener(value);
        });
      } else {
        debugPrint(
          'registerCgmAUthValueListener():_cgmAuthCharacteristic is NULL',
        );
      }
    }

    /*
   * @brief unregister cgm auth characteristic value listener
   */
    void unregisterCgmAuthValueListener() {
      debugPrint('unregisterCgmAuthValueListener():is called');
      if (_cgmAuthValueSubscription != null) {
        _cgmAuthValueSubscription!.cancel();
        _cgmAuthValueSubscription = null;
      }
    }

    /*
   * @brief register cgm battery level characteristic value listener
   */
    void registerCgmBatLvlValueListener(Function(List<int>) listener) {
      if (_cgmRXBatLvlCharacteristic != null) {
        _cgmBatValueSubscription =
            _cgmRXBatLvlCharacteristic!.value.listen((value) {
          listener(value);
        });
      } else {
        debugPrint(
          'registerCgmBatLvlValueListener():_cgmRXBatLvlCharacteristic is NULL',
        );
      }
    }

    /*
   * @brief unregister cgm battery level characteristic value listener
   */
    void unregisterCgmBatLvlValueListener() {
      debugPrint('unregisterCgmBatLvlValueListener():is called');
      if (_cgmBatValueSubscription != null) {
        _cgmBatValueSubscription!.cancel();
        _cgmBatValueSubscription = null;
      }
    }

    /*
   * @brief disconnect cgm device and init listener and  variables
   */
    Future<void> disconnectCgmDevices() async {
      debugPrint('disconnectCgmDevices():is called');
      if (_cgmControlValueSubscription != null) {
        await _cgmControlValueSubscription!.cancel();
        _cgmControlValueSubscription = null;
      }

      if (_cgmAuthValueSubscription != null) {
        await _cgmAuthValueSubscription!.cancel();
        _cgmAuthValueSubscription = null;
      }

      if (_cgmBatValueSubscription != null) {
        await _cgmBatValueSubscription!.cancel();
        _cgmBatValueSubscription = null;
      }

      await _cgmDevice!.disconnect();
      _cgmDevice = null;

      ///< kai_20230304 clear here
      notifyListeners();
    }

    /*
   * @brief send command to cgm device
   *        : xDrip:  VersionRequestTxMessage : opcode 1, length 3
   *        commands : 0x20 Version Request  <=  byte[] = appendCRC()
   *
   * byte[] appendCRC() {
   * data.put(FastCRC16.calculate(getByteSequence(), byteSequence.length - 2));
   * return getByteSequence();
   * }
   */
    Future<void> sendControlCmdToCgmDevice(List<int> data) async {
      if (_cgmControlCharacteristic != null) {
        if (_cgmControlCharacteristic!.properties.notify &&
            !_cgmControlCharacteristic!.isNotifying) {
          await _cgmControlCharacteristic!.setNotifyValue(true);
        }

        if (_cgmControlCharacteristic!.properties.write ||
            _cgmControlCharacteristic!.properties.writeWithoutResponse) {
          await _cgmControlCharacteristic!.write(data);
        }
      }
    }

    /*
   * @brief authentication cgm device
   */
    Future<void> authenticate() async {
      if (_cgmAuthCharacteristic != null) {
        if (_cgmAuthCharacteristic!.properties.notify &&
            !_cgmAuthCharacteristic!.isNotifying) {
          await _cgmAuthCharacteristic!.setNotifyValue(true);
        }

        if (_cgmAuthCharacteristic!.properties.read) {
          await _cgmAuthCharacteristic!.read();
          // can receive the data thru the registered Auth value listener
        }
      }
    }

    int getTokenSize() {
      return 8; // d
    }

    /*
   * @brief send authentication request message to the dexcom G5, 6 cgm device
   */
    Future<void> sendAuthRequestTxMessage() async {
      if (_cgmAuthCharacteristic != null) {
        // AuthRequestTxMessage authRequest =
        //     new AuthRequestTxMessage(getTokenSize());
        // if (_cgmAuthCharacteristic!.properties.notify &&
        //     !_cgmAuthCharacteristic!.isNotifying) {
        //   await _cgmAuthCharacteristic!.setNotifyValue(true);
        //   await _cgmAuthCharacteristic!.write(authRequest.byteSequence);
        // }
      }
    }

    bool useG5NewMethod() {
      //return Pref.getBooleanDefaultFalse("g5_non_raw_method") && (Pref.getBooleanDefaultFalse("engineering_mode"));
      return false;
    }

    /*
   * @brief get sensor data
   */
    Future<void> getSensorData() async {
      try {
        if (_cgmControlCharacteristic != null) {
          if (_cgmControlCharacteristic!.properties.notify &&
              !_cgmControlCharacteristic!.isNotifying) {
            await _cgmControlCharacteristic!.setNotifyValue(true);
            if (useG5NewMethod()) {
              //new style
              // GlucoseTxMessage glucoseTxMessage = new GlucoseTxMessage();
              // _cgmControlCharacteristic!.write(glucoseTxMessage.byteSequence);
            } else {
              // old style
              // SensorTxMessage sensorTx = new SensorTxMessage();
              // _cgmControlCharacteristic!.write(sensorTx.byteSequence);
            }
          }
        }
      } catch (e) {
        debugPrint('Error getSensorData =  $e');
      }
    }

    /*
   * @brief send authentication message to the cgm device
   */
    Future<void> sendAuthCmdToCgmDevice(List<int> data) async {
      if (_cgmAuthCharacteristic != null) {
        if (_cgmAuthCharacteristic!.properties.notify &&
            !_cgmAuthCharacteristic!.isNotifying) {
          await _cgmAuthCharacteristic!.setNotifyValue(true);
        }

        if (_cgmAuthCharacteristic!.properties.write ||
            _cgmAuthCharacteristic!.properties.writeWithoutResponse) {
          await _cgmAuthCharacteristic!.write(data);
        }
      }
    }

    /*
   * @brief send battery level message to the cgm device
   */
    Future<void> sendBatLvlCmdToCgmDevice(List<int> data) async {
      if (_cgmAuthCharacteristic != null) {
        if (_cgmRXBatLvlCharacteristic!.properties.notify &&
            !_cgmRXBatLvlCharacteristic!.isNotifying) {
          await _cgmRXBatLvlCharacteristic!.setNotifyValue(true);
        }

        if (_cgmRXBatLvlCharacteristic!.properties.write ||
            _cgmRXBatLvlCharacteristic!.properties.writeWithoutResponse) {
          await _cgmAuthCharacteristic!.write(data);
        }
      }
    }

    /*
   * @brief kai_20230304
   *    If the data that will be transferred to the connected CGM device is of type String,
   *    you can convert it to a List<int> using the codeUnits property of the String object.
   *    Here is an example of how you could use _cgmTxCharacteristic to send a String to
   *    the connected CGM device:
   *    String data = "Hello, CGM device!";
   *    List<int> dataBytes = data.codeUnits;
   *    _cgmTxCharacteristic.write(dataBytes);
   */
    Future<void> sendStringDataToCgmDevice(String data) async {
      if (_cgmControlCharacteristic != null) {
        // Uint8List bytes = Uint8List.fromList(utf8.encode(data));
        final bytes = data.codeUnits;
        await _cgmControlCharacteristic!.write(bytes);
      }
    }

    /*
   * @brief cgm connectionstatus callback function example
   */
    void cgmConnectionStatus(BluetoothDeviceState state) {
      if (mCgmConnectionState == state) {
        // if connection status is same then ignore
        return;
      }

      switch (state) {
        case BluetoothDeviceState.connected:
          mCgmConnectionState = state;
          break;

        case BluetoothDeviceState.connecting:
          mCgmConnectionState = state;
          break;

        case BluetoothDeviceState.disconnected:
          mCgmConnectionState = state;
          break;

        case BluetoothDeviceState.disconnecting:
          mCgmConnectionState = state;
          break;
      }
    }

    /*
   * @brief register cgm connection state listener callback
   */
    void registerCgmStateCallback(
      void Function(BluetoothDeviceState) callback,
    ) {
      if (_cgmDevice == null) {
        debugPrint('registerCgmStateCallback():_cgmDevice is NULL');
      } else {
        debugPrint('registerCgmStateCallback():is called');
        mCgmconnectionSubscription = _cgmDevice!.state.listen(callback);
      }
    }

    /*
   * @brief unregister cgm connection state listener callback
   */
    void unregisterCgmStateCallback() {
      debugPrint('unregisterCgmStateCallback():is called');
      mCgmconnectionSubscription?.cancel();
      mCgmconnectionSubscription = null;
    }

    /*
   * @brief notify cgm battery characteristic
   */
    Future<void> cgmBatteryNotify() async {
      if (mCGMflutterBlue.state == BluetoothState.on) {
        if (_cgmRXBatLvlCharacteristic != null) {
          if (!_cgmRXBatLvlCharacteristic!.isNotifying) {
            _cgmBatValueSubscription ??=
                _cgmRXBatLvlCharacteristic!.value.listen((value) {
              // _handlePumpBatLevelValue(value);
            });
            await _cgmRXBatLvlCharacteristic!.setNotifyValue(true);
            //let's send command "BAT:" to the connected device here
            sendStringDataToCgmDevice('BAT:');
          } else {
            if (_cgmBatValueSubscription != null) {
              await _cgmBatValueSubscription!.cancel();
              _cgmBatValueSubscription = null;
            }
            await _cgmRXBatLvlCharacteristic!.setNotifyValue(false);
          }
        }
      }
    }

// Pump related functions
    /*
   * @brief process Pump data sent from connected Pump device
   * this kind of funcion can be registered by using registerPumpValueListener() also.
   */
    void handlePumpValue(List<int> value) {
      if (value == null || value.isEmpty) {
        // 예외 처리
        return;
      }

      //kai_20230420 add to check current device.name is caremedi or not
      final pumpname = CspPreference.mPUMP_NAME.isEmpty
          ? pumpDeviceName
          : CspPreference.mPUMP_NAME;
      if (pumpname.isNotEmpty && pumpname.contains(CareLevo_PUMP_NAME)) {
        // handleCaremediPump(value);
      } else {
        // handle pump value
        String data;
        // Try to decode as UTF-8
        try {
          data = utf8.decode(value);
        } on FormatException {
          // If UTF-8 decoding fails, try ASCII decoding
          data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
        }
        // Process decoded string
        log('kai::decodedString = $data');
        /*
     // String data = utf8.decode(value, allowMalformed: true);
      String data = utf8.decode(List<int>.from(value));
       */
      }
    }

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
      return '${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    }

    /*
   * @brief handler to parse the received data sent from the connected pump patch device
   */
    void handleCaremediPump(List<int> value) {
      // handle pump value
      if (value == null || value.isEmpty || value.isEmpty) {
        // 예외 처리
        log(
          'kai: handleCaremediPump(): cannot handle due to no input data,  return',
        );
        return;
      }

      // handle pump value
      /*
    List<int>.of(value) 메소드를 사용하면,
    value 리스트의 크기와 동일한 크기의 새 리스트를 만들어 복사합니다.
    이 경우, value 리스트의 첫 번째 바이트가 삭제되므로 코드가 올바르게 동작하지 않을 수 있습니다.
    따라서, List<int>.from(value) 메소드를 사용하여 value 리스트의 복사본을 만들어야 합니다.
    이 방법은 value 리스트를 복사하면서 첫 번째 바이트를 삭제하지 않습니다.
     */
      /*
    // Unhandled Exception: FormatException: Unexpected extension byte (at offset 0)  발생됨
    String data = utf8.decode(List<int>.from(value));
    List<int> buffer = List<int>.of(value);
     */

      //String data = utf8.decode(List<int>.from(value));
      /*
    Uint8List.fromList 메서드는 List<int>를 Uint8List 형식으로 변환해줍니다.
    utf8.decode 메소드는 List<int> 타입을 인자로 받지 않기 때문에 Uint8List 형식으로 변환하여 사용해야 합니다.
     */

      /*
    String data;
    if (value[0] < 0x80) {
      data = ascii.decode(value);
    } else if (value[0] >= 0xC0 && value[0] <= 0xFD) {
      data = utf8.decode(Uint8List.fromList(value));
    } else {
      // 데이터가 알 수 없는 형식인 경우 예외 처리
     log('kai: handleCaremediPump(): cannot handle due to invalid unknown data format, return');
      return;
    }

     */
      /*  수신된 데이터가 ascii 문자와 다른 문자가 혼용되어 있는 경우
    1. 먼저 수신된 value 데이터의 길이를 구하고
    2. 길이만큼 루프를 돌리면서 값의 구분인자가 나올때 디코딩을 하고 값을 버퍼에 저장한다
    3. List<String> decoded 리스트 값을 합친다
       */

      final LENGTH = value.length;
      final hexString = value.map((byte) => toHexString(byte)).join(' ');
      final decimalString = value
          .map((hex) => hex.toRadixString(10))
          .join(' '); // 10진수로 변환하고 join으로 스트링으로 변환
      if (USE_DEBUG_MESSAGE) {
        log('kai: data length = $LENGTH');
        log('kai : hexString value = $hexString');
        log('kai : decimalString value = $decimalString');
      }

      /*
    String data = '';
    List<String> decodedData = [];
    List<int> Tempbuffer = [];
    for (int i = 0; i < LENGTH; i++) {
      Tempbuffer.add(value[i]);
     // if (value[i] == 0x17)
      { // 마지막 데이터 구분자인 0x17이 나오면 디코딩 수행
        String decodedString;
        try {
          decodedString = utf8.decode(Uint8List.fromList(Tempbuffer));
         log('kai: utf8 decode index[' + i.toString() + '] = ' + decodedString);
          data += decodedString;
        } on FormatException {
          // If UTF-8 decoding fails, try ASCII decoding
          if (isAscii(Tempbuffer)) {
            decodedString = ascii.decode(Tempbuffer);
           // decodedString = ascii.decode(Tempbuffer.where((byte) => byte <= 0x7f).toList());
           log('kai: ascii decode index[' + i.toString() + '] = ' + decodedString);
            data += decodedString;
          }
          else
          {
            decodedString = ascii.decode(Tempbuffer.where((byte) => byte <= 0x7f).toList());
           log('kai: after utf-8: ascii decode index[' + i.toString() + '] = ' + decodedString);
            data += decodedString;
          }
        }
        decodedData.add(decodedString);
       //log('kai: add decodedData index[' + i.toString() + '] = ' + decodedString);
        Tempbuffer.clear();
      }
    }
    */

      /*
    String data
    // Try to decode as UTF-8
    try {
      //data = utf8.decode(value);
      data = utf8.decode(Uint8List.fromList(value));
    } on FormatException {
      // If UTF-8 decoding fails, try ASCII decoding
     log('kai: handleCaremediPump(): ascii decoding ');
      data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
    }
   log('kai: handleCaremediPump():decodedData = ' + data);
     */
      // Process decoded string
      final buffer = List<int>.from(value);
      final code = buffer[0];
      log('handleCaremediPump is called : code = $code');

      switch (code) {
        case SET_TIME_RSP:

          ///< 0x71
          {
            //Result (1 byte): SUCCESS 0, FAIL 1
            if (buffer[1] == 0) {
              SET_TIME_RSP_responseReceived = true;
              log('SET_TIME_RSP: success: ');
              SetUpWizardMsg = 'Set time request is complete!!';
              SetUpWizardActionType = 'SET_TIME_RSP_SUCCESS';
              showSetUpWizardMsgDlg = true;
              //let's send SAFETY_CHECK_REQ here
            } else {
              SET_TIME_RSP_responseReceived = true;
              log('SET_TIME_RSP: failed: ');
              SetUpWizardMsg = 'Set time request is complete!!';
              SetUpWizardActionType = 'SET_TIME_RSP_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case PATCH_INFO_RPT1:
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
              subList = value.sublist(8);

              ///< 모델명 (6 byte, ascii)
              final rootNumber = ascii.decode(subList);
              /*
              String modelName = data.substring(2,8); ///< length 6 byte  : 2 ~ 7
              String rootNumber = data.substring(8 /*,15 */); ///< length 8 byte
               */
              //kai_20230427 let's update infoms.
              ModelName = modelName.toString();
              ValidCode = rootNumber.toString();
              notifyListeners();
              log(
                'PATCH_INFO_RPT1:Model = $modelName, routeNumber = $rootNumber',
              );

              SetUpWizardMsg =
                  'Patch Info: Model = $modelName, routeNumber = $rootNumber';
              SetUpWizardActionType = 'PATCH_INFO_RPT1_SUCCESS';
              showSetUpWizardMsgDlg = true;
            } else {
              log('PATCH_INFO_RPT1:failed: No Data !!');
              SetUpWizardMsg =
                  'Patch Info request is not complete at this time.\nRetry it later!!';
              SetUpWizardActionType = 'PATCH_INFO_RPT1_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case PATCH_INFO_RPT2:
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
                'bootTimeDate = $bootTimeDate',
              ); //decimalString have 2bytes characters, so we  put index per 2 bytes

              final year = subList[0].toInt();
              final month = subList[1].toInt();
              final day = subList[2].toInt();
              final hour = subList[3].toInt();
              final minute = subList[4].toInt();

              //kai_20230427 let's update infoms.
              FWVersion = '$fwMaj.$fwMir.$fwPatch';
              SerialNo = sn.toString();
              FirstConnectedTime = '20$year/$month/$day $hour:$minute';
              //kai_20230427  save info periodically here
              LogMessageView =
                  '모델명:$ModelName, 제조번호:$SerialNo\n펌웨어버전:$FWVersion, 루트번호:$ValidCode\n최초연결시간:$FirstConnectedTime\n';
              //notifyListeners();

              log(
                'PATCH_INFO_RPT2:\nSN = $sn\nf/w ver. = $fwMaj.$fwMir.$fwPatch\nBooting TimeDate = 20$year/$month/$day $hour:$minute',
              );

              SetUpWizardMsg =
                  'Patch Info:\nSN = $sn\nf/w ver. = $fwMaj.$fwMir.$fwPatch\nBooting TimeDate = 20$year/$month/$day $hour:$minute';
              SetUpWizardActionType = 'PATCH_INFO_RPT2_SUCCESS';
              showSetUpWizardMsgDlg = true;

              //let's send THRESHOLD_SETUP_REQ(0x17)  when we get this response from pump
              //actually this operation should be proceed by user action thru setting option UI
              //let's send THRESHOLD_SETUP_REQ(0x17)  when we get this response from pump
              if (_USE_TEST_SET_MAX_BOLUS_THRESHOLD == true) {
                var MaxValue = CspPreference.getString(
                  CspPreference.pumpMaxInfusionThresholdKey,
                );
                log(
                  'kai: call sendSetMaxBolusThreshold($MaxValue, 0x01, NULL)',
                );
                if (MaxValue == null || MaxValue.isEmpty || MaxValue.isEmpty) {
                  MaxValue = '25';
                }
                // sendSetMaxBolusThreshold(MaxValue, 0x01, null);
              } else {
                SetUpWizardMsg = 'Please set Maximum Bolus Value';
                SetUpWizardActionType = 'INFUSION_THRESHOLD_REQ';
                showSetUpWizardMsgDlg = true;
              }
            } else {
              log('PATCH_INFO_RPT2:failed: No Data !!');
              SetUpWizardMsg =
                  'Patch Info second request is not complete at this time.\nRetry it later!!';
              SetUpWizardActionType = 'PATCH_INFO_RPT2_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case SAFETY_CHECK_RSP:

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
                'SAFETY_CHECK_RSP:Reservoir = ${ReservoirAmount}U, (${RAmL}mL)',
              );
              //kai_20230427 let's update infoms.
              reservoir = '${ReservoirAmount}U';
              //notifyListeners();

              //let's update received value to the reservoir amount here
              SetUpWizardMsg =
                  'Check Safety request is complete.\nReservoir = ${ReservoirAmount}U, (${RAmL}mL)';
              SetUpWizardActionType = 'SAFETY_CHECK_RSP_SUCCESS';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 1) {
              reservoir = 'Low insulin!!';
              // notifyListeners();

              log('SAFETY_CHECK_RSP:1 Low insulin !!');
              SetUpWizardMsg = 'Check Safety is not complete:Low insulin!!';
              SetUpWizardActionType = 'SAFETY_CHECK_RSP_LOW_INSULIN';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 2) {
              log('SAFETY_CHECK_RSP:2 Abnormal Pump !!');
              SetUpWizardMsg = 'Check Safety is not complete:Abnormal Pump!!';
              SetUpWizardActionType = 'SAFETY_CHECK_RSP_ABNORMAL_PUMP';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 3) {
              BatLevel = 'Low Battery !!';
              //notifyListeners();

              log('SAFETY_CHECK_RSP:3 Low voltage !!');
              SetUpWizardMsg = 'Check Safety is not complete:Low voltage!!';
              SetUpWizardActionType = 'SAFETY_CHECK_RSP_LOW_VOLTAGE';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 4) {
              log('SAFETY_CHECK_RSP:4 1st response !!');
              SetUpWizardMsg =
                  'Got response for the First Check Safety Request!!';
              SetUpWizardActionType = 'SAFETY_CHECK_RSP_GOT_1STRSP';
              showSetUpWizardMsgDlg = true;
            } else {
              log('SAFETY_CHECK_RSP: failed !!');
              SetUpWizardMsg =
                  'There is no response for Check Safety Request at this time!!';
              SetUpWizardActionType = 'SAFETY_CHECK_RSP_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case INFUSION_THRESHOLD_RSP:

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
                'INFUSION_THRESHOLD_RSP:set bolus max injection threshold success !!',
              );

              //let's send Safety check request automatically here
              if (_USE_TEST_SET_MAX_BOLUS_THRESHOLD == true) {
                log('kai: call sendSafetyCheckRequest(null)');
                // sendSafetyCheckRequest(null);
              } else {
                SetUpWizardMsg =
                    'Please perform a safety check for pump condition and air removal.\nProceed it?';
                // 펌프 상태, 공기 제거를 위한 안전 점검을 진행해 주세요
                SetUpWizardActionType =
                    'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST';
                showSetUpWizardMsgDlg = true;
              }
            } else {
              INFUSION_THRESHOLD_RSP_responseReceived = true;
              log(
                'INFUSION_THRESHOLD_RSP:set bolus max injection threshold failed !!',
              );
              SetUpWizardMsg =
                  'set bolus max injection threshold is not complete at this time.\nRetry it later!!';
              SetUpWizardActionType = 'INFUSION_THRESHOLD_RSP_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case INFUSION_INFO_RPT:
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
            final hour = subList[0].toInt();
            final min = subList[1].toInt();

            subList = value.sublist(4, 7);
            final per100 = subList[0].toInt();
            final per10to1 = subList[1].toInt();
            final afterpoint = subList[2].toInt();

            subList = value.sublist(7, 11);
            final BasalBeforePoint = subList[0].toInt();
            final BasalAfterPoint = subList[1].toInt();
            final BolusBeforePoint = subList[2].toInt();
            final BolusAfterPoint = subList[3].toInt();

            subList = value.sublist(11, 13);
            final StatusPump = subList[0].toInt();
            final InjectMode = subList[1].toInt();

            subList = value.sublist(13, 20);
            final injectPeriodHour = subList[0].toInt();
            final injectPeriodMin = subList[1].toInt();
            final injectAmountBeforePoint = subList[2].toInt();
            final injectAmountAfterPoint = subList[3].toInt();
            final injectSpendTimeHour = subList[4].toInt();
            final injectSpendTimeMin = subList[5].toInt();
            final injectSpendTimeSec = subList[6].toInt();

            final ShowInfusionInfoReportMsg = '패치사용시간= $hour시간$min분\n인슐린 잔여량 = '
                '$per100$per10to1.${afterpoint}U\n총 주입량 = 기저 '
                '$BasalBeforePoint.${BasalAfterPoint}U, 볼루스 '
                '$BolusBeforePoint.${BolusAfterPoint}U\n펌프상태 = '
                '${(StatusPump == 0) ? '대기' : (StatusPump == 1) ? '프라이밍' : (StatusPump == 2) ? '구동중' : (StatusPump == 3) ? '고장' : ' '}\n주입 모드 = ${(InjectMode == 0) ? '기초' : (InjectMode == 1) ? '일시기초' : (InjectMode == 2) ? '즉시 볼러스' : (InjectMode == 3) ? '연장 볼러스' : ' '}\n주입 기간 = '
                '$injectPeriodHour시간 $injectPeriodMin분 \n주입량 = '
                '$injectAmountBeforePoint.${injectAmountAfterPoint}U\n주입결과시간 '
                '= $injectSpendTimeHour시간 $injectSpendTimeMin분 '
                '$injectSpendTimeSec초';

            //kai_20230427  save info periodically here
            LogMessageView =
                '모델명:$ModelName, 제조번호:$SerialNo\n펌웨어버전:$FWVersion, '
                '루트번호:$ValidCode\n최초연결시간:$FirstConnectedTime'
                '\n$ShowInfusionInfoReportMsg';

            if (buffer[1] == 0)

            ///< 주입 현황 요청 응답(0x00)
            {
              //kai_20230427 let's update variable
              PatchUseAvailableTime = '$hour시간$min분';
              reservoir = '$per100$per10to1.${afterpoint}U';
              InsulinDelivery =
                  '$injectAmountBeforePoint.${injectAmountAfterPoint}U';
              latestDeliveryTime =
                  '$injectSpendTimeHour시간 $injectSpendTimeMin분 '
                  '$injectSpendTimeSec초';

              SetUpWizardMsg =
                  'Infusion info report\n$ShowInfusionInfoReportMsg';
              SetUpWizardActionType = 'INFUSION_INFO_RPT_SUCCESS';
              showSetUpWizardMsgDlg = true;
              if (USE_DEBUG_MESSAGE == true) {
                log(
                  'kai:INFUSION_INFO_RPT:success!!\n$ShowInfusionInfoReportMsg',
                );
              }
            } else if (buffer[1] == 1)

            ///< 잔여량 요청 응답(0x01)
            {
              //kai_20230427 let's update variable
              PatchUseAvailableTime = '$hour시간$min분';
              reservoir = '$per100$per10to1.${afterpoint}U';
              InsulinDelivery =
                  '$injectAmountBeforePoint.${injectAmountAfterPoint}U';
              latestDeliveryTime =
                  '$injectSpendTimeHour시간 $injectSpendTimeMin분 '
                  '$injectSpendTimeSec초';

              SetUpWizardMsg =
                  'Infusion info report\n$ShowInfusionInfoReportMsg';
              SetUpWizardActionType = 'INFUSION_INFO_RPT_REMAIN_AMOUNT';
              showSetUpWizardMsgDlg = true;
              if (USE_DEBUG_MESSAGE == true) {
                log(
                  'kai:INFUSION_INFO_RPT_REMAIN_AMOUNT'
                  '\n$ShowInfusionInfoReportMsg',
                );
              }
            } else if (buffer[1] == 2)

            ///< 30분단위 보고 (0x02)
            {
              //kai_20230427 let's update variable
              PatchUseAvailableTime = '$hour시간$min분';
              reservoir = '$per100$per10to1.${afterpoint}U';
              InsulinDelivery =
                  '$injectAmountBeforePoint.${injectAmountAfterPoint}U';
              latestDeliveryTime =
                  '$injectSpendTimeHour시간 $injectSpendTimeMin분 '
                  '$injectSpendTimeSec초';

              SetUpWizardMsg =
                  'Infusion info report\n$ShowInfusionInfoReportMsg';
              SetUpWizardActionType = 'INFUSION_INFO_RPT_30MIN_REPEATEDLY';
              showSetUpWizardMsgDlg = true;
              if (USE_DEBUG_MESSAGE == true) {
                log(
                  'kai:INFUSION_INFO_RPT_30MIN_REPEATEDLY\n$ShowInfusionInfoReportMsg',
                );
              }
            } else if (buffer[1] == 3)

            ///< 재 연결 보고(0x03)
            {
              //kai_20230427 let's update variable
              PatchUseAvailableTime = '$hour시간$min분';
              reservoir = '$per100$per10to1.${afterpoint}U';
              InsulinDelivery =
                  '$injectAmountBeforePoint.${injectAmountAfterPoint}U';
              latestDeliveryTime =
                  '$injectSpendTimeHour시간 $injectSpendTimeMin분 '
                  '$injectSpendTimeSec초';

              log(
                'INFUSION_INFO_RPT:success 0x03:reconnected '
                'between app and patch!',
              );
              SetUpWizardMsg = 'Infusion info report\nPatch connection was '
                  'established again!!';
              SetUpWizardActionType = 'INFUSION_INFO_RPT_RECONNECTED';
              showSetUpWizardMsgDlg = true;
              if (USE_DEBUG_MESSAGE == true) {
                log('kai:INFUSION_INFO_RPT_RECONNECTED\n$SetUpWizardMsg');
              }
            }
          }
          break;

        case HCL_BOLUS_RSP:

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
              //success, then let's check the spent time
              //to inject bolus in pump side
              //at this point app should showing progress status as
              //like progress bar
              SetUpWizardMsg = 'bolus injection expected spend time = '
                  '${buffer[3].toInt()}min ${buffer[4].toInt()}sec';
              SetUpWizardActionType = 'HCL_BOLUS_RSP_SUCCESS';
              showSetUpWizardMsgDlg = true;

              //kai_20230427 let's set timer flag with timeout value which is
              //based on the response duration time.
              final timeout = buffer[3].toInt() * 60 + buffer[4].toInt();
              log(
                'kai: bolus injection expected spend time = '
                '${buffer[3].toInt()}min ${buffer[4].toInt()}sec, '
                'set _isInjectingNow = true and block additional sending Dose '
                'until the timeout($timeout)',
              );
              _isDoseInjectingNow = true;

              Future.delayed(Duration(seconds: timeout), () {
                debugPrint(
                  'kai: release blocked dose request!!: '
                  '_isDoseInjectingNow = false',
                );
                _isDoseInjectingNow = false;

                //kai_20230427 let's update latest insulin injected time here
                latestDeliveryTime =
                    DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now());
                notifyListeners();
              });
            } else if (buffer[2] == 1) {
              //fail
              log(
                'HCL_BOLUS_RSP:failed to inject bolus due to injecting is '
                'ongoing or status of pump is abnormal!!',
              );
              SetUpWizardMsg =
                  'Failed to inject bolus due to injecting is ongoing or '
                  'status of pump is abnormal at this time.';
              SetUpWizardActionType = 'HCL_BOLUS_RSP_FAILED';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[2] == 4) {
              log(
                'HCL_BOLUS_RSP: failed to inject bolus due to '
                'DATA_OVERFLOW(${buffer[2].toInt()})!!',
              );
              SetUpWizardMsg = 'Failed to inject bolus due to '
                  'DATA_OVERFLOW(${buffer[2].toInt()})!!';
              SetUpWizardActionType = 'HCL_BOLUS_RSP_OVERFLOW';
              showSetUpWizardMsgDlg = true;
            } else {
              log(
                'HCL_BOLUS_RSP: failed to inject bolus due to '
                'error(${buffer[2].toInt()})!!',
              );
            }
          }
          break;

        case HCL_BOLUS_CANCEL_RSP:
          {
            // RESULT: SUCCESS 0x00, FAIL 0x01 (주입 중이 아닌 경우)
            //  주입량 (현재까지 주입된 량, 2바이트): DSOE_I, DOSE_D
            //
            // RSP	MODE	RESULT	DOSE_I	DOSE_D
            // 0xD8	0x00	 0x00	    0x03	  0x05
            if (buffer[2] == 0) {
              log(
                'injected bolus amount = ${buffer[3].toInt()}.${buffer[4].toInt()}ml',
              );

              SetUpWizardMsg = 'Cancel injecting bolus amount = '
                  '${buffer[3].toInt()}.${buffer[4].toInt()}ml';
              SetUpWizardActionType = 'HCL_BOLUS_CANCEL_RSP_SUCCESS';
              showSetUpWizardMsgDlg = true;

              //kai_20230427 release blocking dose request flag here
              if (isDoseInjectingNow == true) {
                isDoseInjectingNow = false;
              }
            } else {
              log('HCL_BOLUS_CANCEL_RSP:failed to cancel bolus injection!!');
              SetUpWizardMsg = 'failed to cancel bolus '
                  'injection(${buffer[3].toInt()}.${buffer[4].toInt()}ml)';
              SetUpWizardActionType = 'HCL_BOLUS_CANCEL_RSP_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case CANNULAR_INSERT_RPT:
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
              log('CANNULAR_INSERT_RPT:success !!');
              SetUpWizardMsg =
                  'Cannular insertion success and patch attachment success!!';
              SetUpWizardActionType = 'CANNULAR_INSERT_RPT_SUCCESS';
              showSetUpWizardMsgDlg = true;
              // sendCannularInsertAck(null);
            } else {
              log('CANNULAR_INSERT_RPT:failed to insert cannular needle!!');
              /*TXErrorMsg = 'Inserting cannular is not complete at this time. Retry it?';
              showTXErrorMsgDlg = true;
               */
              SetUpWizardMsg =
                  'Inserting cannular is not complete at this time.\nRetry it later!!';
              SetUpWizardActionType = 'CANNULAR_INSERT_RPT_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case CANNULAR_INSERT_RSP:
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
              log('CANNULAR_INSERT_RSP:success !!');
              SetUpWizardMsg = 'Patch is ready now!!';
              SetUpWizardActionType = 'CANNULAR_INSERT_RSP_SUCCESS';
              showSetUpWizardMsgDlg = true;
            } else {
              log('CANNULAR_INSERT_RSP:failed to insert cannular needle!!');
              SetUpWizardMsg =
                  'Inserting Cannular is not complete.\nRetry it later!!';
              SetUpWizardActionType = 'CANNULAR_INSERT_RSP_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case PATCH_WARNING_RPT:
          {
            // 송신 조건: 패치 부착 중, 펌프 막힘 감지된 경우, 인슐린 잔여량이 없는 경우
            // (eg. 2U 이하, 정확한 값은 추후 약물백의 dead volume 고려), 사용 시간이 종료된 경우,
            // 그리고 배터리가 20% 미만으로 떨어진 경우에 본 메시지가 앱으로 송신된다.
            //
            // . Length 3, RPT: 0xa1
            //  . CAUSE: 펌프 막힘(토출 안됨) 0, 인슐린 고갈 1, 사용시간 종료 2, 배터리 없음(20% 미만)
            //  3, , 온도초과 (섭씨 5~40 도 밖 온도)  4, 앱 장기 미사용 5,
            // BLE 연결 안됨 6, 주입 시작 못함 7,
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
            // . Action: 본 메시지를 수신한 앱은 해당 원인 (Cause)의 경고 팝업과
            // 함께 스마트 폰에서도 경고 부저를 울린다.
            // 그리고 패치 교체 메뉴를 띄워 패치 폐기 절차를 진행한다.
          }

          break;

        case PATCH_ALERT_RPT:
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
            // -	0x08 : 주입임시중지 재개 오류((사용자 설정 재개 시간infusion resume T/O) )
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
          }
          break;

        case PATCH_NOTICE_RPT:
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
            // 시간 동기화 메시지 “SET_TIME_REQ” 수신 시부터 10분 주기로 원인 값
            // “0x0A”와 Count 값을 채워 송신하여야 한다.
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
              log(
                'PATCH_NOTICE_RPT:1 인슐린 잔여량 임계치 도달 (${buffer[2].toInt()}U)',
              );
              /* NoticeMsg = '인슐린 잔여량 임계치 도달 
              (' + buffer[2].toInt().toString() + 'U)';
            showNoticeMsgDlg = true;
            */

              //kai_20230427 let's update variable
              reservoir = '인슐린 잔여량 임계치 도달 (${buffer[2].toInt()}U)';

              SetUpWizardMsg = '인슐린 잔여량 임계치 도달 (${buffer[2].toInt()}U)';
              SetUpWizardActionType = 'PATCH_NOTICE_RPT';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 2) {
              log(
                'PATCH_NOTICE_RPT:2 패치 사용시간 임계치 도달 (${buffer[2].toInt()}시간)',
              );
              /*NoticeMsg = '패치 사용시간 임계치 도달 (' + buffer[2].toInt().toString() + 'hour)';
            showNoticeMsgDlg = true;
             */
              PatchUseAvailableTime = '패치 사용시간 임계치 도달 (${buffer[2].toInt()}시간)';

              SetUpWizardMsg = '패치 사용시간 임계치 도달 (${buffer[2].toInt()}시간)';
              SetUpWizardActionType = 'PATCH_NOTICE_RPT';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 3) {
              log(
                'PATCH_NOTICE_RPT:3 배터리 알림 임계치 도달 (${buffer[2].toInt()}%)',
              );
              /* NoticeMsg = '배터리 알림 임계치 도달 
              (' + buffer[2].toInt().toString() + '%)';
            showNoticeMsgDlg = true;
            */
              //kai_20230427 let's update variable
              BatLevel = '배터리 알림 임계치 도달 (${buffer[2].toInt()}%)';

              SetUpWizardMsg = '배터리 알림 임계치 도달 (${buffer[2].toInt()}%)';
              SetUpWizardActionType = 'PATCH_NOTICE_RPT';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 9) {
              log(
                'PATCH_NOTICE_RPT:9 패치 점검 알림 (패치 부착 후 90분, inspection timer T/O)',
              );
              /*NoticeMsg = '패치 점검 알림 (패치 부착 후 90분, inspection timer T/O)';
            showNoticeMsgDlg = true;
             */
              SetUpWizardMsg = '패치 점검 알림 (패치 부착 후 90분, inspection timer T/O)';
              SetUpWizardActionType = 'PATCH_NOTICE_RPT';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 0xa) {
              log(
                'PATCH_NOTICE_RPT:10 앱 시간 동기화 알림 (${buffer[2].toInt()})count',
              );
              /* NoticeMsg = '앱 시간 동기화 알림 
              ('+ buffer[2].toInt().toString() + ')count';
            showNoticeMsgDlg = true;
            */
              SetUpWizardMsg = '앱 시간 동기화 알림 (${buffer[2].toInt()})count';
              SetUpWizardActionType = 'PATCH_NOTICE_RPT';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 0xb) {
              log(
                'PATCH_NOTICE_RPT:11 볼러스 주입 후 혈당 측정 알림 '
                '(${buffer[2].toInt()})TimerID',
              );
              /* NoticeMsg = '볼러스 주입 후 혈당 측정 알림 
              ('+ buffer[2].toInt().toString() + ')TimerID';
            showNoticeMsgDlg = true;
            */
              SetUpWizardMsg =
                  '볼러스 주입 후 혈당 측정 알림 (${buffer[2].toInt()})TimerID';
              SetUpWizardActionType = 'PATCH_NOTICE_RPT';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case BUZZER_CHECK_RSP:
          {
            /// Length 2, RSP: 0x97, RESULT
            if (buffer[1] == 0) {
              log('BUZZER_CHECK_RSP:success !!');
              SetUpWizardMsg = 'Requesting buzzer check is complete!!';
              SetUpWizardActionType = 'BUZZER_CHECK_RSP_SUCCESS';
              showSetUpWizardMsgDlg = true;
            } else {
              log('BUZZER_CHECK_RSP:failed to check buzzer !!');
              /*TXErrorMsg = 'Requesting buzzer check is 
              not available at this time. Retry it?';
              showTXErrorMsgDlg = true;
               */
              SetUpWizardMsg = 'Requesting buzzer check is not available at '
                  'this time.\nRetry it later!!';
              SetUpWizardActionType = 'BUZZER_CHECK_RSP_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case BUZZER_CHANGE_RSP:
          {
            /// Length 1, RSP: 0x78
            // . Result (1 byte): SUCCESS 0, FAIL 1 (패치가 삽입 감지 못한 경우)
            //
            // RSP	RSLT
            // 0x78	0x00
            if (buffer[1] == 0) {
              log('BUZZER_CHANGE_RSP:success !!');
            } else {
              log('BUZZER_CHANGE_RSP:failed to change buzzer !!');
              TXErrorMsg = 'Requesting buzzer change is not available at '
                  'this time. Retry it?';
              showTXErrorMsgDlg = true;
            }
          }
          break;

        case APP_STATUS_ACK:
          {
            // Length 2, ACK: 0x99,
            //STATUS (APP_STATUS_IND 시 앱에서 통보 받은 값 세팅함: 0 or 1)

            // ACK	STATUS
            // 0x99	0x00
            if (buffer[1] == 0) {
              log('APP_STATUS_ACK:success !!');
            } else {
              log('APP_STATUS_ACK:failed to check app status !!');
            }
          }
          break;

        case MAC_ADDR_RPT:
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

        case ALARM_CLEAR_RSP:
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
              log('ALARM_CLEAR_RSP:success !!');
              if (buffer[2] == 0xa2) {
                // clear alarm
              } else if (buffer[2] == 0xa3) {
                // clear notice
              }
            } else {
              log('ALARM_CLEAR_RSP:failed to clear alarm !!');
            }
          }
          break;

        case PATCH_DISCARD_RSP:
          {
            // Length 2, RSP: 0x95, RESULT
            //
            // RSP	RSLT
            // 0x96	0x00
            if (buffer[1] == 0) {
              log('PATCH_DISCARD_RSP:success !!');
              SetUpWizardMsg = 'Discard patch is complete!!';
              SetUpWizardActionType = 'PATCH_DISCARD_RSP_SUCCESS';
              showSetUpWizardMsgDlg = true;
            } else {
              log('PATCH_DISCARD_RSP:failed to discard patch !!');
              SetUpWizardMsg =
                  'Requesting discard patch is not available at this time. Retry it?';
              SetUpWizardActionType = 'PATCH_DISCARD_RSP_FAILED';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;

        case PATCH_RESET_RPT:
          {
            // Length 2, RSP: 0x9F, MODE
            // Mode: 요청 시 받은 모드
            // 0x00 -> 패치의 Bonding list, NVM 삭제 후 리셋
            // 0x01 -> 패치의 Bonding list, NVM Data 유지 상태 리셋
            // RSP	MODE
            // 0x96	0x00
            if (buffer[1] == 0) {
              log('PATCH_RESET_RPT:success !!');
              SetUpWizardMsg = 'Reset Patch mode 0 is complete!!';
              SetUpWizardActionType = 'PATCH_RESET_RPT_SUCCESS_MODE0';
              showSetUpWizardMsgDlg = true;
            } else if (buffer[1] == 1) {
              log('PATCH_RESET_RPT:success !!');
              SetUpWizardMsg = 'Reset Patch mode 1 is complete!!?';
              SetUpWizardActionType = 'PATCH_RESET_RPT_SUCCESS_MODE1';
              showSetUpWizardMsgDlg = true;
            }
          }
          break;
      }
    }

    /*
   * @brief register Pump RX characteristic value listener
   */
    void registerPumpValueListener(Function(List<int>) listener) {
      if (_PumpRxCharacteristic != null) {
        _pumpValueSubscription = _PumpRxCharacteristic!.value.listen((value) {
          listener(value);
        });
      } else {
        debugPrint('registerPumpValueListener():_PumpRxCharacteristic is NULL');
      }
    }

    /*
   * @brief unregister Pump RX characteristic value listener
   */
    Future<void> unregisterPumpValueListener() async {
      debugPrint('unregisterPumpValueListener():is called');
      if (_pumpValueSubscription != null) {
        await _pumpValueSubscription!.cancel();
        _pumpValueSubscription = null;
      }
    }

    /*
   * @brief disconnect Pump device
   */
    Future<void> disconnectPumpDevices() async {
      debugPrint('disconnectPumpDevices():is called');
      if (_pumpValueSubscription != null) {
        await _pumpValueSubscription!.cancel();
        _pumpValueSubscription = null;
      }
      await _pumpDevice!.disconnect();
      _pumpDevice = null;

      ///< kai_20230304 clear here
      notifyListeners();
    }

    /*
   * @brief send message to the Pump device
   */
    Future<void> sendDataToPumpDevice(String data) async {
      // Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      final bytes = data.codeUnits;
      await _PumpTxCharacteristic!.write(bytes);
    }

    /*
   * @brief caremedi HCL Request
   * 스마트폰  패치 장치 전달 메시지: BLE_GATTS_EVT_WRITE (0x50)
   * Length: 가변 길이 (1 byte ~ 최대 20 byte), 첫 바이트: CMD or ACK type
   * CMD type: 시작 및 설정 메시지 (0x11 ~ 0x1C)
   * 패치구동 제어 메시지 (0x21 ~ 0x2D)
   * 패치/앱 조회 및 폐기 메시지 (0x31 ~ 0x3B)
   * 팩토리 앱 데이터 메시지 (0x40), 알람 해소 요청 메시지(0x47)
   * HCL 주입 및 제어 관련 수신 메시지 (0x60~0x6F, 0xE0~0xE8)
   * 패치 장치  스마트 폰 전달 메시지: BLE_GATTS_EVT_HVN_TX_COMPLETE (0x57)
   * Length: 가변 길이 (1 byte ~ 최대 20byte), 첫 바이트: RSP or RPT type
   * RSP/RPT type: 시작 및 설정 응답 메시지 (0x71~0x7B)
   * 패치구동 제어 응답메시지 (0x81 ~ 0x8D)
   * 패치/앱 조회 및 폐기 보고 메시지 (0x91 ~ 0x9B)
   * 경고/주의/알림 메시지 (0xa1 ~ 0xa3), 알람 해소 응답 메시지(0xA7)
   * 팩토리 앱 데이터 응답 메시지 (0xB0)
   * HCL 주입 및 제어 관련 송신 메시지 (0xD0~0xD9, 0xE9~0xEF)
   *
   * @detail
   * HCL Request
   * HCL_DOSE_REQ (0x67)
   *        Mode (1 byte): HCL 통합 주입(0x00).
   *        교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
   *        주입량 (2 byte): DOSE_I (정수), DOSE_D (소수점 X 100)
   *        Ex) 5.25 U  0x05 0x19
   *        요청한 주입량이 사용자 설정한 최대 볼러스 량보다 크면 실패 (Cause 0x04 DATA_OVER_FLOW) 로 응답함 (HCL_BOLUS_RSP)
   *        REQ 	MODE	DOSE_I	DOSE_D
   *        0x67	0x00	 0x05	   0x19
   *        Action: 본 메시지를 수신하면 패치는 수신한 볼러스 주입량으로 빠르게 볼러스 주입을 진행한다.
   *        동시에 앱으로는 “HCL_DOSE_RSP (0xD7)” 메시지로  결과 값 (SUCCESS or FAIL)과 예상 소요 시간을 추가하여 응답한다.
   *        FAIL 은 이전 주입이 미완료로 주입 중 상태이거나, 이미 경고 알림이 발생하여 펌프 이상으로 주입을 못하는 경우이다.
   *        요청한 주입량이 최대 볼러스 량보다 큰 경우나 0인 경우 FAIL (0x04 DATA_OVERFLOW) 로 응답한다
   *
   *        나.	HCL  주입 응답 (패치 장치  앱): HCL_BOLUS_RSP (0xD7)
   *        Length 5,
   *        CMD: 0xD7,
   *        MODE: 요청 시 모드 값 입력
   *        RESULT: SUCCESS 0x00, FAIL 0x01 (현재 주입 중 상태 또는 펌프 구동 불가 상태),
   *        DATA_OVERFLOW 0x04 (최대 볼러스 량보다 큰 경우, 또는 0)
   *        소요 시간 : 분 (EXP_TIME_M), 초 (EXP_TIME_S)
   *        RSP	  MODE	RESULT	EXP_TIME_M	EXP_TIME_S
   *        0xD7	0x00	0x00	       0x02    0x05
   *        Action: 본 메시지를 수신한 앱은 소요 시간이 적용된 주입 진행바를 띄우고 진행 상태를 실시간 색깔로 표시한다.
   *        또한 주입 시간 동안 새로운 주입 요청을 막아야 한다.
   *        예를 들어 5분 주기로 주입을 제어하는 경우, 총 주입 시간이 5분을 초과하면 5분 후 새로운 주입 요청은 못하게 하여야 하며,
   *        요청 시 패치는 “FAIL” 로 응답하여 Reject 한다.
   *
   *        2.1.2	HCL 주입 취소 요청
   *        본 메시지는 “HCL By App” Mode와 “HCL By Patch” Mode 에서 모두 사용된다.
   *        앱이 패치로, 자동 알고리즘에 의해 교정 볼러스 주입을 요청한 경우,
   *        또는 사용자 프로그램에 의해 식사 볼러스 주입이 자동 요청된 경우,
   *        사용자가 앱 화면에서 인지하여 과도한 량이라고 판단되면 본 메시지로 주입을 취소할 수 있다.
   *        “HCL By Patch” Mode 에서도 사용자가 앱 화면에서 주입 량을 보고,
   *        과도하다고 판단되면 본 메시지로 주입을 즉시 취소할 수 있다.
   *
   *        가.	HCL 주입 취소 요청 (앱  패치 장치): HCL_DOSE_CANCEL_REQ (0x68)
   *        송신 조건1: “HCL By App” 모드에서 기 요청된 교정 또는 식사 볼러스 주입이 과하다고 판단하여,
   *        사용자가 앱 볼러스 화면 하단의 볼러스 취소 버튼을 클릭하면 메시지가 패치로 전송된다.
   *        송신 조건2: “HCL By Patch” 모드에서 패치가 자동 주입한 볼러스 량이 앱에 표시되며,
   *        사용자가 그 량이 하다고 판단되면, 앱 볼러스 화면 하단의 볼러스 취소 버튼을 클릭하여 본 취소 메시지를 보낼 수 있다.
   *        Length 2, REQ: 0x68
   *        Mode (1 byte): HCL 통합 주입(0x00).
   *        교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
   *        	요청 시 입력한 모드 그대로 입력
   *        REQ	  MODE
   *        0x68	0x00
   *        Action: 본 메시지를 수신하면 패치는 주입 중인 볼러스 주입을 즉시 취소한 후,
   *        앱으로 “HCL_BOLUS_CANCEL_RSP (0xD8)” 메시지로  응답한다.
   *
   *        나.	HCL 볼러스 취소 응답 (패치 장치  앱): HCL_BOLUS_CANCEL_RSP (0xD8)
   *        Length 4,
   *        CMD: 0xD8,
   *        RESULT: SUCCESS 0x00, FAIL 0x01 (주입 중이 아닌 경우)
   *        주입량 (현재까지 주입된 량, 2바이트): DSOE_I, DOSE_D
   *        RSP	  MODE	RESULT	DOSE_I	DOSE_D
   *        0xD8	0x00	0x00	    0x03	0x05
   *
   *  패치 정보 조회
   *  패치 정보 조회 요청 (스마트폰 앱  패치 장치): PATCH_INFO_REQ
   *  송신 조건: 사용자가 부착된 패치 정보를 조회할 경우로,
   *  앱 메뉴 중 고급 메뉴의 S-Patch 관리 서브 메뉴에서 “패치 정보”를 클릭하면 본 메시지가 송신된다.
   *  Length 1, CMD: 0x33
   *  CMD
   *  0x33
   *  Action: 본 메시지를 수신하면 패치는 모델명, 로트번호, 제조번호,
   *  펌웨어 버전, 부팅 날자/시간 정보를 다음의 패치 정보 보고 메시지로 보고한다
   *
   *  패치 정보 보고1 (패치 장치  스마트폰 앱): PATCH_INFO_RPT1 (모델명, 로트번호 송부)
   *  송신 조건:
   *  조건 1) 패치 정보 조회 요청을 받으면 패치 정보보고 메시지 1,2 로 나누어
   *  모델명, 로트번호, 그리고 제조번호, 펌웨어 버전, 패치 시작 시간을 보고한다.
   *  조건 2) 패치가 앱과 연결된 후 현재 첫 메시지인 “시간 설정 요청 (SET_TIME_REQ)” 메시지를 수신하여
   *  날자와 시간을 설정한 후 응답 메시지를 보내고, 이후 즉시 미리 패치 정보보고 메시지1,2를 차례로 송신한다.
   *  즉 미리 패치의 모델명, 로드번호, 제조번호, 펌웨어 버전, 부팅 시간 정보를 앱으로 송신한다.
   *  Length 16, RPT1 0x93,
   *  Result (1 byte): SUCCESS 0, FAIL 1 (정보 없음)
   *  Data (14 byte):
   *  모델명 (6 byte, ascii): ex) CM100K  0x43 0x4D 0x31 0x30 0x30 0x4B
   *  로트 번호 (8 byte, ascii): ex) CM210901  0x43 0x4d 0x32 0x31 0x30 0x39 0x30 0x30
   *  RPT	RSLT	MD1	MD2	MD3	MD4	MD5	MD6	LN1	LN2	LN3	LN4	LN5
   *  0x93	0x00	0x43	0x4D	0x31	0x30	0x30	0x4B	0x43	0x4D	0x32	0x31	0x30
   *  LN6	LN7	LN8
   *  0x39	0x30	0x30
   *  Action: SUCCESS Result로 본 메시지를 수신하면 앱은 패치 정보를 표시하고,
   *  FAIL 로 수신한 경우는 각 패치 정보에 “NO Data” 로 표시한다.
   *  시간 정보 설정 시 수신한 패치 정보는 앱에서 미리 저장하였다가,
   *  사용자가 메뉴에서 요청 시 새로 요청하지 않고 기 저장된 정보로 표시한다.
   *
   *  패치 정보 보고2 (패치 장치  스마트폰 앱): PATCH_INFO_RPT2 (제조번호,펌웨어버전,부팅 시간)
   *  Length 18, RPT 0x94,
   *  Result (1 byte): SUCCESS 0, FAIL 1 (정보 없음)
   *  Data (30 byte):
   *  모델명 (6 byte, ascii): ex) CM100K  0x43 0x4D 0x31 0x30 0x30 0x4B
   *  로트 번호 (8 byte, ascii): ex) CM210901  0x43 0x4d 0x32 0x31 0x30 0x39 0x30 0x30
   *  제조 번호 (8 byte, ascii): ex) 21000001  0x32 0x31 0x30 0x30 0x30 0x30 0x30 0x31
   *  펌웨어 버전 (3 byte, ascii): ex) 2.3.0  0x32 0x33 0x30
   *  부팅 날짜/시간 (5 byte, integer): ex) 2021. 11.30, 09: 23  0x15 0x0b 0x1e, 0x09 0x17
   *  RPT	RSLT	MN1	MN2	MN3	MN4	MN5	MN6	MN7	MN8
   *  0x94	0x00	0x32	0x31	0x30	0x30	0x30	0x30	0x30	0x31
   *  VER1	VER2	VER3	YEAR	MON	DAY	HOUR	MIN
   *  0x32	0x33	0x30	0x15	0x0b	0x1e	0x09	0x17
   *  Action: SUCCESS Result로 본 메시지를 수신하면 앱은 패치 정보를 표시하고,
   *  FAIL 로 수신한 경우는 각 패치 정보에 “NO Data” 로 표시한다.
   *  시간 정보 설정 시 수신한 패치 정보는 앱에서 미리 저장하였다가,
   *  사용자가 메뉴에서 요청 시 새로 요청하지 않고 기 저장된 정보로 표시한다.
   *
   *
   *패치 폐기 메시지
   * 가.	패치 폐기 요청 (스마트폰 앱  패치 장치): PATCH_DISCARD_REQ
   * 송신 조건: 사용자가 강제로 부착된 패치를 교체하는 경우 이 메시지를 사용한다.
   * 즉 메뉴의 패치 교체 버튼을 클릭하여 “정말 패치를 교체 하시겠습니까?”
   * 팝업에서 “예”를 클릭하면 본 메시지를 앱으로 송신한다.
   * 앱에서 펌프 막힘, 인슐린 부족, 배터리 부족 등의 경고 수준 메시지를 송신한 경우도 본 메시지를 송신한다.
   * Length 1, CMD: 0x36
   *  CMD
   *  0x36
   *  Action: 패치 폐기를 수신하면 즉시 펌프 중지와 주입 프로그램도 모두 삭제하고,
   *  기 설정 중인 경고/주의/알림 타이머를 모두 삭제한 후 폐기 완료 메시지를 송신한 후 폐기를 알리는 부저를 울린다.
   *  앱으로는 아래의 패치 폐기 완료 메시지를 송신한다.
   *  참고) 패치 폐기 응답 시 패치 연결 정보는 초기화 되어 재 연결이 가능하다.
   *  (테스트 모드에서 동일 패치로 계속 연결하여 시험시 유용함)
   *  나.	패치 폐기 완료 메시지 (패치 장치  스마트폰 앱): PATCH_DISCARD_RSP
   *  Length 2, RSP: 0x95, RESULT
   *  RSP	RSLT
   *  0x96	0x00
   *
   *패치 부저 점검 메시지
   * 가.	패치 부저 점검 요청 (스마트폰 앱  패치 장치): BUZZER_CHECK_REQ
   * 송신 조건: 메뉴 중 패치 관리에 “알람 점검 서브 메뉴를 클릭하면 본 메시지를 송신한다.
   * 송신 후 앱은 스마트 폰의 부저 울림도 확인하여야 한다.
   * Length 1, CMD: 0x37
   * CMD
   * 0x37
   * Action: 본 메시지를 수신하면 패치 부저를 울린다. 앱으로는 아래의 패치 부저 울림 응답 메시지를 송신한다.
   * 나.	패치 부저 울림 완료 메시지 (패치 장치  스마트폰 앱): BUZZER_CHECK_RSP
   * Length 2, RSP: 0x97, RESULT
   * RSP	RSLT
   * 0x97	0x00
   *
   *
   *4.	경고/주의/알림 메시지
   *  4.1경고 메시지 송신 (패치 장치  스마트폰 앱): PATCH_WARNING_RPT
   *  송신 조건: 패치 부착 중, 펌프 막힘 감지된 경우, 인슐린 잔여량이 없는 경우
   *  (eg. 2U 이하, 정확한 값은 추후 약물백의 dead volume 고려), 사용 시간이 종료된 경우,
   *  그리고 배터리가 20% 미만으로 떨어진 경우에 본 메시지가 앱으로 송신된다.
   *  Length 3, RPT: 0xa1
   *  CAUSE: 펌프 막힘(토출 안됨) 0,
   *  인슐린 고갈 1,
   *  사용시간 종료 2,
   *  배터리 없음(20% 미만) 3, ,
   *  온도초과 (섭씨 5~40 도 밖 온도)  4,
   *  앱 장기 미사용 5,
   *  BLE 연결 안됨 6,
   *  주입 시작 못함 7,
   *  주입 정지 재개 오류 8
   *   (Warning CAUSE 정리)
   *   -	0x00 : 주입구 막힘
   *   -	0x01 : 인슐린 없음
   *   -	0x02 : 패치 사용 시간 만료
   *   -	0x03 : 배터리 없음 (참조: 자사는 발생 가능성 없음)
   *   -	0x04 : 부적합 온도
   *   -	0x05 : 앱 장기 미사용 (APP_STATUS_REQ 수신 후 app_use2 T/O 시)
   *   -	0x06 : BLE 연결 안됨 (patch_connect T/O 시, 참조: 페치 자체 원인값 -> 앱 전송 못함)
   *   -	0x07 : 기저주입 시작못함 (basal_monitor T/O 시)
   *   -	0x08 : 경고 미사용 (ALERT CAUSE: 주입임시중지 재개 오류)
   *   -	0x09 : 경고는 미사용 (NOTI CAUSE: 패치 점검 알림)
   *   -	0x0A : 연장된 패치 사용 시간 만료
   *   -	0x0C : 펌프 오류(주입구 막힘 포함) PUMP_ERROR
   *
   * VALUE: 펌프 오류  제외한 나머지의 잔여 값(인슐린 잔여량, 시간, 배터리 레벨)
   *  ㈜ 경고 메시지 송신 후 패치는 경고 부저 울리고, 1분 뒤 경고 메시지 1회 재 송부함.
   *  RPT	CAUSE	VALUE
   *  0xa1	0x01	0x0a
   *  Action: 본 메시지를 수신한 앱은 해당 원인 (Cause)의 경고 팝업과 함께 스마트 폰에서도 경고 부저를 울린다.
   *  그리고 패치 교체 메뉴를 띄워 패치 폐기 절차를 진행한다.
   *
   *  4.2주의 메시지 송신 (패치 장치  스마트폰 앱): PATCH_ALERT_RPT
   *  송신조건:
   *  인슐린 부족 임박(e.g 3U~10U), 사용 시간 종료 임박(1 hr), 배터리 부족 (10%) 등의 주의 임계치에 도달하면 본 메시지를 송신한다.
   *  Length 3, RPT: 0xa2
   *  CAUSE: 인슐린 부족 임박 1, 사용 시간 종료 임박 2, 배터리 부족 (10% 이하) 3, 온도 이상 4
   *  앱 장기 미사용 5, BLE 연결 안됨 6, 주입 시작 못함 7, 주입 정지 재개 오류 8,
   *  연장된 사용 시간 주의 임계치 도달 10
   *
   *  (Alert CAUSE 정리)
   *   -	0x01 : 인슐린 잔여량 적음
   *   -	0x02 : 패치 사용기간 주의
   *   -	0x03 : 배터리 주의 임계치 도달
   *   -	0x04 : 부적합 온도 접근 (참조: 현재 미사용)
   *   -	0x05 : 앱 장기 미사용 (APP_STATUS_REQ 수신 후 app_use1 T/O 시)
   *   -	0x06 : BLE 연결 안됨 (patch_connect T/O 시, 참조: 페치 자체 원인값 -> 앱 전송 못함)
   *   -	0x07 : 기저주입 시작못함 (basal_monitor T/O 시)
   *   -	0x08 : 주입임시중지 재개 오류((사용자 설정 재개 시간infusion resume T/O) )
   *   -	0x09 : 주의는 미사용 (NOTI CAUSE: 패치 점검 알림)
   *   -	0x0A : 연장된 패치 사용 시간 주의
   *   . VALUE: 임계치 도달 값  Type 1) 인슐린 잔여량 (ex. 10U),
   *   Type 2) 배터리 잔량 (30%),
   *   Type 3) 패치 폐기 시간 임박 (1 hr)
   *   Type 4) 연장된 패치 폐기 시간 임박(1 hr)
   *   RPT	CAUSE	VALUE
   *   0xa2	0x01	0x14
   *   . Action: 본 메시지를 수신한 앱은 각 CAUSE 별 수신 임계치 값을 가지고 주의 팝업을 발생시킨다. 주의 팝업을 본 사용자는 곧 패치 교체 시기가 도래함을 알고 미리 교체를 준비를 대비한다.
   *
   *   4.3알림 메시지 송신 (패치 장치  스마트폰 앱): PATCH_NOTICE_RPT
   *   . 송신 조건: 인슐린 잔여 임계치(10U~50U), 사용 시간 임박 임계치(4 hr), 배터리 적음(20%) 등의 알림 임계치에 도달하면 본 메시지를 송신한다. 추가로 시간동기화 Message를 보낸다.
   *   . Length 3, RPT: 0xa3
   *   . CAUSE: 사용 시간 종료 임계치 도래 1, 배터리 적음 (30% 이하) 2, 앱시간 동기화(10분주기) 1,
   *
   *   ((Notice CAUSE 정리)
   *   -	0x01 : 인슐린 잔여량 임계치 도달
   *   -	0x02 : 패치 사용시간 임계치 도달
   *   -	0x03 : 배터리 알림 임계치 도달
   *   -
   *   -	0x09 : 패치 점검 알림 (패치 부착 후 90분, inspection timer T/O)
   *   -	0x0A:: 앱 시간 동기화 알림
   *   -	0x0B: 볼러스 주입 후 혈당 측정
   *   -
   *   . VALUE1: 임계치 도달 값  Cause 1) 인슐린 잔여 임계치 (10U ~ 50U)
   *   Cause 2) 사용시간 임계치 (ex. 4 hr),
   *   Cause 3) 배터리 잔여량 (40%)
   *   . VALUE2: COUNT/TIMER_ID  Cause 0x0A) 동기화 메시지 Sequence Number (COUNT)
   *    Cause 0x0B) 혈당측정 알림 타이머 구분자 (TIMER_ID)
   *   RPT	CAUSE	VALUE
   *   0xa3	0x02	0x04
   *   (주1) Cause 0x0A (앱 시간 동가화 알림): 패치는 앱과 연결 후 시간 동기화 메시지 “SET_TIME_REQ” 수신 시부터 10분 주기로 원인 값 “0x0A”와 Count 값을 채워 송신하여야 한다.
   *   이 때의 VALUE 값은 1부터 하나씩 증가되어 채워 보낸다.
   *   RPT	CAUSE	VALUE
   *   0xa3	0x0A	COUNT
   *   (주2) Cause 0x0B (볼러스 주입 후 혈당 측정 알림): 혈당 측정 알림 요청(GLUCOSE_TIMER_REQ) 메시지에 대한 패치에서의 측정 알림 NOTICE 메시지로 아래의 값을 채워 송신하여야 한다.
   *   이 때의 VALUE 값은 “GLUCOSE_MEASURE_REQ” 시 보낸 타이머 구분자(TIMER_ID)이다.
   *   RPT	CAUSE	VALUE
   *   0xa3	0x0B	TIMER_ID
   *   . Action: 본 메시지를 수신한 앱은 각 CAUSE 별 수신 알림 임계치 값을 가지고 알림 팝업을 발생시킨다.
   *   Cause 가 “볼러스 주입 후 혈당 측정(0x0B)” 이면 앱은 혈당 측정 안내 팝업을 띄워 알려준다.
   *
   *
   */

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
    Future<void> sendSetTimeReservoirRequest(
      int ReservoirAmount,
      int HclMode,
      BluetoothCharacteristic? characteristic,
    ) async {
      //int SET_TIME_REQ = 0x11;
      //int SET_TIME_RSP = 0x71;  ///< response for the SET_TIME_REQ sent from connected Pump device
      //put command 1 byte
      var waitCallback = false;
      final sendBytes = <int>[SET_TIME_REQ];
      // get current time
      final dateTimeString =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
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
      final data2Per10to1 = (ReservoirAmount % 100).toInt();
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
          await _PumpTxCharacteristic!.write(sendBytes);
          waitCallback = true;
        } else {
          log('Failed to send set time request !!');
          TXErrorMsg =
              'Requesting time date setting is not available at this time. Retry it?';
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
              "SET_TIME_RSP Response not received!!; let's try to "
              "send SET_TIME_REQ again!! ",
            );
            SET_TIME_RSP_retryCnt += 1;
            if (SET_TIME_RSP_retryCnt < MAX_RETRY) {
              //let's show dialog which provide an option that user select
              //to try it again
              // or retry it automatically
              sendSetTimeReservoirRequest(
                ReservoirAmount,
                HclMode,
                characteristic,
              );
            } else {
              log(
                'SET_TIME_RSP Response not received : '
                'retry failed!!; timeout!! ',
              );
              SET_TIME_RSP_retryCnt = 0;

              ///< clear
              SET_TIME_RSP_responseReceived = false;

              ///< clear
              TXErrorMsg = 'Patch does not responding for setting time date at '
                  'this time. Retry it?';
              showTXErrorMsgDlg = true;
            }
          } else {
            log('SET_TIME_RSP Response received!! ');
            SET_TIME_RSP_retryCnt = 0;

            ///< clear
            SET_TIME_RSP_responseReceived = false;

            ///< clear

            //kai_20230422  let's send pump patch information
            //request PATCH_INFO_REQ(0x33) to the pump here
            // sendPumpPatchInfoRequest(null);
          }
        });
      }
    }

    /*
   * @brief send pump patch info request to the pump
   */
    Future<void> sendPumpPatchInfoRequest(
      BluetoothCharacteristic? characteristic,
    ) async {
      final sendBytes = <int>[PATCH_INFO_REQ];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send PumpInfoRequest !!');
          TXErrorMsg =
              'Requesting patch info. is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @breif set max bolus injection threshold
   * @param[in] value : input range: 0.5 ~ 25 U
   * @param[in] type  ; 0x01 Max injection amount
   */
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
      final sendBytes = <int>[INFUSION_THRESHOLD_REQ];
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
            await _PumpTxCharacteristic!.write(sendBytes);
            waitCallback = true;
          } else {
            log('Failed to send set max bolus injection amount request !!');
            TXErrorMsg =
                'Requesting max bolus injection amount setting is not available at this time. Retry it?';
            showTXErrorMsgDlg = true;
          }
        }

        // set timer with 5 secs here to check we got the response sent from pmp
        if (waitCallback == true) {
          Future.delayed(Duration(seconds: SET_TIME_RSP_TIMEOUT), () {
            if (!INFUSION_THRESHOLD_RSP_responseReceived) {
              // 응답이 오지 않았을 경우 처리
              log(
                "INFUSION_THRESHOLD_RSP Response not received!!; let's try to send INFUSION_THRESHOLD_REQ again!! ",
              );
              INFUSION_THRESHOLD_RSP_retryCnt += 1;
              if (INFUSION_THRESHOLD_RSP_retryCnt < MAX_RETRY) {
                sendSetMaxBolusThreshold(value, type, characteristic);
              } else {
                log(
                  'INFUSION_THRESHOLD_RSP Response not received : retry failed!!; timeout!! ',
                );
                INFUSION_THRESHOLD_RSP_retryCnt = 0;

                ///< clear
                INFUSION_THRESHOLD_RSP_responseReceived = false;

                ///< clear
              }
            } else {
              log('INFUSION_THRESHOLD_RSP Response received!! ');
              INFUSION_THRESHOLD_RSP_retryCnt = 0;

              ///< clear
              INFUSION_THRESHOLD_RSP_responseReceived = false;

              ///< clear
            }
          });
        }
      } on FormatException catch (e) {
        log(
          'Error: Invalid float format or cannot convert string to float. Details: $e',
        );
      } catch (e) {
        log('Error: An unexpected error occurred. Details: $e');
      }
    }

    /*
   * @brief send safety check request to pump
   */
    Future<void> sendSafetyCheckRequest(
      BluetoothCharacteristic? characteristic,
    ) async {
      //안전점검 요청 (스마트폰 앱  패치 장치): SAFETY_CHECK_REQ
      // 송신 조건: 새 패치 부착과정으로 앱에서 패치와 블루투스 연결 후,
      // 안내에 따라 패치 부착한 후에 앱 화면 하단의 안점점검 버튼을 누르면 본 메시지가 송신된다.
      // Length 1, CMD: 0x12
      // CMD
      // 0x12
      // Action: 안점점검 요청을 받으면 패치 장치는 인슐린을 주사바늘 입구까지 이동시키는 프라이밍(Priming) 작업을 시작한다.
      // 프라이밍 전에 안전 점검 과정으로 온도와 압력을 축정하여 사용 범위를 벗어 나면 안전 점검 실패로 안전 점검 완료 메시지를 송신한다.
      // 프라이밍 시는 압력 센서 기본 값 설정을 위해 펌프 구동 시 각 펄스 볼륨 별로 압력을 측정하여 초기 값을 저장한다.
      final sendBytes = <int>[SAFETY_CHECK_REQ];
      // 최종 송신할 바이트 배열을 characteristic.write 메서드를 사용하여 전송
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send safety check request !!');
          TXErrorMsg =
              'Requesting safety check is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send cannular status request to the pump
   */
    Future<void> sendCannularStatusRequest(
      BluetoothCharacteristic characteristic,
    ) async {
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
      final sendBytes = <int>[CANNULAR_STATUS_REQ, 0x00];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send cannular status request !!');
          TXErrorMsg =
              'Requesting cannular status is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send cannular insert ack to the pump
   */
    Future<void> sendCannularInsertAck(
      BluetoothCharacteristic? characteristic,
    ) async {
      // 케뉼라 삽입 보고 수신 확인 (스마트폰 앱  패치 장치): CANNULAR_INSERT_ACK (0x19)
      //  . Length 1, RSP: 0x19
      // . Result (1 byte): SUCCESS 0, FAIL 1
      // . 송신 조건: 앱에서 안점 점검 절차 후 기저 주입 시도 전 상태에서
      // 수신한 “케뉼라 삽입 보고” 메시지 (CANNULAR_INSERT_RPT) 에 대헤 확인 메시지로 본 메시지를 송신한다.
      // ACK	RSLT
      // 0x19	0x00
      //
      // . Action: 패치가 5초 이내 본 확인 메시지를 수신하지 못한 경우,
      // 패치 장치는 캐뉼라 삽입 보고 메시지 “CANNULAR_INSERT_RPT”를 재 송신한다

      final sendBytes = <int>[CANNULAR_INSERT_ACK];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send cannular insert ack request !!');
          TXErrorMsg =
              'Sending cannular insert ack is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send Bolus/Dose delivery value to the pump
   * @param[in] dataString : bolus dose value, example: 5.25U
   * @param[in] mode : total dose injection(0x00), (Correction Bolus) 0x01, (Meal bolus) 0x02
   */
    Future<void> sendSetDoseValue(
      String value,
      int mode,
      BluetoothCharacteristic? characteristic,
    ) async {
      //. 송신조건: “HCLBy APP” 모드에서 기저와 볼러스 주입이 통합된 자동 모드에서 주입할 인슐린 총량을 주입하기위해 사용된다.
      // . 송신 조건2: “HCL By App” 모드에서 교정 볼러스 주입 제어 알고리즘에 의한 교정 볼러스 계산기 주입 값을
      // 가감한 최종 교정 볼러스 주입량이 있으면 본 메시지를 패치로 전송한다.
      // . Length 4, REQ: 0x67
      // . Mode (1 byte): HCL 통합 주입(0x00).
      //                      교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
      // .  주입량 (2 byte): DOSE_I (정수), DOSE_D (소수점 X 100)
      // Ex) 5.25 U  0x05 0x19
      //   요청한 주입량이 사용자 설정한 최대 볼러스 량보다 크면 실패 (Cause 0x04 DATA_OVER_FLOW) 로 응답함 (HCL_BOLUS_RSP)
      // REQ	MODE	DOSE_I	DOSE_D
      // 0x67	0x00	0x05	0x19

      // 문자열을 바이트 배열로 변환
      // List<int> dataBytes = utf8.encode(dataString);
      // 0x67 뒤에 변환한 데이터 값을 추가하여 최종 송신할 바이트 배열 생성
      final sendBytes = <int>[HCL_DOSE_REQ];
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

      // 최종 송신할 바이트 배열을 characteristic.write 메서드를 사용하여 전송
      if (characteristic != null) {
        await characteristic.write(sendBytes);
        /////kai_20230427 update insulin delivery amount here
        InsulinDelivery = '${value}U';
        //notifyListeners();
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
          /////kai_20230427 update insulin delivery amount here
          InsulinDelivery = '${value}U';
          //notifyListeners();
        } else {
          log('Failed to send dose request !!');
          TXErrorMsg =
              'Sending dose request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief cansel dose injection
   */
    Future<void> cancelSetDoseValue(
      int mode,
      BluetoothCharacteristic? characteristic,
    ) async {
      // . Mode (1 byte): HCL 통합 주입(0x00).
      //   교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
      //
      // 	요청 시 입력한 모드 그대로 입력
      //
      // REQ	MODE
      // 0x68	0x00
      final sendBytes = <int>[HCL_DOSE_CANCEL_REQ, mode];
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send dose cancel request !!');
          TXErrorMsg =
              'Sending dose cancel request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send discard patch request
   */
    Future<void> sendDiscardPatch(
      BluetoothCharacteristic? characteristic,
    ) async {
      final sendBytes = <int>[PATCH_DISCARD_REQ];

      ///< 0x36
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send discard patch request !!');
          TXErrorMsg =
              'Sending discard patch request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send reset patch request
   */
    Future<void> sendResetPatch(
      int mode,
      BluetoothCharacteristic? characteristic,
    ) async {
      final sendBytes = <int>[PATCH_RESET_REQ, mode];

      ///< 0x3F
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send reset patch request !!');
          TXErrorMsg =
              'Sending reset patch request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send buzzer check request
   */
    Future<void> sendBuzzerCheck(
      BluetoothCharacteristic? characteristic,
    ) async {
      final sendBytes = <int>[BUZZER_CHECK_REQ];

      ///< 0x37
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send buzzer check request !!');
          TXErrorMsg =
              'Sending buzzer check request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send buzzer change request
   */
    Future<void> sendBuzzerChangeRequest(
      bool BuzzerOnOff,
      BluetoothCharacteristic? characteristic,
    ) async {
      // 부저 사용 설정 변경 요청 (스마트폰 앱  패치 장치)
      // 송신 조건: 설정 메뉴의 부저 사용 중지/사용 설정을 사용자가 변경하면 본 메시지가 송신된다.
      // . Length 2, CMD: 0x18
      // . USE_FLAG: 부저 울림 여부 (0x01 부저 울림, 0x00 부저 사용 안함)
      // * 기본 값은 미 사용임
      // CMD	USE_FLAG
      // 0x18	0x01
      // . Action: 수신한 패치는 buzzer-use_flag 가 1이면 주의와 알림 발생 시 부저를 사용하고, 0 이면 경고 발생 시 부저만 사용한다.
      final sendBytes = <int>[BUZZER_CHANGE_REQ];

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
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send buzzer change request !!');
          TXErrorMsg =
              'Sending buzzer change request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send application status change indication to the patch
   *        in case of changing the status of mobile app from forground to bacground vice versa.
   */
    Future<void> sendAppStatusChangeIndication(
      int status,
      int StopTimerValue,
      BluetoothCharacteristic? characteristic,
    ) async {
      // Length 3, CMD: 0x39
      // . Status: 0x00 (foreground  background), 0x01 (Background  foreground)
      // . Time: 사용자가 설정한 주입 중단 결정 타이머 (1시간 ~ 24 시간, 0이면 사용 안함 의미임)
      // ㈜ 타임아웃 시 펌프 중단 및 경고 메시지 전송)

      final sendBytes = <int>[APP_STATUS_IND];

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
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send app status change indication !!');
          TXErrorMsg =
              'Sending app status change indication is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send Mac address request
   */
    Future<void> sendMacAddrRequest(
      BluetoothCharacteristic? characteristic,
    ) async {
      final sendBytes = <int>[MAC_ADDR_REQ];

      ///< 0x3b
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send Mac Address request !!');
          TXErrorMsg =
              'Sending Mac Address request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief send current Infusion status request
   * @param[in] type 0x00: current infusion status, 0x01: insulin remain amount
   */
    Future<void> sendInfusionInfoRequest(
      int type,
      BluetoothCharacteristic? characteristic,
    ) async {
      if (type < 0x00 || type > 0x03) {
        return;
      }

      final sendBytes = <int>[INFUSION_INFO_REQ, type];

      ///< 0x31
      if (characteristic != null) {
        await characteristic.write(sendBytes);
      } else {
        if (_PumpTxCharacteristic != null) {
          await _PumpTxCharacteristic!.write(sendBytes);
        } else {
          log('Failed to send Infusion Info Request !!');
          TXErrorMsg =
              'Sending Infusion Info Request is not available at this time. Retry it?';
          showTXErrorMsgDlg = true;
        }
      }
    }

    /*
   * @brief register cgm battery level characteristic value listener
   */
    void registerPumpBatLvlValueListener(Function(List<int>) listener) {
      if (_PumpRXBatLvlCharacteristic != null) {
        _pumpBatValueSubscription =
            _PumpRXBatLvlCharacteristic!.value.listen((value) {
          listener(value);
        });
      } else {
        debugPrint(
          'registerCgmBatLvlValueListener():_cgmRXBatLvlCharacteristic is NULL',
        );
      }
    }

    /*
   * @brief unregister cgm battery level characteristic value listener
   */
    void unregisterPumpBatLvlValueListener() {
      debugPrint('unregisterPumpBatLvlValueListener():is called');
      if (_pumpBatValueSubscription != null) {
        _pumpBatValueSubscription!.cancel();
        _pumpBatValueSubscription = null;
      }
    }

    /*
   * @brief Pump connectionstatus callback function example
   */
    void pumpConnectionStatus(BluetoothDeviceState state) {
      if (mPumpConnectionState == state) {
        // if connection status is same then ignore
        return;
      }

      switch (state) {
        case BluetoothDeviceState.connected:
          mPumpConnectionState = state;
          break;

        case BluetoothDeviceState.connecting:
          mPumpConnectionState = state;
          break;

        case BluetoothDeviceState.disconnected:
          mPumpConnectionState = state;
          break;

        case BluetoothDeviceState.disconnecting:
          mPumpConnectionState = state;
          break;
      }
    }

    /*
   * @brief register Pump connection status listener
   */
    void registerPumpStateCallback(
      void Function(BluetoothDeviceState) callback,
    ) {
      if (_pumpDevice == null) {
        debugPrint('registerPumpStateCallback():_pumpDevice is NULL');
      } else {
        debugPrint('registerPumpStateCallback():is called');
        mPumpconnectionSubscription = _pumpDevice!.state.listen(callback);
      }
    }

    /*
   * @brief unregister Pump connection status listener
   */
    void unregisterPumpStateCallback() {
      debugPrint('unregisterPumpStateCallback():is called');
      mPumpconnectionSubscription?.cancel();
      mPumpconnectionSubscription = null;
    }

    /*
   * @brief Notify Pump battery level characteristic
   */
    Future<void> pumpBatteryNotify() async {
      if (mPumpflutterBlue.state == BluetoothState.on) {
        if (_PumpRXBatLvlCharacteristic != null) {
          if (!_PumpRXBatLvlCharacteristic!.isNotifying) {
            _pumpBatValueSubscription ??=
                _PumpRXBatLvlCharacteristic!.value.listen((value) {
              // _handlePumpBatLevelValue(value);
            });
            await _PumpRXBatLvlCharacteristic!.setNotifyValue(true);
            //let's send command "BAT:" to the connected device here
            sendStringDataToCgmDevice('BAT:');
          } else {
            if (_pumpBatValueSubscription != null) {
              await _pumpBatValueSubscription!.cancel();
              _pumpBatValueSubscription = null;
            }
            await _PumpRXBatLvlCharacteristic!.setNotifyValue(false);
          }
        }
      }
    }
  }
}

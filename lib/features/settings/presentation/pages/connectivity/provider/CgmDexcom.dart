import 'dart:convert';
import 'dart:developer';
//kai_20240127  import 'dart:ffi';
import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/AuthChallengeRxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/AuthChallengeTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/AuthRequestTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/AuthStatusRxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BatteryInfoRxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BatteryInfoTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BondRequestTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/DisconnectTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/Extensions.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/GlucoseRxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/GlucoseTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/KeepAliveTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/SensorRxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/SensorTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/Transmitter.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/TransmitterData.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/TransmitterStatus.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/VersionRequestRxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/VersionRequestTxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Cgm.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Utilities.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

class CgmDexcom extends Cgm {
  //creator   call Cgm creator by using super()
  CgmDexcom() : super() {
    log('${TAG}kai:Create CgmDexcom():init()');
    init();
  }
  final String TAG = 'CgmDexcom:';

  static bool getBatteryStatusNow = false;
  static int lastTransmitterTimestamp = 0;
  static bool getVersionDetails = true; // try to load firmware version details
  static bool getBatteryDetails = true; // try to load battery info details
  static late Transmitter defaultTransmitter;

  AuthStatusRxMessage? authStatus = null;
  AuthRequestTxMessage? authRequest = null;

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

  void init() {}

  /*
   * @brief get Transmitter details
   */
  void getTransmitterDetails() {
    log('${TAG}Transmitter: ${CspPreference.getString('dex_txid')}');
    defaultTransmitter = Transmitter(CspPreference.getString('dex_txid'));
    final previousBondedState = isBonded;
    isBondedOrBonding = false;
    isBonded = false;
    static_is_bonded = false;
    if (mCGMflutterBlue == null) {
      log('${TAG}No bluetooth adapter');
      return;
    }
    if (cgmConnectedDevice != null && cgmConnectedDevice!.name.isNotEmpty) {
      final transmitterIdLastTwo = Extensions.lastTwoCharactersOfString(
        defaultTransmitter.transmitterId,
      );
      final deviceNameLastTwo = Extensions.lastTwoCharactersOfString(
        cgmConnectedDevice!.name.toLowerCase().toString(),
      );

      if (transmitterIdLastTwo == deviceNameLastTwo) {
        isBondedOrBonding = true;
        isBonded = true;
        static_is_bonded = true;
        if (!previousBondedState) {
          log('${TAG}Device is now detected as bonded!');
        }
        // TODO should we break here for performance?
      } else {
        isIntialScan = true;
      }
    }

    if (previousBondedState && !isBonded) {
      log('${TAG}Device is no longer detected as bonded!');
    }
    log(
      '${TAG}getTransmitterDetails() result: Bonded? $isBondedOrBonding${isBonded ? ' localed bonded' : ' not locally bonded'}',
    );
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
      if (CgmRxCharacteristic != null) {
        if (CgmRxCharacteristic!.properties.notify &&
            !CgmRxCharacteristic!.isNotifying) {
          await CgmRxCharacteristic!.setNotifyValue(true);
          if (useG5NewMethod()) {
            //new style
            final glucoseTxMessage = GlucoseTxMessage();
            CgmRxCharacteristic!.write(glucoseTxMessage.byteSequence);
          } else {
            // old style
            final sensorTx = SensorTxMessage();
            CgmRxCharacteristic!.write(sensorTx.byteSequence);
          }
        }
      }
    } catch (e) {
      log('${TAG}Error getSensorData =  $e');
    }
  }

  /*
   * @brief send authentication message to the cgm device
   */
  Future<void> sendAuthCmdToCgmDevice(List<int> data) async {
    if (cgmRXTXAuthenCharacteristic != null) {
      if (cgmRXTXAuthenCharacteristic!.properties.notify &&
          !cgmRXTXAuthenCharacteristic!.isNotifying) {
        await cgmRXTXAuthenCharacteristic!.setNotifyValue(true);
      }

      if (cgmRXTXAuthenCharacteristic!.properties.write ||
          cgmRXTXAuthenCharacteristic!.properties.writeWithoutResponse) {
        await cgmRXTXAuthenCharacteristic!.write(data);
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
    if (cgmRXTXAuthenCharacteristic != null) {
      final authRequest = AuthRequestTxMessage(getTokenSize());
      if (cgmRXTXAuthenCharacteristic!.properties.notify &&
          !cgmRXTXAuthenCharacteristic!.isNotifying) {
        await cgmRXTXAuthenCharacteristic!.setNotifyValue(true);
        await cgmRXTXAuthenCharacteristic!.write(authRequest.byteSequence);
      }
    }
  }

  /*
   * @brief crypt key for dexcom G5, G6 transmitter auth handshaking
   */
  List<int>? cryptKey() {
    if (defaultTransmitter.transmitterId.length != 6) {
      log(
        '${TAG}cryptKey: Wrong transmitter id length!: ${defaultTransmitter.transmitterId.length}',
      );
      return null;
    }

    try {
      final keyString =
          '00${defaultTransmitter.transmitterId}00${defaultTransmitter.transmitterId}';
      return utf8.encode(keyString);
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  /*
   * @brief calculate hash for auth between dexcom G5, G6 and application
   */
  Uint8List? calculateHash(Uint8List? data) {
    if (data == null || data.length != 8) {
      log('${TAG}Decrypt Data length should be exactly 8.');
      return null;
    }

    final list = cryptKey();
    final key = Uint8List.fromList(list!);
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
    log('${TAG}performBondWrite() started');

    if (cgmRXTXAuthenCharacteristic == null) {
      log('${TAG}mGatt was null when trying to write bondRequest');
      return;
    }

    final bondRequest = BondRequestTxMessage();
    cgmRXTXAuthenCharacteristic!.write(bondRequest.byteSequence);

    if (delayOnBond) {
      log('${TAG}Delaying before bond');
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      log('${TAG}Delay finished');
    }
/*
    final deviceAddress = _cgmAuthCharacteristic!.deviceId;
    final device = BluetoothDevice(deviceAddress);

        final device = BluetoothDevice.fromAddress(deviceAddress);

   log(TAG + 'Connecting to the device...');
      if(USE_AUTO_CONNECTION == true) {
        await device.connect();
      }
      else
      {
        await device.connect(autoConnect: false);
      }
   log(TAG + 'Connected to the device');

   log(TAG + 'Requesting pairing...');
    final pairingRequest = BluetoothPairingRequest(device: device);
    final pairingResult = await pairingRequest.pair();

    if (pairingResult) {
      debugPrint(TAG + 'Pairing successful');
      isBondedOrBonding = true;
    } else {
      debugPrint(TAG + 'Pairing failed');
      isBondedOrBonding = false;
    }

 */
    log('${TAG}performBondWrite() finished');
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
      log('${TAG}Store: VersionRX dbg: ${data.buffer}');
    }

    if (transmitterId.length != 6) {
      return false;
    }
    if (data.length < 10) {
      return false;
    }
    CspPreference.setBytes(CspPreference.g5_firmware_ + transmitterId, data);

    ///<kai_20231011 update firmware version here
    /// if use utf8 encoding case
    cgmfw = utf8.decode(data);
    //cgmfw = '${data.buffer}';
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
  bool haveFirmwareDetails() {
    return defaultTransmitter.transmitterId.length == 6 &&
        getStoredFirmwareBytes(defaultTransmitter.transmitterId).length >= 10;
  }

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
    log('${TAG}Store: BatteryRX dbg: $data');
    if (transmitterId.length != 6) return false;
    if (data.length < 10) return false;
    updateBatteryWarningLevel();
    final batteryInfoRxMessage = BatteryInfoRxMessage(data);
    log('${TAG}Saving battery data: $batteryInfoRxMessage');
    //PersistentStore.setBytes(G5_BATTERY_MARKER + transmitterId, data);
    //PersistentStore.setLong(G5_BATTERY_FROM_MARKER + transmitterId, JoH.tsl());

    // TODO logic also needs to handle battery replacements of same transmitter id
    final oldLevel =
        CspPreference.getStringToInt(G5_BATTERY_LEVEL_MARKER + transmitterId);

    ///<kai_20231011 update battery level here
    cgmBattery = '${batteryInfoRxMessage.voltagea}';

    if ((batteryInfoRxMessage.voltagea < oldLevel) || (oldLevel == 0)) {
      if (batteryInfoRxMessage.voltagea < LOW_BATTERY_WARNING_LEVEL) {
        /*
        if (JoH.pratelimit("g5-low-battery-warning", 40000)) {
          final loud = !PowerStateReceiver.is_power_connected();
          JoH.showNotification(
            "G5 Battery Low",
            "G5 Transmitter battery has dropped to: 
            ${batteryInfoRxMessage.voltagea} it may fail soon",
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
      }
      CspPreference.setLong(
        G5_BATTERY_LEVEL_MARKER + transmitterId,
        batteryInfoRxMessage.voltagea,
      );
    }

    return true;
  }

  /*
   * @brief get dexcom g5, g6 current battery level
   */
  bool haveCurrentBatteryStatus() {
    return defaultTransmitter.transmitterId.length == 6 &&
        (int.parse(defaultTransmitter.transmitterId) < BATTERY_READ_PERIOD_MS);
  }

  /*
   * @brief disconnect cgm device and init listener and  variables
   */
  Future<void> disconnectCgmDevices() async {
    log('${TAG}disconnectCgmDevices():is called');
    if (cgmValueSubscription != null) {
      await cgmValueSubscription!.cancel();
      cgmValueSubscription = null;
    }

    if (cgmAuthenValueSubscription != null) {
      await cgmAuthenValueSubscription!.cancel();
      cgmAuthenValueSubscription = null;
    }

    await cgmConnectedDevice!.disconnect();
    cgmConnectedDevice = null;

    ///< kai_20230304 clear here
    notifyListeners();
  }

  /*
   * @brief Sends the disconnect tx message to our bt device.
   */
  // Sends the disconnect tx message to our bt device.
  Future<void> doDisconnectMessage() async {
    log('${TAG}doDisconnectMessage() start');
    if (CgmRxCharacteristic != null && CgmRxCharacteristic!.properties.notify) {
      await CgmRxCharacteristic!.setNotifyValue(false);

      if (CgmRxCharacteristic!.properties.write ||
          CgmRxCharacteristic!.properties.writeWithoutResponse) {
        final disconnectTx = DisconnectTxMessage();
        CgmRxCharacteristic!.write(disconnectTx.byteSequence);
      }
    }
    disconnectCgmDevices();
    log('${TAG}doDisconnectMessage() finished');
  }

  /*
   * @brief Sends the version request message to our bt device.
   */
  Future<void> doVersionRequestMessage() async {
    log('${TAG}doVersionRequestMessage() start');

    if (CgmRxCharacteristic != null &&
        CgmRxCharacteristic!.properties.notify &&
        !CgmRxCharacteristic!.isNotifying) {
      await CgmRxCharacteristic!.setNotifyValue(true);
      if (CgmRxCharacteristic!.properties.write ||
          CgmRxCharacteristic!.properties.writeWithoutResponse) {
        final versionTx = VersionRequestTxMessage();
        CgmRxCharacteristic!.write(versionTx.byteSequence);
      }
    }
    log('${TAG}doVersionRequestMessage() finished');
  }

  /*
   * @brief Sends the battery info request message to our bt device.
   */
  Future<void> doBatteryInfoRequestMessage() async {
    log('${TAG}doBatteryInfoMessage() start');

    if (CgmRxCharacteristic != null &&
        CgmRxCharacteristic!.properties.notify &&
        !CgmRxCharacteristic!.isNotifying) {
      await CgmRxCharacteristic!.setNotifyValue(true);
      if (CgmRxCharacteristic!.properties.write ||
          CgmRxCharacteristic!.properties.writeWithoutResponse) {
        final batInfoTxMsg = BatteryInfoTxMessage();
        CgmRxCharacteristic!.write(batInfoTxMsg.byteSequence);
      }
    }
    log('${TAG}doBatteryInfoMessage() finished');
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
    final transmitterData = TransmitterData.create1(
      rawData,
      filteredData,
      sensorBatteryLevel,
      captureTime,
    );
    if (transmitterData == null) {
      log('${TAG}TransmitterData.create failed: Duplicate packet');
      return;
    } else {
      timeInMillisecondsOfLastSuccessfulSensorRead = captureTime as int?;
    }
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
    //BgReading.create(transmitterData.raw_data, transmitterData.filtered_data, this, transmitterData.timestamp);
    log('${TAG}Dex raw_data ${transmitterData.raw_data}'); //KS
    log(
      '${TAG}Dex filtered_data ${transmitterData.filtered_data}',
    ); //KS
    log(
      '${TAG}Dex sensor_battery_level ${transmitterData.sensor_battery_level}',
    ); //KS
    log('${TAG}Dex timestamp ${transmitterData.timestamp}'); //KS

    static_last_timestamp =
        transmitterData.timestamp == null ? 0 : transmitterData.timestamp!;

    //kai_20231011 update battery level here
    cgmBattery = '${transmitterData.sensor_battery_level}';

    //kai_20230531 let's call response callback here to notify
    // the received bloodglucose data to the registered widget
    final glucoseValue = transmitterData.raw_data.toString();
    final timeDate = transmitterData.timestamp;
    setLastTimeBGReceived(timeDate!);
    setBloodGlucoseValue(double.parse(glucoseValue).toDouble().floor());
    // ...
    notifyListeners();
    setResponseMessage(
      RSPType.UPDATE_SCREEN,
      'New Blood Glucose',
      'NEW_BLOOD_GLUCOSE',
    );
  }

  /*
   * @brief process Rx data from dexcom G5, G6
   */
  void processRxCharacteristic(List<int> value) {
    // handle CGM auth processing
    String data;
    // Try to decode as UTF-8
    try {
      data = utf8.decode(value);
    } on FormatException {
      // If UTF-8 decoding fails, try ASCII decoding
      data = ascii.decode(value.where((byte) => byte <= 0x7f).toList());
    }

    final LENGTH = value.length;
    final hexString = value.map((byte) => toHexString(byte)).join(' ');
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
    final firstByte = buffer[0];
    // List<int> bytes = data.codeUnits;

    log(
      '${TAG}processRxCharacteristic() is called : code = $firstByte',
    );
    log('${TAG}Received opcode = $firstByte');
    log('${TAG}value = $data');

    if (firstByte == 0x2f) {
      final bytes = Uint8List.fromList(utf8.encode(data));
      final sensorRx = SensorRxMessage(bytes);

      // sensorData buffer init as zero here
      final sensorData = ByteData.view(bytes.buffer);
      sensorData.buffer.asUint8List().setAll(0, buffer);

      var sensorBatteryLevel = 0;
      if (sensorRx.status == TransmitterStatus.BRICKED) {
        //TODO Handle this in UI/Notification
        sensorBatteryLevel = 206; //will give message "EMPTY"
      } else if (sensorRx.status == TransmitterStatus.LOW) {
        sensorBatteryLevel = 209; //will give message "LOW"
      } else {
        sensorBatteryLevel = 216; //no message, just system status "OK"
      }

      log(
        '${TAG}Got data OK : ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );

      log(
        '${TAG}SUCCESS!! unfiltered: ${sensorRx.unfiltered} timestamp: ${sensorRx.timestamp} ${sensorRx.timestamp / 86400} days',
      );
      if (sensorRx.unfiltered == 0) {
        log(
          "${TAG}Transmitter sent raw sensor value of 0 !! This isn't good. ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}",
        );
      }

      lastTransmitterTimestamp = sensorRx.timestamp;

      ///< kai_20231011 update transmitter insertion time here
      transmitterInsertTime = lastTransmitterTimestamp;

      if (getVersionDetails && (!haveFirmwareDetails())) {
        doVersionRequestMessage();
      } else if (getBatteryDetails &&
          (getBatteryStatusNow || !haveCurrentBatteryStatus())) {
        doBatteryInfoRequestMessage();
      } else {
        doDisconnectMessage();
      }

      final g6 = usingG6();
      processNewTransmitterData(
        g6 ? sensorRx.unfiltered * G6_SCALING : sensorRx.unfiltered,
        g6 ? sensorRx.filtered * G6_SCALING : sensorRx.filtered,
        sensorBatteryLevel,
        DateTime.now() as int,
      );
    } else if (firstByte == GlucoseRxMessage.opcode) {
      // Uint8List bytes = Uint8List.fromList(utf8.encode(data));
      //kai_20230608
      final bytes = Uint8List.fromList(value);
      log(
        '${TAG}kai: Uint8List.fromList(value): bytes.lengthInBytes = ${bytes.lengthInBytes}',
      );
      if (bytes.lengthInBytes >= 14) {
        final glucoseRx = GlucoseRxMessage(bytes);
        log(
          '${TAG}SUCCESS!! glucose unfiltered: ${glucoseRx.unfiltered}',
        );
        doDisconnectMessage();
        processNewTransmitterData(
          glucoseRx.unfiltered,
          glucoseRx.filtered,
          216,
          DateTime.now() as int,
        );
      } else {
        log(
          '${TAG}kai:processRxCharacteristic(): FAIL!! : data.length < 14 ',
        );
      }
    } else if (firstByte == VersionRequestRxMessage.opcode) {
      final bytes = Uint8List.fromList(utf8.encode(data));

      if (!setStoredFirmwareBytes(
        defaultTransmitter.transmitterId,
        bytes,
        true,
      )) {
        log('${TAG}Could not save out firmware version!');
      }
      doDisconnectMessage();
    } else if (firstByte == BatteryInfoRxMessage.opcode) {
      final bytes = Uint8List.fromList(utf8.encode(data));
      if (!setStoredBatteryBytes(defaultTransmitter.transmitterId, bytes)) {
        log('${TAG}Could not save out battery data!');
      }
      getBatteryStatusNow = false;
      doDisconnectMessage();
    } else {
      log(
        '${TAG}processRxCharacteristic(): unexpected opcode: $firstByte (have not disconnected!)',
      );
    }

    log('${TAG}processRxCharacteristic(): finished!!');
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
    switch (code) {
      case 5:
        final bytes = Uint8List.fromList(utf8.encode(data));
        authStatus = AuthStatusRxMessage(bytes);
        if (authStatus!.authenticated == 1 &&
            authStatus!.bonded == 1 &&
            !isBondedOrBonding) {
          log('${TAG}Special bonding test case!');

          if (tryPreBondWithDelay) {
            log('${TAG}Trying prebonding with delay!');
            isBondedOrBonding = true;
            if (cgmConnectedDevice != null) {
              //_cgmDevice.createBond();
              // _cgmDevice!.connect(4,true);
              await cgmConnectedDevice!.connect(autoConnect: false);
            }

            Future.delayed(const Duration(milliseconds: 1600), () async {
              log('${TAG}Prebond delay finished');
              //waitFor(1600);
              getTransmitterDetails(); // try to refresh on the off-chance
            });
          }
        }

        if (authStatus!.authenticated == 1 &&
            authStatus!.bonded == 1 &&
            (isBondedOrBonding || ignoreLocalBondingState)) {
          // TODO check bonding logic here and above
          isBondedOrBonding = true; // statement has no effect?
          getSensorData();
        } else if ((authStatus!.authenticated == 1 &&
                authStatus!.bonded == 2) ||
            (authStatus!.authenticated == 1 &&
                authStatus!.bonded == 1 &&
                !isBondedOrBonding)) {
          log(
            "${TAG}Let's Bond! ${isBondedOrBonding ? 'locally bonded' : 'not locally bonded'}",
          );

          if (useKeepAlive) {
            log('${TAG}Trying keepalive..');

            final keepAliveRequest = KeepAliveTxMessage(25);
            if (cgmRXTXAuthenCharacteristic != null) {
              cgmRXTXAuthenCharacteristic!.write(keepAliveRequest.byteSequence);
            }
          } else {
            /*
            performBondWrite(characteristic);
             */
          }
        } else {
          log('${TAG}Transmitter NOT already authenticated');
          sendAuthRequestTxMessage();
        }

        break;

      case 3:
        {
          final bytes = Uint8List.fromList(utf8.encode(data));
          final authChallenge = AuthChallengeRxMessage(bytes);
          authRequest ??= AuthRequestTxMessage(getTokenSize());

          log('${TAG}tokenHash ${authChallenge.tokenHash}');
          log(
            '${TAG}singleUse ${calculateHash(authRequest!.singleUseToken)}',
          );

          final challengeHash = calculateHash(authChallenge.challenge);
          log('${TAG}challenge hash$challengeHash');
          if (challengeHash != null) {
            log('${TAG}Transmitter try auth challenge');
            final authChallengeTx = AuthChallengeTxMessage(challengeHash);
            log(
              '${TAG}Auth Challenge: ${authChallengeTx.byteSequence}',
            );
            if (cgmRXTXAuthenCharacteristic != null &&
                cgmRXTXAuthenCharacteristic!.properties.notify &&
                !cgmRXTXAuthenCharacteristic!.isNotifying) {
              await cgmRXTXAuthenCharacteristic!.setNotifyValue(true);
              if (cgmRXTXAuthenCharacteristic!.properties.write ||
                  cgmRXTXAuthenCharacteristic!
                      .properties.writeWithoutResponse) {
                cgmRXTXAuthenCharacteristic!
                    .write(authChallengeTx.byteSequence!);
              }
            }
          }
        }
        break;

      default:
        {
          if ((code == 7) && delayOnBond) {}

          if ((code == 7) && tryOnDemandBondWithDelay) {}

          log(
            '${TAG}Read code: $code - Transmitter NOT already authenticated?',
          );
          sendAuthRequestTxMessage();
        }
        break;
    }

    log('${TAG}OnCharacteristic READ finished ');
  }

  @override
  Future<void> handleDexcomG5_6(List<int> value) async {
    log('${TAG}kai:CgmDexcom.handleDexcomG5_6()');
    // handle cgm dexcomG5 ~6 value
    if (value == null || value.isEmpty || value.isEmpty) {
      // 예외 처리
      log(
        '${TAG}kai: handleDexcomG5_6(): cannot handle due to no input data,  return',
      );
      return;
    }

    processRxCharacteristic(value);
  }

  @override
  void handleCgmAuthenValue(List<int> value) {
    log('${TAG}kai:CgmDexcom.handleCgmAuthenValue()');
    if (value == null || value.isEmpty || value.isEmpty) {
      // 예외 처리
      log(
        '${TAG}kai: handleCgmAuthenValue(): cannot handle due to no input data,  return',
      );
      return;
    }
    processOnCharacteristicRead(value);
  }

  @override
  void clearDeviceInfo() {
    log('${TAG}kai:CgmDexcom.clearDeviceInfo()');
    super.clearDeviceInfo();
  }

  //kai_20230609 override sendBooldGlucoseRequestCgm() here in case of dexcom
  @override
  Future<void> sendBooldGlucoseRequestCgm(
    BluetoothCharacteristic? characteristic,
  ) async {
    sendAuthRequestTxMessage();
  }
}

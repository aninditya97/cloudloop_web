import 'dart:async';
import 'dart:developer';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/danai/DanaRSMessageHashTable.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Pump.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/extension.dart';
import 'package:synchronized/synchronized.dart';

import 'dart:typed_data';
import 'dart:convert';

import '../CspPreference.dart';
import '../danai/BleEncryption.dart';
import '../danai/DanaRSPacket.dart';
import '../danai/EncryptionType.dart';
import '../danai/Packet.dart';
import 'ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/serviceUuid.dart';

class PumpDanars extends Pump {
  final String TAG = 'PumpDanars:';
  //buffer range skip API
  final bool USE_SKIP_BUFFER_METHOD = true;
  final bool USE_LOCK_SYNC = false;

  final int WRITE_DELAY_MILLIS = 50;
  final String UART_READ_UUID = "0000fff1-0000-1000-8000-00805f9b34fb";
  final String UART_WRITE_UUID = "0000fff2-0000-1000-8000-00805f9b34fb";
  final String UART_BLE5_UUID = "00002902-0000-1000-8000-00805f9b34fb";

  final int PACKET_START_BYTE = 0xA5;
  final int PACKET_END_BYTE = 0x5A;
  final int BLE5_PACKET_START_BYTE = 0xAA;
  final int BLE5_PACKET_END_BYTE = 0xEE;

  late BuildContext mContext;
  late BleEncryption _bleEncryption;

  BleEncryption get bleEncryption => _bleEncryption;

  late EncryptionType _encryption;

  DanaRSPacket? processedMessage = null;
  List<List<int>> mSendQueue = [];

  late DanaRSMessageHashTable danaRSMessageHashTable;

  // late BluetoothGatt? bluetoothGatt = null;
  // encryptionType : '0' : crc checksum only,
// '1': device key encryption,
// '2' : ble paring Key encryption
  int _encryptionType = 1;
  int get encryptionType => _encryptionType;
  set encryptionType(int value) {
    _encryptionType = value;
  }

  // flag which can check the start encryption command already sent or not
  bool _enabledStartEncryption = false;
  bool get enabledStartEncryption => _enabledStartEncryption;
  set enabledStartEncryption(bool value) {
    _enabledStartEncryption = value;
  }

  // fail status flag for sendPumpCheckAfterConnect
  int _issendPumpCheckAfterConnectFailed = 0;
  int get issendPumpCheckAfterConnectFailed =>
      _issendPumpCheckAfterConnectFailed;
  set issendPumpCheckAfterConnectFailed(int value) {
    _issendPumpCheckAfterConnectFailed = value;
  }

  // retrying status flag after sendPumpCheckAfterConnect failed
  bool _onRetrying = false;
  bool get onRetrying => _onRetrying;
  set onRetrying(bool value) {
    _onRetrying = value;
  }

  //time zone offset v=based on utc using  hwversion > 0x09 ( dana-i5 )
  int _timezoneOffset = 0;
  int get timezoneOffset => _timezoneOffset;
  set timezoneOffset(int value) {
    _timezoneOffset = value;
  }

  late int _pumpTime;

  ///< dana-i5 pump device time
  int get pumpTime => _pumpTime;
  set pumpTime(int value) {
    _pumpTime = value;
  }

  /*
  *@brief App need to send 0xFF(Keep Connection Command) into
  *       Dana-i5 per 1 min 30 secs or 2 mins
  *       in order to keep the connection between App and Dana-i5
  *       after connection is established
  *       use startKeepConnectionTimer() after connection first.
   */
  Timer? _KeepConnectionStatusTimer;
  Timer? get KeepConnectionStatusTimer => _KeepConnectionStatusTimer;
  set KeepConnectionStatusTimer(Timer? value) {
    _KeepConnectionStatusTimer = value;
  }

  /*
*@brief after sending a Start Command and receiving an OK response,
*       all data is encrypted by using dataEncryptionCode()
*       Encryption Code Table
 */
  List<int> guint8EncryptionMatrix = [
    0x17,
    0x2b,
    0x04,
    0x7e,
    0xba,
    0x77,
    0xd6,
    0x26,
    0xe1,
    0x69,
    0x70,
    0x3e,
    0xb5,
    0x66,
    0x48,
    0x03,
    0xf6,
    0x0e,
    0x61,
    0x35,
    0x3a,
    0x91,
    0x11,
    0x41,
    0x4f,
    0x67,
    0xdc,
    0xea,
    0x97,
    0xf2,
    0x70,
    0x3e,
    0xb5,
    0x66,
    0x48,
    0x03,
    0xf6,
    0x0e,
    0x61,
    0x35,
    0x51,
    0xa3,
    0x40,
    0x8f,
    0x92,
    0x9d,
    0x38,
    0xf5,
    0xbc,
    0xb6,
    0xcd,
    0x0c,
    0x13,
    0xec,
    0x5f,
    0x97,
    0x44,
    0x17,
    0xc4,
    0xa7,
    0x52,
    0x09,
    0x6a,
    0xd5,
    0x30,
    0x36,
    0xa5,
    0x38,
    0xbf,
    0x40,
    0xf8,
    0x98,
    0x11,
    0x69,
    0xd9,
    0x8e,
    0x94,
    0x9b,
    0x1e,
    0x87,
    0xc7,
    0x23,
    0xc3,
    0x18,
    0x96,
    0x05,
    0x9a,
    0x07,
    0x12,
    0x80,
    0x32,
    0x3a,
    0x0a,
    0x49,
    0x06,
    0x24,
    0x5c,
    0xc2,
    0xd3,
    0xac
  ];

  /*
  *@brief Pairing Key ASCII value can be received from 0x00 Command.
  *       (Only Device Bonding Bonding Paring Key Value 6 Digit)
  *    if received List<int> buffer = [56, 49, 49, 54, 52, 53]; (ascii value :  '8', '1', '1', '6', '4', '5' )
  *       => convert buffer to ascii value and save 6 bytes as paring key
   */
  List<int> pairingKeyASCII = [0, 0, 0, 0, 0, 0]; // 6 digits ascii value
  List<int> guint8EncryptionPairingKey = [0, 0, 0]; // 암호화 페어링 키 배열 초기화
  void BLEMakePairingKey(List<int> pairingKeyASCII) {
    guint8EncryptionPairingKey[0] =
        guint8EncryptionMatrix[pairingKeyASCII[0] * 10 + pairingKeyASCII[1]];
    guint8EncryptionPairingKey[1] =
        guint8EncryptionMatrix[pairingKeyASCII[2] * 10 + pairingKeyASCII[3]];
    guint8EncryptionPairingKey[2] =
        guint8EncryptionMatrix[pairingKeyASCII[4] * 10 + pairingKeyASCII[5]];
    debugPrint('${TAG}kai:update BLEMakePairingKey:'
        'guint8EncryptionPairingKey($guint8EncryptionPairingKey) '
        'by input pairingKeyASCII($pairingKeyASCII)');
  }

  //creator   call Pump creator by using super()
  PumpDanars(BuildContext context) : super(context) {
    debugPrint('kai:Create PumpDanars():init()');
    mContext = context;
    init();
  }

  void init() {
    encryptionType = 1;

    ///< default encryption type
  }

  List<int> readBuffer = List<int>.filled(1024, 0);

  ///< data buffer which have incoming received data
  int bufferLength = 0;
  final StreamController<List<int>> _controller = StreamController<List<int>>();
  Stream<List<int>> get addToReadBufferStream => _controller.stream;

  // let's synchronized object here
  final Lock _lock = Lock();

  /*
  void addToReadBuffer(List<int> buffer) {
    if (buffer.isEmpty) return;

    _lock.synchronized(() {
      // Append incoming data to input buffer
      readBuffer.setAll(bufferLength, buffer);
      bufferLength += buffer.length;
    });
  }
   */

  /*
  Future<void> addToReadBuffer(List<int> buffer) async {
    if (buffer.isEmpty) return;

    Future<void>.sync(() {
      // Append incoming data to input buffer
      readBuffer.setRange(bufferLength, bufferLength + buffer.length, buffer);
      bufferLength += buffer.length;
      _controller.add(readBuffer.sublist(0, bufferLength));
    });
  }
*/

  void addToReadBuffer(List<int> buffer) {
    if (buffer.isEmpty) return;

    Future<void>.sync(()
        //   _lock.synchronized(()
        {
      if (bufferLength + buffer.length > readBuffer.length) {
        // 버퍼가 가득 찼을 경우 초기화
        debugPrint(
          '${TAG}kai:addToReadBuffer():readBuffer Full:bufferLength($bufferLength)',
        );
        bufferLength = 0;
        readBuffer = List<int>.filled(1024, 0); // 1024 크기의 빈 버퍼로 초기화
        debugPrint(
          '${TAG}kai:addToReadBuffer():reset readBuffer:bufferLength($bufferLength)',
        );
      }

      final remainingSpace = readBuffer.length - bufferLength;
      final endIndex =
          buffer.length > remainingSpace ? remainingSpace : buffer.length;

      readBuffer.setRange(
        bufferLength,
        bufferLength + endIndex,
        buffer.sublist(0, endIndex),
      );
      bufferLength += endIndex;
      debugPrint(
          '${TAG}kai:addToReadBuffer():remainingSpace($remainingSpace),endIndex($endIndex),'
          ' readBuffer.setRange($bufferLength,${bufferLength + endIndex}),'
          'buffer.length(${buffer.length}),bufferLength($bufferLength)');
      if (buffer.length > remainingSpace) {
        // 버퍼에 남은 공간보다 더 많은 데이터가 있는 경우 재귀적으로 추가
        debugPrint(
          '${TAG}kai:addToReadBuffer():buffer.length(${buffer.length}) > remainingSpace($remainingSpace)',
        );
        addToReadBuffer(buffer.sublist(endIndex));
      } else {
        debugPrint(
          '${TAG}kai:addToReadBuffer():call _controller.add(readBuffer.sublist(0, bufferLength))',
        );
        _controller.add(readBuffer.sublist(0, bufferLength));
      }
    });
  }

  /** let's implement simplify here  */

  void startKeepConnectionTimer(int secs) {
    final timeValue = secs;
    if (timeValue == 0) {
      if (KeepConnectionStatusTimer != null) {
        debugPrint('${TAG}kai:cancel KeepConnectionStatusTimer');
        KeepConnectionStatusTimer!.cancel();
        KeepConnectionStatusTimer = null;
      }
    } else {
      debugPrint(
        '${TAG}kai:start KeepConnectionStatusTimer(90);encryptionType($encryptionType)',
      );
      KeepConnectionStatusTimer ??=
          Timer.periodic(Duration(seconds: timeValue), (timer) {
        const opCode = BleEncryption.DANAR_PACKET__OPCODE_ETC__KEEP_CONNECTION;

        ///< 0xFF
        //  List<int> param = [ 0x00, 0x01, 0x02, ...data ];
        sendBolusCommand(opCode, null);
      });
    }
  }

  void setPumpTimeWithZoneOffset(int value, int zoneOffset) {
    // Get the offset in hours
    final now = DateTime.now();
    final timeZoneOffset = now.timeZoneOffset;
    final offset = timeZoneOffset.inHours;

    // Update pump time according to the provided zone offset
    pumpTime = value + (Duration(hours: offset).inMilliseconds ~/ 1000);

    // Save the zone offset in the pump
    this.timezoneOffset = zoneOffset;
  }

  bool isUsingUTC() {
    if (getModelName().isNotEmpty) {
      return (getModelName.toString().toLowerCase().contains('dana-i5'))
          ? true
          : false;
    } else {
      return false;
    }
  }

  /*
  *@brief encrypts data by using BlePairing Key & Encryption Code Table
  *@param[in] puint8Flag : '1' encryption, others: decryption
  *@param[in] puint8Data : data
   */
  int dataEncryptionCode(int puint8Flag, int puint8Data) {
    var luint8ReturnData = puint8Data;

    if (puint8Flag == 1) {
      /// Encryption
      luint8ReturnData =
          (luint8ReturnData - guint8EncryptionPairingKey[0]) & 0xff;
      luint8ReturnData =
          (luint8ReturnData + guint8EncryptionPairingKey[1]) & 0xff;
      luint8ReturnData =
          ((luint8ReturnData >> 4) & 0x0f) | ((luint8ReturnData << 4) & 0xf0);
      luint8ReturnData =
          (luint8ReturnData ^ guint8EncryptionPairingKey[2]) & 0xff;
    } else {
      /// Decryption
      luint8ReturnData =
          (luint8ReturnData ^ guint8EncryptionPairingKey[2]) & 0xff;
      luint8ReturnData =
          ((luint8ReturnData >> 4) & 0x0f) | ((luint8ReturnData << 4) & 0xf0);
      luint8ReturnData =
          (luint8ReturnData - guint8EncryptionPairingKey[1]) & 0xff;
      luint8ReturnData =
          (luint8ReturnData + guint8EncryptionPairingKey[0]) & 0xff;
    }

    return luint8ReturnData;
  }

/*
*@brief Encrypt/ Decrypt packet , mode =  true Encryption, false = decryption
*@param[in] values : data array
*@param[in] mode : 'true' encryption, 'false' decryption
 */
  final bool _useExceptStartEnd = false;

  List<int> PacketEncryptionDecryption(List<int> values, bool mode) {
    final processedPacketValues = <int>[];

    debugPrint(
      '${TAG}:kai::current guint8EncryptionPairingKey($guint8EncryptionPairingKey)',
    );

    if (_useExceptStartEnd) {
      final startIndex = 2;

      ///< start(2)
      final endIndex = values.length - 2;

      ///< end(2)
      // let's skip start 2 bytes and start encryption till total length - 2
      // add start(2 bytes)
      processedPacketValues.add(values[0]);
      processedPacketValues.add(values[1]);

      for (var index = startIndex; index < endIndex; index++)
      // for (int value in values)
      {
        final value = values[index];
        final processedValue = dataEncryptionCode(mode == true ? 1 : 0, value);
        processedPacketValues.add(processedValue);
      }
      //add end(2 byte)
      processedPacketValues.add(values[endIndex]);
      processedPacketValues.add(values[endIndex + 1]);
      return processedPacketValues;
    } else {
      for (var value in values) {
        final processedValue = dataEncryptionCode(mode == true ? 1 : 0, value);
        processedPacketValues.add(processedValue);
      }
      return processedPacketValues;
    }
  }

/*
*@brief 1st message sent to pump thru onDescriptorWrite() after connect
*       after bond & connected, should send this connect command to Dana-i5 device during 5 second
*       to keep connection
 */
  /*
  Future<void> sendPumpCheckAfterConnect() async {
    debugPrint('kai:${TAG}sendPumpCheckAfterConnect is called !!'
        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
    if (ConnectedDevice == null) {
      return;
    }
    final deviceName = ConnectedDevice!.name;
    if (deviceName == null || deviceName.isEmpty) {
      // uiInteraction.addNotification(
      //     Notification.DEVICE_NOT_PAIRED, rh.gs(R.string.pairfirst), Notification.URGENT);
      log(
          'kai:${TAG}device name is empty, cannot proceed sendPumpCheckAfterConnect, return !!');
      return;
    }

    try {
      //making device key - Shipping Number (Device Key) is Dana-i5 device's name
      String shippingSerial = "AAA00000AA";
      if (ConnectedDevice != null && ConnectedDevice!.name.isNotEmpty) {
        shippingSerial = ConnectedDevice!.name;
        //update serial number and model name here
        SN = shippingSerial;
      }
      Packet packet = Packet();
      int opcode = BleEncryption.DANAR_PACKET__OPCODE_ENCRYPTION__PUMP_CHECK;

      ///< 0x00;
      List<int> parameters = shippingSerial.codeUnits;
      //if before start Encryption then let's set Type as Encryption Request 0x01 here  prior to call CreatePacket
      //if after encryption start then set Type as Command(0xA1)
      packet.type = BleEncryption.DANAR_PACKET__TYPE_ENCRYPTION_REQUEST;
      List<int> encryptedPacket = packet.createPacketEncrytinonWithDeviceKey(
          opcode, parameters, shippingSerial);

      debugPrint('kai:${TAG}shippingSerial($shippingSerial), parameters(' +
          parameters.toString() + ')');
      // UTF-8로 디코딩 시도
      if (USE_PUMPDANA_DEBUGMSG) {
        try {
          String decodedUtf8 = utf8.decode(parameters!);
          debugPrint(
              '${TAG}kai:Decoded with UTF-8:parameters($decodedUtf8), parameters.length: ${parameters
                  .length})');
        } catch (_) {
          // UTF-8 디코딩 실패 시 ASCII로 디코딩
          try {
            String decodedAscii = ascii.decode(parameters!);
            debugPrint(
                '${TAG}kai:Decoded with ASCII:parameters($decodedAscii), parameters.length: ${parameters
                    .length})');
          } catch (e) {
            print('Error decoding with ASCII:parameters $e');
            // 예외 처리: UTF-8 및 ASCII 디코딩 실패
          }
        }
      }

      encryptionType = 1; // set encryptiontype 1 because start encryption does not sent yet.
      debugPrint('kai:${TAG}encryptionType($encryptionType)encryptedPacket:dec(${encryptedPacket.toString()})');
      debugPrint('kai:${TAG}encryptedPacket:hex(${encryptedPacket.map(toHexString)
          .join(' ')})');
      LogMessageView = '>>Type(${toHexString(packet.type)})opCode(${toHexString(
          opcode)})parameters[${shippingSerial.toString()}]'
          ', devkeyencryption:${encryptedPacket.map(toHexString).join(' ')}';
      setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');
      // ascii.decode

      //if after start encryption command(0x0100) sent, then below is
      // needed with Type is 0xA1 and start(0xAA, 0xAA) , end(0xEE,0xEE)
      //encrypt Packet by using BLE paring key(6 digits) which
      // could be received from Dana-i5 after sending  this command(0x00)
      //in this case no needed
      /*
      List<int> encryptedValue = PacketEncryptionDecryption(encryptedPacket,true);
      log('kai:${TAG}encryptedValue(' + encryptedValue.toString() + ')');
       encryptedPacket = encryptedValue;
      */

      /*
      sendDataToPumpDevice(String.fromCharCodes(encryptedPacket));
    */
      if (pumpTxCharacteristic != null) {
        //kai_20230513 sometimes, app does not receive the response from Pump
        //due to RX characteristic's Notify is not enabled after reconnected
        //but actually Notify is disabled regardless of isNotifying is true
        //that's why we force to enable it here
        if (USE_FORCE_ENABE_RXNOTIFY) {
          SetForceRXNotify();
        }
        await pumpTxCharacteristic!.write(encryptedPacket);

        if (USE_SEND_ENCRYPTION_RETRY) {
          // let's send start Encryption command here
          Future<void>.delayed(
              Duration(seconds: 2), () {
            debugPrint('${TAG}kai: kick off sendStartEncryptionCommand()'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
            sendStartEncryptionCommand();
          });

        }

        //let's kick off startKeepConnectionTimer here to keep connection
        if (USE_DANAI_KEEPCONNECTION) {
          Future<void>.delayed(
              Duration(seconds: 5), () {
            debugPrint('${TAG}kai: kick off startKeepConnectionTimer(90)'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
            startKeepConnectionTimer(90);
          });
        }

      } else {
        log('kai:${TAG}Failed to send sendPumpCheckAfterConnect !!'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
       // TXErrorMsg = mContext.l10n.sendingDoseRequestNotAvailable.toString();
        // 'Sending dose request is not available at this time. Retry it?';
        /*
        LogMessageView =
        '>>Error sendPumpCheckAfterConnect';
        AlertMsg = LogMessageView;
        showALertMsgDlg = true;
        setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
        */
        LogMessageView = '>>Fail to sendPumpCheckAfterConnect';
        NoticeMsg = mContext.l10n.requestingCommandIsNotAvailable;;
        showNoticeMsgDlg = true;
        setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
        // set retry to send again later
        issendPumpCheckAfterConnectFailed = 1;
      }
    } catch (e) {
      debugPrint('kai:${TAG}Error sendPumpCheckAfterConnect: $e'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      /*
      LogMessageView = '>>Error sendPumpCheckAfterConnect: $e';
      AlertMsg = LogMessageView;
      showALertMsgDlg = true;
      setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
       */
      LogMessageView = '>>Error sendPumpCheckAfterConnect: $e';
      NoticeMsg = mContext.l10n.requestingCommandIsNotAvailable;
      showNoticeMsgDlg = true;
      setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');

      // set retry to send again later
      issendPumpCheckAfterConnectFailed = 1;
    }
  }
*/

  Future<void> sendPumpCheckAfterConnect(
      /*BluetoothCharacteristic characteristic, List<int> data, int maxRetries*/) async {
    var currentRetry = 0;
    final maxRetries = 10;

    if (onRetrying) {
      debugPrint(
        'kai:${TAG}sendPumpCheckAfterConnect is ongoing now:onRetrying($onRetrying) return!! !!',
      );
      return;
    }

    if (pumpTxCharacteristic == null) {
      debugPrint(
          'kai:${TAG}:pumpTxCharacteristic is null, cannot proceed sendPumpCheckAfterConnect()!!: return'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      onRetrying = false;
      return;
      //  PumpTxCharacteristic = await getCharacteristic(serviceUUID.DANARS_WRITE_UUID);
    }

    if (pumpTxCharacteristic != null) {
      debugPrint('kai:${TAG}sendPumpCheckAfterConnect is called !!'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      if (ConnectedDevice == null) {
        debugPrint(
          '${TAG}kai:onRetrying($onRetrying):Fail to call sendPumpCheckAfterConnect(): ConnectedDevice is null!!',
        );
        onRetrying = false;
        return;
      }
      final deviceName = ConnectedDevice!.name;
      if (deviceName == null || deviceName.isEmpty) {
        debugPrint(
          'kai:${TAG}onRetrying($onRetrying):device name is empty, cannot proceed sendPumpCheckAfterConnect, return !!',
        );
        onRetrying = false;
        return;
      }
/*
      if (ConnectionStatus != BluetoothDeviceState.connected) {
        debugPrint(
            'kai:${TAG}onRetrying($onRetrying):ConnectedDevice(${deviceName}) is not connected. cannot proceed sendPumpCheckAfterConnect, return !!');
        onRetrying = false;
        return;
      }
*/
      onRetrying = true;

      //making device key - Shipping Number (Device Key) is Dana-i5 device's name
      var shippingSerial = "AAA00000AA";
      if (ConnectedDevice != null && ConnectedDevice!.name.isNotEmpty) {
        shippingSerial = ConnectedDevice!.name;
        //update serial number and model name here
        SN = shippingSerial;
      }
      final packet = Packet();
      final opcode = BleEncryption.DANAR_PACKET__OPCODE_ENCRYPTION__PUMP_CHECK;

      ///< 0x00;
      final parameters = shippingSerial.codeUnits;
      //if before start Encryption then let's set Type as Encryption Request 0x01 here  prior to call CreatePacket
      //if after encryption start then set Type as Command(0xA1)
      packet.type = BleEncryption.DANAR_PACKET__TYPE_ENCRYPTION_REQUEST;
      final encryptedPacket = packet.createPacketEncrytinonWithDeviceKey(
        opcode,
        parameters,
        shippingSerial,
      );

      debugPrint(
        'kai:${TAG}shippingSerial($shippingSerial), parameters($parameters)',
      );
      encryptionType =
          1; // set encryptiontype 1 because start encryption does not sent yet.
      debugPrint(
        'kai:${TAG}encryptionType($encryptionType)encryptedPacket:dec(${encryptedPacket.toString()})',
      );
      debugPrint(
        'kai:${TAG}encryptedPacket:hex(${encryptedPacket.map(toHexString).join(' ')})',
      );
      LogMessageView =
          '>>Type(${toHexString(packet.type)})opCode(${toHexString(opcode)})parameters[${shippingSerial.toString()}]'
          ', devkeyencryption:${encryptedPacket.map(toHexString).join(' ')}';
      setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');

      while (currentRetry < maxRetries) {
        try {
          // Write with response
          if (ConnectionStatus == BluetoothDeviceState.connected) {
            if (USE_FORCE_ENABE_RXNOTIFY) {
              SetForceRXNotify();

              while (isSetNotifyFailed) {
                await SetForceRXNotify();
                debugPrint(
                    '${TAG}kai:sendPumpCheckAfterConnect():isSetNotifyFailed($isSetNotifyFailed)'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
              }
            }

            /*
            if (pumpTxCharacteristic == null) {
              PumpTxCharacteristic = await getCharacteristic(serviceUUID.DANARS_WRITE_UUID);
            }
             */
            //  await Future<void>.delayed(Duration(milliseconds: 1000)); /// let's delay 1 sec

            if (pumpTxCharacteristic == null) {
              currentRetry++;
              issendPumpCheckAfterConnectFailed = 1;
              debugPrint('${TAG}kai: pumpTxCharacteristic == null, '
                  'Retry attempt($currentRetry)'
                  ', isSetNotifyFailed($isSetNotifyFailed)'
                  ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

              // Add delay before retrying (adjust duration as needed)
              await Future<void>.delayed(Duration(milliseconds: 1000));
            } else {
              debugPrint(
                  '${TAG}kai:"currentRetry($currentRetry):call  pumpTxCharacteristic!.write(),'
                  'isSetNotifyFailed($isSetNotifyFailed)'
                  ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

              await Future<void>.delayed(Duration(milliseconds: 500));

              ///< set delay

              await pumpTxCharacteristic!
                  .write(encryptedPacket, withoutResponse: true);

              // Continue with other actions after a successful write
              debugPrint('${TAG}kai:"Write operation completed successfully,'
                  'isSetNotifyFailed($isSetNotifyFailed)'
                  ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

              if (USE_SEND_ENCRYPTION_RETRY) {
                // let's send start Encryption command here
                Future<void>.delayed(Duration(milliseconds: 3000), () {
                  debugPrint('${TAG}kai: kick off sendStartEncryptionCommand()'
                      ',isSetNotifyFailed($isSetNotifyFailed)'
                      ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                  sendStartEncryptionCommand();
                });
              }

              //let's kick off startKeepConnectionTimer here to keep connection
              if (USE_DANAI_KEEPCONNECTION) {
                Future<void>.delayed(Duration(milliseconds: 5000), () {
                  debugPrint('${TAG}kai: kick off startKeepConnectionTimer(90)'
                      ',isSetNotifyFailed($isSetNotifyFailed)'
                      ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
                  startKeepConnectionTimer(90);
                });
              }

              // Exit the loop if successful
              issendPumpCheckAfterConnectFailed = 0;
              onRetrying = false;
              break;
            }
          } else {
            currentRetry++;
            issendPumpCheckAfterConnectFailed = 1;
            debugPrint(
                '${TAG}kai: ConnectionStatus != BluetoothDeviceState.connected, '
                'Retry attempt($currentRetry)'
                ', isSetNotifyFailed($isSetNotifyFailed)'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

            // Add delay before retrying (adjust duration as needed)
            await Future<void>.delayed(Duration(milliseconds: 500));
          }
        } catch (e) {
          // Handle errors and increment retry count
          currentRetry++;
          issendPumpCheckAfterConnectFailed = 1;
          debugPrint(
              '${TAG}kai:Error during write operation. Retry attempt $currentRetry: $e '
              'isSetNotifyFailed($isSetNotifyFailed)'
              ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

          LogMessageView =
              '>>Retry($currentRetry): Type(${toHexString(packet.type)})opCode(${toHexString(opcode)})parameters[${shippingSerial.toString()}]'
              ', devkeyencryption:${encryptedPacket.map(toHexString).join(' ')}';
          setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');

          // Add delay before retrying (adjust duration as needed)
          // await Future<void>.delayed(Duration(milliseconds: 500));
        }
      }

      if (currentRetry == maxRetries) {
        // Handle the case when the maximum retries are reached
        debugPrint('${TAG}kai:Maximum retries reached. Write operation failed'
            '.isSetNotifyFailed($isSetNotifyFailed):'
            'Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
        issendPumpCheckAfterConnectFailed = 1;
      } else {
        debugPrint(
            '${TAG}kai:success to send the data: currentRetry($currentRetry)'
            ',isSetNotifyFailed($isSetNotifyFailed)'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      }

      onRetrying = false;
    } else {
      debugPrint('${TAG}kai:Fail to call sendPumpCheckAfterConnect():'
          ' pumpTxCharacteristic is null!!,isSetNotifyFailed($isSetNotifyFailed)'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
      issendPumpCheckAfterConnectFailed = 1;
      onRetrying = false;
    }
  }

/*
*@brief send start encryption opCode(0x01) with parameters below to dana-i
*       to notify encryption is started from now.
*       0x00(1) – Start Encryption + External Device ID(3)[Only Dana-i]
*       External Device ID : CURE STREAM – 0x0E1404
*       packet is as below;
*       start(0xA5,0xA5) + length(8) + Type (Encryption Request 0x01)
*       + Opcode (0x01) + parameters[0x00,0x0E,0x14,0x04] + Checksum(2Byte) + end(0x5A,0x5A)
*/
  Future<void> sendStartEncryptionCommand() async {
    debugPrint('kai:${TAG}sendStartEncryptionCommand is called !!'
        ':enabledStartEncryption($enabledStartEncryption)');
    if (ConnectedDevice == null) {
      return;
    }
    final deviceName = ConnectedDevice!.name;
    if (deviceName == null || deviceName.isEmpty) {
      log('kai:${TAG}device name is empty, cannot proceed sendStartEncryptionCommand, return !!');
      return;
    }
    //check start encryption command already sent to the danan-i or not
    if (USE_CHECK_ENCRYPTION_ENABLED) {
      // if yes, then skip to send this command to the dana-i again to prevent dana-i shundowm
      if (enabledStartEncryption == true) {
        debugPrint('kai:${TAG}already sent to the dana-i'
            ': skip sendStartEncryptionCommand(), return !!');
        return;
      }
    }

    try {
      //making device key - Shipping Number (Device Key) is Dana-i5 device's name
      var shippingSerial = "AAA00000AA";
      if (ConnectedDevice != null && ConnectedDevice!.name.isNotEmpty) {
        shippingSerial = ConnectedDevice!.name;
        SN = shippingSerial;
      }
      final packet = Packet();
      final opcode =
          BleEncryption.DANAI_PACKET__OPCODE_ENCRYPTION__START_ENCRYPTION;

      ///< 0x01;
      final parameters = <int>[
        0x00,
        0x0E,
        0x14,
        0x04
      ]; // Start Encryption(0x00) + External Device ID : CURE STREAM – 0x0E1404
      //if before start Encryption then let's set Type as Encryption Request 0x01 here  prior to call CreatePacket
      //if after encryption start then set Type as Command(0xA1)
      packet.type = BleEncryption.DANAR_PACKET__TYPE_ENCRYPTION_REQUEST;

      ///< 0x01
      final encryptedPacket = packet.createPacketEncrytinonWithDeviceKey(
        opcode,
        parameters,
        shippingSerial,
      );

      debugPrint(
        'kai:${TAG}shippingSerial($shippingSerial), parameters($parameters)',
      );
      // UTF-8로 디코딩 시도
      if (USE_PUMPDANA_DEBUGMSG) {
        try {
          final decodedUtf8 = utf8.decode(parameters);
          debugPrint(
            '${TAG}kai:Decoded with UTF-8:parameters($decodedUtf8), parameters.length: ${parameters.length})',
          );
        } catch (_) {
          // UTF-8 디코딩 실패 시 ASCII로 디코딩
          try {
            final decodedAscii = ascii.decode(parameters);
            debugPrint(
              '${TAG}kai:Decoded with ASCII:parameters($decodedAscii), parameters.length: ${parameters.length})',
            );
          } catch (e) {
            debugPrint('Error decoding with ASCII:parameters $e');
            // 예외 처리: UTF-8 및 ASCII 디코딩 실패
          }
        }
      }

      log('kai:${TAG}encryptedPacket:dec(${encryptedPacket.toString()})');
      log('kai:${TAG}encryptedPacket:hex(${encryptedPacket.map(toHexString).join(' ')})');
      LogMessageView =
          '>>Type(${toHexString(packet.type)})opCode(${toHexString(opcode)})parameters[${parameters.toString()}]'
          ', devkeyencryption:${encryptedPacket.map(toHexString).join(' ')}';
      setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'Error');

      //if after start encryption command(0x0100) sent, then below is
      // needed with Type is 0xA1 and start(0xAA, 0xAA) , end(0xEE,0xEE)
      //encrypt Packet by using BLE paring key(6 digits) which
      // could be received from Dana-i5 after sending  this command(0x00)
      //in this case no needed

      encryptionType =
          2; //after that all received packet will be encrypted by ble pairing key
      /*
      sendDataToPumpDevice(String.fromCharCodes(encryptedPacket));
      */
      if (pumpTxCharacteristic == null) {
        debugPrint(
          'kai:${TAG}pumpTxCharacteristic is null, cannot proceed sendStartEncryptionCommand, return !!',
        );
        return;
        //  PumpTxCharacteristic = await getCharacteristic(serviceUUID.DANARS_WRITE_UUID);
      }

      if (pumpTxCharacteristic != null) {
        //kai_20230513 sometimes, app does not receive the response from Pump
        //due to RX characteristic's Notify is not enabled after reconnected
        //but actually Notify is disabled regardless of isNotifying is true
        //that's why we force to enable it here
        if (USE_FORCE_ENABE_RXNOTIFY) {
          SetForceRXNotify();
        }

        //await Future<void>.delayed(Duration(milliseconds: 1000));

        await pumpTxCharacteristic!
            .write(encryptedPacket, withoutResponse: true);
        //await pumpTxCharacteristic!.write(encryptedPacket);

        //don't need to set success to start encryption sent to dana-i because
        // we can check it in danaHanndlePump's case opcode '0x01" and status '0x00' OK /'0x01' No Paring /'0x02' ID Error
        if (USE_CHECK_ENCRYPTION_ENABLED) {
          // enabledStartEncryption = true;
        }
        //let's kick off startKeepConnectionTimer here to keep connection
        if (USE_DANAI_KEEPCONNECTION) {
          Future<void>.delayed(Duration(seconds: 5), () {
            debugPrint('${TAG}kai: kick off startKeepConnectionTimer(90)');
            startKeepConnectionTimer(90);
          });
        }
      } else {
        log('kai:${TAG}Failed to send sendStartEncryptionCommand !!');
        // AlertMsg = mContext.l10n.sendingDoseRequestNotAvailable.toString();
        // 'Sending dose request is not available at this time. Retry it?';
        LogMessageView = '>>Fail to sendStartEncryptionCommand';
        NoticeMsg = mContext.l10n.requestingCommandIsNotAvailable;
        ;
        showNoticeMsgDlg = true;
        setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
      }
    } catch (e) {
      debugPrint('kai:${TAG}Error sendStartEncryptionCommand: $e');
      /*
      LogMessageView = '>>Error sendStartEncryptionCommand: $e';
      AlertMsg = LogMessageView;
      showALertMsgDlg = true;
      setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
      //setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'Error');
      */
      //set fail to start encryption sent to dana-i
      if (USE_CHECK_ENCRYPTION_ENABLED) {
        enabledStartEncryption = false;
      }
      LogMessageView = '>>Error sendStartEncryptionCommand: $e';
      NoticeMsg = mContext.l10n.requestingCommandIsNotAvailable;
      showNoticeMsgDlg = true;
      setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
    }
  }

  /** below commands could be sent after Start Encryption command
   * has been sent to Dana-i thru sendStartEncryptionCommand()  */

/*
  Bolus Commands which App send to Dana-i pump. [ App ==> Dana-i ]
===================================================================================================
CMD  ||                Parameters                                ||  Description
===================================================================================================
0x40 ||                                                          ||  Get Step Bolus Information
===================================================================================================
0x41 ||                                                          ||  Get Extended Bolus State
     ||                                                          ||
     ||                                                          ||
===================================================================================================
0x42 ||                                                          || Get Extended Bolus
     ||                                                          ||
===================================================================================================
0x43 ||                                                          || Get Dual Bolus
     ||                                                          ||
===================================================================================================
0x44 ||                                                          || Set Step Bolus Stop
===================================================================================================
0x45 ||                                                          || Get Carbohydrate
     ||                                                          || Calculation Information
===================================================================================================
0x46 ||                                                          || Get Extended Menu Option State
===================================================================================================
0x47 || Extended Bolus Rate(2) + Extended Bolus Duration(1)      || Set Extended Bolus
     || Extended Bolus Duration = Duration / 30Min               ||
     || EX) 0:30 – 1 / 1:00 – 2 / 1:30 – 3                       ||
===================================================================================================
0x48 || Step Bolus Rate(2) + Extended Bolus Rate(2)              || Set Dual Bolus
     || + Extended Bolus Duration(1)                             ||
===================================================================================================
0x49 ||                                                          || Set Extended Bolus Cancel
===================================================================================================
0x4A || Step Bolus Rate(2) + Speed(1)                            || Set Step Bolus Start
     || Easy Menu Speed Only 0 (12Sec/U )                        ||
===================================================================================================
0x4B ||                                                          || Get Calculation Information
===================================================================================================
0x4C ||                                                          || Get Bolus Rate
===================================================================================================
0x4D || BOLUS RATE[4] (4*2=8)                                    || Set Bolus Rate
===================================================================================================
0x50 ||                                                          || Get Bolus Option
====================================================================================================
0x51 || Extended Bolus Option On/Off(1)                          || Set Bolus Option
     || + Bolus Calculation Option(1) + Missed Bolus Config(1) + ||
     || Missed Bolus X Start Hour(1)+Min(1)                      ||
     || +End Hour(1)+Min(1) X 4 (16)                             ||
     || Bolus Calculation Option – 0:Unit /                      ||
     || 1:Carbohydrate / 2:Both                                  ||
====================================================================================================
0x52 || Glucose Unit(1) + CIR[24](24*2=48) + CF[24] (24*2=48)    || Get CIR CF 24Hours Array (Dana-i)
     || Glucose Unit - mg/dL : 0 / mmol/L : 1                    || (Only 24Hour CIR/CF Profile Pump)
====================================================================================================
0x53 || CIR[24](24*2=48) + CF[24] (24*2=48)                      || Set CIR CF 24Hours Array (Dana-i)
     || CIR <150                                                 || (Only 24Hour CIR/CF Profile Pump
     || CF – mg/dL : 1~450 / mmol/L : 10~2500(0.1~25.0)          ||
====================================================================================================

  Response of Bolus commands sent from Dana-i pump device [Dana-i ==> App ]
  below command cases parser should be implemented in handleDanaiPump(List<int> value)
===================================================================================================
CMD  ||                Parameters                                ||  Description
===================================================================================================
0x40 || Error(1)+ Bolus Type(1) + Bolus Rate(2)                  ||  Get Step Bolus Information
     || + Recent Bolus Info.[Hour(1)/Min(1)/Rate(2)]             ||
     || + BolusMax(2) + Bolus Increment(1)                       ||
     || Type – 0 [Bolus] / 1[Breakfast] / 2[Lunch] / 3[Dinner]   ||
===================================================================================================
0x41 || Error(1) + Extended Bolus State(1) + Duration(1)         ||  Get Extended Bolus State
     || + Rate(2) + Running Min(2) + Delivery Rate(2)            ||
     || Duration * 30 = Min                                      ||
===================================================================================================
0x42 || Error(1) + Extended Bolus Rate(2) + Bolus Max(2)         || Get Extended Bolus
     || + Bolus Increment(1)                                     ||
===================================================================================================
0x43 || Error(1) + Step Bolus Rate(2) + Extended Bolus Rate(2)   || Get Dual Bolus
     || + Bolus Max(2) + Bolus Increment(1)                      ||
===================================================================================================
0x44 || Status(1) / 0x00 : OK, 0x01 : Error                      || Set Step Bolus Stop
===================================================================================================
0x45 || Error(1) + Carbohydrate Value(2) + CIR Value(2)          || Get Carbohydrate
     || + Bolus Max Rate(2) + Bolus Increment(1)                 || Calculation Information
===================================================================================================
0x46 || Extended Menu Option(1)+ Extended Bolus State(1)         || Get Extended Menu Option State
===================================================================================================
0x47 || Status(1) / 0x00 : OK, 0x01 : Error                      || Set Extended Bolus
===================================================================================================
0x48 || Status(1) / 0x00 : OK, 0x01 : Error                      ||
     || / 0x02 : Step Bolus Error, 0x04 : Extended Error         || Set Dual Bolus
===================================================================================================
0x49 || Status(1) / 0x00 : OK, 0x01 : Error                      || Set Extended Bolus Cancel
===================================================================================================
0x4A || Status(1) / 0x00 : OK, Error Code + 0x10 : Bolus MAX     || Set Step Bolus Start
     || / 0x20 : Delivery Command Error /0x40 : Speed Error      ||
     || / 0x80 : Bolus Safety Rate Error                         ||
===================================================================================================
0x4B || Error(1) + Current BG(2) + Carbohydrate(2) + Target BG(2)|| Get Calculation Information
     || + CIR(2) + CF(2) + Active Insulin(2) + Glucose Unit(1)   ||
     || + Bolus Max Rate(2) + Bolus Increment(1)                 ||
     || Glucose Unit - mg/dL : 0 / mmol/L : 1                    ||
===================================================================================================
0x4C || BOLUS RATE[4] (4*2=8)                                    || Get Bolus Rate
===================================================================================================
0x4D || Status(1) / 0x00 : OK, 0x01 : Error                      || Set Bolus Rate
===================================================================================================
0x50 || Extended Bolus Option On/Off(1)                          || Get Bolus Option
     || + Bolus Calculation Option(1) + Missed Bolus Config(1)   ||
     || + Missed Bolus X Start Hour(1)+Min(1)+End Hour(1)        ||
     || +Min(1) X 4 (16)                                         ||
     || Bolus Calculation Option – 0:Unit                        ||
     || / 1:Carbohydrate / 2:Both                                ||
====================================================================================================
0x51 || Status(1) / 0x00 : OK, 0x01 : Error                      || Set Bolus Option
====================================================================================================
0x52 || Glucose Unit(1) + CIR[24](24*2=48) + CF[24] (24*2=48)    || Get CIR CF 24Hours Array (Dana-i)
     || Glucose Unit - mg/dL : 0 / mmol/L : 1                    || (Only 24Hour CIR/CF Profile Pump)
====================================================================================================
0x53 || Status(1) / 0x00 : OK, 0x01 : Error                      || Set CIR CF 24Hours Array (Dana-i)
     ||                                                          || (Only 24Hour CIR/CF Profile Pump
====================================================================================================

   Notify Command that Dana-i send to App. [ Dana-i ==> App ]
   below command cases parser should be implemented in handleDanaiPump(List<int> value).
   expected received packet format is as example below and
   packet length = type(1) + opCode(1) + parameters.length.
   Start (0xAA 0xAA) + Length(4) + Type(DANAR_PACKET__TYPE_NOTIFY = 0xC3)
   + Opcode(below CMD) + [ parameters(insulin 0x00,0x00) or parameters(alarm 0x01 ~ 0x0c,0x00) ]
   + Checksum(2Byte) + End (0xEE 0x EE).
===================================================================================================
CMD  ||                Parameters                                ||  Description
===================================================================================================
0x01 || Delivered Insulin Rate(2)                                || Delivery Complete
===================================================================================================
0x02 || Delivery Insulin Rate(2)                                 || Delivery Rate Display
===================================================================================================
0x03 || Alarm Code(2)                                            || Notify Alarm
     || 0x01:Battery 0% Alarm / 0x02:Pump Error / 0x03:Occlusion ||
     || / 0x04:LOW BATTERY / 0x05:Shutdown / 0x06:Basal Compare  ||
     || / 0x07 Glucose Check / 0x08 Low Reservoir                ||
     || / 0x09 Empty Reservoir / 0x0A Shaft Check                ||
     || / 0x0B Basal MAX / 0x0C Daily MAX                        ||
===================================================================================================
0x04 || Missed Bolus Start Hour(1)+Min(1)+End Hour(1)+Min(1)     || Missed bolus alarm
===================================================================================================
 */

  /*
  *@brief send set dana-i5 pump UTC and timezone with command 0x79 & parameters below;
  *       Year(1) + Month(1) + Day(1) + Hour(1) + Min(1) + Sec(1) + Time zone(1)[Signed
   */
  Future<void> sendSetPumpUtcTimeZone() async {
    if (pumpTime == 0) {
      debugPrint(
        '${TAG}kai:pumpTime($pumpTime) is not valid. cannor proceed Set pump UTC and timezone',
      );

      return;
    }
    final timeDiff = (pumpTime - DateTime.now().millisecondsSinceEpoch) / 1000;
    final tz = DateTime.now().timeZoneOffset; // Get current time zone offset
    final offsetInHours = (tz.inHours).toInt();

    if ((timeDiff.abs()) > 3 ||
        isUsingUTC() && offsetInHours != timezoneOffset) {
      if ((timeDiff.abs()) > 60 * 60 * 1.5) {
        debugPrint(
          '${TAG}kai:Pump time difference: $timeDiff seconds - large difference',
        );
        return;
      } else {
        // Do something else
        final date = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch,
          isUtc: true,
        );
        final parameters = List<int>.filled(7, 0);
        if (isUsingUTC()) {
          //set current application timezone here
          timezoneOffset = offsetInHours;
          parameters[0] = (date.year - 2000) & 0xFF;
          parameters[1] = date.month & 0xFF;
          parameters[2] = date.day & 0xFF;
          parameters[3] = date.hour & 0xFF;
          parameters[4] = date.minute & 0xFF;
          parameters[5] = date.second & 0xFF;
          parameters[6] = offsetInHours & 0xFF;
        } else {
          parameters[0] = (date.year - 2000) & 0xFF;
          parameters[1] = date.month & 0xFF;
          parameters[2] = date.day & 0xFF;
          parameters[3] = date.hour & 0xFF;
          parameters[4] = date.minute & 0xFF;
          parameters[5] = date.second & 0xFF;
          parameters[6] = timezoneOffset & 0xFF;
        }
        final opCode = 0x79;
        sendBolusCommand(opCode, parameters);
      }
    }
  }

  /*
  *@brief send set dana-i5 pump timezone with command 0x7B & parameters below;
  *       Time zone(1)[Signed
   */
  Future<void> sendSetTimeZoneOnly() async {
    if (pumpTime == 0) {
      debugPrint(
        '${TAG}kai:pumpTime($pumpTime) is not valid. cannor proceed Set pump timezone',
      );

      return;
    }
    final timeDiff = (pumpTime - DateTime.now().millisecondsSinceEpoch) / 1000;
    final tz = DateTime.now().timeZoneOffset; // Get current time zone offset
    final offsetInHours = (tz.inHours).toInt();

    if ((timeDiff.abs()) > 3 ||
        isUsingUTC() && offsetInHours != timezoneOffset) {
      if ((timeDiff.abs()) > 60 * 60 * 1.5) {
        debugPrint(
          '${TAG}kai:Pump time difference: $timeDiff seconds - large difference',
        );
        return;
      } else {
        // Do something else
        final date = DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch,
          isUtc: true,
        );
        final parameters = List<int>.filled(7, 0);
        if (isUsingUTC()) {
          //set current application timezone here
          timezoneOffset = offsetInHours;
          parameters[0] = offsetInHours & 0xFF;
        } else {
          //timezoneOffset = offsetInHours;
          parameters[0] = timezoneOffset & 0xFF;
        }
        final opCode = 0x7B;
        sendBolusCommand(opCode, parameters);
      }
    }
  }

  /*
  *@brief send Bolus commands to Dana-i pump device
  *@param[in] opCode : bolus commands supported in Dana-i
  *@param[in] parameters : data which will be sent to Dana-i
  *@detail in case that bolus commands w/o parameters
  *        ex: call sendBolusCommand(opCode, null);
  *        in case that bolus commands w parameters
  *        ex: List<int> param = [ 0x00, 0x01, 0x02, ...data ];
  *            call sendBolusCommand(opCode, param);
   */
  Future<void> sendBolusCommand(int opCode, List<int>? parameters) async {
    //let's check encryption start command already enabled first here
    if (USE_CHECK_ENCRYPTION_ENABLED) {
      if (!enabledStartEncryption) {
        //need to send this first before send below command
        debugPrint('kai:${TAG}send encryption start command '
            ':because enabledStartEncryption($enabledStartEncryption) is not enabled at this time');
        sendStartEncryptionCommand();
        await Future<void>.delayed(Duration(milliseconds: 1000));
      }
    }

    try {
      final packet = Packet();
      log('kai:${TAG}create Packet(), opCode($opCode)!!');
      packet.type = BleEncryption.DANAR_PACKET__TYPE_COMMAND;

      ///< 0XA1
      final opcode = opCode;

      ///< bolus command
      //encrypt data first by using device Key
      var shippingSerial = "AAA00000AA";
      if (ConnectedDevice != null && ConnectedDevice!.name.isNotEmpty) {
        shippingSerial = ConnectedDevice!.name;
        SN = shippingSerial;
      }
      // we will use ble pairing key second encryption for the first encrypted data by using device key
      packet.afterEncrytionStart = true;

      ///< use startEncrypt(0xAA,0xAA), endEncrypt(0xEE,0xEE)
      if (parameters != null) {
        log('kai:${TAG}parameters($parameters)');
        // UTF-8로 디코딩 시도
        if (USE_PUMPDANA_DEBUGMSG) {
          try {
            final decodedUtf8 = utf8.decode(parameters);
            debugPrint(
              '${TAG}kai:Decoded with UTF-8:parameters($decodedUtf8), parameters.length: ${parameters.length})',
            );
          } catch (_) {
            // UTF-8 디코딩 실패 시 ASCII로 디코딩
            try {
              final decodedAscii = ascii.decode(parameters);
              debugPrint(
                '${TAG}kai:Decoded with ASCII:parameters($decodedAscii), parameters.length: ${parameters.length})',
              );
            } catch (e) {
              debugPrint('Error decoding with ASCII:parameters $e');
              // 예외 처리: UTF-8 및 ASCII 디코딩 실패
            }
          }
        }
      }
      //encrypt data first by device key
      final encryptedPacket = packet.createPacketEncrytinonWithDeviceKey(
        opcode,
        (parameters != null && parameters.isNotEmpty) ? parameters : null,
        shippingSerial,
      );
      log('kai:${TAG}after createPacketEncrytinonWithDeviceKey:dec($encryptedPacket)');
      log('kai:${TAG}after createPacketEncrytinonWithDeviceKey:hex(${encryptedPacket.map(toHexString).join(' ')})');
      //encrypt Packet second by using paring key
      encryptionType = 2;

      ///< set encryptioType ble key
      final encryptedPacketBleKey =
          PacketEncryptionDecryption(encryptedPacket, true);
      log('kai:${TAG}encryptionType($encryptionType)after PacketEncryptionDecryption:dec($encryptedPacketBleKey)');
      log('kai:${TAG}after PacketEncryptionDecryption:hex(${encryptedPacketBleKey.map(toHexString).join(' ')})');
      LogMessageView =
          '>>Type(${toHexString(packet.type)})opCode(${toHexString(opcode)})parameters[${parameters.toString()}]'
          ', blekeyencryption:${encryptedPacketBleKey.map(toHexString).join(' ')}';
      setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');

      if (pumpTxCharacteristic == null) {
        debugPrint(
          'kai:${TAG}pumpTxCharacteristic is null: cannot proceed sendBolusCommand()',
        );
        return;
        // PumpTxCharacteristic = await getCharacteristic(serviceUUID.DANARS_WRITE_UUID);
      }

      if (pumpTxCharacteristic != null) {
        //kai_20230513 sometimes, app does not receive the response from Pump
        //due to RX characteristic's Notify is not enabled after reconnected
        //but actually Notify is disabled regardless of isNotifying is true
        //that's why we force to enable it here
        if (USE_FORCE_ENABE_RXNOTIFY) {
          SetForceRXNotify();
        }

        // await Future<void>.delayed(Duration(milliseconds: 1000));

        await pumpTxCharacteristic!
            .write(encryptedPacketBleKey, withoutResponse: true);

        // await pumpTxCharacteristic!.write(encryptedPacketBleKey);
        //let's kick off startKeepConnectionTimer here to keep connection
        if (USE_DANAI_KEEPCONNECTION) {
          Future<void>.delayed(Duration(seconds: 5), () {
            debugPrint('${TAG}kai: kick off startKeepConnectionTimer(90)');
            startKeepConnectionTimer(90);
          });
        }
      } else {
        log('kai:${TAG}Failed to sendBolusCommand !!');
        // AlertMsg = mContext.l10n.sendingDoseRequestNotAvailable.toString();
        // 'Sending dose request is not available at this time. Retry it?';
        LogMessageView = '>>Failed to sendBolusCommand';
        NoticeMsg = mContext.l10n.requestingCommandIsNotAvailable;
        ;
        showNoticeMsgDlg = true;
        setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
      }
    } catch (e) {
      debugPrint('kai:${TAG}Error sendBolusCommand: $e');
      /*
      LogMessageView = 'Error sendBolusCommand: $e';
      AlertMsg = LogMessageView;
      showALertMsgDlg = true;
      setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
      */
      LogMessageView = '>>Error to sendBolusCommand($opCode))';
      NoticeMsg = mContext.l10n.requestingCommandIsNotAvailable;
      showNoticeMsgDlg = true;
      setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
    }
  }

  @override
  Future<void> sendSetDoseValue(
    String value,
    int mode,
    BluetoothCharacteristic? characteristic,
  ) async {
    //let's check encryption start command already enabled first here
    if (USE_CHECK_ENCRYPTION_ENABLED) {
      if (!enabledStartEncryption) {
        //need to send this first before send below command
        debugPrint('kai:${TAG}send encryption start command '
            ':because enabledStartEncryption($enabledStartEncryption) is not enabled at this time');
        sendStartEncryptionCommand();
        await Future<void>.delayed(Duration(milliseconds: 1000));
      }
    }

    try {
      debugPrint(
        'kai:${TAG}sendSetDoseValue is called : value($value), mode($mode)!!',
      );

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

      final packet = Packet();
      debugPrint('kai:${TAG}create Packet()!!');
      //this command will be sent in case that after Encryption start is sent
      //so type should be command (0xA1)
      packet.type = BleEncryption.DANAR_PACKET__TYPE_COMMAND;

      ///< 0XA1
      final opcode =
          BleEncryption.DANAR_PACKET__OPCODE_BOLUS__SET_STEP_BOLUS_START;

      ///< 0x4A;
      //  double stepBolusRate = 12.0; // example : Step Bolus Rate
      final speed = mode;

      ///< Speed '0' => 12 secs/U , '1' => 30Sec/U , '2' => 60Sec/U

      // 0.05 값을 소숫점 앞자리 1 byte와 소숫점 뒷자리 1 byte로 변환하여 dataBytes에 추가
      if (!value.contains('.')) {
        // 입력된 문자열에 소수점이 없는 경우
        value = '$value.0';
      }
      final stepBolusRate = double.parse(value);

      debugPrint('kai:${TAG}stepBolusRate($stepBolusRate)');
      final stepBolusRateInt = (stepBolusRate * 100).toInt();
      final parameters = <int>[
        stepBolusRateInt & 0xFF,
        (stepBolusRateInt >> 8) & 0xFF,
        speed & 0xFF,
      ];

      debugPrint('kai:${TAG}parameters($parameters)');
      // UTF-8로 디코딩 시도
      if (USE_PUMPDANA_DEBUGMSG) {
        try {
          final decodedUtf8 = utf8.decode(parameters);
          debugPrint(
            '${TAG}kai:Decoded with UTF-8:parameters($decodedUtf8), parameters.length: ${parameters.length})',
          );
        } catch (_) {
          // UTF-8 디코딩 실패 시 ASCII로 디코딩
          try {
            final decodedAscii = ascii.decode(parameters);
            debugPrint(
              '${TAG}kai:Decoded with ASCII:parameters($decodedAscii), parameters.length: ${parameters.length})',
            );
          } catch (e) {
            debugPrint('kai:Error decoding with ASCII:parameters $e');
            // 예외 처리: UTF-8 및 ASCII 디코딩 실패
          }
        }
      }
      //encrypt data first by using device Key
      var shippingSerial = "AAA00000AA";
      if (ConnectedDevice != null && ConnectedDevice!.name.isNotEmpty) {
        shippingSerial = ConnectedDevice!.name;
        SN = shippingSerial;
      }
      // we will use ble pairing key second encryption for the first encrypted data by using device key
      packet.afterEncrytionStart = true;

      ///< use startEncrypt(0xAA,0xAA), endEncrypt(0xEE,0xEE)
      final encryptedPacket = packet.createPacketEncrytinonWithDeviceKey(
        opcode,
        parameters,
        shippingSerial,
      );
      debugPrint(
        'kai:${TAG}after createPacketEncrytinonWithDeviceKey:dec($encryptedPacket)',
      );
      debugPrint(
        'kai:${TAG}after createPacketEncrytinonWithDeviceKey:hex(${encryptedPacket.map(toHexString).join(' ')})',
      );
      //encrypt Packet second by using paring key
      encryptionType = 2;

      ///< set encryptiontype ble key
      final encryptedPacketBleKey =
          PacketEncryptionDecryption(encryptedPacket, true);
      debugPrint(
        'kai:${TAG}encryptionType($encryptionType),after PacketEncryptionDecryption:dec($encryptedPacketBleKey)',
      );
      debugPrint(
        'kai:${TAG}after PacketEncryptionDecryption:hex(${encryptedPacketBleKey.map(toHexString).join(' ')})',
      );

      LogMessageView =
          '>>Type(${toHexString(packet.type)})opCode(${toHexString(opcode)})parameters[${parameters.toString()}]'
          ', blekeyencryption:${encryptedPacketBleKey.map(toHexString).join(' ')}';
      setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');
      // send packet by using Tx write characteristic.write
      /*
      sendDataToPumpDevice(String.fromCharCodes(encryptedPacketBleKey));
       */
      if (characteristic != null) {
        await characteristic.write(encryptedPacketBleKey);
        /////kai_20230427 update insulin delivery amount here
        //BolusDeliveryValue = value + 'U';
        //BolusDeliveryValue = floatValue;  /// U
        setBolusDeliveryValue(stepBolusRate);
        //let's kick off startKeepConnectionTimer here to keep connection
        if (USE_DANAI_KEEPCONNECTION) {
          Future<void>.delayed(Duration(seconds: 5), () {
            debugPrint('${TAG}kai: kick off startKeepConnectionTimer(90)');
            startKeepConnectionTimer(90);
          });
        }
      } else {
        if (pumpTxCharacteristic == null) {
          debugPrint(
            'kai:${TAG}pumpTxCharacteristic is null: cannot proceed sendSetDoseValue()',
          );
          return;
          // PumpTxCharacteristic = await getCharacteristic(serviceUUID.DANARS_WRITE_UUID);
        }

        if (pumpTxCharacteristic != null) {
          //kai_20230513 sometimes, app does not receive the response from Pump
          //due to RX characteristic's Notify is not enabled after reconnected
          //but actually Notify is disabled regardless of isNotifying is true
          //that's why we force to enable it here
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }
          // await Future<void>.delayed(Duration(milliseconds: 1000));

          await pumpTxCharacteristic!
              .write(encryptedPacketBleKey, withoutResponse: true);

          //  await pumpTxCharacteristic!.write(encryptedPacketBleKey);
          setBolusDeliveryValue(stepBolusRate);

          //let's kick off startKeepConnectionTimer here to keep connection
          if (USE_DANAI_KEEPCONNECTION) {
            Future<void>.delayed(Duration(seconds: 5), () {
              debugPrint('${TAG}kai: kick off startKeepConnectionTimer(90)');
              startKeepConnectionTimer(90);
            });
          }
        } else {
          debugPrint('kai:${TAG}Failed to send dose request !!');
          // AlertMsg = mContext.l10n.sendingDoseRequestNotAvailable.toString();
          // 'Sending dose request is not available at this time. Retry it?';
          LogMessageView = '>>Failed to send dose request';
          AlertMsg = mContext.l10n.failInjectionBolus;
          showALertMsgDlg = true;
          setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
        }
      }
    } catch (e) {
      debugPrint('kai:${TAG}Error sendSetDoseValue: $e');
      LogMessageView = '>>Error sendSetDoseValue: $e';
      AlertMsg = mContext.l10n.failInjectionBolus;
      showALertMsgDlg = true;
      setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
    }
  }

  /**
   * @brief must implement this function to cancel that
   *        on going injection of the calculated dose (bolus/basal) in pump device
   *        Set Step Bolus Stop command opCode = 0x44, without parameters
   */
  @override
  Future<void> cancelSetDoseValue(
    int mode,
    BluetoothCharacteristic? characteristic,
  ) async {
    //let's check encryption start command already enabled first here
    if (USE_CHECK_ENCRYPTION_ENABLED) {
      if (!enabledStartEncryption) {
        //need to send this first before send below command
        debugPrint('kai:${TAG}send encryption start command '
            ':because enabledStartEncryption($enabledStartEncryption) is not enabled at this time');
        sendStartEncryptionCommand();
        await Future<void>.delayed(Duration(milliseconds: 1000));
      }
    }

    try {
      debugPrint('kai:${TAG}cancelSetDoseValue is called : mode($mode)!!');

      final packet = Packet();
      log('kai:${TAG}create Packet()!!');
      //this command will be sent in case that after Encryption start is sent
      //so type should be command (0xA1)
      packet.type = BleEncryption.DANAR_PACKET__TYPE_COMMAND;

      ///< 0XA1
      final opcode =
          BleEncryption.DANAR_PACKET__OPCODE_BOLUS__SET_STEP_BOLUS_STOP;

      ///< 0x44;
      final speed = mode;

      ///< Speed '0' => 12 secs/U , '1' => 30Sec/U , '2' => 60Sec/U
      //encrypt data first by using device Key
      var shippingSerial = "AAA00000AA";
      if (ConnectedDevice != null && ConnectedDevice!.name.isNotEmpty) {
        shippingSerial = ConnectedDevice!.name;
        SN = shippingSerial;
      }
      // we will use ble pairing key second encryption for the first encrypted data by using device key
      packet.afterEncrytionStart = true;

      ///< use startEncrypt(0xAA,0xAA), endEncrypt(0xEE,0xEE)
      final encryptedPacket = packet.createPacketEncrytinonWithDeviceKey(
        opcode,
        null,
        shippingSerial,
      );
      log('kai:${TAG}after createPacketEncrytinonWithDeviceKey($encryptedPacket)');
      //encrypt Packet second by using paring key
      final encryptedPacketBleKey =
          PacketEncryptionDecryption(encryptedPacket, true);
      encryptionType = 2;

      ///< set encryptiontype ble key
      log('kai:${TAG}encryptionType($encryptionType),after PacketEncryptionDecryption($encryptedPacketBleKey)');

      LogMessageView =
          '>>Type(${toHexString(packet.type)})opCode(${toHexString(opcode)})parameters[empty]'
          ', blekeyencryption:${encryptedPacketBleKey.map(toHexString).join(' ')}';
      setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');
      // send packet by using Tx write characteristic.write
      /*
        sendDataToPumpDevice(String.fromCharCodes(encryptedPacketBleKey));
       */
      if (characteristic != null) {
        await characteristic.write(encryptedPacketBleKey);

        //let's kick off startKeepConnectionTimer here to keep connection
        if (USE_DANAI_KEEPCONNECTION) {
          Future<void>.delayed(Duration(seconds: 5), () {
            debugPrint('${TAG}kai: kick off startKeepConnectionTimer(90)');
            startKeepConnectionTimer(90);
          });
        }
      } else {
        if (pumpTxCharacteristic == null) {
          debugPrint(
            'kai:${TAG}pumpTxCharacteristic is null: cannot proceed cancelSetDoseValue()',
          );
          return;
          // PumpTxCharacteristic = await getCharacteristic(serviceUUID.DANARS_WRITE_UUID);
        }

        if (pumpTxCharacteristic != null) {
          if (USE_FORCE_ENABE_RXNOTIFY) {
            SetForceRXNotify();
          }

          // await Future<void>.delayed(Duration(milliseconds: 1000));

          await pumpTxCharacteristic!
              .write(encryptedPacketBleKey, withoutResponse: true);
          // await pumpTxCharacteristic!.write(encryptedPacketBleKey);

          //let's kick off startKeepConnectionTimer here to keep connection
          if (USE_DANAI_KEEPCONNECTION) {
            Future<void>.delayed(Duration(seconds: 5), () {
              debugPrint('${TAG}kai: kick off startKeepConnectionTimer(90)');
              startKeepConnectionTimer(90);
            });
          }
        } else {
          log('kai:${TAG}Failed to cancel dose request !!');
          LogMessageView = '>>Failed to cancel dose request';
          AlertMsg = mContext.l10n.failCancelInjectionBolus;
          showALertMsgDlg = true;
          setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
        }
      }
    } catch (e) {
      debugPrint('${TAG}Error cancelSetDoseValue: $e');
      LogMessageView = '>>Error cancelSetDoseValue: $e';
      AlertMsg = mContext.l10n.failCancelInjectionBolus;
      showALertMsgDlg = true;
      setResponseMessage(RSPType.ALERT, AlertMsg, 'Error');
    }
  }

  //set the reservoir injection amount and current timedate into the Pump.
  @override
  Future<void> SendSetTimeReservoirRequest(
    int ReservoirAmount,
    int HclMode,
    BluetoothCharacteristic? characteristic,
  ) async {}

  //request pump information
  @override
  Future<void> sendPumpPatchInfoRequest(
    BluetoothCharacteristic? characteristic,
  ) async {
    debugPrint('${TAG}:kai:sendPumpPatchInfoRequest is called');
    if (characteristic != null) {
      //characteristic!.write(value);
    } else {
      //Initial
      // Get Screen Information
      sendBolusCommand(0x02, null);

      Future.delayed(
        const Duration(seconds: 1),
        () async {
          // Get User Option
          sendBolusCommand(0x21, null);
        },
      );

      Future.delayed(
        const Duration(seconds: 1),
        () async {
          // Get User Option
          sendBolusCommand(0x78, null);
        },
      );

      Future.delayed(
        const Duration(seconds: 1),
        () async {
          // Get Pump UTC and Time zone
          sendBolusCommand(0x7A, null);
        },
      );
    }
  }

  //set maximum bolus injection amount value which will be float or int type
  //as like ( 2.5 or 25 ), just put it as String '2.5' or '200.0'
  @override
  Future<void> sendSetMaxBolusThreshold(
    String value,
    int type,
    BluetoothCharacteristic? characteristic,
  ) async {}

  //send check Safety request to the pump
  @override
  Future<void> sendSafetyCheckRequest(
    BluetoothCharacteristic? characteristic,
  ) async {}

  //send cannular insertion request to the pump
  @override
  Future<void> sendCannularStatusRequest(
    BluetoothCharacteristic characteristic,
  ) async {}

  //send ACK for the response sent from the pump when cannular insertion is
  //complete
  @override
  Future<void> sendCannularInsertAck(
    BluetoothCharacteristic? characteristic,
  ) async {}

  //discard pump device
  @override
  Future<void> sendDiscardPatch(BluetoothCharacteristic? characteristic) async {
    debugPrint('${TAG}kai:sendDiscardPatch is called');
    if (characteristic != null) {
    } else {
      if (ConnectedDevice != null) {
        final devName = ConnectedDevice!.name.toString();

        try {
          await ConnectedDevice!.disconnect();
          //reset the start encryption command flag here
          if (USE_CHECK_ENCRYPTION_ENABLED) {
            enabledStartEncryption = false;
          }
        } catch (e) {
          debugPrint('${TAG}kai:sendDiscardPatch($devName)disconnect:Error=$e');
          if (USE_CHECK_ENCRYPTION_ENABLED) {
            //enabledStartEncryption = false;
          }
        }

        try {
          readBuffer = List<int>.filled(1024, 0);
          bufferLength = 0;

          final result = await ConnectedDevice!.removeBond();
          if (result) {
            debugPrint('${TAG}kai:remove bond of $devName');
            NoticeMsg =
                '${mContext.l10n.discardPatch}:$devName:${mContext.l10n.ok}';
            //clear serial number and model name here
            SN = '';
            ModelName = '';
            fw = '';
            //reset the start encryption command flag here
            if (USE_CHECK_ENCRYPTION_ENABLED) {
              _enabledStartEncryption = false;
            }
          } else {
            debugPrint('${TAG}kai:fail to remove bond of $devName');
            NoticeMsg =
                '${mContext.l10n.discardPatch}:$devName:${mContext.l10n.fail}';
          }
        } catch (e) {
          debugPrint('${TAG}kai:sendDiscardPatch($devName)removeBond:Error=$e');
          NoticeMsg = 'sendDiscardPatch($devName)removeBond:Error=$e';
        }
        showNoticeMsgDlg = true;
        setResponseMessage(RSPType.NOTICE, NoticeMsg, '3');
      } else {
        debugPrint('${TAG}kai:There is no connected device');
        NoticeMsg = '${mContext.l10n.thereIsNoConnectedPump}';
        showNoticeMsgDlg = true;
        setResponseMessage(RSPType.NOTICE, NoticeMsg, '3');
      }
    }
  }

  /*
   * @brief handler to parse the received data sent from the connected Dana-i pump device
   */
  @override
  void handleDanaiPump(List<int> value) {
    if (value == null || value.isEmpty) {
      // 예외 처리
      debugPrint(
        '${TAG}kai: handleDanaiPump(): cannot handle due to no input data,  return',
      );
      return;
    }
    //int encryptionType = 1;    ///< '0' : crc checksum only, '1': device key encryption, '2' : ble paring Key encryption
    var packetIsValid = false;
    var isProcessing = true;
    List<int>? inputBuffer;

    //need to check data encryption by using device key only
    // or packet encryption by using ble pairing key
    final lens = value.length;
    final toHexString = (int value) => value.toRadixString(16).padLeft(2, '0');
    final hexString = value.map(toHexString).join(' ');
    final decimalString = value
        .map((hex) => hex.toRadixString(10))
        .join(' '); // 10진수로 변환하고 join으로 스트링으로 변환

    debugPrint(
        '${TAG}kai: handleDanaiPump() is called; encryptionType($encryptionType)'
        ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
    if (USE_DEBUG_MESSAGE) {
      debugPrint('${TAG}kai: value length = $lens');
      debugPrint('${TAG}kai: hexString value = $hexString');
      debugPrint('${TAG}kai: decimalString value = $decimalString');
      debugPrint(
        '${TAG}kai: before addToReadBuffer():bufferLength = $bufferLength',
      );
    }

    /*
    // hexString을 공백을 기준으로 분할하여 각 바이트 값을 출력합니다.
    List<String> hexValues = hexString.split(' ');
    List<int> bytes = [];

    hexValues.forEach((hex) {
      int byte = int.parse(hex, radix: 16);
      bytes.add(byte);
    });

    // bytes 리스트에 있는 각 바이트 값을 출력합니다.
    for (int i = 0; i < bytes.length; i++) {
      debugPrint('value[$i]: ${bytes[i]}');
    }
    debugPrint('${TAG}kai:end: to show value[]');

    // Process decoded string
    final buffer = List<int>.from(value);
    //final code = buffer[0];
    // let's check received packet length and encryption start(2) & end(2) here
    lens = buffer.length;
  */

    if (encryptionType == 2) {
      //let's decrypt Packet first by using paring key
      final List<int>? decryptedPacketBuffer = (encryptionType == 2)
          ? PacketEncryptionDecryption(value, false)
          : value;
      if (decryptedPacketBuffer != null) {
        debugPrint(
          '${TAG}kai:decryptedPacketBuffer:Hex(${decryptedPacketBuffer.map(toHexString).join(' ')})',
        );
        addToReadBuffer(decryptedPacketBuffer);

        ///< add decrypted received data into readbuff
      } else {
        debugPrint(
          '${TAG}kai: ERROR: encryptionType($encryptionType): decrypted received Values is NULL, return !!',
        );
        return;
      }
    } else {
      addToReadBuffer(value);

      ///< add received data into readbuff
    }

    debugPrint(
      '${TAG}kai: after addToReadBuffer():bufferLength = $bufferLength, isProcessing($isProcessing)',
    );
    final Datalength = 0;

    //let's parsing received data read buffer here
    while (isProcessing) {
      /*
      if (lens >= 6) {
        if ((buffer[0] == PACKET_START_BYTE &&
            buffer[1] == PACKET_START_BYTE) ||
            (buffer[0] == BLE5_PACKET_START_BYTE &&
                buffer[1] == BLE5_PACKET_START_BYTE)) {
          Datalength = buffer[2];

          ///< packet data length =  type(1) + opCode(1) + parameters.length
          if (Datalength + 7 > lens) {
            log('${TAG}kai:handleDanaiPump:invalid packet length($lens)!!');
            return;
          }
          if ((buffer[Datalength + 5] == PACKET_END_BYTE &&
              buffer[Datalength + 6] == PACKET_END_BYTE) ||
              (buffer[Datalength + 5] == BLE5_PACKET_END_BYTE &&
                  buffer[Datalength + 6] == BLE5_PACKET_END_BYTE)) {
            packetIsValid = true;
          }
        }
      }
  */
      var length = 0;

      //  _lock.synchronized(()
      Future<void>.sync(() {
        if (bufferLength >= 6) {
          debugPrint(
            '${TAG}kai:check readBuff[${readBuffer.map(toHexString).join(' ')}]',
          );
          for (var idxStartByte = 0;
              idxStartByte < bufferLength - 2;
              idxStartByte++) {
            debugPrint('${TAG}kai:check index:readBuff[$idxStartByte]');
            if ((readBuffer[idxStartByte] == PACKET_START_BYTE &&
                    readBuffer[idxStartByte + 1] == PACKET_START_BYTE) ||
                (readBuffer[idxStartByte] == BLE5_PACKET_START_BYTE &&
                    readBuffer[idxStartByte + 1] == BLE5_PACKET_START_BYTE)) {
              if (idxStartByte > 0) {
                debugPrint(
                  "${TAG}kai:Shifting the input buffer by $idxStartByte bytes",
                );

                if (USE_SKIP_BUFFER_METHOD) {
                  readBuffer.setRange(
                    0,
                    bufferLength - idxStartByte,
                    readBuffer.skip(idxStartByte),
                  );
                } else {
                  readBuffer.setAll(
                    0,
                    readBuffer.sublist(idxStartByte, bufferLength),
                  );
                }

                bufferLength -= idxStartByte;

                if (bufferLength < 0) {
                  bufferLength = 0;
                  debugPrint(
                    '${TAG}kai:handleDanaiPump:bufferLength < 0 :set bufferLength(0)',
                  );
                }
              }

              length = readBuffer[2].toInt();
              debugPrint(
                "${TAG}kai:readBuffer[2] = length($length):by idxStartByte($idxStartByte)",
              );

              if (length + 7 > bufferLength) {
                debugPrint(
                  '${TAG}kai:handleDanaiPump:invalid packet length(${length + 7}) > bufferLength($bufferLength): return !!',
                );
                return;
              }

              if ((readBuffer[length + 5] == PACKET_END_BYTE &&
                      readBuffer[length + 6] == PACKET_END_BYTE) ||
                  (readBuffer[length + 5] == BLE5_PACKET_END_BYTE &&
                      readBuffer[length + 6] == BLE5_PACKET_END_BYTE)) {
                // set encryption type
                if ((readBuffer[length + 5] == PACKET_END_BYTE &&
                    readBuffer[length + 6] == PACKET_END_BYTE)) {
                  encryptionType = 1;

                  ///< device key encryption
                } else if ((readBuffer[length + 5] == BLE5_PACKET_END_BYTE &&
                    readBuffer[length + 6] == BLE5_PACKET_END_BYTE)) {
                  encryptionType = 2;

                  ///< ble paring key encryption
                }
                packetIsValid = true;
              } else {
                debugPrint(
                  "${TAG}kai:Error in input data. Resetting buffer.: set bufferLength(0)",
                );
                bufferLength = 0;
              }
              break;
            }
            if (USE_SKIP_BUFFER_METHOD) {
              //break;  // is this really needed here?
            } else {
              debugPrint("${TAG}kai:break for loop ");
              break;
            }
          }
        }
      });

      debugPrint('${TAG}kai:packetIsValid($packetIsValid)');

      if (packetIsValid) {
        debugPrint('${TAG}kai:startParsing:packetIsValid($packetIsValid)');
        //assign (length + 7) size into inputBuffer by using Uint8List
        inputBuffer = Uint8List(length + 7);
        //read data of readBuffer from 0 to (length + 7) and
        //copy it into inputBuffer from [0] ~ [length + 7]
        inputBuffer.setAll(0, readBuffer.sublist(0, length + 7));
        try {
          //readBuffer의 0번째 인덱스부터 (bufferLength - (length + 7)) 길이까지의 요소를, readBuffer의 length + 7 인덱스부터 끝까지의 요소로 대체
          //bufferLength - (length + 7)의 길이 만큼의 데이터가 남도록 잘라냄
          if (USE_SKIP_BUFFER_METHOD) {
            readBuffer.setRange(
              0,
              bufferLength - (length + 7),
              readBuffer.skip(length + 7),
            );
          } else {
            readBuffer.setAll(
              length + 7,
              readBuffer.sublist(length + 7, bufferLength),
            );
          }
        } catch (e) {
          debugPrint(
            "${TAG}kai:length: $length bufferLength: $bufferLength, error($e)",
          );
          throw e;
        }
        //bufferLength 변수에서 length + 7만큼을 빼고, 이를 새로운 bufferLength 값으로 업데이트함
        //버퍼의 길이를 줄이는 작업
        bufferLength -= length + 7;

        debugPrint(
          '${TAG}kai:inputBuffer(${inputBuffer.toString()}),inputBuffer.length(${inputBuffer.length})',
        );
        debugPrint(
          '${TAG}kai:inputBufferHex(${inputBuffer.map(toHexString).join(' ')})',
        );
        if (USE_PUMPDANA_DEBUGMSG) {
          LogMessageView =
              '<<receivedPacketHex((${inputBuffer.map(toHexString).join(' ')})';
          setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');

          // UTF-8로 디코딩 시도

          try {
            final decodedUtf8 = utf8.decode(inputBuffer);
            debugPrint(
              '${TAG}kai:Decoded with UTF-8:inputBuffer($decodedUtf8), bufferLength: $bufferLength)',
            );
          } catch (_) {
            // UTF-8 디코딩 실패 시 ASCII로 디코딩
            try {
              final decodedAscii = ascii.decode(inputBuffer);
              debugPrint(
                '${TAG}kai:Decoded with ASCII:inputBuffer($decodedAscii), bufferLength: $bufferLength)',
              );
            } catch (e) {
              debugPrint('${TAG}kai:Error decoding with ASCII:inputBuffer $e');
              // 예외 처리: UTF-8 및 ASCII 디코딩 실패
            }
          }
        }
        // let's skip below ble key decryption due to already check in above
        final decryptedPacket = inputBuffer;
        /*
        //decrypt Packet first by using paring key
        List<int> decryptedPacket = (encryptionType == 2)
            ? PacketEncryptionDecryption(inputBuffer, false)
            : inputBuffer;
        */
        if (decryptedPacket != null && decryptedPacket.isNotEmpty) {
          debugPrint(
            '${TAG}kai:decryptedPacket(${decryptedPacket.toString()}),decryptedPacket.length(${decryptedPacket.length})',
          );
          debugPrint(
            '${TAG}kai:decryptedPacketHex(${decryptedPacket.map(toHexString).join(' ')})',
          );
          if (USE_PUMPDANA_DEBUGMSG) {
            LogMessageView =
                '<<decryptedPacketHex(${decryptedPacket.map(toHexString).join(' ')})';
            setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');

            // UTF-8로 디코딩 시도
            try {
              final decodedUtf8 = utf8.decode(decryptedPacket);
              debugPrint(
                '${TAG}kai:Decoded with UTF-8:decryptedPacket($decodedUtf8), decryptedPacket.length(${decryptedPacket.length})',
              );
            } catch (_) {
              // UTF-8 디코딩 실패 시 ASCII로 디코딩
              try {
                final decodedAscii = ascii.decode(decryptedPacket);
                debugPrint(
                  '${TAG}kai:Decoded with ASCII:decryptedPacket($decodedAscii), decryptedPacket.length(${decryptedPacket.length})',
                );
              } catch (e) {
                debugPrint(
                  '${TAG}kai:Error decoding with ASCII:decryptedPacket $e',
                );
                // 예외 처리: UTF-8 및 ASCII 디코딩 실패
              }
            }
          }
          //decrypt data second by using device Key
          var shippingSerial = "AAA00000AA";
          if (ConnectedDevice != null && ConnectedDevice!.name.isNotEmpty) {
            shippingSerial = ConnectedDevice!.name;
            SN = shippingSerial;
          }
          final packet = Packet();
          final IntDevKey = packet.makeDeviceKey(shippingSerial);
          // List<int> IntDevKey = deviceKey.map((str) => int.parse(str)).toList();

          //let's exclude start(2)/end(2) and try to decrypt decryptedpacket
          //( type(1) + opCode(1) + parameters.length + checksum(2) )
          // List<int> decryptedValue = packet.decryptPacket(decryptedPacket, IntDevKey);
          final exceptStartLenEndsubList =
              decryptedPacket.sublist(3, (decryptedPacket.length - 2));
          final exceptStartLenEnddecryptedValue =
              packet.decryptPacket(exceptStartLenEndsubList, IntDevKey);
          final decryptedValue = <int>[
            decryptedPacket[0],
            decryptedPacket[1],
            decryptedPacket[2],
            ...exceptStartLenEnddecryptedValue,
            decryptedPacket[decryptedPacket.length - 2],
            decryptedPacket[decryptedPacket.length - 1]
          ];
          //int opCode = decryptedPacket[2]; // 패킷의 OpCode 부분 위치에 따라 변경 (패킷에 맞게 조정)
          // }
          //checksum
          final chksum = <int>[
            exceptStartLenEnddecryptedValue[
                exceptStartLenEnddecryptedValue.length - 2],
            exceptStartLenEnddecryptedValue[
                exceptStartLenEnddecryptedValue.length - 1]
          ];
          final exceptchksumValue = exceptStartLenEnddecryptedValue.sublist(
            0,
            (exceptStartLenEnddecryptedValue.length - 2),
          );

          ///< checksum(2)
          final chksum1 = packet.generateCrc(
            exceptchksumValue,
            (encryptionType == 2) ? true : false,
          );
          debugPrint(
            '${TAG}kai:checking checksum(${chksum}) == chksum1(${chksum1})',
          );

          debugPrint(
            '${TAG}kai:decryptedValue(${decryptedValue.toString()}), decryptedValue.length(${decryptedValue.length})',
          );
          debugPrint(
            '${TAG}kai:decryptedValueHex(${decryptedValue.map(toHexString).join(' ')})',
          );

          LogMessageView =
              '<<decryptedValueHex(${decryptedValue.map(toHexString).join(' ')})';
          setResponseMessage(RSPType.UPDATE_SCREEN, LogMessageView, 'update');

          // Process decoded string
          final buffer = List<int>.from(decryptedValue);
          var bufIndex = 0;
          final startcode1 = buffer[bufIndex];

          ///< 0
          bufIndex++;
          final startcode2 = buffer[bufIndex];

          ///< 1
          bufIndex++;
          final pkLength = buffer[bufIndex];

          ///< 2
          bufIndex++;
          final pkType = buffer[bufIndex];

          ///< 3
          bufIndex++;

          ///< Command 0xA1, Response 0xB2, Notify 0xC3, Encryption Request 0x01, Encryption Response 0x02
          final opCode = buffer[bufIndex];

          ///< 4 packet OpCode 부분 위치에 따라 변경 (패킷에 맞게 조정)
          debugPrint(
            '${TAG}kai:handleDanaiPump is called : startcode1($startcode1),startcode2($startcode2),lenght($pkLength),Type($pkType),opCode($opCode)',
          );
          debugPrint('${TAG}kai:buffer(${buffer.map(toHexString).join(' ')})');

          if (pkType == 0x02) {
            // bufIndex = 3
            //(pkType == BleEncryption.DANAR_PACKET__TYPE_ENCRYPTION_RESPONSE) ///< 0x02
            // int status = buffer[5];
            final decryptedBuffer = buffer;
            switch (opCode) {
              // bufIndex = 4
              case 0x00:
                {
                  final subList =
                      decryptedBuffer.sublist(bufIndex + 1, bufIndex + 3);

                  ///<  (2 byte, ascii)
                  final response = ascii.decode(subList);
                  debugPrint(
                    'kai:${TAG}Type(0x02)opCode(0x00)parameters(${response.toString()})',
                  );

                  // 5, 6
                  if (decryptedBuffer[bufIndex + 1] == 'O'.codeUnits[0] &&
                      decryptedBuffer[bufIndex + 2] == 'K'.codeUnits[0]) {
                    // response OK => ascii 79,75 => hex 4f, 4b
                    // ... rest of the logic  7,8 ,9,10
                    if (decryptedBuffer.length >= 14 &&
                        decryptedBuffer[bufIndex + 3] == 'M'.codeUnits[0] &&
                        decryptedBuffer[bufIndex + 5] == 'P'.codeUnits[0]) {
                      //response M , P => ascii 77,80  => hex 4d,50
                      //‘OK’ ‘M’ + Model Code(1) + ‘P’ + Protocol(1) + Pairing Key ASCII(6)
                      // Pairing Key Only Used Device Bonding

                      // let's save delivered key 6 here
                      final pkey = decryptedBuffer.sublist(
                        bufIndex + 7,
                        ((bufIndex + 7) + 6),
                      );

                      ///< 11 ~ 16 : 6 bytes ascii value
                      final pairingKey = String.fromCharCodes(
                        pkey,
                      ); // convert ASCII value to String
                      var StrPairingKey = CspPreference.getString(
                        'key_dana_ble5_pairingkey' /*CspPreference.key_dana_ble5_pairingkey*/,
                        defaultValue: '',
                      );
                      if (StrPairingKey != null && StrPairingKey.isEmpty) {
                        // let's update here
                        if (pairingKey != null && pairingKey.length == 6) {
                          CspPreference.setString(
                            'key_dana_ble5_pairingkey' /*CspPreference.key_dana_ble5_pairingkey*/,
                            pairingKey,
                          );
                        }
                      } else if (StrPairingKey != null &&
                          StrPairingKey.isNotEmpty) {
                        //let's compair key value and update it if not same
                        if (!pairingKey
                            .toLowerCase()
                            .contains(StrPairingKey.toLowerCase())) {
                          if (pairingKey != null && pairingKey.length == 6) {
                            CspPreference.setString(
                              'key_dana_ble5_pairingkey' /*CspPreference.key_dana_ble5_pairingkey*/,
                              pairingKey,
                            );
                          }
                        }
                      }
                      var pairingNumberKey = <int>[]; // 6 digits
                      // convert the String of ASCII value into numeric and save it into pairingNumberKey
                      if (pairingKey != null && pairingKey.length == 6) {
                        for (var i = 0; i < pairingKey.length; i++) {
                          final numericValue = int.parse(
                            pairingKey[i],
                          ); // convert String into integer number
                          pairingNumberKey.add(
                            numericValue,
                          ); // add integer number into pairingNumberKey
                        }
                        BLEMakePairingKey(pairingNumberKey);
                      } else {
                        StrPairingKey = CspPreference.getString(
                          'key_dana_ble5_pairingkey' /*CspPreference.key_dana_ble5_pairingkey*/,
                          defaultValue: '',
                        );
                        if (StrPairingKey != null &&
                            StrPairingKey.length == 6) {
                          for (var i = 0; i < StrPairingKey.length; i++) {
                            final numericValue = int.parse(
                              StrPairingKey[i],
                            ); // convert String into integer number
                            pairingNumberKey.add(
                              numericValue,
                            ); // add integer number into pairingNumberKey
                          }
                          BLEMakePairingKey(pairingNumberKey);
                        } else {
                          // let's return due to invalid pairing key code
                          debugPrint('${TAG}kai: Invalid Pairing key code.');
                          LogMessageView =
                              '<<OK:Type(0x02)opCode(0x00)parameters[M(${decryptedBuffer[bufIndex + 4]})P(${decryptedBuffer[bufIndex + 6]})'
                              'Ble Pairing Key(invalid)]';
                          TXErrorMsg = LogMessageView;
                          showTXErrorMsgDlg = true;
                          setResponseMessage(
                            RSPType.ERROR,
                            TXErrorMsg,
                            'error',
                          );
                          break;
                          pairingNumberKey = [
                            0,
                            0,
                            0,
                            0,
                            0,
                            0,
                          ];

                          ///< 0,0,0,0,0,0
                          BLEMakePairingKey(pairingNumberKey);
                        }
                      }

                      var MP = '';
                      if (decryptedBuffer[bufIndex + 4] == 0x09) {
                        MP = 'Dana-i5';
                      } else if (decryptedBuffer[bufIndex + 4] == 0x0A) {
                        MP = 'Dana-i5 Easy - Korea';
                      }
                      debugPrint(
                          '${TAG}kai:Received Encryption Response: OK:M($MP})P(${decryptedBuffer[bufIndex + 6]})'
                          'Ble Pairing Key(${pairingNumberKey.toString()})');

                      LogMessageView =
                          '<<OK:Type(0x02)opCode(0x00)parameters[M($MP})P(${decryptedBuffer[bufIndex + 6]})'
                          'Ble Pairing Key(${pairingNumberKey.toString()})]';
                      /*
                      setResponseMessage(
                          RSPType.UPDATE_SCREEN, LogMessageView, 'update');
                       */
                      //update Model Name , fw info , first connection time(refill time) here
                      ModelName = MP;
                      fw =
                          '${mContext.l10n.protocolVersion}:${decryptedBuffer[bufIndex + 6]}';
                      refillTime = DateTime.now().millisecondsSinceEpoch;

                      NoticeMsg = '${mContext.l10n.updatingPairingKey}:'
                          '${mContext.l10n.ok},'
                          '${mContext.l10n.model}:$MP,'
                          'PV-${decryptedBuffer[bufIndex + 6]}';
                      showNoticeMsgDlg = true;
                      setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
                    } else {
                      debugPrint(
                        '${TAG}kai:Received Encryption Response: Serial number is same OK',
                      );

                      LogMessageView =
                          '<<Type(0x02)opCode(0x00)parameters[Serial number is same OK]';
                      /*
                      setResponseMessage(
                          RSPType.UPDATE_SCREEN, LogMessageView, 'update');
                       */
                      NoticeMsg =
                          '${mContext.l10n.serialNumberIsSame}:${mContext.l10n.ok}';
                      showNoticeMsgDlg = true;
                      setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
                    }
                    // let's send start Encryption command here
                    sendStartEncryptionCommand();
                  } else if (decryptedBuffer.length >= 9 &&
                      decryptedBuffer[bufIndex + 1] == 'P'.codeUnits[0] &&
                      decryptedBuffer[bufIndex + 2] == 'U'.codeUnits[0] &&
                      decryptedBuffer[bufIndex + 3] == 'M'.codeUnits[0] &&
                      decryptedBuffer[bufIndex + 4] == 'P'.codeUnits[0]) {
                    // response PUMP : error status => ascii 80,85,77,80
                    debugPrint(
                      '${TAG}kai:Received Encryption Response: Pump is Error Status',
                    );

                    LogMessageView =
                        '<<Type(0x02)opCode(0x00)parameters[Pump is Error Status]';
                    TXErrorMsg = mContext.l10n.pumpIsErrorStatus;
                    showTXErrorMsgDlg = true;
                    setResponseMessage(RSPType.ERROR, TXErrorMsg, 'error');
                    // ... rest of the logic
                  } else if (decryptedBuffer.length >= 9 &&
                      decryptedBuffer[bufIndex + 1] == 'B'.codeUnits[0] &&
                      decryptedBuffer[bufIndex + 2] == 'U'.codeUnits[0] &&
                      decryptedBuffer[bufIndex + 3] == 'S'.codeUnits[0] &&
                      decryptedBuffer[bufIndex + 4] == 'Y'.codeUnits[0]) {
                    // response BUSY: error status => ascii 66,85,83,89

                    debugPrint(
                      '${TAG}kai:Received Encryption Response: Motor Delivery Mode or Prime Mode Busy',
                    );
                    LogMessageView =
                        '<<Type(0x02)opCode(0x00)parameters[Motor Delivery Mode or Prime Mode Busy]';
                    TXErrorMsg = mContext.l10n.motorDeliveryModeOrPrimeModeBusy;
                    showTXErrorMsgDlg = true;
                    setResponseMessage(RSPType.ERROR, TXErrorMsg, 'error');

                    // ... rest of the logic
                  } else {
                    // ERROR in response, wrong serial number
                    // ... rest of the logic
                    debugPrint(
                      '${TAG}kai:Received Encryption Response: unknown !!',
                    );
                    LogMessageView =
                        '<<Type(0x02)opCode(0x00)parameters[unknown]';
                    TXErrorMsg = LogMessageView;
                    showTXErrorMsgDlg = true;
                    setResponseMessage(RSPType.ERROR, TXErrorMsg, 'error');
                  }
                }
                break;

              case 0x01:
                {
                  // Status(1) / 0x00 : OK, 0x01 : Error (No Pairing State),0x02 : ID Error
                  // debugPrint('${TAG}kai:received Encryption Response:Type(0x02)opCode(0x01)paremeters(${decryptedBuffer[bufIndex + 1]})');
                  final status = decryptedBuffer[bufIndex + 1];
                  switch (status) {
                    case 0x00:
                      //update encryption start flag here
                      if (USE_CHECK_ENCRYPTION_ENABLED) {
                        enabledStartEncryption = true;
                      }
                      debugPrint(
                          '${TAG}kai:received Encryption Response:Type(0x02)opCode(0x01)paremeters[0x00:OK], '
                          'encryptionType($encryptionType), enabledStartEncryption($enabledStartEncryption)');
                      LogMessageView =
                          '<<Type(0x02)opCode(0x01)parameters[0x00:OK]';
                      setResponseMessage(
                        RSPType.UPDATE_SCREEN,
                        LogMessageView,
                        'update',
                      );
                      encryptionType = 2;

                      ///< set encryptiontype is ble encryption
                      debugPrint(
                        '${TAG}kai:Type(0x02)opCode(0x01)params(0x00):update encryptionType($encryptionType)',
                      );

                      //kai_20240107 send dana-i get UTC and timezone command here
                      sendBolusCommand(0x78, null);
                      break;

                    case 0x01:
                      //update encryption start flag here
                      if (USE_CHECK_ENCRYPTION_ENABLED) {
                        enabledStartEncryption = false;
                      }
                      debugPrint(
                          '${TAG}kai:received Encryption Response:Type(0x02)opCode(0x01)paremeters[0x01:Error (No Pairing State)],'
                          ' encryptionType($encryptionType), enabledStartEncryption($enabledStartEncryption)');
                      LogMessageView =
                          '<<Type(0x02)opCode(0x01)parameters[0x01:Error (No Pairing State)]';
                      TXErrorMsg = '${mContext.l10n.noPairingState}';
                      showTXErrorMsgDlg = true;
                      setResponseMessage(RSPType.ERROR, TXErrorMsg, 'error');
                      encryptionType = 1;

                      ///< set encryptiontype is device key encryption
                      debugPrint(
                        '${TAG}kai:Type(0x02)opCode(0x01)params(0x01):update encryptionType($encryptionType)',
                      );
                      break;

                    case 0x02:
                      //update encryption start flag here
                      if (USE_CHECK_ENCRYPTION_ENABLED) {
                        enabledStartEncryption = false;
                      }
                      debugPrint(
                          '${TAG}kai:received Encryption Response:Type(0x02)opCode(0x01)paremeters[0x02:ID Error],'
                          ' encryptionType($encryptionType), enabledStartEncryption($enabledStartEncryption)');
                      LogMessageView =
                          '<<Type(0x02)opCode(0x01)parameters[0x02:ID Error]';
                      TXErrorMsg = '${mContext.l10n.idError}';
                      showTXErrorMsgDlg = true;
                      setResponseMessage(RSPType.ERROR, TXErrorMsg, 'error');
                      encryptionType = 1;

                      ///< set encryptiontype is device key encryption
                      debugPrint(
                        '${TAG}kai:Type(0x02)opCode(0x01)params(0x02):update encryptionType($encryptionType)',
                      );
                      break;
                  }
                }
                break;

              case 0xFE:
                //Response of Dana-i for Set Refill Rate by AutoSetter: App => Dana-i with Refill Rate(2)
                //Status(1) / 0x00 : OK, 0x01 : Error
                final status = decryptedBuffer[bufIndex + 1];
                switch (status) {
                  case 0x00:
                    debugPrint(
                      '${TAG}kai:received Encryption Response:Type(0x02)opCode(0xFE)paremeters(0x00) OK (Set Refill Rate)',
                    );
                    LogMessageView =
                        '<<Type(0x02)opCode(0xFE)paremeters[0x00:OK (Set Refill Rate)]';
                    setResponseMessage(
                      RSPType.UPDATE_SCREEN,
                      LogMessageView,
                      'update',
                    );
                    break;

                  case 0x01:
                    debugPrint(
                      '${TAG}kai:received Encryption Response:Type(0x02)opCode(0xFE)paremeters(0x01) Error (Set Refill Rate)',
                    );
                    LogMessageView =
                        '<<Type(0x02)opCode(0xFE)paremeters[0x01:Error (Set Refill Rate)]';
                    TXErrorMsg = LogMessageView;
                    showTXErrorMsgDlg = true;
                    setResponseMessage(RSPType.ERROR, TXErrorMsg, 'error');
                    break;
                }
                break;

              case 0xF0:
                break;

              case 0xF4:
                break;
            }
          } else if (pkType == 0xB2) {
            // command Response 0xB2 : DANAR_PACKET__TYPE_RESPONSE = 0xB2
            if (opCode == 0x4A) {
              ///< Set Step Bolus Start
              final status =
                  buffer[bufIndex + 1]; // bufIndex = 4 opCode position,
              // response Status position is bufIndex = 1 => 5
              switch (status) {
                case 0x00:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x4A)parameters(0x00) OK',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x4A)parameters[0x00:OK]';
                  /* setResponseMessage(
                      RSPType.UPDATE_SCREEN, LogMessageView, 'update');
                  */
                  NoticeMsg =
                      '${mContext.l10n.setStepBolusStart}:${mContext.l10n.ok}';
                  showNoticeMsgDlg = true;
                  setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
                  // 처리할 작업 추가 (OK 상태일 때)
                  break;
                case 0x10:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x4A)parameters(0x10) Error Code - Bolus MAX',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x4A)parameters[0x10:Error Code - Bolus MAX]';
                  AlertMsg = '${mContext.l10n.errorCodeBolusMAX}';
                  showALertMsgDlg = true;
                  setResponseMessage(RSPType.ALERT, AlertMsg, 'error');
                  // 처리할 작업 추가 (Bolus MAX 상태일 때)
                  // need to send a warning message to show pop up here
                  break;
                case 0x20:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x4A)parameters(0x20) Error Code - Delivery Command Error',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x4A)parameters[0x20:Error Code - Delivery Command Error]';
                  AlertMsg = '${mContext.l10n.errorCodeDeliveryCommandError}';
                  showALertMsgDlg = true;
                  setResponseMessage(RSPType.ALERT, AlertMsg, 'error');
                  // 처리할 작업 추가 (Delivery Command Error 상태일 때)
                  // need to send a warning message to show pop up here
                  break;
                case 0x40:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x4A)parameters(0x40) Error Code - Speed Error',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x4A)parameters[0x40:Error Code - Speed Error]';
                  AlertMsg = "${mContext.l10n.errorCodeSpeedError}";
                  showALertMsgDlg = true;
                  setResponseMessage(RSPType.ALERT, AlertMsg, 'error');
                  // 처리할 작업 추가 (Speed Error 상태일 때)
                  // need to send a warning message to show pop up here
                  break;
                case 0x80:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x4A)parameters(0x80) Error Code - Bolus Safety Rate Error',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x4A)parameters[0x80:Error Code - Bolus Safety Rate Error]';
                  AlertMsg = '${mContext.l10n.errorCodeBolusSafetyRateError}';
                  showALertMsgDlg = true;
                  setResponseMessage(RSPType.ALERT, AlertMsg, 'error');
                  // 처리할 작업 추가 (Bolus Safety Rate Error 상태일 때)
                  // need to send a warning message to show pop up here
                  break;
                default:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x4A)parameters() Unknown status',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x4A)parameters[Unknown status]';
                  AlertMsg = "${mContext.l10n.unknownstatus}";
                  showALertMsgDlg = true;
                  setResponseMessage(RSPType.ALERT, AlertMsg, 'error');
                  // 처리할 작업 추가 (알 수 없는 상태일 때)
                  break;
              }
            } else if (opCode == 0x44) {
              ///< Set Step Bolus Stop
              final status =
                  buffer[bufIndex + 1]; // bufIndex = 4 opCode position,
              // response Status position is bufIndex = 1 => 5
              switch (status) {
                case 0x00:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x44)parameters(0x00) OK',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x44)parameters[0x00:OK]';

                  NoticeMsg =
                      '${mContext.l10n.setStepBolusStop}:${mContext.l10n.ok}';
                  showNoticeMsgDlg = true;
                  setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');

                  // 처리할 작업 추가 (OK 상태일 때)
                  break;
                case 0x01:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x44)parameters(0x01) Error - Set Step Bolus Stop',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x44)parameters[0x01:Error - Set Step Bolus Stop]';
                  AlertMsg =
                      '${mContext.l10n.error}:${mContext.l10n.setStepBolusStop}';
                  showALertMsgDlg = true;
                  setResponseMessage(RSPType.ALERT, AlertMsg, 'error');
                  // 처리할 작업 추가 (Set Step Bolus Stop 에러 상태일 때)
                  // need to send a warning message to show pop up here
                  break;
                default:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x44)parameters() Unknown status',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x44)parameters[Unknown status]';
                  AlertMsg = '${mContext.l10n.unknownstatus}';
                  showALertMsgDlg = true;
                  setResponseMessage(RSPType.ALERT, AlertMsg, 'error');
                  // 처리할 작업 추가 (알 수 없는 상태일 때)
                  break;
              }
            } else if (opCode == 0x21) {
              ///< get Pump Check response
              //int status = buffer[bufIndex + 1]; // bufIndex = 4 opCode position,
              //response Status or data position is bufIndex = 1 => 5
              final check0 = buffer[bufIndex + 1]; // Check[0]  5
              final check1 = buffer[bufIndex + 2]; // Check[1]  6
              final check2 = buffer[bufIndex + 3]; // Check[2]  7

              // Check[0] 해석
              switch (check0) {
                case 0x09:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x21)parameters[0x09:Model - Dana-i5,',
                  );
                  //update model name here
                  ModelName = 'Dana-i5';
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x21)parameters[0x09:Model - Dana-i5,';
                  setResponseMessage(
                    RSPType.UPDATE_SCREEN,
                    LogMessageView,
                    'update',
                  );
                  // 처리할 작업 추가 (Model이 Dana-i5인 경우)
                  break;
                case 0x0A:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x21)parameters[0x0A:Model - Dana-i5 Easy - Korea,',
                  );
                  //update Model Name here
                  ModelName = 'Dana-i5 Easy - Korea';
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x21)parameters[0x0A:Model - Dana-i5 Easy - Korea,';
                  setResponseMessage(
                    RSPType.UPDATE_SCREEN,
                    LogMessageView,
                    'error',
                  );
                  // 처리할 작업 추가 (Model이 Dana-i5 Easy - Korea인 경우)
                  break;
                default:
                  debugPrint(
                    '${TAG}kai:Received response:Type(0xB2)opCode(0x21)parameters[Unknown Model,',
                  );
                  ModelName = 'Unknown';
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x21)parameters[Unknown Model,';
                  setResponseMessage(
                    RSPType.UPDATE_SCREEN,
                    LogMessageView,
                    'unknown',
                  );
                  /*
                  TXErrorMsg = LogMessageView;
                  showTXErrorMsgDlg = true;
                  setResponseMessage(RSPType.ERROR, TXErrorMsg, 'error');
                   */
                  // 처리할 작업 추가 (알 수 없는 Model인 경우)
                  break;
              }

              // Check[1] 및 Check[2] 해석
              debugPrint(
                '${TAG}kai:Received:Type(0xB2)opCode(0x21)parameters(Protocol Version: ${check1})',
              );
              debugPrint(
                '${TAG}kai:Received:Type(0xB2)opCode(0x21)parameters(Product Code: ${check2})',
              );
              //update firmware version info here
              fw =
                  '${getModelName()}:${mContext.l10n.protocolVersion}:${check1},${mContext.l10n.productCode}:${check2}';

              LogMessageView = '$LogMessageView$fw]';
              setResponseMessage(
                RSPType.UPDATE_SCREEN,
                LogMessageView,
                'update',
              );
              // 각 Check[1]과 Check[2]에 대한 작업 수행
            } else {
              switch (opCode) {
                case 0x02:
                  debugPrint(
                    '${TAG}kai:Received Notify:Type(0xB2)opCode(0x02)parameters(0x02) Initial Screen Information: ',
                  );
                  // Initial Screen Information
                  /*
                  Status(1) + Daily Delivery Rate(2) +Daily Max Rate(2) + Reservoir Rate(2) + Current Basal Rate(2)
                  + Temporary Ratio(1) + Battery Ratio(1) + Extended Bolus Rate per Hour(2) + Active Insulin
                  Rate(2) + Error(1) + Alarm Max(1)
                  - Status -
                  Suspend : 0x01 / Bolus Block : 0x02 / Extended Bolus : 0x04 / Dual Bolus : 0x08 /
                  Temporary Basal : 0x10 / Button Lock : 0x20
                   */
                  final decryptedBuffer = buffer;
                  // start(2) + length(1) + type(1) + opcode(1) + parameters.length(17) + checksum(2) + end(2)
                  if (decryptedBuffer.length >= 22) {
                    //reservoir rate(2)
                    //Battery Ratio(1)
                    //Active Insulin Rate(2)
                    final status = decryptedBuffer[bufIndex + 1];
                    var receivedData = (decryptedBuffer[bufIndex + 3] << 8) |
                        decryptedBuffer[bufIndex + 2];

                    ///< [buff[7] << 8 | buff[6]]
                    final DailyDeliveryRated = receivedData / 100;

                    receivedData = (decryptedBuffer[bufIndex + 5] << 8) |
                        decryptedBuffer[bufIndex + 4];

                    ///< [buff[9] << 8 | buff[8]]
                    final DailyMaxRate = receivedData / 100;

                    receivedData = (decryptedBuffer[bufIndex + 7] << 8) |
                        decryptedBuffer[bufIndex + 6];

                    ///< [buff[11] << 8 | buff[10]]
                    final ReservoirRate = receivedData / 100;
                    //update reservoir here
                    reservoir = ReservoirRate.toString();

                    receivedData = (decryptedBuffer[bufIndex + 9] << 8) |
                        decryptedBuffer[bufIndex + 8];

                    ///< [buff[13] << 8 | buff[12]]
                    final CurrentBasalRate = receivedData / 100;

                    final TemporaryRatio = decryptedBuffer[bufIndex + 10];
                    final BatteryRatio = decryptedBuffer[bufIndex + 11];
                    //update Battery level here
                    Battery = BatteryRatio.toString();

                    receivedData = (decryptedBuffer[bufIndex + 13] << 8) |
                        decryptedBuffer[bufIndex + 12];

                    ///< [buff[17] << 8 | buff[16]]
                    final ExtendedBolusRate = receivedData / 100;

                    receivedData = (decryptedBuffer[bufIndex + 13] << 8) |
                        decryptedBuffer[bufIndex + 12];

                    ///< [buff[19] << 8 | buff[18]]
                    final ActiveInsulin = receivedData / 100;
                    //update insulin delivery value here
                    //actually received active insulin value is 0.0 so don't need to update here
                    //setBolusDeliveryValue(ActiveInsulin);

                    final Error = decryptedBuffer[bufIndex + 14];
                    final AlarmMax = decryptedBuffer[bufIndex + 15];

                    var statusStr = '';

                    switch (status) {
                      case 0x01:
                        statusStr = 'Status(suspend)';
                        break;

                      case 0x02:
                        statusStr = 'Status(Bolus Block)';
                        break;

                      case 0x04:
                        statusStr = 'Status(Extended Bolus)';
                        break;

                      case 0x08:
                        statusStr = 'Status(Dual Bolus)';
                        break;

                      case 0x10:
                        statusStr = 'Status(Temporary Basal)';
                        break;

                      case 0x20:
                        statusStr = 'Status(Button Lock)';
                        break;
                    }

                    final Params =
                        '$statusStr,Daily Delivery Rate($DailyDeliveryRated),Daily Max Rate($DailyMaxRate),Reservoir Rate($ReservoirRate),Current Basal Rate($CurrentBasalRate),Temporary Ratio($TemporaryRatio),Battery Ratio($BatteryRatio),Extended Bolus Rate per Hour($ExtendedBolusRate),Active Insulin Rate($ActiveInsulin),Error($Error),Alarm Max($AlarmMax)';

                    LogMessageView =
                        '<<Type(0xB2)opCode(0x02)parameters[0x02:Initial Screen Information:$Params]';

                    NoticeMsg = 'Initial Screen Information:$Params';
                    showNoticeMsgDlg = true;
                    setResponseMessage(RSPType.NOTICE, NoticeMsg, '3');
                    /*  setResponseMessage(
                          RSPType.UPDATE_SCREEN, LogMessageView, 'update');
                     */

                    // Initial Screen Information
                  }

                  break;
                case 0x03:
                  debugPrint(
                    '${TAG}kai:Received Notify:Type(0xB2)opCode(0x02)parameters(0x03) Delivery Status: ',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x02)parameters[0x03:Delivery Status:]';
                  NoticeMsg = '${mContext.l10n.deliveryStatus}';
                  showNoticeMsgDlg = true;
                  setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
                  // Delivery Status
                  break;
                case 0x04:
                  debugPrint(
                    '${TAG}kai:Received Notify:Type(0xB2)opCode(0x02)parameters(0x04) Get Password: ',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x02)parameters[0x04:Get Password:]';
                  setResponseMessage(
                    RSPType.UPDATE_SCREEN,
                    LogMessageView,
                    'notify',
                  );
                  // Get Password
                  break;

                case 0x20:
                  {
                    // Get Shipping Information
                    // Serial No.(10) + Shipping Country(3) + Shipping Date(3)
                  }
                  break;

                case 0x24:
                  {
                    // Get more info.
                    // Active Insulin(2)
                    // + Daily Total Rate(2)
                    // + Extended Bolus State(1)
                    // + Remain Min(2) + Remain Rate(2)
                    // + Last Bolus Time Min(4) + Last Bolus Rate(2)

                    final decryptedBuffer = buffer;
                    // start(2) + length(1) + type(1) + opcode(1) + parameters.length(15) + checksum(2) + end(2)
                    if (decryptedBuffer.length >= 20) {
                      var receivedData = (decryptedBuffer[bufIndex + 2] << 8) |
                          decryptedBuffer[bufIndex + 1];

                      ///< [buff[7] << 8 | buff[6]]
                      final ActiveInsulin = receivedData / 100;

                      receivedData = (decryptedBuffer[bufIndex + 4] << 8) |
                          decryptedBuffer[bufIndex + 3];

                      ///< [buff[9] << 8 | buff[8]]
                      final DailyTotalRate = receivedData / 100;

                      final ExtendedBolusState = decryptedBuffer[bufIndex + 5];

                      receivedData = (decryptedBuffer[bufIndex + 7] << 8) |
                          decryptedBuffer[bufIndex + 6];

                      ///< [buff[12] << 8 | buff[11]]
                      final RemainMin = receivedData;

                      ///< minutes

                      receivedData = (decryptedBuffer[bufIndex + 9] << 8) |
                          decryptedBuffer[bufIndex + 8];

                      ///< [buff[14] << 8 | buff[13]]
                      final RemainRate = receivedData / 100;

                      receivedData = (decryptedBuffer[bufIndex + 11] << 8) |
                          decryptedBuffer[bufIndex + 10];

                      ///< [buff[16] << 8 | buff[15]]
                      final LastBolusTime = (receivedData / 3600).toInt();

                      ///< hours

                      receivedData = (decryptedBuffer[bufIndex + 13] << 8) |
                          decryptedBuffer[bufIndex + 12];

                      ///< [buff[18] << 8 | buff[17]]
                      final LastBolusMins = (receivedData / 60).toInt();

                      ///< minutes

                      receivedData = (decryptedBuffer[bufIndex + 15] << 8) |
                          decryptedBuffer[bufIndex + 14];

                      ///< [buff[20] << 8 | buff[19]]
                      final LastBolusRate = receivedData / 100;

                      NoticeMsg = '${mContext.l10n.getMoreInfo}:'
                          '${mContext.l10n.activeInsulin}(${ActiveInsulin.toString()})'
                          ',${mContext.l10n.dailyTotalRate}(${DailyTotalRate.toString()})'
                          ',${mContext.l10n.extendedBolusState}($ExtendedBolusState)'
                          ',${mContext.l10n.remainMin}(${RemainMin})'
                          ',${mContext.l10n.remainRate}(${RemainRate.toString()})'
                          ',${mContext.l10n.lastBolusTimeMin}(${LastBolusTime}:${LastBolusMins})'
                          ',${mContext.l10n.lastBolusRate}(${LastBolusRate.toString()})';

                      LogMessageView =
                          '<<Type(0xB2)opCode(0x24)parameters[${NoticeMsg}]';
                      debugPrint('${TAG}kai:Received Notify:$LogMessageView');

                      showNoticeMsgDlg = true;
                      setResponseMessage(RSPType.NOTICE, NoticeMsg, '4');
                      /*
                      setResponseMessage(
                            RSPType.UPDATE_SCREEN, LogMessageView, 'update');
                      */
                      //  notifyListeners();
                    }
                  }
                  break;

                case 0x72:
                  {
                    // Get User Option
                    /*
                    Time Display Type 12[0]/24[1](1) + Button Scroll On/Off(1) + Beep and Alarm(1) + LCD On
                    Time[SEC](1) + Backlight On Time[SEC](1) + Selected Language(1) + Glucose Unit(1) + Shutdown
                    Hour(1) + Low Reservoir Rate(1) + Cannula Volume(2) + Refill Rate(2) + Selectable Language(1*5
                    = 5) + Target Bg(Ideal)(2)
                    Beep On/Off = Beep and Alarm & 0x04
                    Alarm – Beep and Alarm & 0x03 – 0x01 : Sound / 0x02 : Vibration / 0x03 : Both
                    Glucose Unit - mg/dL : 0 / mmol/L : 1
                    Backlight : 0~60
                    Language Code
                    KO : 1 / EN : 2 / CH : 3 / DE : 4 / IL : 5 / IR : 6 / RU : 7 / SP : 8 / TR : 9 / NO : 10 /
                    CZ : 11 / AR : 12 / BE : 13 / SL : 14 / LI : 15 / FR : 16 / SW : 17 / HI : 18 / LA : 19 / NE : 20 /
                    IT : 21 / DM : 22 / HU : 23 / PO : 24 / PT : 25 / GR : 26
                     */

                    // refill rate (2 bytes)
                    // low reservoir rate ( 1)
                    // shutdown hour(1)
                  }
                  break;

                case 0x78:
                  {
                    // get UTC and Time zone response
                    // Year(1) + Month(1) + Day(1) + Hour(1) + Min(1) + Sec(1) + Time zone(1)[Signed]
                    final decryptedBuffer = buffer;
                    // start(2) + length(1) + type(1) + opcode(1) + parameters.length(7) + checksum(2) + end(2)
                    if (decryptedBuffer.length >= 12) {
                      final year = decryptedBuffer[bufIndex + 1].toInt();
                      final month = decryptedBuffer[bufIndex + 2].toInt();
                      final day = decryptedBuffer[bufIndex + 3].toInt();
                      final hours = decryptedBuffer[bufIndex + 4].toInt();
                      final mins = decryptedBuffer[bufIndex + 5].toInt();
                      final secs = decryptedBuffer[bufIndex + 6].toInt();
                      final timeZone = decryptedBuffer[bufIndex + 7].toInt();
                      // update dana-i5 pump time and timezone offset here
                      // timezoneOffset = timeZone;
                      final timedate =
                          DateTime(year, month, day, hours, mins, secs)
                              .millisecondsSinceEpoch;
                      setPumpTimeWithZoneOffset(timedate, timeZone);
                      debugPrint(
                        '${TAG}kai:<<Get Pump UTC and Time zone(${2000 + year}/$month/$day $hours:$mins:$secs timezone($timeZone)',
                      );
                      LogMessageView =
                          '<<Get Pump UTC and Time zone(${2000 + year}/$month/$day $hours:$mins:$secs timezone($timeZone)';
                      NoticeMsg =
                          'Get Pump UTC and Time zone(${2000 + year}/$month/$day $hours:$mins:$secs timezone($timeZone)';
                      showNoticeMsgDlg = true;
                      setResponseMessage(RSPType.NOTICE, NoticeMsg, '3');
                    }
                  }
                  break;

                case 0x79:
                  {
                    // set UTC and timezone
                    // send 0x79 w/ below format
                    // Year(1) + Month(1) + Day(1) + Hour(1) + Min(1) + Sec(1) + Time zone(1)[Signed]
                    // Correcting the UTC time of the pump can cause problems.(History…..)
                    // It is suggested to modify only the Timezone (0x7B)

                    // response 0x00 : OK, 0x01 : Error
                    final decryptedBuffer = buffer;
                    debugPrint(
                      '${TAG}kai:<<Type(0xB2)opCode(0x79)parameters(${decryptedBuffer[bufIndex + 1]})',
                    );
                    LogMessageView =
                        '<<Type(0xB2)opCode(0x79)parameters(${decryptedBuffer[bufIndex + 1]})';
                    if (decryptedBuffer[bufIndex + 1] == 0x00) {
                      NoticeMsg = 'Set Pump UTC and Time zone:OK';
                    } else if (decryptedBuffer[bufIndex + 1] == 0x01) {
                      NoticeMsg = 'Set Pump UTC and Time zone:Error';
                    }
                    showNoticeMsgDlg = true;
                    setResponseMessage(RSPType.NOTICE, NoticeMsg, '3');
                  }
                  break;

                case 0x7A:
                  {
                    // Get Pump Time zone
                    // response Time zone(1)
                    final decryptedBuffer = buffer;
                    debugPrint(
                      '${TAG}kai:<<Type(0xB2)opCode(0x7A)parameters(TimeZone(${decryptedBuffer[bufIndex + 1].toInt()})',
                    );
                    debugPrint(
                      '${TAG}kai: timezoneOffset($timezoneOffset) , received TimeZone(${decryptedBuffer[bufIndex + 1].toInt()})',
                    );
                    LogMessageView =
                        '<<Type(0xB2)opCode(0x7A)parameters(TimeZone(${decryptedBuffer[bufIndex + 1].toInt()})';
                    NoticeMsg =
                        'timezoneOffset($timezoneOffset),received TimeZone(${decryptedBuffer[bufIndex + 1].toInt()})';
                    showNoticeMsgDlg = true;
                    setResponseMessage(RSPType.NOTICE, NoticeMsg, '3');
                  }
                  break;

                case 0x7B:
                  {
                    // Set Pump Time zone response
                    // 0x00 : OK, 0x01 : Error
                    // response 0x00 : OK, 0x01 : Error
                    final decryptedBuffer = buffer;
                    debugPrint(
                      '${TAG}kai:<<Type(0xB2)opCode(0x7B)parameters(${decryptedBuffer[bufIndex + 1]})',
                    );
                    LogMessageView =
                        '<<Type(0xB2)opCode(0x7B)parameters(${decryptedBuffer[bufIndex + 1]})';
                    if (decryptedBuffer[bufIndex + 1] == 0x00) {
                      NoticeMsg = 'Set Pump Time zone:OK';
                    } else if (decryptedBuffer[bufIndex + 1] == 0x01) {
                      NoticeMsg = 'Set Pump Time zone:Error';
                    }
                    showNoticeMsgDlg = true;
                    setResponseMessage(RSPType.NOTICE, NoticeMsg, '3');
                  }
                  break;

                case 0xFF:
                  {
                    final decryptedBuffer = buffer;
                    LogMessageView = '<<${mContext.l10n.keepConnection}(0xff)';
                    debugPrint('${TAG}kai:Received Notify:$LogMessageView');
                    if (USE_PUMPDANA_DEBUGMSG) {
                      setResponseMessage(
                        RSPType.UPDATE_SCREEN,
                        NoticeMsg,
                        'Notify',
                      );
                      /*
                    NoticeMsg = '${mContext.l10n.keepConnection}(0xff)';
                    showNoticeMsgDlg = true;
                    setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
                     */
                    } else {
                      //  notifyListeners();
                    }
                  }
                  break;

                default:
                  debugPrint(
                    '${TAG}kai:Received Notify:Type(0xB2)opCode(0x02)parameters(${toHexString(opCode)})',
                  );
                  LogMessageView =
                      '<<Type(0xB2)opCode(0x02)parameters[${toHexString(opCode)}]';
                  setResponseMessage(
                    RSPType.UPDATE_SCREEN,
                    LogMessageView,
                    'notify',
                  );
                  /*
                  NoticeMsg = LogMessageView;
                  showNoticeMsgDlg = true;
                  setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
                  */
                  break;
              }
            }
          } else if (pkType == 0xC3) {
            // Notify 0xC3 : BleEncryption.DANAR_PACKET__TYPE_NOTIFY
            switch (opCode) {
              case 0x01:
                // Delivery Complete
                // Delivered Insulin Rate(2)
                final receivedValue =
                    (buffer[bufIndex + 2] << 8) | buffer[bufIndex + 1];

                ///< [buff[6] << 8 | buff[5]]
                final receivedDouble = receivedValue / 100;
                debugPrint(
                  '${TAG}kai:Received Notify:Type(0xC3)opCode(0x01)parameters(Delivery Complete:$receivedDouble)',
                );
                LogMessageView =
                    '<<Type(0xC3)opCode(0x01)parameters[0x01:Delivery Complete:$receivedDouble]';
                NoticeMsg = '${mContext.l10n.deliveryComplete}:$receivedDouble';
                showNoticeMsgDlg = true;
                setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
                // need to update insulin delivery here
                //update insulin delivery value here
                setBolusDeliveryValue(receivedDouble);
                setLastBolusDeliveryTime(DateTime.now().millisecondsSinceEpoch);

                isDoseInjectingNow = false;
                //kai_20230506 let's notify SendSetDose processing result to the caller here
                setResponseMessage(
                  RSPType.PROCESSING_DONE,
                  '${mContext.l10n.deliveredInsulin}($receivedDouble)',
                  HCL_BOLUS_RSP_SUCCESS,
                );

                //let's send command 0x02(init screen info) into dana-i5 to refresh dana-i5 the information on setting page.
                // List<int> param = [ 0x02];
                Future.delayed(
                  const Duration(seconds: 1),
                  () async {
                    sendBolusCommand(0x02, null);
                  },
                );

                //let's send 0x24 get more info command to Dana-i5 in order to update dana-i5 information on cloudLoop
                if (USE_PUMPDANA_DEBUGMSG) {
                  Future.delayed(
                    const Duration(seconds: 1),
                    () async {
                      sendBolusCommand(0x24, null);
                    },
                  );
                }

                break;

              case 0x02:
                // Delivery Rate Display
                // Delivery Insulin Rate(2)
                final receivedValue =
                    (buffer[bufIndex + 2] << 8) | buffer[bufIndex + 1];

                ///< [buff[6] << 8 | buff[5]]
                final receivedDouble = receivedValue / 100;
                debugPrint(
                  '${TAG}kai:Received Notify:Type(0xC3)opCode(0x02)parameters(Delivery Rate Display:$receivedDouble)',
                );
                LogMessageView =
                    '<<Type(0xC3)opCode(0x01)parameters[0x02:Delivery Rate Display:$receivedDouble]';
                if (USE_PUMPDANA_DEBUGMSG) {
                  NoticeMsg =
                      '${mContext.l10n.deliveryRateDisplay}:$receivedDouble';
                  showNoticeMsgDlg = true;
                  setResponseMessage(RSPType.NOTICE, NoticeMsg, '2');
                } else {}

                break;
              case 0x03:
                debugPrint(
                  '${TAG}kai:Received Notify:Type(0xC3)opCode(0x03)parameters(Alarm: ',
                );
                // Alarm Code(2)
                // 0x01:Battery 0% Alarm / 0x02:Pump Error / 0x03:Occlusion / 0x04:LOW BATTERY /
                // 0x05:Shutdown / 0x06:Basal Compare / 0x07 Glucose Check / 0x08 Low Reservoir /
                // 0x09 Empty Reservoir / 0x0A Shaft Check
                final status =
                    buffer[bufIndex + 1]; // bufIndex = 4 opCode position,
                // response Status position is bufIndex = 1 => 5
                // need to send a message to show warning pop up here
                switch (status) {
                  case 0x01:
                    final batlevel = buffer[bufIndex + 2];
                    //update Battery level here
                    Battery = batlevel.toString();

                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x01) Battery $batlevel% Alarm',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x01:Battery $batlevel% Alarm]';
                    /*
                    WarningMsg = 'Battery $batlevel% Alarm';
                    showWarningMsgDlg = true;
                    setResponseMessage(
                        RSPType.WARNING, WarningMsg, PATCH_WARNING_RPT);
                     */
                    AlertMsg =
                        '${mContext.l10n.battery} $batlevel% ${mContext.l10n.alarm}';
                    showALertMsgDlg = true;
                    setResponseMessage(
                      RSPType.ALERT,
                      AlertMsg,
                      PATCH_ALERT_RPT,
                    );
                    break;
                  case 0x02:
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x02) Pump Error',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x02:Pump Error]';
                    WarningMsg = '${mContext.l10n.pumpError}';
                    showWarningMsgDlg = true;
                    setResponseMessage(
                      RSPType.WARNING,
                      WarningMsg,
                      PATCH_WARNING_RPT,
                    );
                    break;
                  case 0x03:
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x03) Occlusion',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x03:Occlusion]';
                    WarningMsg = '${mContext.l10n.occlusionAlert}';
                    showWarningMsgDlg = true;
                    setResponseMessage(
                      RSPType.WARNING,
                      WarningMsg,
                      PATCH_WARNING_RPT,
                    );
                    break;
                  case 0x04:
                    SetUpWizardMsg = 'LOW BATTERY';
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x04) LOW BATTERY',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x04:LOW BATTERY]';
                    /*
                    SetUpWizardActionType = 'SAFETY_CHECK_RSP_LOW_VOLTAGE';
                    showSetUpWizardMsgDlg = true;
                    setResponseMessage(RSPType.SETUP_DLG, SetUpWizardMsg,
                        SAFETY_CHECK_RSP_LOW_VOLTAGE);
                     */
                    AlertMsg = '${mContext.l10n.lowBattery}';
                    showALertMsgDlg = true;
                    setResponseMessage(
                      RSPType.ALERT,
                      AlertMsg,
                      PATCH_ALERT_RPT,
                    );
                    break;
                  case 0x05:
                    SetUpWizardMsg = 'Shutdown';
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x05) Shutdown',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x05:Shutdown]';
                    /*
                    SetUpWizardActionType = 'PATCH_DISCARD_RSP_FAILED';
                    showSetUpWizardMsgDlg = true;
                    setResponseMessage(RSPType.SETUP_DLG, SetUpWizardMsg,
                        PATCH_DISCARD_RSP_FAILED);
                     */
                    WarningMsg = SetUpWizardMsg;
                    showWarningMsgDlg = true;
                    setResponseMessage(
                      RSPType.WARNING,
                      WarningMsg,
                      PATCH_WARNING_RPT,
                    );
                    break;
                  case 0x06:
                    SetUpWizardMsg = '${mContext.l10n.basalCompare}';
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x06) Basal Compare',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x06:Basal Compare]';
                    /*
                    SetUpWizardActionType = 'HCL_BOLUS_RSP_FAILED';
                    showSetUpWizardMsgDlg = true;
                    setResponseMessage(RSPType.SETUP_DLG, SetUpWizardMsg,
                        HCL_BOLUS_RSP_FAILED);
                    */
                    AlertMsg = SetUpWizardMsg;
                    showALertMsgDlg = true;
                    setResponseMessage(
                      RSPType.ALERT,
                      AlertMsg,
                      PATCH_ALERT_RPT,
                    );
                    break;
                  case 0x07:
                    SetUpWizardMsg = '${mContext.l10n.glucoseCheck}';
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x07) Glucose Check',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x07:Glucose Check]';
                    /*
                    SetUpWizardActionType = 'HCL_BOLUS_RSP_FAILED';
                    showSetUpWizardMsgDlg = true;
                    setResponseMessage(RSPType.SETUP_DLG, SetUpWizardMsg,
                        HCL_BOLUS_RSP_FAILED);
                    */
                    AlertMsg = SetUpWizardMsg;
                    showALertMsgDlg = true;
                    setResponseMessage(
                      RSPType.ALERT,
                      AlertMsg,
                      PATCH_ALERT_RPT,
                    );
                    break;
                  case 0x08:
                    SetUpWizardMsg = '${mContext.l10n.lowReservoir}';
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x08) Low Reservoir',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x08:Low Reservoir]';
                    AlertMsg = SetUpWizardMsg;
                    showALertMsgDlg = true;
                    setResponseMessage(
                      RSPType.ALERT,
                      AlertMsg,
                      PATCH_ALERT_RPT,
                    );
                    break;
                  case 0x09:
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x09) Empty Reservoir',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x09:Empty Reservoir]';
                    WarningMsg = '${mContext.l10n.emptyReservoir}';
                    showWarningMsgDlg = true;
                    setResponseMessage(
                      RSPType.WARNING,
                      WarningMsg,
                      PATCH_WARNING_RPT,
                    );
                    break;
                  case 0x0A:
                    SetUpWizardMsg = '${mContext.l10n.shaftCheck}';
                    debugPrint(
                      '${TAG}kai:Type(0xC3)opCode(0x01)parameters(0x0A) Shaft Check',
                    );
                    LogMessageView =
                        '<<Type(0xC3)opCode(0x01)parameters[0x0A:Shaft Check]';
                    SetUpWizardActionType = 'SAFETY_CHECK_RSP_FAILED';
                    showSetUpWizardMsgDlg = true;
                    setResponseMessage(
                      RSPType.SETUP_DLG,
                      SetUpWizardMsg,
                      SAFETY_CHECK_RSP_FAILED,
                    );
                    break;
                }

                break;
              case 0x04:
                debugPrint(
                  '${TAG}kai:Received Notify:Type(0xC3)opCode(0x04)parameters() Missed Bolus Alarm',
                );
                LogMessageView =
                    '<<Type(0xC3)opCode(0x04)parameters[Missed Bolus Alarm]';
                SetUpWizardMsg = '${mContext.l10n.missedBolusAlarm}';
                SetUpWizardActionType = 'HCL_BOLUS_RSP_FAILED';
                showSetUpWizardMsgDlg = true;
                setResponseMessage(
                  RSPType.SETUP_DLG,
                  SetUpWizardMsg,
                  HCL_BOLUS_RSP_FAILED,
                );
                // Missed Bolus Alarm
                // Missed Bolus Start Hour(1)+Min(1)+End Hour(1)+Min(1)
                break;
            }
          }

          //kai_20240111 let's clear handled readbuffer here
          debugPrint(
            '${TAG}kai:clear readBuffer , set bufferLength($bufferLength) as 0, packetIsValid($packetIsValid)',
          );
          /*
          bufferLength = 0;
          readBuffer = List<int>.filled(1024, 0); // 1024 크기의 빈 버퍼로 초기화
           */
        } else {
          debugPrint(
            '${TAG}kai:Fail to decryptedPacket = PacketEncryptionDecryption:bufferLength($bufferLength):Error',
          );
        }

        packetIsValid = false;
        //kai_20240105 in case of receiving Notify sent from Dana-i w/o previous sent command from CloudLoop
        // if encryptionType is '1' then invalid decryption could be proceed and can't handle the incoming notification continuously
        // let's block below
        // encryptionType = 1; ///< default '1'

        //if bufferLength is lower than 6( minimum packet size )
        //stop parsing
        if (bufferLength < 6) {
          isProcessing = false;
        }
      } else {
        //if packet is invalid then stop parsing
        isProcessing = false;
      }
    } //while(isProcessing)

    debugPrint('${TAG}kai:leave handleDanaiPump():bufferLength($bufferLength)');
  }

  //overwrite interface for connect/disconnect of ble device. here
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

      debugPrint('${TAG}kai: call device.connect(autoConnect: false)'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

      if (USE_AUTO_CONNECTION == true) {
        await device.connect();
      } else {
        await device.connect(autoConnect: false);
      }

      if (USE_CHECK_PAIRED_DEV == true) {
        // 기기의 본딩 상태 확인
        var isBonded = (await mPumpflutterBlue.bondedDevices).contains(device);

        debugPrint('${TAG}kai: isbonded($isBonded)'
            ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');

        if (!isBonded) {
          // 기기가 본딩되어 있지 않으면 대기 (타임아웃 설정)
          var secondsWaited = 0;
          // 기기가 본딩되어 있지 않으면 대기
          while (!isBonded && secondsWaited < 30) {
            debugPrint(
              '${TAG}kai:Waiting for bonding...Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
            );
            await Future<void>.delayed(Duration(seconds: 1));
            // 다시 본딩 상태 확인
            isBonded = (await mPumpflutterBlue.bondedDevices).contains(device);
            secondsWaited++;
          }

          if (!isBonded) {
            debugPrint('${TAG}kai:Timeout waiting for bonding.'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
            // 타임아웃 처리 또는 알림
            return;
          } else {
            debugPrint('${TAG}kai: bonding is done.'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
          }
        }
      }

      final danaIservice = await device.discoverServices();
      ConnectedDevice = device;
      ConnectionStatus = BluetoothDeviceState.connected;
      ConnectedTime = DateTime.now().millisecondsSinceEpoch;
      //let's find RX/TX characteristic here
      var findCharacteristic = 0;

      ///< clear
      for (final service in danaIservice) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              mTX_WRITE_UUID.toLowerCase()) {
            findCharacteristic = findCharacteristic + 1;
            PumpTxCharacteristic = characteristic;
          } else if (characteristic.uuid.toString().toLowerCase() ==
              mRX_READ_UUID.toLowerCase()) {
            findCharacteristic = findCharacteristic + 1;
            PumpRxCharacteristic = characteristic;
          } else if (characteristic.uuid.toString().toLowerCase() ==
              mRX_READ_BATTERY_UUID.toLowerCase()) {
            findCharacteristic = findCharacteristic + 1;
            PumpRXBatLvlCharacteristic = characteristic;
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
        if (pumpRxCharacteristic!.properties.notify &&
            pumpRxCharacteristic!.descriptors.isNotEmpty) {
          if (!pumpRxCharacteristic!.isNotifying) {
            try {
              //kai_20240121let's consider set retry after delay here
              if (isSetNotifyFailed == true) {
                if (USE_CHECK_CONNECTION_STATUS) {
                  await Future<void>.delayed(const Duration(milliseconds: 500),
                      () async {
                    debugPrint(
                      '$TAG:kai: 2nd call pumpRxCharacteristic!.setNotifyValue(true)'
                      ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                    );

                    await pumpRxCharacteristic!.setNotifyValue(true);
                    isSetNotifyFailed = false;
                    debugPrint(
                      '$TAG:kai: complete 2nd call pumpRxCharacteristic!.setNotifyValue(false)'
                      ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                    );
                  });
                } else {
                  await pumpRxCharacteristic!.setNotifyValue(true);
                  isSetNotifyFailed = false;
                  debugPrint(
                    '$TAG:kai: complete 2nd call pumpRxCharacteristic!.setNotifyValue(false)'
                    ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
                  );
                }
              } else {
                await pumpRxCharacteristic!.setNotifyValue(true);
                isSetNotifyFailed = false;
              }
            } catch (e) {
              isSetNotifyFailed = true;
              debugPrint(
                '$TAG:kai:pumpRxCharacteristic notify set error: uuid =  ${pumpRxCharacteristic!.uuid} $e'
                ':isSetNotifyFailed($isSetNotifyFailed)'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})',
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

        if (USE_DANAI_CHECK_CONNECTION_COMMAND_SENT) {
          if (onRetrying == false) {
            //reset the flag here first
            issendPumpCheckAfterConnectFailed = 0;

            //let's set timeout count
            if (USE_CHECK_CONNECTION_STATUS) {
              final MaxWaitCnt = 50;

              /// 5secs
              var waitCnt = 0;
              while (ConnectionStatus != BluetoothDeviceState.connected) {
                waitCnt++;
                debugPrint(
                    '${TAG}kai::wait($waitCnt) for that mCMgr.mPump!.ConnectionStatus is goning to ${ConnectionStatus}'
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
                '${TAG}kai:onRetrying(false):call sendPumpCheckAfterConnect()'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
            sendPumpCheckAfterConnect();
          } else {
            debugPrint(
                '${TAG}kai::onRetrying(true) skip call sendPumpCheckAfterConnect()'
                ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
          }
        }
      }
    } catch (e) {
      debugPrint('${TAG}kai:Error connecting to device: $e'
          ':Time(${DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now())})');
    }
  }
}

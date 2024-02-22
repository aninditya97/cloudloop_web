import 'package:flutter/material.dart';
import 'dart:typed_data';

class BleEncryption {
  late BuildContext context;
  BleEncryption({required this.context});

  static const int DANAR_PACKET__TYPE_ENCRYPTION_REQUEST = 0x01;
  static const int DANAR_PACKET__TYPE_ENCRYPTION_RESPONSE = 0x02;///< encryption response
  static const int DANAR_PACKET__TYPE_COMMAND = 0xA1;
  static const int DANAR_PACKET__TYPE_RESPONSE = 0xB2;
  static const int DANAR_PACKET__TYPE_NOTIFY = 0xC3;

  static const int DANAR_PACKET__OPCODE_ENCRYPTION__PUMP_CHECK = 0x00;  ///< connect command ( app => dana-i )
  static const int DANAR_PACKET__OPCODE_ENCRYPTION__TIME_INFORMATION = 0x01;
  static const int DANAI_PACKET__OPCODE_ENCRYPTION__START_ENCRYPTION = 0x01; ///< start encryption command ( app => dana-i )
  static const int DANAR_PACKET__OPCODE_ENCRYPTION__CHECK_PASSKEY = 0xD0;
  static const int DANAR_PACKET__OPCODE_ENCRYPTION__PASSKEY_REQUEST = 0xD1;
  static const int DANAR_PACKET__OPCODE_ENCRYPTION__PASSKEY_RETURN = 0xD2;
  // Easy Mode
  static const int DANAR_PACKET__OPCODE_ENCRYPTION__GET_PUMP_CHECK = 0xF3;
  static const int DANAR_PACKET__OPCODE_ENCRYPTION__GET_EASYMENU_CHECK = 0xF4;

  static const int DANAR_PACKET__OPCODE_NOTIFY__DELIVERY_COMPLETE = 0x01;
  static const int DANAR_PACKET__OPCODE_NOTIFY__DELIVERY_RATE_DISPLAY = 0x02;
  static const int DANAR_PACKET__OPCODE_NOTIFY__ALARM = 0x03;
  static const int DANAR_PACKET__OPCODE_NOTIFY__MISSED_BOLUS_ALARM = 0x04;

  static const int DANAR_PACKET__OPCODE_REVIEW__INITIAL_SCREEN_INFORMATION = 0x02;
  static const int DANAR_PACKET__OPCODE_REVIEW__DELIVERY_STATUS = 0x03;
  static const int DANAR_PACKET__OPCODE_REVIEW__GET_PASSWORD = 0x04;

  static const int DANAR_PACKET__OPCODE_REVIEW__BOLUS_AVG = 0x10;
  static const int DANAR_PACKET__OPCODE_REVIEW__BOLUS = 0x11;
  static const int DANAR_PACKET__OPCODE_REVIEW__DAILY = 0x12;
  static const int DANAR_PACKET__OPCODE_REVIEW__PRIME = 0x13;
  static const int DANAR_PACKET__OPCODE_REVIEW__REFILL = 0x14;
  static const int DANAR_PACKET__OPCODE_REVIEW__BLOOD_GLUCOSE = 0x15;
  static const int DANAR_PACKET__OPCODE_REVIEW__CARBOHYDRATE = 0x16;
  static const int DANAR_PACKET__OPCODE_REVIEW__TEMPORARY = 0x17;
  static const int DANAR_PACKET__OPCODE_REVIEW__SUSPEND = 0x18;
  static const int DANAR_PACKET__OPCODE_REVIEW__ALARM = 0x19;
  static const int DANAR_PACKET__OPCODE_REVIEW__BASAL = 0x1A;
  static const int DANAR_PACKET__OPCODE_REVIEW__ALL_HISTORY = 0x1F;
  static const int DANAR_PACKET__OPCODE_REVIEW__GET_SHIPPING_INFORMATION = 0x20;
  static const int DANAR_PACKET__OPCODE_REVIEW__GET_PUMP_CHECK = 0x21;
  static const int DANAR_PACKET__OPCODE_REVIEW__GET_USER_TIME_CHANGE_FLAG = 0x22;
  static const int DANAR_PACKET__OPCODE_REVIEW__SET_USER_TIME_CHANGE_FLAG_CLEAR = 0x23;
  static const int DANAR_PACKET__OPCODE_REVIEW__GET_MORE_INFORMATION = 0x24;
  static const int DANAR_PACKET__OPCODE_REVIEW__SET_HISTORY_UPLOAD_MODE = 0x25;
  static const int DANAR_PACKET__OPCODE_REVIEW__GET_TODAY_DELIVERY_TOTAL = 0x26;

  static const int DANAR_PACKET__OPCODE_BOLUS__GET_STEP_BOLUS_INFORMATION = 0x40;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_EXTENDED_BOLUS_STATE = 0x41;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_EXTENDED_BOLUS = 0x42;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_DUAL_BOLUS = 0x43;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_STEP_BOLUS_STOP = 0x44;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_CARBOHYDRATE_CALCULATION_INFORMATION = 0x45;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_EXTENDED_MENU_OPTION_STATE = 0x46;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_EXTENDED_BOLUS = 0x47;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_DUAL_BOLUS = 0x48;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_EXTENDED_BOLUS_CANCEL = 0x49;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_STEP_BOLUS_START = 0x4A;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_CALCULATION_INFORMATION = 0x4B;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_BOLUS_RATE = 0x4C;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_BOLUS_RATE = 0x4D;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_CIR_CF_ARRAY = 0x4E;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_CIR_CF_ARRAY = 0x4F;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_BOLUS_OPTION = 0x50;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_BOLUS_OPTION = 0x51;
  static const int DANAR_PACKET__OPCODE_BOLUS__GET_24_CIR_CF_ARRAY = 0x52;
  static const int DANAR_PACKET__OPCODE_BOLUS__SET_24_CIR_CF_ARRAY = 0x53;

  static const int DANAR_PACKET__OPCODE_BASAL__SET_TEMPORARY_BASAL = 0x60;
  static const int DANAR_PACKET__OPCODE_BASAL__TEMPORARY_BASAL_STATE = 0x61;
  static const int DANAR_PACKET__OPCODE_BASAL__CANCEL_TEMPORARY_BASAL = 0x62;
  static const int DANAR_PACKET__OPCODE_BASAL__GET_PROFILE_NUMBER = 0x63;

  static const int DANAR_PACKET__OPCODE_BASAL__SET_PROFILE_NUMBER = 0x64;
  static const int DANAR_PACKET__OPCODE_BASAL__GET_PROFILE_BASAL_RATE = 0x65;
  static const int DANAR_PACKET__OPCODE_BASAL__SET_PROFILE_BASAL_RATE = 0x66;
  static const int DANAR_PACKET__OPCODE_BASAL__GET_BASAL_RATE = 0x67;
  static const int DANAR_PACKET__OPCODE_BASAL__SET_BASAL_RATE = 0x68;
  static const int DANAR_PACKET__OPCODE_BASAL__SET_SUSPEND_ON = 0x69;
  static const int DANAR_PACKET__OPCODE_BASAL__SET_SUSPEND_OFF = 0x6A;

  static const int DANAR_PACKET__OPCODE_OPTION__GET_PUMP_TIME = 0x70;
  static const int DANAR_PACKET__OPCODE_OPTION__SET_PUMP_TIME = 0x71;
  static const int DANAR_PACKET__OPCODE_OPTION__GET_USER_OPTION = 0x72;
  static const int DANAR_PACKET__OPCODE_OPTION__SET_USER_OPTION = 0x73;

  static const int DANAR_PACKET__OPCODE_BASAL__APS_SET_TEMPORARY_BASAL = 0xC1;
  static const int DANAR_PACKET__OPCODE__APS_HISTORY_EVENTS = 0xC2;
  static const int DANAR_PACKET__OPCODE__APS_SET_EVENT_HISTORY = 0xC3;

  // v3 specific
  static const int DANAR_PACKET__OPCODE_REVIEW__GET_PUMP_DEC_RATIO = 0x80;
  static const int DANAR_PACKET__OPCODE_GENERAL__GET_SHIPPING_VERSION = 0x81;

  // Easy Mode
  static const int DANAR_PACKET__OPCODE_OPTION__GET_EASY_MENU_OPTION = 0x74;
  static const int DANAR_PACKET__OPCODE_OPTION__SET_EASY_MENU_OPTION = 0x75;
  static const int DANAR_PACKET__OPCODE_OPTION__GET_EASY_MENU_STATUS = 0x76;
  static const int DANAR_PACKET__OPCODE_OPTION__SET_EASY_MENU_STATUS = 0x77;
  static const int DANAR_PACKET__OPCODE_OPTION__GET_PUMP_UTC_AND_TIME_ZONE = 0x78;
  static const int DANAR_PACKET__OPCODE_OPTION__SET_PUMP_UTC_AND_TIME_ZONE = 0x79;
  static const int DANAR_PACKET__OPCODE_OPTION__GET_PUMP_TIME_ZONE = 0x7A;
  static const int DANAR_PACKET__OPCODE_OPTION__SET_PUMP_TIME_ZONE = 0x7B;

  static const int DANAR_PACKET__OPCODE_ETC__SET_HISTORY_SAVE = 0xE0;
  static const int DANAR_PACKET__OPCODE_ETC__KEEP_CONNECTION = 0xFF;


  /* Usage
    // Shipping Serial을 기반으로 Device Key 생성
    String shippingSerial = "AAA00000AA";
    List<String> deviceKey = makeDeviceKey(shippingSerial);

    // 암호화할 데이터
    String dataToEncrypt = "TypeOpCodeParametersChecksum"; // 예시 데이터

    // 암호화 진행
    String encryptedData = encryptData(dataToEncrypt, deviceKey);
    print('Encrypted Data: $encryptedData');
 */
  // 주어진 Shipping Serial을 기반으로 Device Key를 생성하는 함수
  List<String> makeDeviceKey(String shippingSerial) {
    List<String> deviceKey = [
      shippingSerial[0], shippingSerial[1], shippingSerial[2], // Encryption Serial No [0]
      shippingSerial.substring(3, 8), // Encryption Serial No [1]
      shippingSerial[8], shippingSerial[9], // Encryption Serial No [2]
    ];
    return deviceKey;
  }

// 주어진 데이터를 주어진 Encryption Serial No와 XOR 연산을 수행하여 암호화하는 함수
  String encryptData(String data, List<String> encryptionSerial) {
    List<int> encrypted = [];
    for (int i = 0; i < data.length; i++) {
      encrypted.add(data.codeUnitAt(i) ^ encryptionSerial[i % 3].codeUnitAt(i % 3));
    }
    return String.fromCharCodes(encrypted);
  }




  //connected device.name = devicename
  Uint8List getEncryptedPacket(int opcode, Uint8List bytes, String deviceName) {
    // return encryptPacketJni(context, opcode, bytes, deviceName);
    String shippingSerial = "AAA00000AA";
    List<String> deviceKey = makeDeviceKey(shippingSerial);


    return Uint8List(0); // Placeholder for returning encrypted data
  }

  Uint8List getDecryptedPacket(Uint8List bytes) {
    // return decryptPacketJni(context, bytes);
    // Uncomment the line above once the decryptPacketJni function is available in Dart.
    // Ensure to modify the return type to match the expected Uint8List data type.
    // Shipping Serial을 기반으로 Device Key 생성


    return Uint8List(0); // Placeholder for returning decrypted data
  }

  void setPairingKeys(Uint8List pairingKey, Uint8List randomPairingKey, int randomSyncKey) {
    // setPairingKeysJni(pairingKey, randomPairingKey, randomSyncKey);
    // Uncomment the line above once the setPairingKeysJni function is available in Dart.
  }

  void setBle5Key(Uint8List ble5Key) {
    // setBle5KeyJni(ble5Key);
    // Uncomment the line above once the setBle5KeyJni function is available in Dart.
  }

  void setEnhancedEncryption(int securityVersion) {
    // setEnhancedEncryptionJni(securityVersion);
    // Uncomment the line above once the setEnhancedEncryptionJni function is available in Dart.
  }

  Uint8List encryptSecondLevelPacket(Uint8List bytes) {
    // return encryptSecondLevelPacketJni(context, bytes);
    // Uncomment the line above once the encryptSecondLevelPacketJni function is available in Dart.
    return Uint8List(0); // Placeholder for returning encrypted data
  }

  Uint8List decryptSecondLevelPacket(Uint8List bytes) {
    // return decryptSecondLevelPacketJni(context, bytes);
    // Uncomment the line above once the decryptSecondLevelPacketJni function is available in Dart.
    return Uint8List(0); // Placeholder for returning decrypted data
  }
}






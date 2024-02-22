import 'dart:convert';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/danai/BleEncryption.dart';
import 'package:flutter/material.dart';

class DanaRSPacket {
  late BuildContext mContext;
  bool isReceived = false;
  bool failed = false;
  int type = BleEncryption.DANAR_PACKET__TYPE_RESPONSE;
  int opCode = 0;

  DanaRSPacket(this.mContext){
    init();
  }

  bool success() => !failed;

  void setReceived() {
    isReceived = true;
  }

  int get command => (type & 0xFF << 8) + (opCode & 0xFF);

  List<int> getRequestParams() => List<int>.filled(0, 0);

  int getCommand(List<int> data) {
    int type = byteArrayToInt(getBytes(data, TYPE_START, 1));
    int opCode = byteArrayToInt(getBytes(data, OPCODE_START, 1));
    return (type & 0xFF << 8) + (opCode & 0xFF);
  }

  void handleMessage(List<int> data) {}
  void handleMessageNotReceived() {
    failed = true;
  }

  String get friendlyName => 'UNKNOWN_PACKET';

  List<int> getBytes(List<int> data, int srcStart, int srcLength) {
    List<int> ret = List<int>.filled(srcLength, 0);
    ret.setRange(0, srcLength, data.sublist(srcStart, srcStart + srcLength));
    return ret;
  }

  int dateFromBuff(List<int> buff, int offset) {
    DateTime date = DateTime(
      2000 + byteArrayToInt(getBytes(buff, offset, 1)),
      byteArrayToInt(getBytes(buff, offset + 1, 1)),
      byteArrayToInt(getBytes(buff, offset + 2, 1)),
      0,
      0,
    );
    return date.millisecondsSinceEpoch;
  }

  int byteArrayToInt(List<int> b) {
    switch (b.length) {
      case 1:
        return b[0] & 0xFF;
      case 2:
        return ((b[1] & 0xFF) << 8) + (b[0] & 0xFF);
      case 3:
        return ((b[2] & 0xFF) << 16) + ((b[1] & 0xFF) << 8) + (b[0] & 0xFF);
      case 4:
        return ((b[3] & 0xFF) << 24) +
            ((b[2] & 0xFF) << 16) +
            ((b[1] & 0xFF) << 8) +
            (b[0] & 0xFF);
      default:
        return -1;
    }
  }

  int dateTimeSecFromBuff(List<int> buff, int offset) {
    try {
      DateTime date = DateTime(
        2000 + intFromBuff(buff, offset, 1),
        intFromBuff(buff, offset + 1, 1),
        intFromBuff(buff, offset + 2, 1),
        intFromBuff(buff, offset + 3, 1),
        intFromBuff(buff, offset + 4, 1),
        intFromBuff(buff, offset + 5, 1),
      );
      return date.millisecondsSinceEpoch;
    } on Exception catch (e) {
      // expect
      DateTime date = DateTime(
        2000 + intFromBuff(buff, offset, 1),
        intFromBuff(buff, offset + 1, 1),
        intFromBuff(buff, offset + 2, 1),
        intFromBuff(buff, offset + 3, 1) + 1,
        intFromBuff(buff, offset + 4, 1),
        intFromBuff(buff, offset + 5, 1),
      );
      return date.millisecondsSinceEpoch;
    }
  }

  int intFromBuff(List<int> b, int srcStart, int srcLength) {
    switch (srcLength) {
      case 1:
        return b[DATA_START + srcStart + 0] & 0xFF;
      case 2:
        return ((b[DATA_START + srcStart + 1] & 0xFF) << 8) +
            (b[DATA_START + srcStart + 0] & 0xFF);
      case 3:
        return ((b[DATA_START + srcStart + 2] & 0xFF) << 16) +
            ((b[DATA_START + srcStart + 1] & 0xFF) << 8) +
            (b[DATA_START + srcStart + 0] & 0xFF);
      case 4:
        return ((b[DATA_START + srcStart + 3] & 0xFF) << 24) +
            ((b[DATA_START + srcStart + 2] & 0xFF) << 16) +
            ((b[DATA_START + srcStart + 1] & 0xFF) << 8) +
            (b[DATA_START + srcStart + 0] & 0xFF);
      default:
        return -1;
    }
  }

  int intFromBuffMsbLsb(List<int> b, int srcStart, int srcLength) {
    switch (srcLength) {
      case 1:
        return b[DATA_START + srcStart] & 0xFF;
      case 2:
        return ((b[DATA_START + srcStart] & 0xFF) << 8) +
            (b[DATA_START + srcStart + 1] & 0xFF);
      case 3:
        return ((b[DATA_START + srcStart] & 0xFF) << 16) +
            ((b[DATA_START + srcStart + 1] & 0xFF) << 8) +
            (b[DATA_START + srcStart + 2] & 0xFF);
      case 4:
        return ((b[DATA_START + srcStart] & 0xFF) << 24) +
            ((b[DATA_START + srcStart + 1] & 0xFF) << 16) +
            ((b[DATA_START + srcStart + 2] & 0xFF) << 8) +
            (b[DATA_START + srcStart + 3] & 0xFF);
      default:
        return -1;
    }
  }

  String stringFromBuff(List<int> buff, int offset, int length) {
    List<int> stringBuff =
    List<int>.from(buff.sublist(offset, offset + length));
    return utf8.decode(stringBuff);
  }

  static const int TYPE_START = 0;
  static const int OPCODE_START = 1;
  static const int DATA_START = 2;

  static String asciiStringFromBuff(
      List<int> buff, int offset, int length) {
    List<int> stringBuff =
    List<int>.from(buff.sublist(offset, offset + length));
    return utf8.decode(stringBuff);
  }

  static String toHexString(List<int>? buff) {
    if (buff == null) return 'null';
    StringBuffer sb = StringBuffer();
    for (int count = 0; count < buff.length; count++) {
      sb.write('${buff[count].toRadixString(16).padLeft(2, '0')} ');
      if ((count + 1) % 4 == 0) sb.write(' ');
    }
    return sb.toString();
  }

  static final List<String> hexArray = '0123456789ABCDEF'.split('');

  static String bytesToHex(List<int> bytes) {
    List<String> hexChars = List<String>.filled(bytes.length * 2, '');
    for (int j = 0; j < bytes.length; j++) {
      int v = bytes[j] & 0xFF;
      hexChars[j * 2] = hexArray[v >> 4];
      hexChars[j * 2 + 1] = hexArray[v & 0x0F];
    }
    return hexChars.join('');
  }

  static List<int> hexToBytes(String s) {
    int len = s.length;
    List<int> data = List<int>.filled(len ~/ 2, 0);
    int i = 0;
    while (i < len) {
      data[i ~/ 2] =
          ((int.parse(s[i], radix: 16) << 4) + int.parse(s[i + 1], radix: 16))
              .toSigned(8);
      i += 2;
    }
    return data;
  }

  void init() {
    //injector.androidInjector().inject(this);
  }
}

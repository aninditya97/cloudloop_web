import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import 'BleEncryption.dart';
import 'DanaRSPacket.dart';

class DanaRSPacketEtcKeepConnection extends DanaRSPacket {
  // TODO: Add HasAndroidInjector dependency

  //late Uint8List data; // For handling data
  DanaRSPacketEtcKeepConnection(super.mContext) {
    // TODO: Initialize HasAndroidInjector
    // injector = HasAndroidInjector();
    opCode = BleEncryption.DANAR_PACKET__OPCODE_ETC__KEEP_CONNECTION;
    debugPrint("kai:New message");
  }


  @override
  void handleMessage(List<int> data) {
    int result = intFromBuff(data, 0, 1);
    if (result == 0) {
      debugPrint( "kai:Result OK");
      failed = false;
    } else {
      debugPrint("kai:Result Error: $result");
      failed = true;
    }
  }

  String friendlyName = "ETC__KEEP_CONNECTION";
}

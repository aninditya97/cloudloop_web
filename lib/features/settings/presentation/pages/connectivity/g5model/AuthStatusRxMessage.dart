import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:flutter/cupertino.dart';

class AuthStatusRxMessage extends BaseMessage {
  AuthStatusRxMessage(Uint8List packet) {
    if (packet.length >= 3) {
      if (packet[0] == opcode) {
        data = packet.buffer;
        final _data = ByteData.view(packet.buffer);
        authenticated = _data.getInt8(1);
        bonded = _data.getInt8(2);
        debugPrint(
          'AuthRequestRxMessage:  authenticated:$authenticated  bonded:$bonded',
        );
      }
    }
  }
  static const int opcode = 0x5;
  late int authenticated;
  late int bonded;

  bool get isAuthenticated => authenticated == 1;
  bool get isBonded => bonded == 1;
}

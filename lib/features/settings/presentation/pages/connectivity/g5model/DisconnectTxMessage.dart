import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:flutter/cupertino.dart';

class DisconnectTxMessage extends BaseMessage {
  DisconnectTxMessage() {
    final data = Uint8List(1);
    data[0] = opcode;

    byteSequence = data;
    debugPrint('${TAG}DisconnectTX: $byteSequence');
  }
  static const int opcode = 0x09;
  static const String TAG = 'DisconnectTxMessage';
}

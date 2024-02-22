import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/Extensions.dart';
import 'package:flutter/cupertino.dart';

class KeepAliveTxMessage extends BaseMessage {
  KeepAliveTxMessage(this.time) {
    data = Uint8List(2).buffer;
    data.asByteData().setUint8(0, opcode);
    data.asByteData().setUint8(1, time);
    data.asUint8List();

    debugPrint('${TAG}New KeepAliveRequestTxMessage: '
        '${Extensions.bytesToHex(byteSequence)}');
  }
  static const int opcode = 0x06;
  late int time;

  static const String TAG = 'KeepAliveTxMessage';
}

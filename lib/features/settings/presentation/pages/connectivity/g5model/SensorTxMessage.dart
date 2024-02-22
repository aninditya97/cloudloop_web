import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/CRC.dart';
import 'package:flutter/cupertino.dart';

class SensorTxMessage extends BaseMessage {
  SensorTxMessage() {
    final data = Uint8List.fromList([opcode, ...crc]);

    //init(data);
    byteSequence = data.buffer.asUint8List();
    debugPrint('SensorTx dbg: $byteSequence');
  }
  static const int opcode = 0x2e;
  List<int> crc = CRC.calculate(opcode);
}

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:flutter/cupertino.dart';

class BatteryInfoTxMessage extends BaseMessage {
  BatteryInfoTxMessage() {
    init(opcode, 3);
    debugPrint('${TAG}BatteryInfoTx dbg: $byteSequence');
  }

  static const String TAG = 'BatteryInfoTxMessage';
  static const int opcode = 0x22;
}

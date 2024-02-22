import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:flutter/cupertino.dart';

class GlucoseTxMessage extends BaseMessage {
  GlucoseTxMessage() {
    init(opcode, 3);
    debugPrint('$TAG: GlucoseTx dbg: $byteSequence');
  }

  static const String TAG = 'GlucoseTxMessage';
  static const int opcode = 0x30;
}

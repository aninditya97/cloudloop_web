import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:flutter/cupertino.dart';

class VersionRequestTxMessage extends BaseMessage {
  VersionRequestTxMessage([int version = 0]) {
    var this_opcode = 0;
    var length = 3;

    switch (version) {
      case 0:
        this_opcode = opcode0;
        break;
      case 1:
        this_opcode = opcode1;
        break;
      case 2:
      case 3:
        this_opcode = opcode2;
        break;
    }

    if (version == 3) {
      length = 4;
    }

    init(this_opcode, length);

    if (version == 3) {
      data.asByteData().setUint8(0, INFO_2);
      //  ByteData.view(data).setUint8(0, INFO_2);
      appendCRC();
    }

    debugPrint('VersionTx ($version) ');
  }
  static const int opcode0 = 0x20;
  static const int opcode1 = 0x4A;
  static const int opcode2 = 0x52;
  static const int INFO_2 = 2;
}

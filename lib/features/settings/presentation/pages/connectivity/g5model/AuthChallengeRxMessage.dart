import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/Extensions.dart';
import 'package:flutter/cupertino.dart';

class AuthChallengeRxMessage extends BaseMessage {
  AuthChallengeRxMessage(Uint8List data) {
    debugPrint('${TAG}AuthChallengeRX: ${Extensions.bytesToHex(data)}');
    if (data.length >= 17) {
      if (data[0] == opcode) {
        tokenHash = data.sublist(1, 9);
        challenge = data.sublist(9, 17);
      }
    }
  }
  static const int opcode = 0x03;
  Uint8List? tokenHash;
  Uint8List? challenge;
  static const String TAG = 'AuthChallengeRxMessage';
}

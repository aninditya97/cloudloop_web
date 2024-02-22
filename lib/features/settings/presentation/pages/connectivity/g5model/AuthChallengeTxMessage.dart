import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/Extensions.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/TransmitterMessage.dart';
import 'package:flutter/cupertino.dart';

class AuthChallengeTxMessage extends TransmitterMessage {
  AuthChallengeTxMessage(Uint8List challenge) {
    challengeHash = challenge;

    data = Uint8List(9).buffer;
    final byteData = data!.asByteData()..setUint8(0, opcode);
    final challengeHashList = challengeHash.toList();
    data!
        .asUint8List(1, 8)
        .setRange(0, challengeHashList.length, challengeHashList);
    byteSequence = data!.asUint8List();

    debugPrint('AuthChallengeTX: ${Extensions.bytesToHex(byteSequence!)}');
  }
  static const opcode = 0x04;
  late Uint8List challengeHash;
}

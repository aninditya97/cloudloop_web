import 'dart:math';
import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:flutter/cupertino.dart';

class AuthRequestTxMessage extends BaseMessage {
  AuthRequestTxMessage(int token_size) : this._internal(token_size, false);
  AuthRequestTxMessage._internal(int token_size, bool alt) {
    final endByte = alt ? endByteAlt : endByteStd;
    final length = token_size + 2;
    init(opcode, length);

    final randomBytes = getRandomKey();
    singleUseToken = Uint8List(token_size);
    singleUseToken.setRange(0, token_size, randomBytes);

    // data = ByteBuffer.allocate(length);
    data.asUint8List().setRange(0, token_size, singleUseToken);
    data.asByteData().setUint8(token_size, endByte);
    byteSequence = data.asUint8List();
    debugPrint('New AuthRequestTxMessage: $byteSequence');
  }

  AuthRequestTxMessage.alternative(int token_size)
      : this._internal(token_size, true);
  static const int opcode = 0x01;

  late Uint8List singleUseToken;
  static const int endByteStd = 0x2;
  static const int endByteAlt = 0x1;

  /*
  Uint8List getRandomKey(int length) {
    return Uint8List.fromList(List.generate(length, (index) => Random.secure().nextInt(256)));
  }

   */

  Uint8List getRandomKey() {
    final keybytes = Uint8List(16);
    final sr = Random.secure();
    for (var i = 0; i < keybytes.length; i++) {
      keybytes[i] = sr.nextInt(256);
    }
    return keybytes;
  }
}

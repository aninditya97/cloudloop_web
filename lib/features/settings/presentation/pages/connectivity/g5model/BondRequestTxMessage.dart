import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';

class BondRequestTxMessage extends BaseMessage {
  BondRequestTxMessage() {
    init(opcode, 1);
  }
  static const int opcode = 0x07;
}

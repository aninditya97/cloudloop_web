import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/TransmitterStatus.dart';
import 'package:flutter/cupertino.dart';

class BatteryInfoRxMessage extends BaseMessage {
  BatteryInfoRxMessage(List<int> packet) {
    if (packet.length >= 10) {
      final data = ByteData.view(Uint8List.fromList(packet).buffer);
      if (data.getUint8(0) == opcode) {
        status = data.getInt8(1);
        voltagea = data.getUint16(2, Endian.little);
        voltageb = data.getUint16(4, Endian.little);
        if (packet.length != 10) {
          resist = data.getUint16(6, Endian.little);
        }
        runtime = data.getUint8(packet.length == 10 ? 6 : 8);
        if (packet.length == 10) {
          runtime = -1;
        }
        temperature = data.getInt8(packet.length == 10 ? 7 : 9);
      } else {
        debugPrint('$TAG:Invalid opcode for BatteryInfoRxMessage');
      }
    } else {
      debugPrint(
        '$TAG:Invalid length for BatteryInfoMessage: ${packet.length}',
      );
    }
  }
  final String TAG = 'BatteryInfoRxMessage';

  static const int opcode = 0x23;

  late int status;
  late int voltagea;
  late int voltageb;
  late int resist;
  late int runtime;
  late int temperature;

  String toString() {
    return 'Status: ${TransmitterStatus.getBatteryLevel(status).toString()} '
        '/ VoltageA: ${voltagea.toString()} '
        '/ VoltageB: ${voltageb.toString()} '
        '/ Resistance: ${resist.toString()} '
        '/ Run Time: $runtime '
        '/ Temperature: $temperature';
  }
}

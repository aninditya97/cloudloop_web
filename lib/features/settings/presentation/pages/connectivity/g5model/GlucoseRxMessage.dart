import 'dart:typed_data';

import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseGlucoseRxMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/TransmitterStatus.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/calibration_state.dart';
import 'package:flutter/cupertino.dart';

class GlucoseRxMessage extends BaseGlucoseRxMessage {
  GlucoseRxMessage(Uint8List packet) {
    debugPrint('$TAG:GlucoseRX dbg = ${ByteData.view(packet.buffer)}');
    if (packet.length >= 14) {
      //data = ByteBuffer.wrap(packet).order(ByteOrder.LITTLE_ENDIAN);
      final buffer = ByteData.view(packet.buffer);
      data = packet.buffer;
      //kai_20230608 add
      init(opcode, packet.length);
      // debugPrint(TAG + ":GlucoseRX ByteOrder.LITTLE_ENDIAN dbg = " + data.get());
      if ((data.asByteData().getInt8(0) == opcode) && checkCRC(packet)) {
        //data = ByteBuffer.wrap(packet).order(ByteOrder.LITTLE_ENDIAN);

        status_raw = data.asByteData().getInt8(1);
        status =
            TransmitterStatus.getBatteryLevel(data.asByteData().getInt8(1));
        sequence = data.asByteData().getInt32(2, Endian.little);
        timestamp = data.asByteData().getInt32(6, Endian.little);

        final glucoseBytes = data.asByteData().getInt16(
              10,
              Endian.little,
            ); // check signed vs unsigned!! : 2 bytes
        glucoseIsDisplayOnly = (glucoseBytes & 0xf000) > 0;
        glucose = glucoseBytes & 0xfff;
        debugPrint(
          '$TAG:GlucoseRX dbg:glucoseBytes = $glucoseBytes , glucose = $glucose',
        );

        state = data.asByteData().getInt8(12);
        trend = data.asByteData().getInt8(13);
        if (glucose > 13) {
          unfiltered = glucose * 1000;
          filtered = glucose * 1000;
        } else {
          filtered = glucose;
          unfiltered = glucose;
        }

        debugPrint(
          '$TAG:GlucoseRX: seq:$sequence ts:$timestamp sg:$glucose do:$glucoseIsDisplayOnly ss:$status sr:$status_raw st:${CalibrationState.parse(state)} tr:${getTrend()}',
        );
      }
    } else {
      debugPrint(
        '$TAG:GlucoseRxMessage packet length received wrong: ${packet.length}',
      );
    }
  }
  final String TAG = 'GlucoseRxMessage';

  static const int opcode = 0x31;
}

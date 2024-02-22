import 'dart:typed_data';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/TransmitterStatus.dart';

class SensorRxMessage extends BaseMessage {
  SensorRxMessage(Uint8List packet) {
    final packetLength = packet.length;
    if (packetLength >= 14 && packet[0] == opcode) {
      final buffer = ByteData.view(packet.buffer);
      data = packet.buffer;

      //  buffer.offsetInBytes = packet.offsetInBytes;

      status = _getTransmitterStatus(buffer.getUint8(1));
      timestamp = buffer.getInt32(2, Endian.little);

      unfiltered = buffer.getInt32(6, Endian.little);
      filtered = buffer.getInt32(10, Endian.little);
    }
  }
  static const int opcode = 0x2f;

  TransmitterStatus status = TransmitterStatus.UNKNOWN;
  int timestamp = 0;
  int unfiltered = 0;
  int filtered = 0;

  TransmitterStatus _getTransmitterStatus(int batteryLevel) {
    if (batteryLevel < 0 || batteryLevel > 4) {
      return TransmitterStatus.UNKNOWN;
    } else {
      return TransmitterStatus.values[batteryLevel];
    }
  }
}

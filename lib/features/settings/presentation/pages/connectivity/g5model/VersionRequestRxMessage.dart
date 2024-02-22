import 'dart:core';
import 'dart:typed_data';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/TransmitterStatus.dart';

class VersionRequestRxMessage extends BaseMessage {
  VersionRequestRxMessage(Uint8List packet) {
    if (packet.length >= 18) {
      // TODO check CRC??
      final data = packet.buffer.asByteData();
      if (data.getUint8(0) == opcode) {
        status = data.getInt8(1);
        firmware_version_string = dottedStringFromData(data.buffer, 4);
        bluetooth_firmware_version_string =
            dottedStringFromData(data.buffer, 4);
        hardwarev = data.getUint8(9);
        other_firmware_version = dottedStringFromData(data.buffer, 3);
        asic = data.getUint16(
          16,
          Endian.little,
        ); // check signed vs unsigned & byte order!!
      }
    }
  }
  static const int opcode = 0x21;

  late int status;
  late String firmware_version_string;
  late String bluetooth_firmware_version_string;
  late int hardwarev;
  late String other_firmware_version;
  late int asic;

  String toString() {
    return 'Status: ${TransmitterStatus.getBatteryLevel(status)} '
        '/ Firmware: $firmware_version_string '
        '/ BT-Firmware: $bluetooth_firmware_version_string '
        '/ Other-FW: $other_firmware_version '
        '/ hardwareV: $hardwarev '
        '/ asic: $asic';
  }
}

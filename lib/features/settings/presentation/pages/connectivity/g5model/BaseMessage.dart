import 'dart:developer';
import 'dart:typed_data';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/FastCRC16.dart';

class BaseMessage {
  late Uint8List byteSequence;
  late ByteBuffer data;
  late FastCRC16 fastCRC16;

  void init(int opcode, int length) {
    data = Uint8List(length).buffer;
    data.asByteData().setUint8(0, opcode);
    fastCRC16 = FastCRC16();

    if (length == 1) {
      getByteSequence();
    } else if (length == 3) {
      appendCRC();
    }
  }

  Uint8List appendCRC() {
    final crc = fastCRC16.calculateWithEnd(
      getByteSequence(),
      byteSequence.length - 2,
    );
    data.asByteData().setUint8(byteSequence.length - 2, crc[0]);
    data.asByteData().setUint8(byteSequence.length - 1, crc[1]);
    return getByteSequence();
  }

  bool checkCRC(Uint8List data) {
    if (data == null || data.length < 3) return false;
    //kai_202300608
    log('kai:checkCRC():data.length = ${data.length}');
    final crc = fastCRC16.calculateWithEnd(data, data.length);
    // List<int> crc = fastCRC16.calculateWithEnd(data, data.length - 2);
    // return crc[0] == data[data.length - 2] && crc[1] == data[data.length - 1];
    return crc[0] == (data[data.length - 2] & 0xFF) &&
        crc[1] == (data[data.length - 1] & 0xFF);
  }

  Uint8List getByteSequence() {
    return data.asUint8List();
  }

  int? getUnsignedByte(ByteBuffer data) {
    return ByteData.view(data).getUint8(0) & 0xff;
  }

  /*
  int? getUnsignedByte(ByteBuffer data) {
    return data.asByteData().getUint8(0);
  }
   */

  int getUnsignedShort(ByteBuffer data) {
    return (data.asByteData().getUint8(0) & 0xff) +
        ((data.asByteData().getUint8(1) & 0xff) << 8);
  }

  int getUnsignedInt(ByteBuffer data) {
    return (data.asByteData().getUint8(0) & 0xff) +
        ((data.asByteData().getUint8(1) & 0xff) << 8) +
        ((data.asByteData().getUint8(2) & 0xff) << 16) +
        ((data.asByteData().getUint8(3) & 0xff) << 24);
  }

  String dottedStringFromData(ByteBuffer data, int length) {
    final bytes = Uint8List(length);
    // data.get(bytes);
    data
        .asByteData()
        .buffer
        .asUint8List(data.asByteData().offsetInBytes, length)
        .setAll(0, bytes);

    final sb = StringBuffer();
    for (final x in bytes) {
      if (sb.length > 0) sb.write('.');
      sb.write('${x & 0xff}');
    }
    return sb.toString();
  }
}

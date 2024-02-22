import 'dart:typed_data';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/CRC.dart';

class TransmitterMessage {
  static const String TAG = 'TransmitterMessage';
  static const int INVALID_TIME = 0xFFFFFFFF;

  int postExecuteGuardTime = 50;
  Uint8List? byteSequence;

  ByteBuffer? data;

  void setData() {
    // TODO: setData 함수 구현
  }

  static int getUnsignedShort(ByteBuffer data) {
    return (data.asByteData().getUint8(0) & 0xff) +
        ((data.asByteData().getUint8(1) & 0xff) << 8);
  }

  static int getUnsignedByte(ByteBuffer data) {
    return data.asByteData().getUint8(0) & 0xff;
  }

  static int getUnixTime() {
    //return (JoH.tsl() ~/ 1000);
    return 0;
  }

  void init(int opcode, int length) {
    data = Uint8List(length).buffer;
    data!.asByteData().setUint8(0, opcode);
    // data!.order(ByteOrder.LITTLE_ENDIAN);
    // data!.put(opcode);
  }

  Uint8List? appendCRC() {
    final crc =
        CRC.calculateList(getByteSequence()!, 0, byteSequence!.length - 2);
    data!.asByteData().setUint8(byteSequence!.length - 2, crc[0]);
    data!.asByteData().setUint8(byteSequence!.length - 1, crc[1]);
    return getByteSequence();
  }

  bool checkCRC(Uint8List? data) {
    if ((data == null) || (data.length < 3)) return false;
    final crc = CRC.calculateList(data, 0, data.length - 2);
    return crc[0] == data[data.length - 2] && crc[1] == data[data.length - 1];
  }

  Uint8List? getByteSequence() {
    byteSequence = data!.asUint8List();
    return byteSequence;
  }

  int guardTime() {
    return postExecuteGuardTime;
  }
}

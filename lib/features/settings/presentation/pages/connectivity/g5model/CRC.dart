import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/CRC16.dart';

class CRC {
  static List<int> calculate(int b) {
    var crcShort = 0;
    crcShort = ((crcShort >> 8) | (crcShort << 8)) & 0xffff;
    crcShort ^= b & 0xff;
    crcShort ^= (crcShort & 0xff) >> 4;
    crcShort ^= (crcShort << 12) & 0xffff;
    crcShort ^= ((crcShort & 0xFF) << 5) & 0xffff;
    crcShort &= 0xffff;
    return [crcShort & 0xff, (crcShort >> 8) & 0xff];
  }

  static List<int> calculateList(List<int> bytes, int start, int end) {
    return CRC16.calculate(bytes, 0, end);
  }
}

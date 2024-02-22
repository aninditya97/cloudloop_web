class CRC16 {
  static List<int> calculate(List<int> buff, int start, int end) {
    int crcShort = 0;

    for (int i = start; i < end; i++) {
      crcShort = ((crcShort >> 8) | (crcShort << 8)) & 0xffff;
      crcShort ^= (buff[i] & 0xff);
      crcShort ^= ((crcShort & 0xff) >> 4);
      crcShort ^= (crcShort << 12) & 0xffff;
      crcShort ^= ((crcShort & 0xFF) << 5) & 0xffff;
    }

    crcShort &= 0xffff;

    return [crcShort & 0xff, (crcShort >> 8) & 0xff];
  }
}

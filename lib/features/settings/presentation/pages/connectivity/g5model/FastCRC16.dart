class FastCRC16 {

  static const table = [
  0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
  0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
  0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
  0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
  0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
  0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
  0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
  0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
  0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
  0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
  0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12,
  0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
  0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
  0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
  0x7e97, 0x6eb6, 0x5ed5, 0x181d, 0x080c, 0x3c3f, 0x2c1e, 0xdedb,
  0xcefa, 0xfec9, 0xeee8, 0x9f9b, 0x8fba, 0xbf89, 0xafa8, 0x5c44,
  0x4c65, 0x7c36, 0x6c17, 0x0d90, 0x1db1, 0x2d82, 0x3da3, 0xcdec,
  0xddcd, 0xedfe, 0xfddf, 0x8e58, 0x9e79, 0xae4a, 0xbe6b, 0x4f75,
  0x5f54, 0x6f27, 0x7f06, 0x1fb1, 0x0f90, 0x3fd3, 0x2fb2, 0xef1f,
  0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8, 0x6e17,
  0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0 ];


  List<int> calculate(List<int> bytes) {
    return calculateWithEnd(bytes, bytes.length);
  }

  List<int> calculateWithEnd(List<int> bytes, int end) {
    int crc = 0;
    for (int i = 0; i < end; i++) {
      crc = (crc << 8) ^ table[(crc >> 8 ^ bytes[i]) & 0xff];
    }
    return [crc & 0xff, (crc >> 8) & 0xff];
  }

}
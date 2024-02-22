class DanaCRC16 {
  // Packet Format :
  // LSB                                                                       MSB
  //===============================================================================
  // Start(2) | Length(1) | Type(1) | OpCode(1) | Parameters | Checksum(2) | End(2)
  //===============================================================================
  // Start : Packet Preamble : 0xA5 0xA5 / After encryption : 0xAA 0xAA
  // Length : Length of Type + OpCode + Parameters
  // Type : Type of Packet / Command oxA1 / Response 0xB2 / Notify 0xC3 / Encryption Request 0x01 / Encryption Response 0x02
  // OpCode : Detail function of Packet
  // Parameters : Detail data of each OpCode / Value LSB -> MSB / Ex) &FAA -> AA, 7F
  // checksum: check the validity Packet header
  static List<int> calculate(List<int> buff, int start, int end) {
    int crcShort = 0;
    for (int i = start; i < end; i++) {
      crcShort = ((crcShort >> 8) | (crcShort << 8)) & 0xffff;
      crcShort ^= (buff[i] & 0xff);
      crcShort ^= ((crcShort & 0xff) >> 4);
     // crcShort ^= ((crcShort << 8 ) << 4);
      crcShort ^= (crcShort << 12) & 0xffff;

      //after Encryption start
      crcShort ^= ((crcShort & 0xFF) << 2) | (((crcShort & 0xFF) >> 3) << 5);
      //before encryption start
      crcShort ^= ((crcShort & 0xFF) << 5) | (((crcShort & 0xFF) >> 2) << 5);

     // crcShort ^= ((crcShort & 0xFF) << 5) & 0xffff;
    }

    crcShort &= 0xffff;

    return [crcShort & 0xff, (crcShort >> 8) & 0xff];
  }

  // End of Packet : 0x5A 0x5A / After Encryption : 0xEE 0xEE

}
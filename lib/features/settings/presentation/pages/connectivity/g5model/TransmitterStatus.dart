enum TransmitterStatus {
  UNKNOWN,
  BRICKED,
  LOW,
  OK;

  static TransmitterStatus getBatteryLevel(int b) {
    if (b > 0x81) {
      return TransmitterStatus.BRICKED;
    } else {
      if (b == 0x81) {
        return TransmitterStatus.LOW;
      } else if (b == 0x00) {
        return TransmitterStatus.OK;
      } else {
        return TransmitterStatus.UNKNOWN;
      }
    }
  }
}
enum CalibrationState {
  Unknown(0x00, 'Unknown'),
  Stopped(0x01, 'Stopped'),
  WarmingUp(0x02, 'Warming Up'),
  ExcessNoise(0x03, 'Excess Noise'),
  NeedsFirstCalibration(0x04, 'Needs Initial Calibration'),
  NeedsSecondCalibration(0x05, 'Needs Second Calibration'),
  Ok(0x06, 'OK'),
  NeedsCalibration(0x07, 'Needs Calibration'),
  CalibrationConfused1(0x08, 'Confused Calibration 1'),
  CalibrationConfused2(0x09, 'Confused Calibration 2'),
  NeedsDifferentCalibration(0x0a, 'Needs More Calibration'),
  SensorFailed(0x0b, 'Sensor Failed'),
  SensorFailed2(0x0c, 'Sensor Failed 2'),
  UnusualCalibration(0x0d, 'Unusual Calibration'),
  InsufficientCalibration(0x0e, 'Insufficient Calibration'),
  Ended(0x0f, 'Ended'),
  SensorFailed3(0x10, 'Sensor Failed 3'),
  TransmitterProblem(0x11, 'Transmitter Problem'),
  Errors(0x12, 'Sensor Errors'),
  SensorFailed4(0x13, 'Sensor Failed 4'),
  SensorFailed5(0x14, 'Sensor Failed 5'),
  SensorFailed6(0x15, 'Sensor Failed 6'),
  SensorFailedStart(0x16, 'Sensor Failed Start'),
  SensorStarted(0xC1, 'Sensor Started'),
  SensorStopped(0xC2, 'Sensor Stopped'),
  CalibrationSent(0xC3, 'Calibration Sent');

  /*
  final Set<CalibrationState> transitional = {
    CalibrationState.WarmingUp,
    CalibrationState.SensorStarted,
    CalibrationState.SensorStopped,
    CalibrationState.CalibrationSent,
  };

   */

  //final transitional = LinkedHashSet.of([CalibrationState.WarmingUp, CalibrationState.SensorStarted, CalibrationState.SensorStopped, CalibrationState.CalibrationSent]);

  final int value;
  final String description;

  const CalibrationState(this.value, this.description);

  bool usableGlucose() {
    return this == CalibrationState.Ok ||
        this == CalibrationState.NeedsCalibration;
  }

  bool insufficientCalibration() {
    return (this == CalibrationState.NeedsDifferentCalibration);
  }

  bool needsCalibration() {
    return (this == NeedsCalibration ||
        this == NeedsFirstCalibration ||
        this == NeedsSecondCalibration ||
        this == NeedsDifferentCalibration);
  }

  bool readyForCalibration() {
    return (this == Ok || needsCalibration());
  }

  static CalibrationState parse(int state) {
    for (var v in CalibrationState.values) {
      if (v.value == state) {
        return v;
      }
    }
    return CalibrationState.Unknown;
  }

  bool sensorStarted() {
    return (this != Stopped ||
        this != Ended ||
        this != SensorFailed ||
        this != SensorFailed2 ||
        this != SensorFailed3 ||
        this != SensorFailed4 ||
        this != SensorFailed5 ||
        this != SensorFailed6 ||
        this != SensorFailedStart ||
        this != SensorStopped);
  }

  bool sensorFailed() {
    return (this == SensorFailed ||
        this == SensorFailed2 ||
        this == SensorFailed3 ||
        this == SensorFailed4 ||
        this == SensorFailed5 ||
        this == SensorFailed6 ||
        this == SensorFailedStart);
  }

  bool ended() {
    return this == Ended;
  }

  bool warmingUp() {
    return this == WarmingUp;
  }

  bool transitional() {
    return (this == WarmingUp ||
        this == SensorStarted ||
        this == SensorStopped ||
        this == CalibrationSent);
  }

  bool ok() {
    return this == Ok;
  }

  bool readyForBackfill() {
    return this != WarmingUp &&
        this != Stopped &&
        this != Unknown &&
        this != NeedsFirstCalibration &&
        this != NeedsSecondCalibration &&
        this != Errors;
  }
}

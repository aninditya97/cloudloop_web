import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/BaseMessage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/TransmitterStatus.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/G5Model/calibration_state.dart';

abstract class BaseGlucoseRxMessage extends BaseMessage {
  // static const String TAG = G5CollectionService.TAG;

  late TransmitterStatus status;
  late int status_raw;
  late int timestamp;
  late int unfiltered;
  late int filtered;
  late int sequence;
  late bool glucoseIsDisplayOnly;
  late int glucose;
  late int state;
  late int trend;

  CalibrationState calibrationState() {
    return CalibrationState.parse(state);
  }

  bool usable() {
    return calibrationState().usableGlucose();
  }

  bool insufficient() {
    return calibrationState().insufficientCalibration();
  }

  bool OkToCalibrate() {
    return calibrationState().readyForCalibration();
  }

  double? getTrend() {
    return trend != 127 ? trend / 10.0 : null;
  }

  int? getPredictedGlucose() {
    return null; // stub
  }
}

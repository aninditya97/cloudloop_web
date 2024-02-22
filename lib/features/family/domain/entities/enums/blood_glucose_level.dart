import 'package:json_annotation/json_annotation.dart';

enum BloodGlucoseLevel {
  @JsonValue('VERY_LOW')
  status1,

  @JsonValue('LOW')
  status2,

  @JsonValue('NORMAL')
  status3,

  @JsonValue('HIGH')
  status4,

  @JsonValue('VERY_HIGH')
  status5
}

extension BloodGlucoseLevelX on BloodGlucoseLevel {
  int toCode() {
    switch (this) {
      case BloodGlucoseLevel.status1:
        return 1;
      case BloodGlucoseLevel.status2:
        return 2;
      case BloodGlucoseLevel.status3:
        return 3;
      case BloodGlucoseLevel.status4:
        return 4;
      case BloodGlucoseLevel.status5:
        return 5;
    }
  }

  String toLabel() {
    switch (this) {
      case BloodGlucoseLevel.status1:
        return 'VERY LOW';
      case BloodGlucoseLevel.status2:
        return 'LOW';
      case BloodGlucoseLevel.status3:
        return 'NORMAL';
      case BloodGlucoseLevel.status4:
        return 'HIGH';
      case BloodGlucoseLevel.status5:
        return 'VERY HIGH';
    }
  }
}

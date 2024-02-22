import 'package:json_annotation/json_annotation.dart';

enum ReportSource {
  @JsonValue('USER')
  user,

  @JsonValue('SENSOR')
  sensor,
}

extension ReportSourceX on ReportSource {
  String toCode() {
    switch (this) {
      case ReportSource.sensor:
        return 'SENSOR';
      case ReportSource.user:
        return 'USER';
    }
  }
}

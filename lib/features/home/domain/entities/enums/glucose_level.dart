import 'package:json_annotation/json_annotation.dart';

enum GlucoseLevel {
  @JsonValue('VERY_LOW')
  veryLow,

  @JsonValue('LOW')
  low,

  @JsonValue('NORMAL')
  normal,

  @JsonValue('HIGH')
  high,

  @JsonValue('VERY_HIGH')
  veryHigh,
}

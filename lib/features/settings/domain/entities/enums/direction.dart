import 'package:json_annotation/json_annotation.dart';

enum Directions {
  @JsonValue('SingleUp')
  singleUp,

  @JsonValue('SingleDown')
  singleDown,

  @JsonValue('Flat')
  flat,

  @JsonValue('DoubleUp')
  doubleUp,

  @JsonValue('DoubleDown')
  doubleDown,

  @JsonValue('FortyFiveUp')
  fortyFiveUp,

  @JsonValue('FortyFiveDown')
  fortyFiveDown,

  @JsonValue('...')
  none,
}

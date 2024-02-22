import 'package:json_annotation/json_annotation.dart';

enum InputSource {
  @JsonValue('SENSOR')
  sensor,

  @JsonValue('USER')
  user
}

extension InputSourceX on InputSource {
  int toCode() {
    switch (this) {
      case InputSource.sensor:
        return 1;
      case InputSource.user:
        return 2;
    }
  }

  String toLabel() {
    switch (this) {
      case InputSource.sensor:
        return 'SENSOR';
      case InputSource.user:
        return 'USER';
    }
  }
}

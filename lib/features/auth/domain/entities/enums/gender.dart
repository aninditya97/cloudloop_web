import 'package:json_annotation/json_annotation.dart';

enum Gender {
  @JsonValue('MALE')
  male,

  @JsonValue('FEMALE')
  female
}

extension GenderX on Gender {
  String toStringCode() {
    switch (this) {
      case Gender.male:
        return 'MALE';
      case Gender.female:
        return 'FEMALE';
    }
  }
}

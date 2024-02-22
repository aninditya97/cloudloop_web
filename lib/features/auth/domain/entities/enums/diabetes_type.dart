import 'package:json_annotation/json_annotation.dart';

enum DiabetesType {
  @JsonValue(1)
  type1,

  @JsonValue(2)
  type2
}

extension DiabetesTypeX on DiabetesType {
  int toCode() {
    switch (this) {
      case DiabetesType.type1:
        return 1;
      case DiabetesType.type2:
        return 2;
    }
  }

  String toLabel() {
    switch (this) {
      case DiabetesType.type1:
        return 'Type 1';
      case DiabetesType.type2:
        return 'Type 2';
    }
  }
}

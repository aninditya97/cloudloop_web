import 'package:json_annotation/json_annotation.dart';

enum ConnectionStatus {
  @JsonValue('UNCONNECTED')
  status1,

  @JsonValue('CONNECTED')
  status2,

  @JsonValue('PENDING')
  status3
}

extension ConnectionStatusX on ConnectionStatus {
  int toCode() {
    switch (this) {
      case ConnectionStatus.status1:
        return 1;
      case ConnectionStatus.status2:
        return 2;
      case ConnectionStatus.status3:
        return 3;
    }
  }

  String toLabel() {
    switch (this) {
      case ConnectionStatus.status1:
        return 'UNCONNECTED';
      case ConnectionStatus.status2:
        return 'CONNECTED';
      case ConnectionStatus.status3:
        return 'PENDING';
    }
  }
}

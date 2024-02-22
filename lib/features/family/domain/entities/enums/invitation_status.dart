import 'package:json_annotation/json_annotation.dart';

enum InvitationStatus {
  @JsonValue('ACCEPTED')
  status1,

  @JsonValue('REJECTED')
  status2,

  @JsonValue('PENDING')
  status3
}

extension InvitationStatusX on InvitationStatus {
  int toCode() {
    switch (this) {
      case InvitationStatus.status1:
        return 1;
      case InvitationStatus.status2:
        return 2;
      case InvitationStatus.status3:
        return 3;
    }
  }

  String toLabel() {
    switch (this) {
      case InvitationStatus.status1:
        return 'ACCEPTED';
      case InvitationStatus.status2:
        return 'REJECTED';
      case InvitationStatus.status3:
        return 'PENDING';
    }
  }
}

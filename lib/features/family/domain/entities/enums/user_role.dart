import 'package:json_annotation/json_annotation.dart';

enum UserRole {
  @JsonValue('ADMIN')
  admin,

  @JsonValue('MEMBER')
  member
}

extension UserRoleX on UserRole {
  int toCode() {
    switch (this) {
      case UserRole.admin:
        return 1;
      case UserRole.member:
        return 2;
    }
  }

  String toLabel() {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.member:
        return 'MEMBER';
    }
  }
}

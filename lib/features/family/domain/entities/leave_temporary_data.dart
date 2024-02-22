import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'leave_temporary_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class LeaveTemporaryData extends Equatable {
  const LeaveTemporaryData({
    required this.temporaryId,
    required this.userId,
  });

  factory LeaveTemporaryData.fromJson(Map<String, dynamic> json) =>
      _$LeaveTemporaryDataFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String temporaryId;

  @JsonKey(name: 'user_id')
  final String userId;

  Map<String, dynamic> toJson() => _$LeaveTemporaryDataToJson(this);

  @override
  List<Object?> get props => [
        temporaryId,
        userId,
      ];
}

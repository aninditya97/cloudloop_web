import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_blood_glucose_params.g.dart';

@JsonSerializable()
class SendBloodGlucoseParams extends Equatable {
  const SendBloodGlucoseParams({
    this.temporaryId,
    this.userId,
    required this.value,
    required this.source,
    this.time,
    this.createdAt,
    this.updatedAt,
  });

  factory SendBloodGlucoseParams.fromJson(Map<String, dynamic> json) =>
      _$SendBloodGlucoseParamsFromJson(json);

  @JsonKey(name: 'temporary_id')
  final String? temporaryId;

  @JsonKey(fromJson: NumParser.doubleParse)
  final double value;

  final String source;

  final String? time;

  @JsonKey(name: 'user_id')
  final int? userId;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  Map<String, dynamic> toJson() => _$SendBloodGlucoseParamsToJson(this);

  @override
  List<Object?> get props => [
        temporaryId,
        value,
        source,
        time,
        userId,
        createdAt,
        updatedAt,
      ];
}

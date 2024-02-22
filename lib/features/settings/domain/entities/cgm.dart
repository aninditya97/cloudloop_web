import 'package:cloudloop_mobile/core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cgm.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class CgmData extends Equatable {
  const CgmData({
    required this.id,
    required this.deviceId,
    required this.status,
    required this.transmitterId,
    required this.transmitterCode,
    this.connectAt,
  });

  factory CgmData.fromJson(Map<String, dynamic> json) =>
      _$CgmDataFromJson(json);

  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'device_id', fromJson: StringParser.parse)
  final String deviceId;

  @JsonKey(name: 'transmitter_id', fromJson: StringParser.parse)
  final String transmitterId;

  @JsonKey(name: 'transmitter_code', fromJson: StringParser.parse)
  final String transmitterCode;

  final bool status;

  @JsonKey(name: 'connect_at', fromJson: DateTime.tryParse)
  final DateTime? connectAt;

  Map<String, dynamic> toJson() => _$CgmDataToJson(this);

  @override
  List<Object?> get props => [
        id,
        deviceId,
        transmitterId,
        transmitterCode,
        status,
        connectAt,
      ];
}

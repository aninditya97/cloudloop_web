import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connection_data.g.dart';

@JsonSerializable()
@DateTimeJsonConverter()
class ConnectionData extends Equatable {
  const ConnectionData({
    required this.sentAt,
    required this.connectedAt,
    required this.status,
  });

  factory ConnectionData.fromJson(Map<String, dynamic> json) =>
      _$ConnectionDataFromJson(json);

  final DateTime? sentAt;

  final DateTime? connectedAt;

  @JsonKey(defaultValue: ConnectionStatus.status1)
  final ConnectionStatus status;

  Map<String, dynamic> toJson() => _$ConnectionDataToJson(this);

  @override
  List<Object?> get props => [sentAt, connectedAt, status];
}

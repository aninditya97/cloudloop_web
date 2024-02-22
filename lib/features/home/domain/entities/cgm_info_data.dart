import 'package:equatable/equatable.dart';

class CgmInfoData extends Equatable {
  const CgmInfoData({
    required this.deviceId,
    this.transmitterId,
    this.transmitterCode,
  });

  final String deviceId;
  final String? transmitterId;
  final int? transmitterCode;

  @override
  List<Object?> get props => [
        deviceId,
        transmitterId,
        transmitterCode,
      ];
}

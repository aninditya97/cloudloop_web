part of 'save_cgm_bloc.dart';

abstract class SaveCgmEvent extends Equatable {
  const SaveCgmEvent();

  @override
  List<Object> get props => [];
}

class CgmIdChanged extends SaveCgmEvent {
  const CgmIdChanged(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

class CgmDeviceIdChanged extends SaveCgmEvent {
  const CgmDeviceIdChanged(this.deviceId);

  final String deviceId;

  @override
  List<Object> get props => [deviceId];
}

class CgmTransmitterIdChanged extends SaveCgmEvent {
  const CgmTransmitterIdChanged(this.transmitterId);

  final String transmitterId;

  @override
  List<Object> get props => [transmitterId];
}

class CgmTransmitterCodeChanged extends SaveCgmEvent {
  const CgmTransmitterCodeChanged(this.transmitterCode);

  final String transmitterCode;

  @override
  List<Object> get props => [transmitterCode];
}

class CgmRequestSubmitted extends SaveCgmEvent {
  const CgmRequestSubmitted();
}

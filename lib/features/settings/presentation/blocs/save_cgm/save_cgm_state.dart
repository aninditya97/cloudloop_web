part of 'save_cgm_bloc.dart';

class SaveCgmState extends Equatable {
  const SaveCgmState({
    required this.id,
    required this.deviceId,
    required this.transmitterId,
    required this.transmitterCode,
    required this.status,
    this.failure,
    this.cgm,
  });

  const SaveCgmState.pure()
      : this(
          status: FormzStatus.pure,
          id: const NotNullFormz.pure(),
          deviceId: const NotNullFormz.pure(),
          transmitterId: const NotNullFormz.pure(),
          transmitterCode: const NotNullFormz.pure(),
        );

  final NotNullFormz<String> id;
  final NotNullFormz<String> deviceId;
  final NotNullFormz<String> transmitterId;
  final NotNullFormz<String> transmitterCode;
  final FormzStatus status;
  final ErrorException? failure;
  final CgmData? cgm;

  SaveCgmState copyWith({
    NotNullFormz<String>? id,
    NotNullFormz<String>? deviceId,
    NotNullFormz<String>? transmitterId,
    NotNullFormz<String>? transmitterCode,
    ErrorException? failure,
    FormzStatus? status,
    CgmData? cgm,
  }) {
    return SaveCgmState(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      transmitterId: transmitterId ?? this.transmitterId,
      transmitterCode: transmitterCode ?? this.transmitterCode,
      failure: failure ?? this.failure,
      status: status ?? this.status,
      cgm: cgm ?? this.cgm,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deviceId,
        transmitterId,
        transmitterCode,
        failure,
        status,
        cgm,
      ];
}

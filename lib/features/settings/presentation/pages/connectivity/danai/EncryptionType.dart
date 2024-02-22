class EncryptionType {
  static const EncryptionType ENCRYPTION_DEFAULT = EncryptionType._(0);
  static const EncryptionType ENCRYPTION_RSv3 = EncryptionType._(1);
  static const EncryptionType ENCRYPTION_BLE5 = EncryptionType._(2);

  final int value;

  const EncryptionType._(this.value);
}

int getValueFromEncryptionType(EncryptionType type) {
  return type.value;
}
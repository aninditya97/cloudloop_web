import 'dart:developer';

class Packet {
  final List<int> start = [0xA5, 0xA5]; // 디바이스키로 암호화죈 패킷 시작
  final List<int> end = [0x5A, 0x5A]; // 디바이스키로 암호화된 패킷 끝
  final List<int> startEncrypt = [0xAA, 0xAA]; // 페어링키로 암호화된 패킷 시작
  final List<int> endEncrypt = [0xEE, 0xEE]; // 페어링키로 암호화된 패킷 끝
  // Type of Packet / Command 0xA1 / Response 0xB2 / Notify 0xC3 / Encryption Request 0x01/ Encryption Response 0x02
  int _type = 0xA1; // 패킷 타입 Command
  int get type => _type;
  set type(int value) {
    _type = value;
  }

  bool _afterEncrytionStart =  false; ///< if true, then use startEncrypt/endEncrypt after encrypt packet by bleParing Key
  bool get afterEncrytionStart => _afterEncrytionStart;
  set afterEncrytionStart(bool value) {
    _afterEncrytionStart = value;
  }

  late int length; // 패킷 길이
  late int opCode; // 패킷 오퍼레이션 코드
  late List<int> parameters; // 패킷 파라미터
  late List<int> checksum; // 패킷 체크섬

  /*
  *@brief Create Packet , packet format is as below
  *    [ start(2) | length(1) | Type(1) | opCode(1) | parameters ( variables...) | checksum(2) | end(2) ]
   */
  List<int> createPacket(int opCode, List<int>? parameters) {
    this.opCode = opCode;
    if (parameters != null && parameters.isNotEmpty) {
      this.parameters = parameters;
      this.length = 1 + 1 + parameters.length; // Type(1) + OpCode(1) + Parameters
      var sendBuf = [type, opCode, ...parameters];
      this.checksum = generateCrc(sendBuf,false);
      return [...start, length, type, opCode, ...parameters, ...checksum, ...end];
    }
    else {
      this.length = 1 + 1 ; // Type(1) + OpCode(1) + Parameters
      var sendBuf = [type, opCode];
      this.checksum = generateCrc(sendBuf,false);
      return [...start, length, type, opCode, ...checksum, ...end];
    }

  }

  /*
  *@brief Create Packet encrypted by using device key which is dana-i5 device shipping serial number
  *    packet format is as below
  *    [ start(2) | length(1) | Type(1) | opCode(1) | parameters ( variables...) | checksum(2) | end(2) ]
  *    data [ Type(1) | opCode(1) | parameters ( variables...) | checksum(2) ] is encrypted by using shipping serial number
  */
  List<int> createPacketEncrytinonWithDeviceKey(int opCode, List<int>? parameters, String shippingSerialNumber) {
    this.opCode = opCode;
    if (parameters != null && parameters.isNotEmpty) {
      this.parameters = parameters;
      this.length = 1 + 1 + parameters.length; // Type(1) + OpCode(1) + Parameters
      var sendBuf = [type, opCode, ...parameters];
      this.checksum = generateCrc(sendBuf, afterEncrytionStart);
      //if shipping serial number(dana-i5 device name is available,
      // then let's encrypt data by using it.
      if (shippingSerialNumber != null && shippingSerialNumber.isNotEmpty) {
        List<int> IntDevKey = makeDeviceKey(shippingSerialNumber);
        List<int> senddata = [type, opCode, ...parameters, ...checksum];
        List<int> encryptedData = encryptPacket(senddata, IntDevKey);
        if (afterEncrytionStart == true) {
          return [...startEncrypt, length, ...encryptedData, ...endEncrypt];
        }
        else {
          return [...start, length, ...encryptedData, ...end];
        }

      }

      if (afterEncrytionStart == true) {
        return [...startEncrypt, length, type, opCode, ...parameters, ...checksum, ...endEncrypt];
      } else {
        return [...start, length, type, opCode, ...parameters, ...checksum, ...end];
      }

    } else {
      this.length = 1 + 1; // Type(1) + OpCode(1) + Parameters
      var sendBuf = [type, opCode];
      this.checksum = generateCrc(sendBuf,afterEncrytionStart);
      //if shipping serial number(dana-i5 device name is available,
      // then let's encrypt data by using it.
      if (shippingSerialNumber != null && shippingSerialNumber.isNotEmpty) {
        List<int> IntDevKey = makeDeviceKey(shippingSerialNumber);
        List<int> senddata = [type, opCode, ...checksum];
        List<int> encryptedData = encryptPacket(senddata, IntDevKey);
        if (afterEncrytionStart == true) {
          return [...startEncrypt, length, ...encryptedData, ...endEncrypt];
        } else {
          return [...start, length, ...encryptedData, ...end];
        }

      }

      if (afterEncrytionStart == true) {
        return [...startEncrypt, length, type, opCode, ...checksum, ...endEncrypt];
      } else {
        return [...start, length, type, opCode, ...checksum, ...end];
      }

    }

  }

  // 패킷 해석 함수
  void processReceivedPacket(List<int> receivedPacket, List<int> deviceKey) {
    List<int> decryptedPacket = decryptPacket(receivedPacket, deviceKey);
    // 수신된 패킷 파싱하여 처리하는 작업
    // decryptedPacket의 내용을 파싱하여 필요한 작업을 수행
  }

  // 패킷 암호화 함수
  List<int> encryptPacket(List<int> packet, List<int> deviceKey) {
    // packet을 deviceKey를 사용하여 암호화하는 과정 추가
    // 암호화된 패킷을 반환
    // 여기서는 가상의 암호화 함수를 가정하여 구현하지만, 실제로는 복잡한 암호화 알고리즘을 사용해야 합니다.
    List<int> encryptedPacket = List<int>.from(packet); // 가상의 암호화 과정
    for (int i = 0; i < encryptedPacket.length; i++) {
      encryptedPacket[i] ^= deviceKey[i % deviceKey.length];
    }
    return encryptedPacket;
  }

  // 패킷 복호화 함수
  List<int> decryptPacket(List<int> packet, List<int> deviceKey) {
    // packet을 deviceKey를 사용하여 복호화하는 과정 추가
    // 복호화된 패킷을 반환
    // 여기서는 가상의 복호화 함수를 가정하여 구현하지만, 실제로는 복잡한 암호화 알고리즘을 사용해야 합니다.
    List<int> decryptedPacket = List<int>.from(packet); // 가상의 복호화 과정
    for (int i = 0; i < decryptedPacket.length; i++) {
      decryptedPacket[i] ^= deviceKey[i % deviceKey.length];
    }
    return decryptedPacket;
  }

  // 체크섬 생성 함수
  /*
  *@brief create checksum
  *       if afterEncryptionStart is true then use after start Encryption
  *@param[in] byteList : data
  *@param[in] afterEncryptionStart :
  *           'true'  use After Encryption Start
  *            luint16_crc ^= ((luint16_crc & 0xff)<< 2) | (((luint16_crc & 0xff) >> 3) << 5);
  *           'false' use Before Encryption Start
  *            luint16_crc ^= ((luint16_crc & 0xff)<< 5) | (((luint16_crc & 0xff) >> 2) << 5);
   */
  List<int> generateCrc(List<int> byteList, bool afterEncryptionStart) {
    int crc = 0;
    for (int byte in byteList) {
      crc = crc16(byte, crc, afterEncryptionStart);
    }
    return [(crc >> 8) & 0xFF, crc & 0xFF];
  }

  // CRC16 계산 함수
  /*
  in case that After Encryption Start: (0x01,0x00) command already sent to Dana-i, use below;
  luint16_crc ^= ((luint16_crc & 0xff)<< 2) | (((luint16_crc & 0xff) >> 3) << 5);
  Before Encryption Start, use below;
  luint16_crc ^= ((luint16_crc & 0xff)<< 5) | (((luint16_crc & 0xff) >> 2) << 5);
   */
  int crc16(int byte, int crc, bool afterEncryptionStart) {
    crc = (crc >> 8) | ((crc & 0xFF) << 8);
    crc ^= byte;
    crc ^= ((crc & 0xFF) >> 4);
    crc ^= (crc << 8) << 4;
    if (afterEncryptionStart) {
      crc ^= (((crc & 0xFF) << 2) | (((crc & 0xFF) >> 3) << 5));
    } else {
      crc ^= (((crc & 0xFF) << 5) | (((crc & 0xFF) >> 2) << 5));
    }

    return crc & 0xFFFF;
  }


  /* Usage
    // Shipping Serial을 기반으로 Device Key 생성
    String shippingSerial = "AAA00000AA";
    List<String> deviceKey = makeDeviceKey(shippingSerial);

    // 암호화할 데이터
    String dataToEncrypt = "TypeOpCodeParametersChecksum"; // 예시 데이터

    // 암호화 진행
    String encryptedData = encryptData(dataToEncrypt, deviceKey);
    print('Encrypted Data: $encryptedData');
 */
  // 주어진 Shipping Serial을 기반으로 Device Key를 생성하는 함수
  // 함수: 디바이스 키 생성
  List<int> makeDeviceKey(String serialNumber) {
    // 문자열을 각 문자의 ASCII 값 리스트로 변환
    List<int> asciiValues = serialNumber.codeUnits;

    // Encryption Serial No[0], [1], [2] 계산
    int encryptionSerialNo0 = (asciiValues[0] + asciiValues[1] + asciiValues[2]) & 0xFF;
    int encryptionSerialNo1 = (asciiValues[3] + asciiValues[4] + asciiValues[5] + asciiValues[6] + asciiValues[7]) & 0xFF;
    int encryptionSerialNo2 = (asciiValues[8] + asciiValues[9]) & 0xFF;
    // 디바이스 키 리스트 생성 및 반환
    return [encryptionSerialNo0, encryptionSerialNo1, encryptionSerialNo2];
  }


  // 주어진 데이터를 주어진 Encryption Serial No와 XOR 연산을 수행하여 암호화하는 함수
  String encryptData(String data, List<String> encryptionSerial) {
    log('kai:encryptData($data), encryptionSerial($encryptionSerial)');
    List<int> encrypted = [];

    // 데이터와 시리얼 번호의 길이 중 짧은 길이로 설정
    int length = data.length < encryptionSerial.length ? data.length : encryptionSerial.length;

    for (int i = 0; i < length; i++) {
      // 데이터와 시리얼 번호의 문자 코드를 가져올 때 null 체크
      int dataCodeUnit = data.codeUnitAt(i);
      int serialCodeUnit = encryptionSerial[i].codeUnitAt(i % 3);

      if (dataCodeUnit != null && serialCodeUnit != null) {
        // XOR 연산을 수행하여 암호화
        encrypted.add(dataCodeUnit ^ serialCodeUnit);
      } else {
        // 예외 처리 또는 오류 처리
        // 데이터나 시리얼 번호의 문자 코드가 null인 경우 처리
        // 이 부분은 상황에 맞게 수정되어야 합니다.
      }
    }

    log('kai:encryptData(), encrypted($encrypted)');
    return String.fromCharCodes(encrypted);
  }

  String decryptData(String encryptedData, List<String> encryptionSerial) {
    List<int> decrypted = [];
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted.add(encryptedData.codeUnitAt(i) ^ encryptionSerial[i % 3].codeUnitAt(i % 3));
    }
    return String.fromCharCodes(decrypted);
  }

  String encryptData1(List<int> data, List<int> encryptionSerial) {
    List<int> encrypted = [];

    int length = data.length < encryptionSerial.length ? data.length : encryptionSerial.length;

    for (int i = 0; i < length; i++) {
      encrypted.add(data[i] ^ encryptionSerial[i % encryptionSerial.length]);
    }

    return encrypted.toString(); // 실제 암호화 된 값 반환
  }



}

/*
 * @brief serviceUUID class defines service UUID and characrteristics UUID for several Cgm/Pump deviecs
 */
class serviceUUID {
  //==================================  Pump ===================================//
  /*
   * @brief Curestream Pump UUID
   */
  static const String CSP_SERVICE_UUID = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  ///< sending data from app to csp
  static const String CSP_TX_CHARACTERISTIC =
      '6e400003'; //0x0003               /*< The UUID of the TX Characteristic. */
  static const String CSP_RX_CHARACTERISTIC =
      '6e400002'; //0x0002               /*< The UUID of the RX Characteristic. */
  static const String CSP_TX_WRITE_CHARACTER_UUID =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  ///< sending data from app to csp
  static const String CSP_RX_READ_CHARACTER_UUID =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  ///< receiving data from csp to app
  static const String CSP_BATLEVEL_NOTIFY_CHARACTER_UUID =
      '00002a19-0000-1000-8000-00805f9b34fb';

  ///< receiving battery level data from csp
  static const String CSP_PUMP_NAME = 'csp-1';

  /*
   * @brief danaRS Pump UUID
   */
  static const String DANARS_BOLUS_SERVICE =
      '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String DANARS_READ_UUID = '0000fff1-0000-1000-8000-00805f9b34fb';
  static const String DANARS_WRITE_UUID =
      '0000fff2-0000-1000-8000-00805f9b34fb';
  static const String DANARS_PUMP_NAME = 'Dana-i';

  ///< Dana-i5

  /*
   * @brief caremedi pump UUID
   *
   */
  static const String CareLevoSERVICE_UUID =
      'e1b40001-ffc4-4daa-a49b-1c92f99072ab';

  ///< pump service uuid
  static const String CareLevoRX_CHAR_UUID =
      'e1b40003-ffc4-4daa-a49b-1c92f99072ab';

  ///< pump send msg to app
  static const String CareLevoTX_CHAR_UUID =
      'e1b40002-ffc4-4daa-a49b-1c92f99072ab';

  ///< pump receive msg from app
  ///const String  CareLevoSERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"; ///< pump service uuid
// const String  CareLevoRX_CHAR_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; ///< pump send msg to app
// const String  CareLevoTX_CHAR_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; ///< pump receive msg from app
  static const String CareLevo_PUMP_NAME = 'CareLevo'; //'CM100K';

  /*
   * @brief dexcom pump UUID
   */
  static const String DexcomSERVICE_UUID =
      '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  ///< pump service uuid
  static const String DexcomRX_CHAR_UUID =
      '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  ///< pump send msg to app
  static const String DexcomTX_CHAR_UUID =
      '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  ///< pump receive msg from app
  static const String Dexcom_PUMP_NAME = 'Dexcom';

//===================================  CGM  ==================================//
  /*
   * @brief in case of using XDrip
   */
  static const String Xdrip_CGM_NAME = 'Xdrip';

  /*
   * @breif in case of i-sens
   */
  static const String ISENSE_CGM_NAME = 'i-sens';

  /*
 * @brief dexcom Model G5
 */
  static const String DEXCOM_CGM_NAME = 'Dexcom';
  //Transmitter Service UUIDs
  static const String DeviceInfo_UUID = '0000180A-0000-1000-8000-00805F9B34FB';
  //iOS uses FEBC?
  static const String Advertisement_UUID =
      '0000FEBC-0000-1000-8000-00805F9B34FB';
  static const String CGMService_UUID = 'F8083532-849E-531C-C594-30F1F86A4EA5';
  static const String ServiceB_UUID = 'F8084532-849E-531C-C594-30F1F86A4EA5';
  //DeviceInfoCharacteristicUUID, Read, DexcomUN
  static const String ManufacturerNameString_UUID =
      '00002A29-0000-1000-8000-00805F9B34FB';
  //CGMServiceCharacteristicUUID
  static const String Communication_UUID =
      'F8083533-849E-531C-C594-30F1F86A4EA5';
  static const String Control_UUID = 'F8083534-849E-531C-C594-30F1F86A4EA5';
  static const String Authentication_UUID =
      'F8083535-849E-531C-C594-30F1F86A4EA5';
  static const String ProbablyBackfill_UUID =
      'F8083536-849E-531C-C594-30F1F86A4EA5';
  static const String ExtraData_UUID = 'F8083538-849E-531C-C594-30F1F86A4EA5';
  //ServiceBCharacteristicUUID
  static const String CharacteristicE_UUID =
      'F8084533-849E-531C-C594-30F1F86A4EA5';
  static const String CharacteristicF_UUID =
      'F8084534-849E-531C-C594-30F1F86A4EA5';
  //CharacteristicDescriptorUUID
  static const String CharacteristicUpdateNotification_UUID =
      '00002902-0000-1000-8000-00805F9B34FB';

  static final Map<String, String> mapToName = {
    DeviceInfo_UUID: 'DeviceInfo',
    Advertisement_UUID: 'Advertisement',
    CGMService_UUID: 'CGMService',
    ServiceB_UUID: 'ServiceB',
    ManufacturerNameString_UUID: 'ManufacturerNameString',
    Communication_UUID: 'Communication',
    Control_UUID: 'Control',
    Authentication_UUID: 'Authentication',
    ExtraData_UUID: 'Extra Data',
    ProbablyBackfill_UUID: 'ProbablyBackfill',
    CharacteristicE_UUID: 'CharacteristicE',
    CharacteristicF_UUID: 'CharacteristicF',
    CharacteristicUpdateNotification_UUID: 'CharacteristicUpdateNotification',
  };

  static String getUUIDName(String? uuid) {
    if (uuid == null) return 'null';
    if (mapToName.containsKey(uuid)) {
      return mapToName[uuid]!;
    } else {
      return 'Unknown uuid: $uuid';
    }
  }
}

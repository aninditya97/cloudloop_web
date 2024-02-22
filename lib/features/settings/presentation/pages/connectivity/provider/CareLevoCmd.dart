/*
 * @brief CareLevoCmd class define several commands for caremedi's Pump device
 */
//============= caremedi pump related variable here ================//
class CareLevoCmd {
  static const int SET_TIME_REQ = 0x11;
  static const int SET_TIME_RSP = 0x71;

  ///< response for the SET_TIME_REQ sent from connected Pump device
  static const int SAFETY_CHECK_REQ = 0x12;

  ///<  안전점검 요청
  static const int SAFETY_CHECK_RSP = 0x72;

  ///< Result: SUCCESS 0, 인슐린 부족 1, 펌프 이상 2, 전압 낮음 3, 안전 점검 요청 응답 4
  static const int INFUSION_THRESHOLD_REQ = 0x17;

  ///<  인슐린 주입 임계치 설정 요청(Type 1)
  static const int INFUSION_THRESHOLD_RSP = 0x77;
  static const int INFUSION_INFO_REQ = 0x31;

  ///< 주입 현황 조회 요청 (스마트폰 앱  패치 장치)
  /// 송신 조건: 사용자가 앱에서 홈화면으로 이동한 경우, 앱 동작 상 홈 화면 가기로 자동 이동하는 경우,
  /// 그리고 앱의 주기적인 홈 화면 업데이트 타이머에 의해 본 메시지가 패치로 송신된다.
  /// Length 2, CMD: 0x31
  /// Sub ID: 주입 현황 조회 요청 (0x00), 인슐린 잔여량 요청 (0x01)
  /// CMD	 Sub ID
  /// 0x31	0x00
  /// Action: 주입 현황 조회 요청을 받은 패치는 현재 주입 중인 주입 펌프 상태와 잔여량, 주입 모드, 주입 속도 등의 값을
  /// 다음의 주입 현황 조회 응답 메시지로 앱으로 송신한다.
  static const int INFUSION_INFO_RPT = 0x91;

  ///< 주입 현황 조회 보고 (패치 장치  스마트폰 앱)
  static const int HCL_DOSE_REQ = 0x67;

  ///< HCL 주입 요청
  static const int HCL_BOLUS_RSP = 0xD7;
  static const int HCL_DOSE_CANCEL_REQ = 0x68;

  ///< HCL 주입 취소 요청
  static const int HCL_BOLUS_CANCEL_RSP = 0xD8;
  static const int PATCH_INFO_REQ = 0x33;

  ///< 	패치 정보 조회 요청 (스마트폰 앱  패치 장치)
  static const int PATCH_INFO_RPT1 = 0x93;

  ///< 패치 정보 보고1 (패치 장치  스마트폰 앱): PATCH_INFO_RPT1 (모델명, 로트번호 송부)
  static const int PATCH_INFO_RPT2 = 0x94;

  ///< 패치 정보 보고2 (패치 장치  스마트폰 앱): PATCH_INFO_RPT2 (제조번호,펌웨어버전,부팅 시간)
  static const int CANNULAR_STATUS_REQ = 0x1a;

  ///<
//static const int CANNULAR_STATUS = (0x79);
  static const int CANNULAR_INSERT_RPT = 0x79;
  static const int CANNULAR_INSERT_ACK = 0x19;

  ///< (스마트폰 앱  패치 장치) after receive CANNULAR_INSERT_RPT
  static const int CANNULAR_INSERT_RSP = 0x7A;
  static const int PATCH_WARNING_RPT = 0xa1;
  static const int PATCH_ALERT_RPT = 0xa2;
  static const int PATCH_NOTICE_RPT = 0xa3;
  static const int PATCH_DISCARD_REQ = 0x36;

  ///< 	패치 폐기 요청 (스마트폰 앱  패치 장치)
  /// 패치 디바이스에서 패치 폐기를 수신하면 즉시 펌프 중지와 주입 프로그램도 모두 삭제하고,
  /// 기 설정 중인 경고/주의/알림 타이머를 모두 삭제한 후 폐기 완료 메시지를 송신한 후 폐기를 알리는 부저를 울린다.
  /// 앱으로는 아래의 패치 폐기 완료 메시지를 송신한다.
  /// 참고) 패치 폐기 응답 시 패치 연결 정보는 초기화 되어 재 연결이 가능하다.
  /// (테스트 모드에서 동일 패치로 계속 연결하여 시험시 유용함)
  static const int PATCH_DISCARD_RSP = 0x96;

  ///<  패치 폐기 완료 메시지 (패치 장치  스마트폰 앱):
  /// RSP	RSLT
// 0x96	0x00
  static const int BUZZER_CHECK_REQ = 0x37;

  ///< 패치 부저 점검 요청 (스마트폰 앱  패치 장치)
  /// 메뉴 중 패치 관리에 “알람 점검 서브 메뉴를 클릭하면 본 메시지를 송신한다.
//  송신 후 앱은 스마트 폰의 부저 울림도 확인하여야 한다.
  /// Length 1,
  /// CMD
  /// 0x37
  static const int BUZZER_CHECK_RSP = 0x97;
  static const int BUZZER_CHANGE_REQ = 0x18;
  static const int BUZZER_CHANGE_RSP = 0x88;
  static const int APP_STATUS_IND = 0x39;

  ///< 앱 상태 통보 메시지 : 앱 상태 통보 (스마트폰 앱  패치 장치)
  /// 앱이 Foreground 나 Background 로의 상태 천이 시 본 메시지를 패치로 송신
  /// Status: 0x00 (foreground  background), 0x01 (Background  foreground)
  /// Action: Status 0x00 을 받으면 주입감시 타이머를 구동하고, 0x01을 받으면 주입 감시 타이머를 중지한다
  /// 주입감시 타이머 Timeout 처리: 첫 타임아웃이면 주의 메시지를 송부한 후 다시 주입감시 타이머를 구동한다.
  /// 두번째 타임아웃이면 주입을 차단하고 경고 메시지를 송부한다.
  /// 두번째 타이머 값은 30분으로 설정한다. 즉 주의 메시지 송신 후 30분 내 앱 사용 재개 없으면 경고 및 주입 차단함.
  /// 주의/경고, 펌프 중단 메시지에 Cause 값 추가 정의 (앱 장기 미사용 5)
  /// IND	  STATUS	TIME
  /// 0x39	0x00	0x06
  static const int APP_STATUS_ACK = 0x99;

  ///< 앱 상태 수신 확인  메시지 (패치 장치  스마트폰 앱)
  ///  Length 2, ACK: 0x99, STATUS (APP_STATUS_IND 시 앱에서 통보 받은 값 세팅함: 0 or 1)
  ///  ACK	STATUS
  ///  0x99	0x00
  static const int MAC_ADDR_REQ = 0x3b;

  ///< MAC Address 조회 요청 (스마트폰 앱  패치 장치)
  static const int MAC_ADDR_RPT = 0x9b;

  ///< MAC Address 보고(패치 장치  스마트폰 앱):
  /// Data (6 byte): MAC Address -> 6바이트 HEXA 값임
  /// RPT 	ADDR1	ADDR2	ADDR3	ADDR4	ADDR5	ADDR6
//  0x9B	0x80	0x4B	0x50	0x6F	0xDC	0x61
  static const int ALARM_CLEAR_REQ = 0x47;

  ///< 알람/알림 해소 요청 (스마트폰 앱  패치 장치):
  static const int ALARM_CLEAR_RSP = 0xa7;

  ///< 알람/알림 해소 응답 (패치 장치  스마트폰 앱):
  static const int PATCH_RESET_REQ = 0x3F;

  ///< 패치 리셋 위한 명령어 (스마트폰 앱 -> 패치 장치): 2 바이트
  /// Length 2, CMD: 0x3F
  /// CMD  | MODE
  /// 0x3F | 0x00
  //  Mode: 0x00 -> 패치의 Bonding list, NVM 삭제 후 리셋
  //        0x01 -> 패치의 Bonding list, NVM Data 유지 상태 리셋
  static const int PATCH_RESET_RPT = 0x9F;

  ///< 패치리셋 응답 ( 패치 장치 -> 스마트폰 앱)
// Length 2, RPT: 0x9F
// RPT  | MODE
// 0x9F | 0x00
// Mode: 요청 시 받은 모드
// 0x00 -> 패치의 Bonding list, NVM 삭제 후 리셋
// 0x01 -> 패치의 Bonding list, NVM Data 유지 상태 리셋
}

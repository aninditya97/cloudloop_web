/*
 * @brief define test  or feature flag here
 */
//kai_20230522
// if you want just for the purpose of simulation of virtual Pump/Cgm app , then set false
// sometimes, virtual Pump/cgm app does not connect under this flag is set as true.
//If you want auto connection in case of cgm/pump is disconnected not user action, then set "true"
const bool USE_AUTO_CONNECTION = false;

///< if device is disconnected, then try to connect again automatically
///
//kai_20230513 sometimes, app does not receive the response from Pump
//due to RX characteristic's Notify is not enabled after reconnected
//but actually Notify is disabled regardless of isNotifying is true
//that's why we force to enable it here
const bool USE_FORCE_ENABE_RXNOTIFY = true;
//kai_20230613
// push the bloodglucose data sent from the connected CGM device into the remote DB
const bool FORCE_BGLUCOSE_UPDATE_FLAG = true;
//kai_20230714 added to get user confirm for exit app
// if user press back button on the main page then cloudloop show an option
// "All activated services will be terminated. Do you want to exit? [OK | Cancel]"
const bool EXIT_NOTIFY_POPUP_OPTION = true;
//kai_20230719 add to support reconnection in case of disconnecting from CGM & PUMP
const bool USE_RECONNECTION = true;
//kai_20230720 add to save appView's context
const bool USE_APPCONTEXT = true;
//kai_20230724 add to support i-sens cgm broadcasting
const bool USE_ISENSE_BROADCASTING = true;
const bool USE_AUDIO_PLAYBACK = true;
const bool USE_AUDIOCACHE = true;
//kai_20230911 add to match caremedi command in csp-1
const bool USE_CAREMEDI_COMMAND = true;
//kai_20231016 add to reset pump timesync first in case of pressing Stop button
const bool USE_RESET_PUMP_BY_PRESSING_STOP = true;
//kai_20231018 add to use alertPage API in anywhere
const bool USE_ALERT_PAGE_INSTANCE = true;
//kai_20231024 add to check new bloodglucose is incoming during 10 minutes
const bool USE_CHECK_NEW_BG_IS_INCOMING = true;
//kai_20231102 if use virtual as xdrip then use below condition here
const bool USE_XDRIP_AS_VIRTUAL_CGM = true;
//kai_20231219 add to support virtual CGM broadcasting send policyNet bolus to bleperipheral App
const bool USE_BROADCASTING_POLICYNET_BOLUS = true;
//kai_20231227 add to use encryption fo danai5 pump
const bool USE_ENCRYPTION_DECRYPTION_DANAI = true;
//kai_20240106 add to debug message for dana-i5
const bool USE_PUMPDANA_DEBUGMSG = false; // for the purpose of debugging only
//kai_20240106 add to keep dana-i connection
const bool USE_DANAI_KEEPCONNECTION = true;
//kai_20240109 add to check connection command is sent to dana-i5 or not after 5 secs when connection is established
const bool USE_DANAI_CHECK_CONNECTION_COMMAND_SENT = true;
//ka_20240111  add to send encryption start command after sent connection command
const bool USE_SEND_ENCRYPTION_RETRY = false;
const int DANA_CHECK_CONNECTION_COMMAND_SENT_TIMER_VALUE = 1;
const bool USE_CHECK_PAIRED_DEV = true;
//ki_20240121 add to check connection status is connected or not
const bool USE_CHECK_CONNECTION_STATUS = true;
//kai_20240121 add to check start encryption enabled or not
// during communication between app & dana-i
const bool USE_CHECK_ENCRYPTION_ENABLED = false;

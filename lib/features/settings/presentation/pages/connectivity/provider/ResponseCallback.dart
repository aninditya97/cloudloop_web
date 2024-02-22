/*
 * @brief register callback to listen for the response type message sent from PUMP and CGM
 * @detail generally define ResponseCallback type function and register the function
 *         by using setResponseCallbackListener(ResponseCallback callback) which will be provided by IPump and ICgm.
 *         example :
 *         void PumpResponseMessageHandler(RSPType indexRsp, String message, String ActionType){
 *         switch(indexRsp)
 *         {
 *            case 0:
 *
 *                break;
 *
*             case 1:
 *
 *                break;
 *
 *           default:
 *
 *                break;
 *
 *         }
 */

enum RSPType {
  ALERT,

  ///< showALertMsgDlg => _showTXErrorMsgDialog(Title,Msg)
  NOTICE,

  ///< showNoticeMsgDlg => _showTXErrorMsgDialog(String title, String message)
  WARNING,

  ///< showWarningMsgDlg => _showTXErrorMsgDialog(Title,Msg)
  ERROR, //< showTXErrorMsgDlg => _showTXErrorMsgDialog(Title,Msg)
  SETUP_DLG,
  SETUP_INPUT_DLG,

  ///< showSetUpWizardMsgDlg => _showSetupWizardMsgDialog(String title, String message, String actionType)
  TOAST_POPUP,

  ///< _showToastMessage(BuildContext context, String Msg , String ColorType, int showingTime)
  UPDATE_SCREEN,

  ///< update screen value
  PROCESSING_DONE,

  ///< Notify processing done
  MAX_RSPTYPE
}

typedef ActionType = String;

const ActionType HCL_DOSE_CANCEL_REQ = 'HCL_DOSE_CANCEL_REQ';
const ActionType PATCH_DISCARD_REQ = 'PATCH_DISCARD_REQ';
const ActionType CANNULAR_INSERT_RPT_SUCCESS = 'CANNULAR_INSERT_RPT_SUCCESS';
const ActionType CANNULAR_INSERT_RSP_SUCCESS = 'CANNULAR_INSERT_RSP_SUCCESS';
const ActionType INFUSION_INFO_RPT_SUCCESS = 'INFUSION_INFO_RPT_SUCCESS';
const ActionType INFUSION_INFO_RPT_REMAIN_AMOUNT =
    'INFUSION_INFO_RPT_REMAIN_AMOUNT';
const ActionType INFUSION_INFO_RPT_30MIN_REPEATEDLY =
    'INFUSION_INFO_RPT_30MIN_REPEATEDLY';
const ActionType INFUSION_INFO_RPT_RECONNECTED =
    'INFUSION_INFO_RPT_RECONNECTED';
const ActionType SET_TIME_REQ = 'SET_TIME_REQ';
const ActionType SET_TIME_RSP_SUCCESS = 'SET_TIME_RSP_SUCCESS';
const ActionType SET_TIME_RSP_FAILED = 'SET_TIME_RSP_FAILED';
const ActionType INFUSION_THRESHOLD_REQ = 'INFUSION_THRESHOLD_REQ';
const ActionType INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST =
    'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST';
const ActionType INFUSION_THRESHOLD_RSP_FAILED =
    'INFUSION_THRESHOLD_RSP_FAILED';
const ActionType HCL_DOSE_REQ = 'HCL_DOSE_REQ';
const ActionType INFUSION_INFO_REQ = 'INFUSION_INFO_REQ';
const ActionType HCL_BOLUS_RSP_SUCCESS = 'HCL_BOLUS_RSP_SUCCESS';
const ActionType HCL_BOLUS_RSP_FAILED = 'HCL_BOLUS_RSP_FAILED';
const ActionType HCL_BOLUS_RSP_OVERFLOW = 'HCL_BOLUS_RSP_OVERFLOW';
const ActionType HCL_BOLUS_CANCEL_RSP_SUCCESS = 'HCL_BOLUS_CANCEL_RSP_SUCCESS';
const ActionType HCL_BOLUS_CANCEL_RSP_FAILED = 'HCL_BOLUS_CANCEL_RSP_FAILED';
const ActionType CANNULAR_INSERT_RPT = 'CANNULAR_INSERT_RPT';
const ActionType CANNULAR_INSERT_RPT_FAILED = 'CANNULAR_INSERT_RPT_FAILED';
const ActionType CANNULAR_INSERT_RSP_FAILED = 'CANNULAR_INSERT_RSP_FAILED';
const ActionType PATCH_NOTICE_RPT = 'PATCH_NOTICE_RPT';
const ActionType PATCH_WARNING_RPT = 'PATCH_WARNING_RPT';
const ActionType PATCH_ALERT_RPT = 'PATCH_ALERT_RPT';

const ActionType BUZZER_CHECK_RSP = 'BUZZER_CHECK_RSP';
const ActionType BUZZER_CHANGE_RSP = 'BUZZER_CHANGE_RSP';
const ActionType PATCH_DISCARD_RSP_SUCCESS = 'PATCH_DISCARD_RSP_SUCCESS';
const ActionType PATCH_DISCARD_RSP_FAILED = 'PATCH_DISCARD_RSP_FAILED';
const ActionType BUZZER_CHECK_RSP_FAILED = 'BUZZER_CHECK_RSP_FAILED';
const ActionType BUZZER_CHECK_RSP_SUCCESS = 'BUZZER_CHECK_RSP_SUCCESS';
const ActionType BUZZER_CHANGE_RSP_FAILED = 'BUZZER_CHANGE_RSP_FAILED';
const ActionType BUZZER_CHANGE_RSP_SUCCESS = 'BUZZER_CHANGE_RSP_FAILED';
const ActionType PATCH_INFO_REQ = 'PATCH_INFO_REQ';
const ActionType PATCH_INFO_RPT1_SUCCESS = 'PATCH_INFO_RPT1_SUCCESS';
const ActionType PATCH_INFO_RPT1_FAILED = 'PATCH_INFO_RPT1_FAILED';
const ActionType PATCH_INFO_RPT2_SUCCESS = 'PATCH_INFO_RPT2_SUCCESS';
const ActionType PATCH_INFO_RPT2_FAILED = 'PATCH_INFO_RPT2_FAILED';
const ActionType SAFETY_CHECK_RSP_SUCCESS = 'SAFETY_CHECK_RSP_SUCCESS';
const ActionType SAFETY_CHECK_RSP_GOT_1STRSP = 'SAFETY_CHECK_RSP_GOT_1STRSP';
const ActionType SAFETY_CHECK_RSP_LOW_INSULIN = 'SAFETY_CHECK_RSP_LOW_INSULIN';
const ActionType SAFETY_CHECK_RSP_ABNORMAL_PUMP =
    'SAFETY_CHECK_RSP_ABNORMAL_PUMP';
const ActionType SAFETY_CHECK_RSP_LOW_VOLTAGE = 'SAFETY_CHECK_RSP_LOW_VOLTAGE';
const ActionType SAFETY_CHECK_RSP_FAILED = 'SAFETY_CHECK_RSP_FAILED';

const ActionType PATCH_RESET_REQ = 'PATCH_RESET_REQ';
const ActionType PATCH_RESET_RPT = 'PATCH_RESET_RPT';
const ActionType PATCH_RESET_RPT_SUCCESS_MODE0 =
    'PATCH_RESET_RPT_SUCCESS_MODE0';
const ActionType PATCH_RESET_RPT_SUCCESS_MODE1 =
    'PATCH_RESET_RPT_SUCCESS_MODE1';
const ActionType UPDATE_SCREEN = 'UPDATE_SCREEN';

typedef ResponseCallback = void Function(
  RSPType indexRsp,
  String message,
  String ActionType,
);

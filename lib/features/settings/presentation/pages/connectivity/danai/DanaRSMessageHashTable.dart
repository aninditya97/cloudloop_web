import 'dart:collection';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/danai/DanaRSPacket.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DanaRSMessageHashTable {
  late BuildContext mContext;
  final HashMap<int, DanaRSPacket> messages = HashMap<int, DanaRSPacket>();
  //final HasAndroidInjector injector;

  DanaRSMessageHashTable(this.mContext) {
    //kai_20231225 let's check belows later
    /*
    put(DanaRSPacketBasalSetCancelTemporaryBasal(mContext))
    put(DanaRSPacketBasalGetBasalRate(mContext))
    put(DanaRSPacketBasalGetProfileNumber(mContext))
    put(DanaRSPacketBasalSetProfileBasalRate(mContext, 0, arrayOf()))
    put(DanaRSPacketBasalSetProfileNumber(mContext))
    put(DanaRSPacketBasalSetSuspendOff(mContext))
    put(DanaRSPacketBasalSetSuspendOn(mContext))
    put(DanaRSPacketBasalSetTemporaryBasal(mContext))
    put(DanaRSPacketBolusGetBolusOption(mContext))
    put(DanaRSPacketBolusGetCalculationInformation(mContext))
    put(DanaRSPacketBolusGetCIRCFArray(mContext))
    put(DanaRSPacketBolusGetStepBolusInformation(mContext))
    put(DanaRSPacketBolusSetBolusOption(mContext))
    put(DanaRSPacketBolusSet24CIRCFArray(mContext, null))
    put(DanaRSPacketBolusGet24CIRCFArray(mContext))
    put(DanaRSPacketBolusSetExtendedBolus(mContext))
    put(DanaRSPacketBolusSetExtendedBolusCancel(mContext))
    put(DanaRSPacketBolusSetStepBolusStart(mContext))
    put(DanaRSPacketBolusSetStepBolusStop(mContext))
    put(DanaRSPacketEtcKeepConnection(mContext))
    put(DanaRSPacketEtcSetHistorySave(mContext))
    put(DanaRSPacketGeneralInitialScreenInformation(mContext))
    put(DanaRSPacketNotifyAlarm(mContext))
    put(DanaRSPacketNotifyDeliveryComplete(mContext))
    put(DanaRSPacketNotifyDeliveryRateDisplay(mContext))
    put(DanaRSPacketNotifyMissedBolusAlarm(mContext))
    put(DanaRSPacketOptionGetPumpTime(mContext))
    put(DanaRSPacketOptionGetPumpUTCAndTimeZone(mContext))
    put(DanaRSPacketOptionGetUserOption(mContext))
    put(DanaRSPacketOptionSetPumpTime(mContext))
    put(DanaRSPacketOptionSetPumpUTCAndTimeZone(mContext))
    put(DanaRSPacketOptionSetUserOption(mContext))
    //put(new DanaRS_Packet_History_(mContext));
    put(DanaRSPacketHistoryAlarm(mContext))
    put(DanaRSPacketHistoryAllHistory(mContext))
    put(DanaRSPacketHistoryBasal(mContext))
    put(DanaRSPacketHistoryBloodGlucose(mContext))
    put(DanaRSPacketHistoryBolus(mContext))
    put(DanaRSPacketReviewBolusAvg(mContext))
    put(DanaRSPacketHistoryCarbohydrate(mContext))
    put(DanaRSPacketHistoryDaily(mContext))
    put(DanaRSPacketHistoryPrime(mContext))
    put(DanaRSPacketHistoryRefill(mContext))
    put(DanaRSPacketHistorySuspend(mContext))
    put(DanaRSPacketHistoryTemporary(mContext))
    put(DanaRSPacketGeneralGetPumpCheck(mContext))
    put(DanaRSPacketGeneralGetShippingInformation(mContext))
    put(DanaRSPacketGeneralGetUserTimeChangeFlag(mContext))
    put(DanaRSPacketGeneralSetHistoryUploadMode(mContext))
    put(DanaRSPacketGeneralSetUserTimeChangeFlagClear(mContext))
    // APS
    put(DanaRSPacketAPSBasalSetTemporaryBasal(mContext, 0))
    put(DanaRSPacketAPSHistoryEvents(mContext, 0))
    put(DanaRSPacketAPSSetEventHistory(mContext, 0, 0, 0, 0))
    // v3
    put(DanaRSPacketGeneralGetShippingVersion(mContext))
    put(DanaRSPacketReviewGetPumpDecRatio(mContext))

     */
  }

  void put(DanaRSPacket message) {
    messages[message.command] = message;
  }

  DanaRSPacket findMessage(int command) {
    return messages[command] ?? DanaRSPacket(mContext);
  }
}


// Define all other DanaRSPacket classes used in the DanaRSMessageHashTable

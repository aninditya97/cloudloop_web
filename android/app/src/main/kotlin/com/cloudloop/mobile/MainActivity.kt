package com.cloudloop.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.Nullable
import androidx.core.app.NotificationCompat.BubbleMetadata.fromPlatform
import com.cloudloop.mobile.isense.Cgm
import com.cloudloop.mobile.isense.Const
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONException
import org.json.JSONObject
import java.text.SimpleDateFormat
import com.cloudloop.mobile.Intents
import java.util.*
import kotlin.collections.ArrayList
import java.time.LocalDateTime
import kotlin.math.min

//kai_20221122 test flag
const val DEBUG_MESSAGE_FLAG = true;
//kai_20230719 use one receiver which support xdrip and another cgm broadcasting
const val USE_CGM_RECEIVER_TOGETHER = true;
//kai_20231102 use only last item of CGM sent from i-sens
const val USE_LAST_ITEM_ONLY = true;
/**
 * @brief kai_20230727 if use dynamic register broadcasting receiver of i-sens then set true
 *                     in this case don't need to register cgmBCReceiver in androidmanifest.xml
 */
const val USE_DYNAMIC_REGISTER_ISENSE_BR = false;

class MainActivity : FlutterActivity(), EventChannel.StreamHandler {
    val TAG = "CloudLoop:" + MainActivity::class.java.simpleName.toString()
    private val CHANNEL_BLOODGLUCOSE_PAGE = "app.channel.bloodglucose.data"
    private val METHOD_CHANNEL = "app.channel.callmethod"
    private val IAPPLAUNCHER_METHOD_CHANNEL = "iapplauncher"
    private val CHANNEL = "app.channel.shared.data"
    private val CHANNEL_CGM = "app.channel.cgm.data"    //kai_20230717 added for isense cgm broadcasting
    private val POLICYNET_METHOD_CHANNEL = "ipolicynet";
    //kai_20230512 just testing only
    val _USE_SIMULATION = true
    private val sharedText: String? = null
    private var mGlucoseCgmReceiveChannel: EventChannel? = null
    private var mBloodGlucosePageChannel: EventChannel? = null
    private var mCallMethodChannel: MethodChannel? = null
    private var mPolicyNetMethodChannel: MethodChannel? = null
    private var mGlucoseCgmSink: EventChannel.EventSink? =null
    private var mBloodGlucosePageSink: EventChannel.EventSink?= null


    private var glucose = 0f
    private var glucoseDelta = 0f
    private var glucoseold = 0f

    private var glucose_avg = 0f
    private var glucoseDelta_avg = 0f
    private var glucoseold_avg = 0f

    private var g1 = 0f
    private var g2 = 0f
    private var g3 = 0f
    private var g4 = 0f
    private var g5 = 0f
    private var g6 = 0f

    private var g1_avg = 0f
    private var g2_avg = 0f
    private var g3_avg = 0f
    private var g4_avg = 0f
    private var g5_avg = 0f
    private var g6_avg = 0f
    private var tdd_avg = 0f
    private var basalrate_min = 0.0
    private var inserted_init_iob = 0.0
    private var iob = 0f
    private var outputIobX1 = 1.8
    private var outputIobX2 = 1.8

    // private var dia = 0.025 //3in
    private var dia = 0.03

    private var outputIobDx1 = 0.0
    private var outputIobDx2 = 0.0
    private var outInit = 0.0
    private var insulin = 0.0
    private var response = 0.0

    private var final_out = 0.0
    // private var meal_info= -0.689189
    private var meal_info= 0.0 // update=8.26

    private var meal_flag= 0.0
    private var i =0.0
    private var zero_count = 0.0
    private var target = 0.1 //3in

   // private val mDestinationPackageName = "com.androidaps"
    private val mDestinationPackageName = "com.kai.bleperipheral"
   // private val mDestinationReceiverClassName = "com.androidaps.policyNetReceiver"
    private val mDestinationReceiverClassName = "com.kai.bleperipheral.policyNetReceiver"
    private val mSenderActionName = "com.cloudloop.POLICYNET_BROADCAST"

    private val mIsensDataReceiver : BroadcastReceiver = cgmBCReceiver()

    private val mGluecoseCgmReceiver : BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(p0: Context?, p1: Intent?) {
            var action: String = p1?.getAction().toString();

            if (Intents.ACTION_NEW_BG_ESTIMATE.equals(action)) {
                var bundle: Bundle? = p1?.getExtras();
                var glucose_estimateValue: Double? = bundle?.getDouble(Intents.EXTRA_BG_ESTIMATE);
                var timestamp: Long? = bundle?.getLong(Intents.EXTRA_TIMESTAMP);
                var raw: Double? = bundle?.getDouble(Intents.EXTRA_RAW);
                var direction: String? = bundle?.getString(Intents.EXTRA_BG_SLOPE_NAME);
                var source: String? = bundle?.getString(Intents.XDRIP_DATA_SOURCE_DESCRIPTION, "no Source specified");
                var serial: String? = bundle?.getString(Intents.XDRIP_DATA_SOURCE_INFO, "no Source Info specified");
                var calibrationInfo: String? = bundle?.getString(Intents.XDRIP_CALIBRATION_INFO, " no calibration Info");

                if(DEBUG_MESSAGE_FLAG) {
                    Log.d(TAG, "mGluecoseCgmReceiver:glucose_estimateValue = " + glucose_estimateValue.toString() + " ml");
                    Log.d(TAG, "mGluecoseCgmReceiver:timestamp = " + timestamp.toString());
                    Log.d(TAG, "Received DateTime = " + getDate(timestamp));
                    Log.d(TAG, "mGluecoseCgmReceiver:raw = " + raw.toString());
                    Log.d(TAG, "mGluecoseCgmReceiver:direction = " + direction.toString());
                    Log.d(TAG, "mGluecoseCgmReceiver:source = " + source.toString());
                    Log.d(TAG, "mGluecoseCgmReceiver:sensorSerial:source info = " + serial.toString());
                    Log.d(TAG, "mGluecoseCgmReceiver:calibrationInfo = " + calibrationInfo.toString());
                }

                //create  json object format here
                var jsonObj: JSONObject = JSONObject();
                try {
                    jsonObj.put("glucose", glucose_estimateValue.toString());
                    jsonObj.put("timestamp", timestamp.toString());
                    jsonObj.put("raw", raw.toString());
                    jsonObj.put("direction", direction);
                    jsonObj.put("source", source);
                    jsonObj.put("sensorSerial", serial);
                    jsonObj.put("calibrationInfo", calibrationInfo);

                    //  jsonArray.put(jsonObj);
                    //  jsonMain.put("dataSet", jsonArray);
                    // {"glucose":"150.0","timestamp":"1669944611002","raw":"0.0","direction":"Flat","source":"G6 Native / G5 Native"}
                    // Log.d(TAG, "json format = " + jsonMain.toString());
                    if(DEBUG_MESSAGE_FLAG) {
                        Log.d(TAG, "json format = " + jsonObj.toString());
                    }
                } catch ( e: JSONException) {
                    e.printStackTrace();
                }

                // sink.success(Double.toString(glucose_estimateValue));
                // sink.success(jsonMain.toString());
                if(mGlucoseCgmSink != null)
                {
                    Log.d(TAG, "kai: MainActivity.onReceive(): mGlucoseCgmSink send data to the registered caller");
                    mGlucoseCgmSink?.success(jsonObj.toString());
                }
                else
                {
                    Log.d(TAG, "kai: MainActivity.onReceive(): sink is null!!");
                }

            }
            else if (Const.INTENT_CGM_RECEIVED.equals(action))
            {
                if(USE_CGM_RECEIVER_TOGETHER != true)
                {
                    //kai_20230719 to do something here for CGM data
                    var bundle: Bundle? = p1?.getExtras();
                    var glucose_estimateValue: Double? = bundle?.getDouble(Intents.EXTRA_BG_ESTIMATE);
                    var timestamp: Long? = bundle?.getLong(Intents.EXTRA_TIMESTAMP);
                    var raw: Double? = bundle?.getDouble(Intents.EXTRA_RAW);
                    var direction: String? = bundle?.getString(Intents.EXTRA_BG_SLOPE_NAME);
                    var source: String? = bundle?.getString(Intents.XDRIP_DATA_SOURCE_DESCRIPTION, "no Source specified");
                    var serial: String? = bundle?.getString(Intents.XDRIP_DATA_SOURCE_INFO, "no Source Info specified");
                    var calibrationInfo: String? = bundle?.getString(Intents.XDRIP_CALIBRATION_INFO, " no calibration Info");
                    //create  json object format here
                    var jsonObj: JSONObject = JSONObject();
                    try {
                        jsonObj.put("glucose", glucose_estimateValue.toString());
                        jsonObj.put("timestamp", timestamp.toString());
                        jsonObj.put("raw", raw.toString());
                        jsonObj.put("direction", direction);
                        jsonObj.put("source", source);
                        jsonObj.put("sensorSerial", serial);
                        jsonObj.put("calibrationInfo", calibrationInfo);

                        //  jsonArray.put(jsonObj);
                        //  jsonMain.put("dataSet", jsonArray);
                        // {"glucose":"150.0","timestamp":"1669944611002","raw":"0.0","direction":"Flat","source":"G6 Native / G5 Native"}
                        // Log.d(TAG, "json format = " + jsonMain.toString());
                        if(DEBUG_MESSAGE_FLAG) {
                            Log.d(TAG, "json format = " + jsonObj.toString());
                        }
                    } catch ( e: JSONException) {
                        e.printStackTrace();
                    }

                    // sink.success(Double.toString(glucose_estimateValue));
                    // sink.success(jsonMain.toString());
                    if(mGlucoseCgmSink != null)
                    {
                        Log.d(TAG, "kai: MainActivity.onReceive(): mGlucoseCgmSink send data to the registered caller");
                        mGlucoseCgmSink?.success(jsonObj.toString());
                    }
                    else
                    {
                        Log.d(TAG, "kai: MainActivity.onReceive(): sink is null!!");
                    }
                }


            }
            else {
                if(DEBUG_MESSAGE_FLAG) {
                    Log.d(TAG, "onReceive() is called but not handled");
                }
            }

        }

    }

    /**
     * @brief current we use this broadcast receiver at this time.
     */
    private val mBloodGluecosePageReceiver : BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(p0: Context?, p1: Intent?) {
            var action: String = p1?.getAction().toString();
            if(DEBUG_MESSAGE_FLAG) {
                Log.d(TAG,"kai:mBloodGluecosePageReceiver:onReceive() is called ");
            }

            if(action == null)
            {
                return;
            }

            if(DEBUG_MESSAGE_FLAG) {
                Log.d(TAG,"kai:mBloodGluecosePageReceiver:onReceive():intents.action = " + action.toString());
            }

            if (Intents.ACTION_NEW_BG_ESTIMATE.equals(action)) {
                var bundle: Bundle? = p1?.getExtras();
                var glucose_estimateValue: Double? = bundle?.getDouble(Intents.EXTRA_BG_ESTIMATE);
                var timestamp: Long? = bundle?.getLong(Intents.EXTRA_TIMESTAMP);
                var raw: Double? = bundle?.getDouble(Intents.EXTRA_RAW);
                var direction: String? = bundle?.getString(Intents.EXTRA_BG_SLOPE_NAME);
                var source: String? = bundle?.getString(Intents.XDRIP_DATA_SOURCE_DESCRIPTION, "no Source specified");
                var serial: String? = bundle?.getString(Intents.XDRIP_DATA_SOURCE_INFO, "no Source Info specified");
                var calibrationInfo: String? = bundle?.getString(Intents.XDRIP_CALIBRATION_INFO, " no calibration Info");

                if(DEBUG_MESSAGE_FLAG) {
                    Log.d(TAG, "mBloodGluecosePageReceiver:glucose_estimateValue = " + glucose_estimateValue.toString() + " ml");
                    Log.d(TAG, "mBloodGluecosePageReceiver:timestamp = " + timestamp.toString());
                    Log.d(TAG, "Received DateTime = " + getDate(timestamp));
                    Log.d(TAG, "mBloodGluecosePageReceiver:raw = " + raw.toString());
                    Log.d(TAG, "mBloodGluecosePageReceiver:direction = " + direction.toString());
                    Log.d(TAG, "mBloodGluecosePageReceiver:source = " + source.toString());
                    Log.d(TAG, "mBloodGluecosePageReceiver:sensorSerial:source info = " + serial.toString());
                    Log.d(TAG, "mBloodGluecosePageReceiver:calibrationInfo = " + calibrationInfo.toString());
                }
                //create  json object format here
                var jsonObj: JSONObject = JSONObject();
                try {
                    jsonObj.put("glucose", glucose_estimateValue.toString());
                    jsonObj.put("timestamp", timestamp.toString());
                    jsonObj.put("raw", raw.toString());
                    jsonObj.put("direction", direction);
                    jsonObj.put("source", source);
                    jsonObj.put("sensorSerial", serial);
                    jsonObj.put("calibrationInfo", calibrationInfo);

                    if(DEBUG_MESSAGE_FLAG)
                    {
                        Log.d(TAG, "json format = " + jsonObj.toString());
                    }
                } catch ( e: JSONException) {
                    e.printStackTrace();
                }

                if(mBloodGlucosePageSink != null)
                {
                    Log.d(TAG, "kai: mBloodGluecosePageReceiver.onReceive(): mBloodGlucosePageSink send data to the registered caller");
                    mBloodGlucosePageSink?.success(jsonObj.toString());
                }
                else
                {
                    Log.d(TAG, "kai: mBloodGluecosePageReceiver.onReceive(): sink is null!!");
                }

            }
            else if (Const.INTENT_CGM_RECEIVED.equals(action))
            {
                val bundle = p1?.getBundleExtra(Const.EXTRA_CGM_VALUES)
                if(bundle == null)
                {
                    Log.d(TAG, "kai:onReceive(): INTENT_CGM_RECEIVED bundle is null!!");
                    return
                }
                else
                {
                    Log.d(TAG, "kai:INTENT_CGM_RECEIVED bundle!!.size() = " + bundle.size());
                }

                val cgmList: java.util.ArrayList<Cgm> = java.util.ArrayList<Cgm>()
                if(USE_LAST_ITEM_ONLY == true && bundle.size() > 0 )
                {
                    val i =  bundle.size() - 1
                    Log.d(TAG, "kai:INTENT_CGM_RECEIVED bundle!!.size() -1 = " + i);
                    val bundleData = bundle.getBundle(i.toString())
                    if(bundleData == null)
                    {
                        Log.d(TAG, "kai:onReceive(): INTENT_CGM_RECEIVED bundleData is null!!, ");
                        return
                    }
                    val cgm = Cgm()
                    cgm.sequenceNumber = bundleData.getInt(Const.EXTRA_CGM_SEQUENCE) //v1
                    cgm.sensorSerial =
                        bundleData.getString(Const.EXTRA_CGM_SENSOR_SERIAL_NUMBER) //v1
                    cgm.measurementTime = bundleData.getInt(Const.EXTRA_CGM_MEASUREMENT_TIME)
                    cgm.initialValue = bundleData.getFloat(Const.EXTRA_CGM_INITIAL_VALUE) //v1
                    cgm.value = bundleData.getFloat(Const.EXTRA_CGM_FILTERED_VALUE)
                    cgm.trend = bundleData.getInt(Const.EXTRA_CGM_TREND) //v1
                    cgm.trendRate = bundleData.getFloat(Const.EXTRA_CGM_TREND_RATE)
                    cgm.stage = bundleData.getInt(Const.EXTRA_CGM_STAGE) //v1
                    cgm.rawData = bundleData.getString(Const.EXTRA_CGM_RAW_DATA) //v1
                    cgm.errorCode = bundleData.getInt(Const.EXTRA_CGM_ERROR_CODE) //v1
                    cgm.voltage = bundleData.getFloat(Const.EXTRA_CGM_VOLTAGE) //v1
                    cgm.temperature = bundleData.getFloat(Const.EXTRA_CGM_TEMPERATURE) //v1
                    cgm.debug_info = bundleData.getString(Const.EXTRA_CGM_DEBUG_INFO) //v1
                    cgm.calibrationInfo = bundleData.getString(Const.EXTRA_CGM_CALIBRATION_INFO, " no calibration Info");
                    cgmList.add(cgm)

                    //kai_20231114 let's check timestamp is valid or not here
                    var timestamp: Long? = bundleData.getInt(Const.EXTRA_CGM_MEASUREMENT_TIME).toLong()*1000    ///< conpansate the date as milliseconds
                    if(cgm.measurementTime < 0)
                    {
                        //if not valid then get current time here
                        timestamp = System.currentTimeMillis()
                    }

                    val viewData =
                        "sensorSerial:" + cgm.sensorSerial.toString() + "  Seq.:" + cgm.sequenceNumber
                            .toString() + "\ncgm.measurementTime:" + cgm.measurementTime
                            .toString() + "\ncurrentTimeDate:" + getDate(timestamp).toString() + "  value:" + cgm.value
                            .toString() + "\ninitialValue:" + cgm.initialValue.toString() + "  trend:" + cgm.trend.toString() + "  trendRate:" + cgm.trendRate
                            .toString() + "\nstage:" + cgm.stage.toString() + "  errorCode:" + cgm.errorCode.toString() + "  voltage:" + cgm.voltage.toString() + "  temp.:" + cgm.temperature
                            .toString() + "\ncalibrationInfo:" + cgm.calibrationInfo.toString() + "\n";

                    Log.d(TAG,"kai:INTENT_CGM_RECEIVED:" + viewData.toString());

                    //create  json object format here
                    var jsonObj: JSONObject = JSONObject();
                    var glucose_estimateValue: Double? = bundleData.getFloat(Const.EXTRA_CGM_FILTERED_VALUE).toDouble()
                    //var timestamp: Long? = bundleData.getInt(Const.EXTRA_CGM_MEASUREMENT_TIME).toLong()*1000    ///< conpansate the date as milliseconds
                    var raw: Double? = bundleData.getFloat(Const.EXTRA_CGM_INITIAL_VALUE).toDouble()
                    /* I-Sens : careSense Air Cgm
                        Default values of glucose targets
                        very low < 54 <= 70 <= normal < 180 <= high < 250 <= very high

                        Range of glucose output values
                        40 ~ 500mg/dL

                        Unit Conversion
                        (mmol/L value)=(mg/dL value)/18.016

                        trendRate -15.33 ~ +15.33 mg/dL/min, 100 : invalid value

                        TrendType ( 0 ~ 7)
                        "..."           TREND_TYPE_NONE(0)
                        "DoubleDown"    TREND_TYPE_M1(1)
                        "SingleDown"    TREND_TYPE_M1(2)
                        "FortyFiveDown" TREND_TYPE_M1(3)
                        "Flat"          TREND_TYPE_M1(4)
                        "FortyFiveUp"   TREND_TYPE_M1(5)
                        "SingleUp"      TREND_TYPE_M1(6)
                        "DoubleUp"      TREND_TYPE_M1(7)
                     */
                    var direction: String? = "...";
                    if(cgm.trend == 1)
                    {
                        direction = "DoubleDown";
                    }
                    else if(cgm.trend == 2)
                    {
                        direction = "SingleDown";
                    }
                    else if(cgm.trend == 3)
                    {
                        direction = "FortyFiveDown";
                    }
                    else if(cgm.trend == 4)
                    {
                        direction = "Flat";
                    }
                    else if(cgm.trend == 5)
                    {
                        direction = "FortyFiveUp";
                    }
                    else if(cgm.trend == 6)
                    {
                        direction = "SingleUp";
                    }
                    else if(cgm.trend == 7)
                    {
                        direction = "DoubleUp";
                    }
                    else
                    {
                        direction = "...";
                    }

                    var source: String? = "isens.csair";    ///kai-20231013 bundleData.getString(Const.EXTRA_CGM_SENSOR_SERIAL_NUMBER)
                    var serial: String? = bundleData.getString(Const.EXTRA_CGM_SENSOR_SERIAL_NUMBER)
                    var calibrationInfo: String? = bundleData.getString(Const.EXTRA_CGM_CALIBRATION_INFO, " no calibration Info");

                    try {
                        jsonObj.put("glucose", glucose_estimateValue.toString());
                        jsonObj.put("timestamp", timestamp.toString());
                        jsonObj.put("raw", raw.toString());
                        jsonObj.put("direction", direction);
                        jsonObj.put("source", source);
                        jsonObj.put("sensorSerial", serial);
                        jsonObj.put("calibrationInfo", calibrationInfo);

                        if(DEBUG_MESSAGE_FLAG) {
                            Log.d(TAG, "ACTION_CGM_DATA:json format = " + jsonObj.toString());
                        }
                    } catch ( e: JSONException) {
                        e.printStackTrace();
                    }

                    if(mBloodGlucosePageSink != null)
                    {
                        Log.d(TAG, "kai: MainActivity.onReceive():ACTION_CGM_DATA:mBloodGlucosePageSink send data to the registered caller");
                        mBloodGlucosePageSink?.success(jsonObj.toString());
                    }
                    else
                    {
                        Log.d(TAG, "kai: MainActivity.onReceive():ACTION_CGM_DATA:sink is null!!");
                    }

                }
                else
                {
                    for (i in 0 until bundle.size())
                    {
                        val bundleData = bundle.getBundle(i.toString()) ?: continue
                        val cgm = Cgm()
                        cgm.sequenceNumber = bundleData.getInt(Const.EXTRA_CGM_SEQUENCE) //v1
                        cgm.sensorSerial =
                            bundleData.getString(Const.EXTRA_CGM_SENSOR_SERIAL_NUMBER) //v1
                        cgm.measurementTime = bundleData.getInt(Const.EXTRA_CGM_MEASUREMENT_TIME)
                        cgm.initialValue = bundleData.getFloat(Const.EXTRA_CGM_INITIAL_VALUE) //v1
                        cgm.value = bundleData.getFloat(Const.EXTRA_CGM_FILTERED_VALUE)
                        cgm.trend = bundleData.getInt(Const.EXTRA_CGM_TREND) //v1
                        cgm.trendRate = bundleData.getFloat(Const.EXTRA_CGM_TREND_RATE)
                        cgm.stage = bundleData.getInt(Const.EXTRA_CGM_STAGE) //v1
                        cgm.rawData = bundleData.getString(Const.EXTRA_CGM_RAW_DATA) //v1
                        cgm.errorCode = bundleData.getInt(Const.EXTRA_CGM_ERROR_CODE) //v1
                        cgm.voltage = bundleData.getFloat(Const.EXTRA_CGM_VOLTAGE) //v1
                        cgm.temperature = bundleData.getFloat(Const.EXTRA_CGM_TEMPERATURE) //v1
                        cgm.debug_info = bundleData.getString(Const.EXTRA_CGM_DEBUG_INFO) //v1
                        cgm.calibrationInfo = bundleData.getString(Const.EXTRA_CGM_CALIBRATION_INFO, " no calibration Info");
                        cgmList.add(cgm)

                        //kai_20231114 let's check timestamp is valid or not here
                        var timestamp: Long? = bundleData.getInt(Const.EXTRA_CGM_MEASUREMENT_TIME).toLong()*1000    ///< conpansate the date as milliseconds
                        if(cgm.measurementTime < 0)
                        {
                            //if not valid then get current time here
                            timestamp = System.currentTimeMillis()
                        }

                        val viewData =
                            "sensorSerial:" + cgm.sensorSerial.toString() + "  Seq.:" + cgm.sequenceNumber
                                .toString() + "\ncgm.measurementTime:" + cgm.measurementTime
                                .toString() + "\ncurrentTimeDate:" + getDate(timestamp).toString() + "  value:" + cgm.value
                                .toString() + "\ninitialValue:" + cgm.initialValue.toString() + "  trend:" + cgm.trend.toString() + "  trendRate:" + cgm.trendRate
                                .toString() + "\nstage:" + cgm.stage.toString() + "  errorCode:" + cgm.errorCode.toString() + "  voltage:" + cgm.voltage.toString() + "  temp.:" + cgm.temperature
                                .toString() + "\ncalibrationInfo:" + cgm.calibrationInfo.toString() + "\n";

                        Log.d(TAG,"kai:INTENT_CGM_RECEIVED:" + viewData.toString());

                        //create  json object format here
                        var jsonObj: JSONObject = JSONObject();
                        var glucose_estimateValue: Double? = bundleData.getFloat(Const.EXTRA_CGM_FILTERED_VALUE).toDouble()
                        // var timestamp: Long? = bundleData.getInt(Const.EXTRA_CGM_MEASUREMENT_TIME).toLong()*1000    ///< conpansate the date as milliseconds
                        var raw: Double? = bundleData.getFloat(Const.EXTRA_CGM_INITIAL_VALUE).toDouble()
                        /* I-Sens : careSense Air Cgm
                            Default values of glucose targets
                            very low < 54 <= 70 <= normal < 180 <= high < 250 <= very high

                            Range of glucose output values
                            40 ~ 500mg/dL

                            Unit Conversion
                            (mmol/L value)=(mg/dL value)/18.016

                            trendRate -15.33 ~ +15.33 mg/dL/min, 100 : invalid value

                            TrendType ( 0 ~ 7)
                            "..."           TREND_TYPE_NONE(0)
                            "DoubleDown"    TREND_TYPE_M1(1)
                            "SingleDown"    TREND_TYPE_M1(2)
                            "FortyFiveDown" TREND_TYPE_M1(3)
                            "Flat"          TREND_TYPE_M1(4)
                            "FortyFiveUp"   TREND_TYPE_M1(5)
                            "SingleUp"      TREND_TYPE_M1(6)
                            "DoubleUp"      TREND_TYPE_M1(7)
                         */
                        var direction: String? = "...";
                        if(cgm.trend == 1)
                        {
                            direction = "DoubleDown";
                        }
                        else if(cgm.trend == 2)
                        {
                            direction = "SingleDown";
                        }
                        else if(cgm.trend == 3)
                        {
                            direction = "FortyFiveDown";
                        }
                        else if(cgm.trend == 4)
                        {
                            direction = "Flat";
                        }
                        else if(cgm.trend == 5)
                        {
                            direction = "FortyFiveUp";
                        }
                        else if(cgm.trend == 6)
                        {
                            direction = "SingleUp";
                        }
                        else if(cgm.trend == 7)
                        {
                            direction = "DoubleDown";
                        }
                        else
                        {
                            direction = "...";
                        }

                        var source: String? = "isens.csair";    ///kai-20231013 bundleData.getString(Const.EXTRA_CGM_SENSOR_SERIAL_NUMBER)
                        var serial: String? = bundleData.getString(Const.EXTRA_CGM_SENSOR_SERIAL_NUMBER)
                        var calibrationInfo: String? = bundleData.getString(Const.EXTRA_CGM_CALIBRATION_INFO, " no calibration Info");

                        try {
                            jsonObj.put("glucose", glucose_estimateValue.toString());
                            jsonObj.put("timestamp", timestamp.toString());
                            jsonObj.put("raw", raw.toString());
                            jsonObj.put("direction", direction);
                            jsonObj.put("source", source);
                            jsonObj.put("sensorSerial", serial);
                            jsonObj.put("calibrationInfo", calibrationInfo);

                            if(DEBUG_MESSAGE_FLAG) {
                                Log.d(TAG, "ACTION_CGM_DATA:json format = " + jsonObj.toString());
                            }
                        } catch ( e: JSONException) {
                            e.printStackTrace();
                        }

                        if(mBloodGlucosePageSink != null)
                        {
                            Log.d(TAG, "kai: MainActivity.onReceive():ACTION_CGM_DATA:mBloodGlucosePageSink send data to the registered caller");
                            mBloodGlucosePageSink?.success(jsonObj.toString());
                        }
                        else
                        {
                            Log.d(TAG, "kai: MainActivity.onReceive():ACTION_CGM_DATA:sink is null!!");
                        }

                    }
                }


            }
            else {
                if(DEBUG_MESSAGE_FLAG)
                {
                    Log.d(TAG, "mBloodGluecosePageReceiver:onReceive() is called but not handled");
                }
            }

        }

    }

    // convert timestamp to date
    private fun getDate(time_stamp_server: Long?): String? {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        return formatter.format(time_stamp_server)
    }


    // convert timestamp to date
    private fun getDate(time_stamp_server: Long): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
        return formatter.format(time_stamp_server)
    }

    @Override
    protected override fun onCreate(@Nullable savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate()")
    }

    @Override
    protected override fun onStart() {
        super.onStart()
        Log.d(TAG, "onStart()")
    }

    @Override
    protected override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume()")
    }

    @Override
    protected override fun onPause() {
        super.onPause()
        Log.d(TAG, "onPause()")
    }

    @Override
    protected override fun onStop() {
        super.onStop()
        Log.d(TAG, "onStop()")
    }

    @Override
    protected override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "onDestroy()")
    }

    @Override
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
         super.configureFlutterEngine(flutterEngine);
        Log.d(TAG, "kai:configureFlutterEngine()")
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        // register channel to communicate with flutter client app
        this.mCallMethodChannel = MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),METHOD_CHANNEL);
        this.mCallMethodChannel!!.setMethodCallHandler { call, result ->
                when (call.method) {
                    "xdripSettings" -> {
                        if (DEBUG_MESSAGE_FLAG) {
                            Log.d(TAG, "call xdripSettings activity");
                        }
                        result.success("")
                    }
                    "xdripSystemStatus" -> {
                        if (DEBUG_MESSAGE_FLAG) {
                            Log.d(TAG, "call xdripSystemStatus activity");
                        }
                        result.success("")
                    }
                    else -> {
                        result.notImplemented()
                    }

                }

        }
        //kai_20231127 IAppLauncher methodchannel here to check an app is installed or not
        this.mCallMethodChannel = MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),IAPPLAUNCHER_METHOD_CHANNEL);
        this.mCallMethodChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (DEBUG_MESSAGE_FLAG) {
                        Log.d(TAG, "kai:call isAppInstalled " + packageName);
                    }
                    val isInstalled = isAppInstalled(packageName)
                    if (DEBUG_MESSAGE_FLAG) {
                        Log.d(TAG, "kai: isInstalled =  " + isInstalled);
                    }
                    result.success(isInstalled)
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (DEBUG_MESSAGE_FLAG) {
                        Log.d(TAG, "call launchApp " + packageName);
                    }
                    launchApp(packageName)
                }
                else -> {
                    result.notImplemented()
                }

            }

        }


        //kai_20230507 define policynet methodchannel here due to CPolicyNet.java does not called
        // i don't know why it could not be called regardless of registering the same channel"ipolicynet" as flutter used
        this.mPolicyNetMethodChannel = MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), POLICYNET_METHOD_CHANNEL)
        this.mPolicyNetMethodChannel!!.setMethodCallHandler { call, result ->
            android.util.Log.d(TAG, "kai:call PolicyNet: onMethodCall ")
            when (call.method) {
                "execution" -> {
                    val cgmHist: ArrayList<Double?> = call.argument("cgm_hist")!!
                    val timeHist: ArrayList<Int?> = call.argument("time_hist")!!
                    val lastInsulin: Double = call.argument("last_insulin")!!
                    val announceMeal: Int = call.argument("announce_meal")!!
                    val totalDailyDose: Double = call.argument("total_daily_dose")!!
                    val basalRate: Double = call.argument("basal_rate")!!
                    val insulinCarbRatio: Double = call.argument("insulin_carb_ratio")!!
                    val iob: Double = call.argument("iob")!!

                    basalrate_min = basalRate /12.0
                    tdd_avg = ((totalDailyDose - 42.5) / 13.7).toFloat()
                    glucose = (cgmHist[0] as Double).toFloat()
                    glucose_avg = ((glucose-140)/44).toFloat();

                    glucoseold = (cgmHist[1] as Double).toFloat()    
                    glucoseold_avg = ((glucoseold-140)/44).toFloat();

                    glucoseDelta = glucose - glucoseold       
                    glucoseDelta_avg = (glucoseDelta/10).toFloat();
    
                    g1 = (cgmHist[0] as Double).toFloat()
                    g1_avg = ((g1-140)/44).toFloat();
    
                    insulin = lastInsulin // this is the value of injected insulin of previous iteration

                    //insulin = response

                    if (announceMeal == 1){
                        meal_flag = 48.0 - i;
                        i += 1.0;
                        if (meal_flag <=0.0){
                            meal_flag = 0.0
                            i = 0.0;
                        }                        
                    }
                    else if (announceMeal == 2){
                        meal_flag = 96.0 - i;
                        i += 2.0;
                        if (meal_flag <=0.0){
                            meal_flag = 0.0
                            //i = 0.0;
                        }                        
                    }
                    else {
                        meal_flag = 0.0;
                        i = 0.0;
                    }
                    meal_info = (meal_flag/480.0); //// update=8.26

                    // for (i in 0..4) {
                    //     outputIobDx1 = insulin - (dia * outputIobX1) // this insulin will get from page 5
                    //     outputIobDx2 = (dia * outputIobX1) - (dia * outputIobX2)
                    //     // adding minimum iob information x1 and x2
                    //     outputIobX1 = outputIobX1 + outputIobDx1
                    //     outputIobX2 = outputIobX2 + outputIobDx2
                    //     insulin = 0.0
                    // }

                    // iob = ((outputIobX1 + outputIobX2 - 2.2) / 2.1).toFloat()


                    val now = LocalDateTime.now()          
                    val hour = now.getHour();
                    val minute = now.getMinute();
            
                    val currentMinuteOfDay = ((hour * 60) + minute);  

                    Log.d("PostechAps", " cgmHist: " +  cgmHist)
                    Log.d("PostechAps", " minutesOfDayNow: " +  currentMinuteOfDay)
                    Log.d("PostechAps", " timeHist: " +  timeHist)
                    Log.d("PostechAps", " glucoseold: " +  glucoseold)
                    Log.d("PostechAps", " glucose: " +  glucose)
                    Log.d("PostechAps", " g1: " +  g1)
                    Log.d("PostechAps", " g2: " +  g2)
                    // Log.d("PostechAps", " g4: " +  g4)
                    Log.d("PostechAps", " glucose_avg: " +  glucose_avg);
                    Log.d("PostechAps", " glucoseDelta: " +  glucoseDelta)
                    Log.d("PostechAps", " glucoseDelta_avg: " +  glucoseDelta_avg);
                    Log.d("PostechAps", " announceMeal: " +  announceMeal);
                    Log.d("PostechAps", " meal_flag: " +  meal_flag);
                    Log.d("PostechAps", " meal_info: " +  meal_info);
                    Log.d("PostechAps", " outputIobX1: " +  outputIobX1);
                    Log.d("PostechAps", " outputIobX2: " +  outputIobX2);
                    Log.d("PostechAps", " iob: " +  iob);

                    Log.d("PostechAps", " totalDailyDose: " +  totalDailyDose)
                    Log.d("PostechAps", " inserted_init_iob: " + inserted_init_iob);
                    Log.d("PostechAps", " basalRate: " +  basalRate)

                    //response = (OpenAPSPOSTECHPlugin.doModuleForward(glucose_avg, glucoseDelta_avg, iob, context) as Float).toDouble() // DOMUDULE.....
                    // if(currentMinuteOfDay >= 0.0 && currentMinuteOfDay < (6*60) ){
                    //     target = 0.1
                    // } else if (currentMinuteOfDay > (22 * 60)){
                    //     target = 0.1
                    // } else {
                    //     target = 0.0
                    // }
                    target = 0.1  //3in     
                    // target = 0.0

                    response = (OpenAPSPOSTECHPlugin.doModuleForward(glucose_avg, glucoseDelta_avg, meal_info.toFloat(), iob.toFloat(), tdd_avg, target.toFloat(), context) as Float).toDouble() //3in                     

                    // response is original before convertion
                    final_out = response

                    var glucosedeltapermin = glucoseDelta / 5.0
                    val basalrateday = totalDailyDose / 24.0 / 12.0

                    if(final_out < 0.0){
                        final_out = (final_out * 0.3) + 0.3
                    } else {
                        final_out = (final_out* 0.7) + 0.3
                    }

                    final_out = (Math.round(final_out * 50.0) / 50.0);

                    if (glucose <= 80.0){
                        final_out = 0.0
                    }
           
                    // clogging prevention
                    if (final_out == 0.0){
                        zero_count += 1.0
                        if (zero_count >=10.0 && glucose >= 180){
                            final_out = 0.02
                            zero_count = 0.0
                        }
                        if (zero_count >=15.0 && glucose >= 70){
                            final_out = 0.02
                            zero_count = 0.0
                        }
                        if (zero_count >=12.0){
                            final_out = 0.02
                            zero_count = 0.0
                        }                     
                    } else{
                        zero_count = 0.0
                    }         
                    
                    
                    
                    Log.d("PostechAps", " zero_count: " +  zero_count);
                    Log.d("PostechAps", " response: " +  response);
                    Log.d("PostechAps", " final_out: " +  final_out);

                    result.success(final_out)
                }
                "init" -> {
                    Init()
                    result.success(null)
                }
                "dispose" -> {
                    Dispose()
                    result.success(null)
                }
                "iob" -> {
                    val lastInsulin: Double = call.argument("last_insulin")!!
                    
                    for (i in 0..4) {
                        outputIobDx1 = lastInsulin - (dia * outputIobX1) // this insulin will get from page 5
                        outputIobDx2 = (dia * outputIobX1) - (dia * outputIobX2)
                        outputIobX1 = outputIobX1 + outputIobDx1
                        outputIobX2 = outputIobX2 + outputIobDx2
                        insulin = 0.0
                    }

                    iob = ((outputIobX1 + outputIobX2 - 2.2) / 2.1).toFloat()

                    Log.d("PostechAps", " iob: " +  iob);

                    result.success(iob)
                }
                "broadcasting" ->{
                    val bolus: Double = call.argument("policyNetBolus")!!
                    val pkgName: String = call.argument("destinationPkgName")!!
                    val valueToSend = bolus // policyNet result
                    val destinationReceiverClassName: String = packageName + ".policyNetReceiver"
                    val bundle = Bundle()
                    //bundle.putFloat("policyNetBolus", valueToSend)   // key value "bolus"
                    bundle.putDouble("policyNetBolus", valueToSend)   // key value "bolus"
                    val intent = Intent()
                    intent.action = mSenderActionName // intent.action

                    //ComponentName componentName = new ComponentName(mDestinationPackageName, mDestinationReceiverClassName);
                    //intent.setComponent(componentName);
                    if(pkgName != null && pkgName.isNotEmpty())
                    {
                        Log.d("broadcasting", " :policyNetBolus= " +  valueToSend + ", destinationPkgName= " + pkgName)
                        intent.setClassName(pkgName, pkgName + ".policyNetReceiver")
                    }
                    else
                    {
                        Log.d("broadcasting", " :policyNetBolus= " +  valueToSend + ", default destinationPkgName= " + mDestinationPackageName)
                        intent.setClassName(mDestinationPackageName, mDestinationReceiverClassName)
                    }
                    intent.putExtras(bundle)
                    Log.d("PostechAps", " bolus: " +  valueToSend)
                    Log.d("PostechAps", " mDestinationPackageName: " +  packageName)
                    Log.d("PostechAps", " mDestinationReceiverClassName: " +  destinationReceiverClassName)

                    sendBroadcast(intent) // send policyNetBolus to destination application's receiver
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // register StreamHandler after create EventChannel
        this.mBloodGlucosePageChannel = EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(),CHANNEL_BLOODGLUCOSE_PAGE);
        this.mBloodGlucosePageChannel!!.setStreamHandler(this)

        if(USE_CGM_RECEIVER_TOGETHER != true)
        {
            // register StreamHandler after create EventChannel of cgm device which use android broadcasting method
            this.mGlucoseCgmReceiveChannel =
                EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_CGM);
            this.mGlucoseCgmReceiveChannel!!.setStreamHandler(this)
        }
    }

    /**
     * @brief PolicyNet API define here
     * let's implement OpenAPSPOSTECHPlugin_2's method here
     */
    fun Init() {
        // To do something ...ex) download latest policyNet version
        android.util.Log.d(TAG, "kai:call PolicyNet: Init ")
    }

    fun execution(cgm_hist: ArrayList<Double?>): Double {
        // Implementation
        android.util.Log.d(TAG, "kai:call PolicyNet: execution ")
        if (_USE_SIMULATION == true) {
            val bg: Double = cgm_hist.get(0)!!
            return estimatedInsulin(bg.toInt())
        }
        /*
            //this part still combine python and java, please help to uniform to java
            CGM =(float)cgm_hist[0];
            IOB =(float)calcIob(insulin_hist);
            dCGM =(float)calcDcgmdt(cgm_hist);
            dcgm_hist.append(dCGM)
            d2CGM = (float)calcDcgmdt(dcgm_hist);

            Result result = doModuleForward(CGM,dCGM,IOB,d2CGM);  /////////////need to confirm postech aps

            InsulinInput retInsulinInput= GetInsulinInput(result.scores[0]);
            if (retInsulinInput.fBasalUnit > 0 && m_fCurGlu > 85 )
            {
                return (Double)retInsulinInput.fBasalUnit;
            }
            else
            {
                return (Double)0.0f;
            }
         */

        return 0.0
    }

    fun Dispose() {
        // ...
        android.util.Log.d(TAG, "kai:call PolicyNet: Dispose ")
    }

    /*

    private ArrayList<Entry> mValues1 = new ArrayList<>();
    private ArrayList<Entry> mValues2 = new ArrayList<>();
    protected Handler mBackgroundHandler;
    private Module mModule=null;
    private FloatBuffer mInputTensorBuffer;
    private Tensor mInputTensor;
    private StringBuilder mTextViewStringBuilder = new StringBuilder();

    private float m_fCurGlu=0;
    private float m_fCurIOB=0;
    private float m_fGluDt=0;
    private float m_fGluD2t=0;


    private static int m_iCnt=100;

    float fCGM_mean =(float)130.844696044922;
    float fCGM_std =(float)34.3600959777832;
    float fCGMdt_mean =(float)-0.00446680700406432;
    float fCGMdt_std =(float)0.786847114562988;
    float fCGMd2t_mean =(float)0.01;
    float fCGMd2t_std =(float)0.01;
    float fIOB_mean =(float)1.28514540195465;
    float fIOB_std =(float)0.482856333255768;

    int iIndex=0;


    static class Result
    {
        private final float[] scores;
        private final long totalDuration;
        private final long moduleForwardDuration;
        private float fMax=0;
        private float fMin=0;
        private int iMaxIndex;

        public Result(float[] scores, long moduleForwardDuration, long totalDuration) {
            float max=-999999;
            for(int i=0;i<scores.length;i++)
            {
                if(scores[i]>max)
                {
                    max=scores[i];
                    iMaxIndex=i;
                }
            }
            Arrays.sort(scores);
            this.fMin = scores[0];
            this.fMax = scores[scores.length-1];
            this.scores = scores;
            this.moduleForwardDuration = moduleForwardDuration;
            this.totalDuration = totalDuration;
        }
    }

     public static InsulinInput GetInsulinInput(float iIndex)
    {
        InsulinInput retInsulin = new InsulinInput();
        double fInsulinTotal=0;
        fInsulinTotal =iIndex;
        retInsulin.fBasalUnit = (float) (fInsulinTotal);//         #0.06 ~0.08 U / h

        return retInsulin;//
    }

	public double calcIob(ArrayList<double> insHist) {
		final double ALPHA = 2.0;
		final double SCALE = this.SCALE; // 1.5
		final int INSULIN_ACTIVATION_TIME = (int) (this.ACT_TIME * (60 / this.sample_time)); // sample_time = 5, ACT_TIME = 5
		double IOB = 0.0;
		double hour = 0.0;
		for (int timeidx = 0; timeidx < INSULIN_ACTIVATION_TIME; timeidx++) {
			double insulin = insHist.get(insHist.size() - INSULIN_ACTIVATION_TIME + timeidx);
			hour = (double) timeidx / 20.0;
			IOB += (1 - Gamma.regularizedGammaP(ALPHA, hour / SCALE)) * insulin;
		}
		return IOB;
	}

	public double calcDcgmdt(ArrayList<double> cgmHist) {
		ArrayList<double> lastCgm = new ArrayList<>();
		ArrayList<double> dcgmdt = new ArrayList<>();
		final int HORIZON = 1;
		final double SCALE = 1.0;
		for (int timeidx = 0; timeidx < cgmHist.size(); timeidx++) {
			double cgm = cgmHist.get(cgmHist.size() - timeidx - 1);
			lastCgm.add(cgm);
			if (timeidx > 0 && timeidx == HORIZON) {
				dcgmdt.add(lastCgm.get(lastCgm.size() - 2) - lastCgm.get(lastCgm.size() - 1));
				break;
			}
		}
		double dCGMdt = dcgmdt.stream().mapToDouble(double::doubleValue).sum() / (SCALE * this.sample_time);
		return dCGMdt;
	}

    protected Result doModuleForward(float fGlcos,float fCurGlucosDt,float fCurIob, float fCurGlucosD2t)
    {
        if (mModule == null) {
            final long[] shape = new long[]{1, 4};
            long numElements = 1;
            for (int i = 0; i < shape.length; i++) {
                numElements *= shape[i];
            }
            mInputTensorBuffer = Tensor.allocateFloatBuffer((int) numElements);

            mModule = Config.m_PostechModuel; //this is loaded model

        }

        float norm_CGM = (fGlcos-fCGM_mean)/fCGM_std;
        float norm_dCGMdt = (fCurGlucosDt-fCGMdt_mean)/fCGMdt_std;
        float norm_IOB = (fCurIob-fIOB_mean)/fIOB_std;
        float norm_dCGMd2t = (fCurGlucosD2t-fCGMd2t_mean)/fCGMd2t_std;

        mInputTensorBuffer.put(0,norm_CGM);
        mInputTensorBuffer.put(1,norm_dCGMdt);
        mInputTensorBuffer.put(2,norm_IOB);
        mInputTensorBuffer.put(3,norm_dCGMd2t);

        Config.m_lastInslInput.fGlucos = fGlcos;
        Config.m_lastInslInput.fGlucosDt = fCurGlucosDt;
        Config.m_lastInslInput.fIOB = fCurIob;
        Config.m_lastInslInput.fGlucosD2t = fCurGlucosD2t;

        mInputTensor = Tensor.fromBlob(mInputTensorBuffer, new long[]{1, 4});
        PyTorchAndroid.setNumThreads(1);
        final long startTime = SystemClock.elapsedRealtime();
        final long moduleForwardStartTime = SystemClock.elapsedRealtime(); //Start Time
        final Tensor outputTensor = mModule.forward(IValue.from(mInputTensor)).toTensor();// policy-net Forward
        final long moduleForwardDuration = SystemClock.elapsedRealtime() - moduleForwardStartTime; //forward Time
        final float[] scores = outputTensor.getDataAsFloatArray();
        final long analysisDuration = SystemClock.elapsedRealtime() - startTime;

        Log.i("PostechAps", " doModuleForward norm_CGM: " +  norm_CGM);
        Log.i("PostechAps", " doModuleForward norm_dCGMdt: " +  norm_dCGMdt);
        Log.i("PostechAps", " doModuleForward norm_IOB: " +  norm_IOB);
        Log.i("PostechAps", " doModuleForward norm_dCGMd2t: " +  norm_dCGMd2t);

        Log.i("PostechAps", " doModuleForward fGlcos: " +  fGlcos);
        Log.i("PostechAps", " doModuleForward fCurGlucosDt: " +  fCurGlucosDt);
        Log.i("PostechAps", " doModuleForward fCurIob: " +  fCurIob);
        Log.i("PostechAps", " doModuleForward fCurGlucosD2t: " +  fCurGlucosD2t);

        return new Result(scores, moduleForwardDuration, analysisDuration);
        }

     */
    //kai_20230512 simulation bolus calculation
    /* Insulin Assisted Corrective Dose Determination Protocol (1U = 0.01 mg)
        ====================================================================================
        gloodglucose(mg/dL) || Very sensitive || Sensitive  ||     Usual    ||  Resistant
        ====================================================================================
        140 ~ 180           ||      +1U       ||    +2U     ||      +4U     ||      +6U
        181 ~ 220           ||      +2U       ||    +4U     ||      +6U     ||      +8U
        221 ~ 260           ||      +4U       ||    +6U     ||      +8U     ||      +10U
        261 ~ 300           ||      +6U       ||    +8U     ||      +10U    ||      +12U
        301 ~ 350           ||      +8U       ||    +10U    ||      +12U    ||      +14U
        351 ~ 400           ||      +10U      ||    +12U    ||      +14U    ||      +16U
        > 400               ||      +12U      ||    +14U    ||      +16U    ||      +18U
        ====================================================================================
     */
    fun estimatedInsulin(BGValue: Int): Double {
        //let's use Usual Case
        if (BGValue >= 140 && BGValue <= 180) {
            return 0.04
        } else if (BGValue >= 181 && BGValue <= 220) {
            return 0.06
        } else if (BGValue >= 221 && BGValue <= 260) {
            return 0.08
        } else if (BGValue >= 261 && BGValue <= 300) {
            return 0.10
        } else if (BGValue >= 301 && BGValue <= 350) {
            return 0.12
        } else if (BGValue >= 351 && BGValue <= 400) {
            return 0.14
        } else if (BGValue >= 401) {
            return 0.16
        }
        return 0.00
    }



    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {

        if(DEBUG_MESSAGE_FLAG) {
            Log.d(TAG, "kai:onListen is called");
        }
        if (events != null) {
            var argu: String = arguments as String
            if(DEBUG_MESSAGE_FLAG) {
                Log.d(TAG, "kai:onListen(): arguments = " + arguments.toString());
            }
            if(argu.equals(CHANNEL_BLOODGLUCOSE_PAGE))
            {
                mBloodGlucosePageSink = events
                if(DEBUG_MESSAGE_FLAG) {
                    Log.d(TAG, "kai:onListen: registerReceiver(mBloodGluecosePageReceiver) is called");
                }
                var filter: IntentFilter = IntentFilter(Intents.ACTION_NEW_BG_ESTIMATE);
                filter.addAction(Intents.ACTION_NEW_BG_ESTIMATE_NO_DATA);
                filter.addAction(Intents.ACTION_STATUS_UPDATE);
                if(USE_CGM_RECEIVER_TOGETHER == true)
                {
                    filter.addAction(Const.INTENT_CGM_RECEIVED);
                }
                getApplicationContext().registerReceiver(mBloodGluecosePageReceiver, filter);

                if(USE_DYNAMIC_REGISTER_ISENSE_BR == true)
                {
                    //kai_20230727 test only
                    var isensefilter: IntentFilter = IntentFilter(Const.ISENS_CGM);
                    getApplicationContext().registerReceiver(mIsensDataReceiver, isensefilter);
                    if(DEBUG_MESSAGE_FLAG) {
                        Log.d(TAG,"kai:onListen: registerReceiver(mIsensDataReceiver) is called");
                    }
                }

            }
            else if(argu.equals(CHANNEL_CGM))
            {
                if(USE_CGM_RECEIVER_TOGETHER != true)
                {
                    mGlucoseCgmSink = events
                    if(DEBUG_MESSAGE_FLAG) {
                        Log.d(TAG, "kai:onListen: registerReceiver(mGluecoseCgmReceiver) is called");
                    }
                    var filter: IntentFilter = IntentFilter(Intents.ACTION_NEW_BG_ESTIMATE);
                    filter.addAction(Intents.ACTION_NEW_BG_ESTIMATE_NO_DATA);
                    filter.addAction(Intents.ACTION_STATUS_UPDATE);
                    filter.addAction(Const.INTENT_CGM_RECEIVED);
                    getApplicationContext().registerReceiver(mGluecoseCgmReceiver, filter);
                }

            }

        };
    }

    override fun onCancel(arguments: Any?) {
        if(DEBUG_MESSAGE_FLAG) {
            Log.d(TAG, "kai:onCancel is called")
        }
        if(arguments != null) {
            var argu: String = arguments as String
            if (argu.equals(CHANNEL_BLOODGLUCOSE_PAGE)) {
                if(DEBUG_MESSAGE_FLAG) {
                    Log.d(TAG,"kai:onCancel: unregisterReceiver(mBloodGluecosePageReceiver) is called");
                }
                getApplicationContext().unregisterReceiver(mBloodGluecosePageReceiver);
                if(USE_DYNAMIC_REGISTER_ISENSE_BR == true) {
                    //kai_20230727 test only
                    var isensefilter: IntentFilter = IntentFilter(Const.ISENS_CGM);
                    getApplicationContext().unregisterReceiver(mIsensDataReceiver);
                    if(DEBUG_MESSAGE_FLAG) {
                        Log.d(TAG,"kai:onCancel: unregisterReceiver(mIsensDataReceiver) is called");
                    }
                }

                this.mBloodGlucosePageSink = null
                this.mBloodGlucosePageChannel = null

            } else if (argu.equals(CHANNEL_CGM)) {
                if(USE_CGM_RECEIVER_TOGETHER != true)
                {
                    if(DEBUG_MESSAGE_FLAG) {
                        Log.d(TAG, "kai:onCancel: unregisterReceiver(mGluecoseCgmReceiver) is called");
                    }
                    getApplicationContext().unregisterReceiver(mGluecoseCgmReceiver);
                    this.mGlucoseCgmSink = null
                    this.mGlucoseCgmReceiveChannel = null
                }

            }
        }
    }


    fun getDateTime(t: Int): String? {
        val formatter = SimpleDateFormat(Const.ISO8601_DATEFORMAT)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        return StringBuilder(formatter.format(t)).insert(22, ":").toString()
    }

    /*
    *@brief implement IAppLauncher API here
     */
    private fun isAppInstalled(packageName: String?): Boolean {
        try {
            val packageInfo = packageName?.let {
                packageManager.getPackageInfo(it, PackageManager.GET_ACTIVITIES)
            }

            if (DEBUG_MESSAGE_FLAG) {
                Log.d(TAG, "kai:isAppInstalled:packageInfo " + packageInfo);
            }

            if(packageInfo != null)
            {
                 return true
            }
            else
            {
                return false
            }
        } catch (e: PackageManager.NameNotFoundException) {
            return false
        }
    }

    private fun launchApp(packageName: String?) {
        packageName?.let {
            val intent: Intent? = packageManager.getLaunchIntentForPackage(it)
            intent?.let {
                startActivity(it)
            }
        }
    }

}

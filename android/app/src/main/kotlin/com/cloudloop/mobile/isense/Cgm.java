package com.cloudloop.mobile.isense;

public class Cgm {
    public String sensorSerial = "";
    public Integer sequenceNumber = 0;
    public Float initialValue = 0.0f; // glucose value
    public Float trendRate = 0.0f;
    public Integer trend = 0;   // TrendType
    public Float value = 0.0f;
    public Integer stage = 0;
    public Integer measurementTime = 0; //UTC time seconds
    public String rawData = "";
    public Integer errorCode = 0;
    public Float voltage = 0.0f;
    public Float temperature = 0.0f;
    public String debug_info = "";
    public String calibrationInfo = "";
}

import 'dart:developer';
//kai_20240127  import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

class TransmitterData {
  TransmitterData({
    this.raw_data = 0,
    this.sensor_battery_level = 0,
    this.filtered_data,
    this.id,
    this.timestamp,
    this.uuid,
  });
  int? raw_data;
  int? filtered_data;
  int? sensor_battery_level;
  int? timestamp;
  String? uuid;
  int? id;

  TransmitterData? create(Uint8List buffer, int len, int? timestamp) {
    if (len < 6) {
      return null;
    }

    final transmitterData = TransmitterData();

    try {
      if ((buffer[0] == 0x11 || buffer[0] == 0x15) && buffer[1] == 0x00) {
        // this is a dexbridge packet.  Process accordingly.
        log('Processing a Dexbridge packet');

        final txData = List<int>.from(Uint8List(len).buffer.asUint8List());
        final buffer = Uint8List.fromList(txData);
        final byteData = ByteData.view(buffer.buffer);
        final transmitterData = TransmitterData()
          ..raw_data = byteData.getInt32(2, Endian.little)
          ..filtered_data = byteData.getInt32(6, Endian.little)
          ..sensor_battery_level = byteData.getUint8(10);

        if (buffer[0] == 0x15) {
          log('Processing a Dexbridge packet includes delay information');
          // transmitterData.timestamp = timestamp! - txData.getInt(16);
          transmitterData.timestamp =
              timestamp! - byteData.getInt32(16, Endian.little);
        } else {
          transmitterData.timestamp = timestamp;
        }

        log('Created transmitterData record with Raw value of '
            '${transmitterData.raw_data} and Filtered value of '
            '${transmitterData.filtered_data} at $timestamp with '
            'timestamp ${transmitterData.timestamp}');
      } else {
        // this is NOT a dexbridge packet.  Process accordingly.
        log('Processing a BTWixel or IPWixel packet');
        //StringBuilder data_string = new StringBuilder();
        final dataString = StringBuffer();
        for (var i = 0; i < len; ++i) {
          // data_string.append(String.fromCharCode(buffer[i]));
          dataString.writeCharCode(buffer[i]);
        }
        final data = dataString.toString().split(r'\s+');

        if (data.length > 1) {
          transmitterData.sensor_battery_level = int.parse(data[1]);

          if (data.length > 2) {
            try {
              /*
              Pref.setInt("bridge_battery", int.parse(data[2]));
              if (Home.get_master()) {
                GcmActivity.sendBridgeBattery
                (Pref.getInt("bridge_battery", -1));
              }

              CheckBridgeBattery.checkBridgeBattery();
               */
            } catch (e) {
              log('Got exception processing classic wixel or limitter '
                  'battery value: $e');
            }
            if (data.length > 3) {
              /*
              if ((DexCollectionType.getDexCollectionType() == 
              exCollectionType.LimiTTer) && 
              (!Pref.getBooleanDefaultFalse("use_transmiter_pl_bluetooth"))) {
                try {
                  // reported sensor age in minutes
                  final int sensorAge = int.parse(data[3]);
                  if ((sensorAge > 0) && (sensorAge < 200000))
                    Pref.setInt("nfc_sensor_age", sensorAge);
                } catch (e) {
                 log("Got exception processing field 4 in classic 
                 limitter protocol: $e");
                }
              }
              */
            }
          }
        }
        transmitterData
          ..raw_data = int.parse(data[0])
          ..filtered_data = int.parse(data[0])
          // TODO process does_have_filtered_here with extended protocol
          ..timestamp = timestamp;
      }
/*
      // Stop allowing readings that are older than the last one - or duplicate data, its bad! (from savek-cc)
      final TransmitterData lastTransmitterData = TransmitterData.last();
      if (lastTransmitterData != null && lastTransmitterData.timestamp >= 
      transmitterData.timestamp) {
        debugPrint("Rejecting TransmitterData constraint: last: " + 
        JoH.dateTimeText(lastTransmitterData.timestamp) + " >= this: " + 
        JoH.dateTimeText(transmitterData.timestamp));
        return null;
      }
      if (lastTransmitterData != null && lastTransmitterData.raw_data == 
      transmitterData.raw_data && Math.abs(lastTransmitterData.timestamp - 
      transmitterData.timestamp) < (Constants.MINUTE_IN_MS * 2)) {
        debugPrint("Rejecting identical TransmitterData constraint: last: " + 
        JoH.dateTimeText(lastTransmitterData.timestamp) + " due to 2 minute 
        rule this: " + JoH.dateTimeText(transmitterData.timestamp));
        return null;
      }
      final Calibration lastCalibration = Calibration.lastValid();
      if (lastCalibration != null && lastCalibration.timestamp > 
      transmitterData.timestamp) {
        debugPrint( "Rejecting historical TransmitterData constraint: calib: " 
        + JoH.dateTimeText(lastCalibration.timestamp) + " > this: " 
        + JoH.dateTimeText(transmitterData.timestamp));
        return null;
      }

      transmitterData.uuid = UUID.randomUUID().toString();
      transmitterData.save();
      */
      return transmitterData;
    } catch (e) {
      debugPrint('Got exception processing fields in protocol: $e $buffer');
    }
    return null;
  }

  static TransmitterData? create1(
    int rawData,
    int filteredData,
    int sensorBatteryLevel,
    int timestamp,
  ) {
    /*
    TransmitterData? lastTransmitterData = TransmitterData.last();
    if (lastTransmitterData != null && lastTransmitterData.rawData == rawData && (lastTransmitterData.timestamp - DateTime.now().millisecondsSinceEpoch).abs() < (Constants.minuteInMs * 2)) { //Stop allowing duplicate data, its bad!
      return null;
    }

     */

    final transmitterData = TransmitterData()
      ..sensor_battery_level = sensorBatteryLevel
      ..raw_data = rawData
      ..filtered_data = filteredData
      ..timestamp = timestamp as int?;
    //transmitterData.uuid = Uuid().v4();
    //transmitterData.save();
    return transmitterData;
  }
/*
  static TransmitterData? create(
      int raw_data, int sensor_battery_level, int timestamp) {
    TransmitterData? lastTransmitterData = TransmitterData.last();
    if (lastTransmitterData != null &&
        lastTransmitterData.raw_data == raw_data &&
        (lastTransmitterData.timestamp - 
        DateTime.now().millisecondsSinceEpoch).abs() <
            (Constants.MINUTE_IN_MS * 2)) {
      //Stop allowing duplicate data, its bad!
      return null;
    }

    TransmitterData transmitterData = TransmitterData(
      raw_data: raw_data,
      sensor_battery_level: sensor_battery_level,
      timestamp: timestamp,
      uuid: Random().nextInt(pow(2, 32)).toString(),
    );
    transmitterData.save();
    return transmitterData;
  }
*/

  TransmitterData? last() {
    // return Select().from(TransmitterData).orderBy("_ID desc").executeSingle();
    return null;
  }

  List<TransmitterData>? lasts(int count) {
    //  return Select().from(TransmitterData).orderBy("_ID desc").
    // limit(count).execute();
    return null;
  }

  TransmitterData? lastByTimestamp() {
    // return Select().from(TransmitterData).
    //orderBy("timestamp desc").executeSingle();
    return null;
  }

  static void updateTransmitterBatteryFromSync(int batteryaLevel) {
    /*
    try {
      TransmitterData td = TransmitterData.last();
      if ((td == null) || (td.raw_data != 0)) {
        td = TransmitterData.create(0, battery_level, JoH.ts().toInt());
       log('Created new fake transmitter data record for battery sync');
        if (td == null) return;
      }
      if ((battery_level != td.sensor_battery_level) || ((JoH.ts() - 
      td.timestamp) > (1000 * 60 * 60))) {
        td.sensor_battery_level = battery_level;
        td.timestamp = JoH.ts().toInt(); // freshen timestamp on this bogus record for system status
       log('Saving synced sensor battery, new level: $battery_level');
        td.save();
      } else {
       log('Synced sensor battery level same as existing: $battery_level');
      }
    } catch (e) {
     log('Got exception updating sensor battery from sync: $e');
    }

     */
  }

  static double roundRaw(TransmitterData td) {
    // return JoH.roundDouble(td.raw_data, 3);
    return 0;
  }

  static double roundFiltered(TransmitterData td) {
    //  return JoH.roundDouble(td.filtered_data, 3);
    return 0;
  }

  static bool unchangedRaw() {
    /*
    final items = last(3);
    if (items != null && items.length == 3) {
      return (roundRaw(items[0]) == roundRaw(items[1]) &&
          roundRaw(items[0]) == roundRaw(items[2]) &&
          roundFiltered(items[0]) == roundFiltered(items[1]) &&
          roundFiltered(items[0]) == roundFiltered(items[2]));
    }

     */
    return false;
  }

  static TransmitterData? getForTimestamp(double timestamp) {
    /*
    try {
      final sensor = Sensor.currentSensor();
      if (sensor != null) {
        final bgReading = new Select()
            .from(TransmitterData.class)
            .where('timestamp <= ?', (timestamp + (60 * 1000))) // 1 minute padding (should never be that far off, but why not)
            .orderBy('timestamp desc')
            .executeSingle();
        if (bgReading != null && (bgReading.timestamp - timestamp).abs() < (3 * 60 * 1000)) { //cool, so was it actually within 4 minutes of that bg reading?
         log('getForTimestamp: Found a BG timestamp match');
          return bgReading;
        }
      }
    } catch (e) {
     log('getForTimestamp() Got exception on Select: $e');
      return null;
    }

     */
    log('getForTimestamp: No luck finding a BG timestamp match');
    return null;
  }

  static TransmitterData? findByUuid(String uuid) {
    /*
    try {
      return new Select()
          .from(TransmitterData.class)
          .where('uuid = ?', uuid)
          .executeSingle();
    } catch (e) {
     log('findByUuid() Got exception on Select: $e');
      return null;
    }
     */
    return null;
  }

  static TransmitterData? byid(int id) {
    /*
    return new Select()
        .from(TransmitterData.class)
        .where('_ID = ?', id)
        .executeSingle();

     */
    return null;
  }

  void save() {
    // implementation
  }
}

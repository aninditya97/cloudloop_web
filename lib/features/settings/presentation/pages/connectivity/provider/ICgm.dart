// ICgm interface
import 'package:cloudloop_mobile/features/settings/domain/entities/xdrip_data.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/IDevice.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';

/*
 * @brief this interface define Cgm functions.
 * @author kai_20230429
 */
abstract class ICgm extends IDevice {
  int getBloodGlucoseValue();

  ///< get the blood glucose sent from the connected CGM device
  int getLastTimeBGReceived();
  int getLastBloodGlucose();
  XdripData? getCollectBloodGlucose();
  List<int>? getBloodGlucoseHistoryList();
  List<String>? getRecievedTimeHistoryList();
  List<double>? getIobCalculateHistoryList();

  ///< get the latest time & date that blood glucose is received from the CGM
  void setBloodGlucoseValue(int _value);
  void setLastTimeBGReceived(int _value);
  void setLastBloodGlucose(int _value);
  void setCollectBloodGlucose(XdripData _value);
  void setBloodGlucoseHistoryList(int initial, int _value);
  void setRecievedTimeHistoryList(int initial, String _value);
  void setIobCalculateHistoryList(double initial, double _value);

// In order to show an message or additional interaction to user
  // can register/unregister the Response Callback Listener which notify a response sent from Cgm to user by using
  // the registered callback function of the type 'ResponseCallback'
  void setResponseCallbackListener(ResponseCallback callback);
  void releaseResponseCallbackListener();
  ResponseCallback? getResponseCallbackListener();
}

package com.cloudloop.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.cloudloop.mobile.isense.Const


/**
 * @brief CGM Broadcast Receiver
 * @details this class could be used by external application in order to send data to cloudloop
 *         external Application side usage example:
 *         val intent = Intent()
 *         ComponentName componentName = new ComponentName("com.cloudloop.mobile", "com.cloudloop.mobile.isense.cgmBCReceiver")
 *         intent.setComponent(componentName);
 *         val bundle = Bundle()
 *         bundle.putString("key_string", "Hello, this is a string data!")
 *         bundle.putInt("key_integer", 42)
 *         intent.putExtras(bundle)
 *         context.sendBroadcast(intent)
 *
 *         also need to register BCReceiver in AndroidManifest.xml w/o intent filter as like below;
 *         <application ..... >
 *          <!-- cgmBCReceiver Register -->
 *          <receiver
 *          android:name=".cgmBCReceiver"
 *          android:enabled="true"
 *          android:exported="true">
 *          <!-- intent-filter>
 *          <action android:name="com.isens.csair.EXTERNAL_BROADCAST" />
 *          </intent-filter-->
 *          </receiver>
 *          </application>
 */
class cgmBCReceiver : BroadcastReceiver(){
    val TAG = cgmBCReceiver::class.java.simpleName.toString()

    override fun onReceive(ctxt: Context?, intent: Intent?) {
       //retrieve data
        Log.d(TAG,"kai:onReceive() is called");        
        if(ctxt != null && intent != null)
        {
            val action: String? = intent.action
            Log.d(TAG,"kai:onReceive(): intent.action = " + action.toString());
            val bundle = intent.getBundleExtra(Const.EXTRA_CGM_VALUES)

            if (bundle != null && action != null && action.equals(Const.ISENS_CGM))
            {
                Log.d(TAG,"kai:onReceive(): sendBroadcast(Const.INTENT_CGM_RECEIVED)");
             // Broadcast the data within the app using a custom action
                val newIntent = Intent(Const.INTENT_CGM_RECEIVED).apply {
                    putExtra(Const.EXTRA_CGM_VALUES,bundle)
                }
                ctxt.sendBroadcast(newIntent)
            }
        }

    }
}

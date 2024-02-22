package com.cloudloop.mobile;

import android.content.Context;
import org.pytorch.IValue;
import org.pytorch.LiteModuleLoader;
import org.pytorch.Module;
import org.pytorch.PyTorchAndroid;
import org.pytorch.Tensor;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.FloatBuffer;

class OpenAPSPOSTECHPlugin {
    private static Module mModule = null;
    private static FloatBuffer mInputTensorBuffer;
    private static Tensor mInputTensor;

    // private static final DecimalFormat decfor = new DecimalFormat("0.00");  

    private static int iUnit_to_pmol = 6000;
    private static int ihour = 60;
    private static double fPump_increment_rate = 0.05;
    private static double iPump_min_rate = 0.05;
    private static int iPump_max_rate = 30;

    public static Float doModuleForward(float g1, float grate, float meal, float iob, float tdd, float target, Context context) throws IOException {
    // public static Float doModuleForward(float g1, float g2, float g3, float g4, float g5, float g6, float meal, float iob, float tdd, float target, Context context) throws IOException {

        if (mModule == null) {
            final long[] shape = new long[]{1, 6};
            // final long[] shape = new long[]{1, 10};

            long numElements = 1;
            for (int i = 0; i < shape.length; i++) {
                numElements *= shape[i];
            }
            mInputTensorBuffer = Tensor.allocateFloatBuffer((int) numElements);
            mModule = LiteModuleLoader.load(assetFilePath(context, "generalized_sac_androidaps_1016_target2.ptl")); //update 08.26
            // mModule = LiteModuleLoader.load(assetFilePath(context, "generalized_sac_androidaps_1019_6in.ptl")); //update 08.26

            
        }

        mInputTensorBuffer.put(0, g1);
        mInputTensorBuffer.put(1, grate);
        mInputTensorBuffer.put(2, meal);
        mInputTensorBuffer.put(3, iob);
        mInputTensorBuffer.put(4, tdd);
        mInputTensorBuffer.put(5, target);

        // mInputTensorBuffer.put(0, g1);
        // mInputTensorBuffer.put(1, g2);
        // mInputTensorBuffer.put(2, g3);
        // mInputTensorBuffer.put(3, g4);
        // mInputTensorBuffer.put(4, g5);
        // mInputTensorBuffer.put(5, g6);
        // mInputTensorBuffer.put(6, meal);
        // mInputTensorBuffer.put(7, iob);
        // mInputTensorBuffer.put(8, tdd);
        // mInputTensorBuffer.put(9, target);


        mInputTensor = Tensor.fromBlob(mInputTensorBuffer, new long[]{1, 6});
        // mInputTensor = Tensor.fromBlob(mInputTensorBuffer, new long[]{1, 10});

        PyTorchAndroid.setNumThreads(1);
        final Tensor outputTensor = mModule.forward(IValue.from(mInputTensor)).toTensor();

        float[] dataOutput = outputTensor.getDataAsFloatArray();
        Float insulin = dataOutput[0];

        float tdd_ori  = (float) Math.floor((tdd*13.7)+42.5);

        // if (insulin < 0){
        //     insulin = (float) ((insulin * 0.2) + 0.2);
        // }
        // else{
        //     insulin = (float) (insulin * (Math.round((tdd_ori/40)+0.15) + 0.2));
        // }

        // if (insulin < 0){
        //     insulin = (float) ((insulin * 0.3) + 0.3);
        // }
        // else{
        //     insulin = (float) ((insulin * 0.7) + 0.3);
        // }
        // insulin = (float) ((insulin * 50.0) / 50.0);

        return insulin;
    }

    public static String assetFilePath(Context context, String assetName) throws IOException {
        File file = new File(context.getFilesDir(), assetName);
        if (file.exists() && file.length() > 0) {
            return file.getAbsolutePath();
        }

        try (InputStream is = context.getAssets().open(assetName)) {
            try (OutputStream os = new FileOutputStream(file)) {
                byte[] buffer = new byte[4 * 1024];
                int read;
                while ((read = is.read(buffer)) != -1) {
                    os.write(buffer, 0, read);
                }
                os.flush();
            }
            return file.getAbsolutePath();
        }
    }

    public static float GetInsulinRate(float iIndex)
    {
        float insulin_rate=0;
        insulin_rate =iIndex;
        double pump_basal_inc = fPump_increment_rate * iUnit_to_pmol ;//   # convert from U/hour to pmmol/min
        insulin_rate = Math.round(insulin_rate / (float)pump_basal_inc ) * (float)pump_basal_inc;

        double pump_rate_min = iPump_min_rate * iUnit_to_pmol;//   # convert from U/hour to pmmol/min
        double pump_rate_max = iPump_max_rate  * iUnit_to_pmol;//  # convert from U/hour to pmmol/min

        insulin_rate = Math.min(insulin_rate, (float)pump_rate_max);
        insulin_rate = Math.max(insulin_rate, (float)pump_rate_min);
        insulin_rate = insulin_rate / iUnit_to_pmol;//  # convert from pmol/min to U/min
        return insulin_rate;//*/
    }
}


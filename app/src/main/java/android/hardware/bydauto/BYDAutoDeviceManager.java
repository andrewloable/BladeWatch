package android.hardware.bydauto;

import android.content.Context;
import android.hardware.BYDAutoManager;
import android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice;

public abstract class BYDAutoDeviceManager implements BYDAutoManager.OnBYDAutoListener {
    public static synchronized BYDAutoDeviceManager getInstance(Context context) {
        synchronized (BYDAutoDeviceManager.class) {
        }
        return null;
    }

    public int setInt(int i, int i2, int i3) {
        return BYDAutoBodyworkDevice.BODYWORK_COMMAND_FAILED;
    }
}

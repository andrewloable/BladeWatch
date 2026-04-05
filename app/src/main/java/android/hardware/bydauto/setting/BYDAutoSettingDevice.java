package android.hardware.bydauto.setting;

import android.content.Context;
import android.hardware.bydauto.AbsBYDAutoDevice;
import android.hardware.bydauto.BYDAutoEventValue;

public class BYDAutoSettingDevice extends AbsBYDAutoDevice {
    private static BYDAutoSettingDevice sInstance;

    protected BYDAutoSettingDevice(Context context) {
        super(context);
    }

    public static synchronized BYDAutoSettingDevice getInstance(Context context) {
        BYDAutoSettingDevice bYDAutoSettingDevice;
        synchronized (BYDAutoSettingDevice.class) {
            if (sInstance == null) {
                sInstance = new BYDAutoSettingDevice(context);
            }
            bYDAutoSettingDevice = sInstance;
        }
        return bYDAutoSettingDevice;
    }

    public int getType() {
        return 0;
    }

    public int set(int[] iArr, BYDAutoEventValue bYDAutoEventValue) {
        return 0;
    }

    public int setSeatHeatingState(int i, int i2) {
        return 0;
    }

    public int setSeatVentilatingState(int i, int i2) {
        return 0;
    }
}

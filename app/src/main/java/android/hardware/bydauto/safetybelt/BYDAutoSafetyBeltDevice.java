package android.hardware.bydauto.safetybelt;

import android.content.Context;
import android.hardware.bydauto.AbsBYDAutoDevice;

public class BYDAutoSafetyBeltDevice extends AbsBYDAutoDevice {
    public static final int SAFETY_BELT_UNBUCKLED = 0;
    public static final int SAFETY_BELT_BUCKLED = 1;

    public static final int SEAT_DRIVER = 0;
    public static final int SEAT_FRONT_PASSENGER = 1;

    private static BYDAutoSafetyBeltDevice sInstance;

    protected BYDAutoSafetyBeltDevice(Context context) {
        super(context);
    }

    public static synchronized BYDAutoSafetyBeltDevice getInstance(Context context) {
        BYDAutoSafetyBeltDevice bYDAutoSafetyBeltDevice;
        synchronized (BYDAutoSafetyBeltDevice.class) {
            if (sInstance == null) {
                sInstance = new BYDAutoSafetyBeltDevice(context);
            }
            bYDAutoSafetyBeltDevice = sInstance;
        }
        return bYDAutoSafetyBeltDevice;
    }

    public int getPassengerStatus(int seatPosition) {
        return 0;
    }

    public int getType() {
        return 0;
    }
}

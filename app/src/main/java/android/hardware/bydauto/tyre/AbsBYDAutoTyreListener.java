package android.hardware.bydauto.tyre;

import android.hardware.IBYDAutoListener;

public abstract class AbsBYDAutoTyreListener implements IBYDAutoListener {
    public void onTyrePressureValueChanged(int wheel, int value) {}
    public void onTyrePressureStateChanged(int wheel, int state) {}
    public void onTyreBatteryValueChanged(int wheel, double value) {}
    public void onTyreBatteryStateChanged(int state) {}
    public void onTyreTemperatureStateChanged(int state) {}
    public void onTyreAirLeakStateChanged(int wheel, int state) {}
    public void onTyreSignalStateChanged(int wheel, int state) {}
    public void onTyreSystemStateChanged(int state) {}
    public void onIndirectTyreSystemStateChanged(int state) {}
}

package android.hardware.bydauto.charging;

import android.hardware.IBYDAutoEvent;
import android.hardware.IBYDAutoListener;

public class AbsBYDAutoChargingListener implements IBYDAutoListener {
    
    public void onBatteryManagementDeviceStateChanged(int state) {
    }
    
    public void onChargerStateChanged(int i) {
    }

    public void onChargingGunStateChanged(int i) {
    }

    public void onChargingPowerChanged(double d) {
    }
    
    public void onChargingCapacityChanged(double d) {
    }

    public void onDataChanged(IBYDAutoEvent iBYDAutoEvent) {
    }
}

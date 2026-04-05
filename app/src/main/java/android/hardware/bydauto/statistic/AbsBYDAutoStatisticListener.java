package android.hardware.bydauto.statistic;

import android.hardware.IBYDAutoListener;

/**
 * Abstract listener for BYD statistic device callbacks.
 */
public class AbsBYDAutoStatisticListener implements IBYDAutoListener {
    
    public void onDrivingTimeChanged(double time) {
    }
    
    public void onElecDrivingRangeChanged(int range) {
    }
    
    public void onElecPercentageChanged(double percentage) {
    }
    
    public void onFuelDrivingRangeChanged(int range) {
    }
    
    public void onFuelPercentageChanged(int percentage) {
    }
    
    public void onEVMileageChanged(int mileage) {
    }
    
    public void onTotalMileageChanged(int mileage) {
    }
    
    public void onKeyBatteryLevelChanged(int level) {
    }
    
    public void onTotalElecConChanged(double consumption) {
    }
    
    public void onTotalFuelConChanged(double consumption) {
    }
}

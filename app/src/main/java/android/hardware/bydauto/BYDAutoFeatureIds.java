package android.hardware.bydauto;

public final class BYDAutoFeatureIds {
    public static final int CHARGING_DISCHARGE_VEHICLE_OUTPUT_VOLTAGE = 4112;
    public static final int ENGINE_FRONT_MOTOR_SPEED = 4098;
    public static final int ENGINE_REAR_MOTOR_SPEED = 4097;
    public static final int ENGINE_SPEED = 4105;
    public static final int INSTRUMENT_DD_MILEAGE_UNIT = 4099;
    public static final int SPEED_ACCELERATOR_S = 4100;
    public static final int SPEED_BRAKE_S = 4101;
    public static final int STATISTIC_FUEL_PERCENTAGE = 4102;
    public static final int STATISTIC_MILEAGE_EV = 4103;
    public static final int STATISTIC_MILEAGE_HEV = 4104;
    public static final int STATISTIC_TOTAL_MILEAGE = 4096;

    public static final class Setting {
        public static final int SET_LF_MEMORY_LOCATION_WAKE_SET = 8192;

        private Setting() {
        }
    }

    private BYDAutoFeatureIds() {
    }
}

package com.overdrive.app.monitor;

/**
 * Data class for driving range information.
 * Contains both electric and fuel range for hybrid vehicles.
 */
public class DrivingRangeData {
    
    public static final int MIN_RANGE = 0;
    public static final int MAX_RANGE = 999;
    public static final int LOW_RANGE_THRESHOLD = 50;  // km
    public static final int CRITICAL_RANGE_THRESHOLD = 20;  // km
    
    public final int elecRangeKm;      // Electric driving range in km
    public final int fuelRangeKm;      // Fuel driving range in km (0 for pure EV)
    public final int totalRangeKm;     // Combined range
    public final boolean isLow;        // true if total range < 50km
    public final boolean isCritical;   // true if total range < 20km
    public final long timestamp;
    
    /**
     * Create range data from electric range only (pure EV).
     * @param elecRangeKm Electric driving range in km
     */
    public DrivingRangeData(int elecRangeKm) {
        this(elecRangeKm, 0);
    }
    
    /**
     * Create range data from both electric and fuel range (hybrid).
     * @param elecRangeKm Electric driving range in km
     * @param fuelRangeKm Fuel driving range in km
     */
    public DrivingRangeData(int elecRangeKm, int fuelRangeKm) {
        this.elecRangeKm = Math.max(0, elecRangeKm);
        this.fuelRangeKm = Math.max(0, fuelRangeKm);
        this.totalRangeKm = this.elecRangeKm + this.fuelRangeKm;
        this.isCritical = (this.totalRangeKm < CRITICAL_RANGE_THRESHOLD);
        this.isLow = (this.totalRangeKm < LOW_RANGE_THRESHOLD);
        this.timestamp = System.currentTimeMillis();
    }
    
    /**
     * Check if range is within valid bounds.
     */
    public boolean isValidRange() {
        return elecRangeKm >= MIN_RANGE && elecRangeKm <= MAX_RANGE &&
               fuelRangeKm >= MIN_RANGE && fuelRangeKm <= MAX_RANGE;
    }
    
    /**
     * Get status string for display.
     */
    public String getStatus() {
        if (isCritical) return "CRITICAL";
        if (isLow) return "LOW";
        return "OK";
    }
    
    /**
     * Check if this is a pure EV (no fuel range).
     */
    public boolean isPureEV() {
        return fuelRangeKm == 0;
    }
    
    @Override
    public String toString() {
        return "DrivingRangeData{" +
                "elecRangeKm=" + elecRangeKm +
                ", fuelRangeKm=" + fuelRangeKm +
                ", totalRangeKm=" + totalRangeKm +
                ", isLow=" + isLow +
                ", isCritical=" + isCritical +
                ", timestamp=" + timestamp +
                '}';
    }
}

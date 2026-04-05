package android.hardware.bydauto.safetybelt;

import android.hardware.IBYDAutoListener;

public abstract class AbsBYDAutoSafetyBeltListener implements IBYDAutoListener {
    public void onSafetyBeltStatusChanged(int seatPosition, int status) {
    }
}

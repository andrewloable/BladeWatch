package com.overdrive.app.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.overdrive.app.services.LocationSidecarService

/**
 * Boot receiver to auto-start LocationSidecarService after device reboot.
 * Uses the same pattern as other boot receivers for consistent auto-start behavior.
 */
class LocationBootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "LocationBootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            
            Log.i(TAG, "Boot/Package update received, starting LocationSidecarService...")
            
            try {
                val serviceIntent = Intent(context, LocationSidecarService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                Log.i(TAG, "LocationSidecarService start requested")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start LocationSidecarService: ${e.message}", e)
            }
        }
    }
}

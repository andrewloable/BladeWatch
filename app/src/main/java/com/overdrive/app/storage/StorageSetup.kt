package com.overdrive.app.storage

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import java.io.File

/**
 * StorageSetup - Creates Overdrive directories from the App (UID 10xxx)
 * 
 * On Android 11+, directories created by the daemon (UID 2000) cannot be
 * written to by the app. By creating directories from the app with
 * MANAGE_EXTERNAL_STORAGE permission, the app becomes the owner and
 * both app and daemon can access the files.
 * 
 * Usage:
 * 1. Call checkStoragePermission() to verify permission
 * 2. If false, call requestStoragePermission() to request it
 * 3. Once granted, call setupDirectories() to create folders
 */
object StorageSetup {
    private const val TAG = "StorageSetup"
    
    // Base directory for all Overdrive files
    private const val BASE_DIR = "/storage/emulated/0/Overdrive"
    
    // Subdirectories to create
    private val SUBDIRS = listOf("recordings", "surveillance", "proximity")
    
    // Request codes
    const val REQUEST_CODE_STORAGE_PERMISSION = 100
    const val REQUEST_CODE_RUNTIME_PERMISSION = 101
    
    /**
     * Check if app has storage permission.
     * - Android 11+: MANAGE_EXTERNAL_STORAGE
     * - Android 10 and below: WRITE_EXTERNAL_STORAGE runtime permission
     */
    fun checkStoragePermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+: Check for "All Files Access"
            Environment.isExternalStorageManager()
        } else {
            // Android 10 and below: Check runtime permission
            ContextCompat.checkSelfPermission(context, Manifest.permission.WRITE_EXTERNAL_STORAGE) == 
                PackageManager.PERMISSION_GRANTED
        }
    }
    
    /**
     * Request storage permission.
     * - Android 11+: Opens Settings for MANAGE_EXTERNAL_STORAGE
     * - Android 10 and below: Requests WRITE_EXTERNAL_STORAGE runtime permission
     * 
     * @return true if runtime permission was requested (use onRequestPermissionsResult),
     *         false if Settings was opened (use onActivityResult)
     */
    fun requestStoragePermission(activity: Activity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+: Open Settings
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                    addCategory("android.intent.category.DEFAULT")
                    data = Uri.parse("package:${activity.packageName}")
                }
                @Suppress("DEPRECATION")
                activity.startActivityForResult(intent, REQUEST_CODE_STORAGE_PERMISSION)
            } catch (e: Exception) {
                val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                @Suppress("DEPRECATION")
                activity.startActivityForResult(intent, REQUEST_CODE_STORAGE_PERMISSION)
            }
            false // Settings opened, use onActivityResult
        } else {
            // Android 10 and below: Request runtime permission
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                    Manifest.permission.READ_EXTERNAL_STORAGE
                ),
                REQUEST_CODE_RUNTIME_PERMISSION
            )
            true // Runtime permission requested, use onRequestPermissionsResult
        }
    }
    
    /**
     * Setup all Overdrive directories.
     * App creates the directories so it becomes the OWNER.
     * 
     * @return true if all directories were created/exist successfully
     */
    fun setupDirectories(): Boolean {
        val myUid = android.os.Process.myUid()
        Log.i(TAG, "========== STORAGE SETUP START ==========")
        Log.i(TAG, "App UID: $myUid")
        Log.i(TAG, "Android SDK: ${Build.VERSION.SDK_INT}")
        Log.i(TAG, "isExternalStorageManager: ${if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) Environment.isExternalStorageManager() else "N/A (pre-R)"}")
        
        val baseDir = File(BASE_DIR)
        var success = true
        
        // Create base directory
        try {
            if (!baseDir.exists()) {
                val created = baseDir.mkdirs()
                Log.i(TAG, "Base dir mkdirs() returned: $created")
                if (!created) {
                    Log.e(TAG, "FAILED to create base directory: $BASE_DIR")
                    // Try alternative: mkdir parent first
                    val parent = baseDir.parentFile
                    if (parent != null && !parent.exists()) {
                        Log.i(TAG, "Parent doesn't exist: ${parent.absolutePath}")
                    }
                    success = false
                } else {
                    Log.i(TAG, "SUCCESS: Created base dir: $BASE_DIR")
                }
            } else {
                Log.i(TAG, "Base dir already exists: $BASE_DIR (canWrite=${baseDir.canWrite()})")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception creating base dir: ${e.message}", e)
            success = false
        }
        
        // Make base dir accessible
        try {
            baseDir.setReadable(true, false)
            baseDir.setWritable(true, false)
            baseDir.setExecutable(true, false)
        } catch (e: Exception) {
            Log.w(TAG, "Could not set base dir permissions: ${e.message}")
        }
        
        // Create subdirectories
        for (subdir in SUBDIRS) {
            val dir = File(baseDir, subdir)
            try {
                if (!dir.exists()) {
                    val created = dir.mkdirs()
                    Log.i(TAG, "Subdir '$subdir' mkdirs() returned: $created")
                    if (!created) {
                        Log.e(TAG, "FAILED to create subdir: $subdir")
                        success = false
                    } else {
                        Log.i(TAG, "SUCCESS: Created subdir: $subdir")
                    }
                } else {
                    Log.i(TAG, "Subdir '$subdir' already exists (canWrite=${dir.canWrite()})")
                }
                
                // Make subdir accessible
                dir.setReadable(true, false)
                dir.setWritable(true, false)
                dir.setExecutable(true, false)
            } catch (e: Exception) {
                Log.e(TAG, "Exception creating subdir '$subdir': ${e.message}", e)
                success = false
            }
        }
        
        Log.i(TAG, "========== STORAGE SETUP END (success=$success) ==========")
        return success
    }
    
    /**
     * Check if directories exist and are writable.
     */
    fun areDirectoriesReady(): Boolean {
        val baseDir = File(BASE_DIR)
        if (!baseDir.exists() || !baseDir.canWrite()) {
            return false
        }
        
        for (subdir in SUBDIRS) {
            val dir = File(baseDir, subdir)
            if (!dir.exists() || !dir.canWrite()) {
                return false
            }
        }
        
        return true
    }
    
    /**
     * Get the base directory path.
     */
    fun getBasePath(): String = BASE_DIR
    
    /**
     * Get recordings directory path.
     */
    fun getRecordingsPath(): String = "$BASE_DIR/recordings"
    
    /**
     * Get surveillance directory path.
     */
    fun getSurveillancePath(): String = "$BASE_DIR/surveillance"
    
    /**
     * Get proximity directory path.
     */
    fun getProximityPath(): String = "$BASE_DIR/proximity"
}

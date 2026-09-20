package net.bladewatch.app.daemon.proxy

/**
 * Encrypted string constants, decrypted at class-init time by [Safe.s] (AES-256-CBC).
 *
 * The values are produced by `generate_safe_enc.py`, which encrypts ONE string per invocation and
 * prints it — it does not write this file. (The previous header said "DO NOT EDIT - regenerate
 * with: python generate_safe_enc.py", which was wrong and would have stopped anyone editing a file
 * nothing regenerates.) To add an entry: run the script on the plaintext, paste the ciphertext
 * here, and keep the plaintext in the KDoc so the entry stays readable.
 *
 * Obfuscation only — see [Safe] for why these are not secrets.
 */
object Enc {


    // ==================== PATHS ====================
    /** /data/system/sentry_daemon.log */
    @JvmField
    val SENTRY_LOG_SYSTEM: String = Safe.s("9tdDgaIWuXyXxqP8qmKWMPvAEj729chJmgA4XiF9VOo=")

    /** /data/local/tmp/sentry_daemon.log */
    @JvmField
    val SENTRY_LOG_TMP: String = Safe.s("ZHx6IP38aGV/Q7iMCCcxz9TTr71BkwVSU1UO8CyXRy7yB1SvKmAAYi99Xx5v11Xa")

    /** /data/local/tmp/sentry_daemon.pid */
    @JvmField
    val SENTRY_PID: String = Safe.s("ZHx6IP38aGV/Q7iMCCcxzy1lsQShZtcRseW7dNE1si25na89IOT5cRwBuRuJBcXS")

    /** /data/local/tmp/sentry_network_diag.log */
    @JvmField
    val SENTRY_NETWORK_DIAG_LOG: String = Safe.s("ZHx6IP38aGV/Q7iMCCcxz3F+jKfo+GyPGXQzNQPg1lqNYmt3ujG7x4QjuN3pYK2f")

    /** /data/local/tmp/acc_sentry.log */
    @JvmField
    val ACC_SENTRY_LOG: String = Safe.s("ZHx6IP38aGV/Q7iMCCcxz4BdefvSzYGU61RsHmJQJ+g=")

    /** /data/local/tmp/cam_stream */
    @JvmField
    val CAMERA_STREAM_DIR: String = Safe.s("ZHx6IP38aGV/Q7iMCCcxzxuq9ag7mKGoQaOvzuwMDqM=")

    /** /sdcard/DCIM/BYDCam */
    @JvmField
    val CAMERA_OUTPUT_DIR: String = Safe.s("C6E+8XkzSNnhdgOIKBfVSXGyuhqY7qDiNp4pBP/hRuY=")

    /** /data/local/tmp/stream_mode.txt */
    @JvmField
    val CAMERA_STREAM_MODE_FILE: String = Safe.s("ZHx6IP38aGV/Q7iMCCcxz4A79W/sQd0NkqiGs/MIZWo=")

    /** /data/local/tmp/.byd_device_id */
    @JvmField
    val CAMERA_DEVICE_ID_FILE: String = Safe.s("ZHx6IP38aGV/Q7iMCCcxz8mvs/gQENVv3FEZ6OVKD54=")

    /** /sys/power/wake_lock */
    @JvmField
    val WAKE_LOCK_PATH: String = Safe.s("kb7HnwNgcQAsfjzzZ2HOBMxdOhkMxwXzhyFBtedHnSE=")

    /** /sys/power/wake_unlock */
    @JvmField
    val WAKE_UNLOCK_PATH: String = Safe.s("kb7HnwNgcQAsfjzzZ2HOBFL9LU9wOcz7uvaGd3r+PHU=")

    /** /data/local/tmp */
    @JvmField
    val DATA_LOCAL_TMP: String = Safe.s("vuaMjrmBGBFh07qqnUuL8w==")

    /** /data/data/com.android.providers.settings */
    @JvmField
    val DATA_SYSTEM_SETTINGS: String = Safe.s("4FWGV7tPhe9614nkUCor4bnqFPfssDPoiHYPJxgenGAPG3xCP+0Cb2Hm04LZxNNJ")


    // ==================== COMMANDS ====================
    /** svc power stayon true */
    @JvmField
    val SVC_POWER_ON: String = Safe.s("evL2bKzQb67Tf3KRHg1cMVG8PSjiOvOcAsdtUSiirz4=")

    /** svc power stayon false */
    @JvmField
    val SVC_POWER_OFF: String = Safe.s("evL2bKzQb67Tf3KRHg1cMaUQ0s15R3JRQ4W151UI/Rs=")

    /** svc wifi enable */
    @JvmField
    val SVC_WIFI_ENABLE: String = Safe.s("GzzLDvODRsKARkPOXEZeIA==")

    /** cmd wifi set-wifi-enabled enabled */
    @JvmField
    val WIFI_ENABLE_CMD: String = Safe.s("OHt1ORBfaA6jti9DhL+LSDghCI3qSNr9WYGyb82Ov2DsCnMgXaYKKKOzpoICOnGX")


    // ==================== SERVICES ====================
    /** accmodemanager */
    @JvmField
    val SERVICE_ACCMODE: String = Safe.s("tr877WU3+MV4zFtCjanWUw==")

    /** byd_datacached */
    @JvmField
    val SERVICE_BYD_DATACACHE: String = Safe.s("JQiIxMJxYlF8spk2fIi8Sg==")

    /** bg_datacache */
    @JvmField
    val SERVICE_BG_DATACACHE: String = Safe.s("m84QJmAGTQpH+XP36MaDpA==")

    /** android.os.IAccModeManager */
    @JvmField
    val INTERFACE_ACCMODE: String = Safe.s("8AsXgmArXEIVQTzlKJxcF6yCBHWM2MoAIE3hnqCQMWM=")


    // ==================== MISC ====================
    /** net.bladewatch.app */
    @JvmField
    val APP_PACKAGE: String = Safe.s("b+URlanuKqV+a8w43uR6VwE1hpEbteNkkdukhTGHkdY=")

    /** 127.0.0.1 */
    @JvmField
    val LOCALHOST: String = Safe.s("6e8x7uzAzonqK41m43RhgA==")

}

package net.bladewatch.app.ai

import android.content.ContextWrapper
import android.content.res.AssetManager
import android.content.res.Resources

/**
 * Minimal Context wrapper for daemon mode — just enough Context for TFLite to load models from
 * an AssetManager.
 *
 * [getResources] deliberately returns null. That is not an oversight: TFLite only reaches for
 * the AssetManager, and there is no real Resources instance to give it in a headless daemon.
 * The platform type is declared nullable so Kotlin callers see the truth rather than tripping
 * over it at runtime.
 */
class AssetContext(private val assetManager: AssetManager) : ContextWrapper(null) {

    override fun getAssets(): AssetManager = assetManager

    override fun getResources(): Resources? = null

    override fun getPackageName(): String = "net.bladewatch.app"
}

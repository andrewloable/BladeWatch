@file:JvmName("HardwareBufferTextureBinder")

package net.bladewatch.app.camera

import android.hardware.HardwareBuffer

/**
 * JNI bridge to bind an [HardwareBuffer] to a `GL_TEXTURE_EXTERNAL_OES` via `EGLImageKHR`.
 * Required for the ImageReader-based zero-copy camera path that bypasses SurfaceFlinger throttling
 * on the SurfaceTexture consumer (see CAMERA_FPS_INVESTIGATION.md).
 *
 * The caller MUST hold a current EGL context on the calling thread before invoking
 * [bindHardwareBufferToTextureNative]. The bind targets `GL_TEXTURE_EXTERNAL_OES` on the supplied
 * texture ID.
 *
 * The native impl is in cpp/camera/HardwareBufferTextureBinder.cpp, statically linked into the
 * existing libsurveillance.so.
 *
 * Declared as TOP-LEVEL functions with an explicit `@file:JvmName`, not as members of an `object`
 * or a `companion object`, and that is load-bearing. JNI resolves these by symbol name, and the
 * C++ side exports
 * `Java_net_bladewatch_app_camera_HardwareBufferTextureBinder_probeExtensionsNative`. Top-level
 * externals in a file named this way compile to static methods on exactly that class, so the
 * symbol is unchanged and Java callers still write `HardwareBufferTextureBinder.probe...()`. A
 * `companion object` would mangle it to `...HardwareBufferTextureBinder$Companion_...` and the
 * link would fail at runtime, on the car, with no compile-time warning.
 */

/**
 * Probe the EGL/GL extensions required for AHardwareBuffer to EGLImage binding on the current
 * display. The result is a human-readable string suitable for one-shot logging at startup. Safe to
 * call from any thread that has a current EGL display.
 */
external fun probeExtensionsNative(): String

/**
 * Wrap [hwBuffer] as an `EGLImageKHR` and bind it to [textureId] as a `GL_TEXTURE_EXTERNAL_OES`
 * target. The texture retains an internal reference to the gralloc buffer; the EGLImage wrapper
 * itself is destroyed before this function returns.
 *
 * @param hwBuffer the HardwareBuffer obtained from `android.media.Image.getHardwareBuffer()`
 * @param textureId an OpenGL ES texture ID created with the `GL_TEXTURE_EXTERNAL_OES` target
 * @return true if the EGL/GL bind succeeded
 */
external fun bindHardwareBufferToTextureNative(hwBuffer: HardwareBuffer, textureId: Int): Boolean

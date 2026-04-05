package com.overdrive.app.ui.model

/**
 * Access mode for camera streams.
 * PUBLIC: Access via dynamic Cloudflared tunnel URL
 * PRIVATE: Access via static VPS IP address
 */
enum class AccessMode {
    PUBLIC,
    PRIVATE
}

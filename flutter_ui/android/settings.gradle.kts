pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    // BladeWatch-ncbb.2: Kotlin coverage gate for this module's JVM tests
    // (flutter_ui/android/app/src/test/kotlin/) — same plugin/version as the
    // main app's app/build.gradle.kts (BladeWatch-ncbb.5), applied per-module
    // since this is a separate Gradle project with no shared version catalog.
    id("org.jetbrains.kotlinx.kover") version "0.9.9" apply false
}

include(":app")

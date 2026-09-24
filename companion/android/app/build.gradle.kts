plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "net.bladewatch.bladewatch_companion"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Chosen before anything is installed: an application id cannot change once the app is
        // on phones. Sits beside net.bladewatch.app (service host) and net.bladewatch.flutter
        // (in-car UI), but shares neither their signing key's UID nor anything else -- this app
        // runs on the owner's phone, not the head unit.
        applicationId = "net.bladewatch.companion"
        // flutter_pear_bare's real floor: libbare-kit.so is built against API 29, and below it
        // the Gradle manifest merger fails the build outright (flutter_pear README, Install).
        minSdk = 29
        targetSdk = flutter.targetSdkVersion

        // flutter_pear ships native code for these two ABIs only; an armeabi-v7a build would
        // install on a 32-bit phone and then fail at worklet start. This keeps armeabi-v7a out
        // of every APK and bundle, and makes --split-per-abi fail at configuration (AGP refuses
        // ndk abiFilters alongside ABI splits) instead of emitting that broken split. It only
        // holds because gradle.properties sets disable-abi-filtering: without that, the Flutter
        // plugin replaces this list with its own, armeabi-v7a included.
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

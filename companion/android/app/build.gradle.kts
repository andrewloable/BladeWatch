plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The release keystore, when there is one: KEYSTORE_FILE, else the repo's app/release.jks.
// The companion does not share a UID with the head-unit APKs, so no key is REQUIRED to match
// theirs; what matters is that every release is signed with the same key forever, because
// Android refuses an update signed differently (docs/build-and-operations.md, "Signing").
val releaseKeystore = file(System.getenv("KEYSTORE_FILE") ?: "../../../app/release.jks")

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

    signingConfigs {
        create("release") {
            storeFile = releaseKeystore
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            keyAlias = System.getenv("KEY_ALIAS") ?: "key0"
        }
    }

    buildTypes {
        release {
            // UNSIGNED without a keystore -- which is every CI build: the release workflow emits
            // it unsigned and fails if it is not. It must never fall back to the debug key: a
            // phone that installed a debug-signed release could not take the real one as an update.
            signingConfig = if (releaseKeystore.exists()) signingConfigs.getByName("release") else null
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

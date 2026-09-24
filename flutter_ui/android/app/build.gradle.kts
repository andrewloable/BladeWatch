import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlinx.kover")
}

android {
    signingConfigs {
        create("release") {
            // Same keystore/cert as the main app (app/build.gradle.kts) — required
            // because android:sharedUserId only resolves to one UID when both APKs
            // are signed with an identical certificate.
            storeFile = file(System.getenv("KEYSTORE_FILE") ?: "../../../app/release.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            keyAlias = System.getenv("KEY_ALIAS") ?: "key0"
        }
    }

    namespace = "net.bladewatch.bladewatch_ui"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "net.bladewatch.flutter"
        // Device floor is API 29 (measured on the BYD head unit) — Flutter's own
        // floor is 24, but 29 documents the real hardware target and lets the
        // Impeller Vulkan backend be relied on. targetSdk intentionally left at
        // Flutter's own template default; do not lower it to match the main
        // app's legacy targetSdk=25 (untested territory for the embedding).
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        // versionCode comes from pubspec.yaml's build number (the `+13100`), so
        // there is one number to bump.
        versionCode = flutter.versionCode

        // versionName is written out explicitly because BladeWatch versions have
        // FOUR parts ("1.4.0.0", matching app/build.gradle.kts) and a pubspec
        // version must be valid semver — `version: 1.4.0.0+14000` is rejected by
        // pub outright, so `flutter.versionName` can only ever yield "1.3.1".
        //
        // The two APKs are installed as a pair and the About screen reads this
        // value through package_info_plus, so they must report the same string.
        // Keep this in step with app/build.gradle.kts's versionName.
        versionName = "1.4.0.0"

        // BYD head unit is arm64-v8a only — same reasoning as the main app's
        // splits.abi block.
        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    buildTypes {
        release {
            // Sign only when the shared keystore is actually available, mirroring
            // the main app's behavior — otherwise build UNSIGNED, to be signed
            // later with apksigner.
            //
            // This used to fall back to the DEBUG signing config while the comment
            // said "unsigned". That mattered: the service host falls back to `null`
            // (genuinely unsigned), so a keystore-less release build produced one
            // unsigned APK and one debug-signed APK. `android:sharedUserId` only
            // collapses the two packages into one UID when their certificates are
            // identical, so that pair could never work together — and signing the
            // service host afterwards with a real key would still not match the
            // debug cert baked into this one.
            //
            // Installing a release build has always required a keystore; use
            // `--debug` for the install-and-test path (see CLAUDE.md).
            signingConfig = if (file(System.getenv("KEYSTORE_FILE") ?: "../../../app/release.jks").exists())
                signingConfigs.getByName("release")
            else
                null
        }
    }

    // BladeWatch-yz1e.4: dadb transitively pulls in JUnit 5, which collides
    // on these META-INF files at merge time — same exclusion list the main
    // app's app/build.gradle.kts already uses for the same reason (it
    // depends on dadb too).
    packaging {
        resources {
            excludes += listOf(
                "META-INF/LICENSE.md",
                "META-INF/LICENSE-notice.md",
                "META-INF/NOTICE.md",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "META-INF/DEPENDENCIES",
                "META-INF/INDEX.LIST",
                "META-INF/*.kotlin_module",
            )
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

dependencies {
    // BladeWatch-yz1e.4 (ADB Console): same library + version the main app
    // depends on (gradle/libs.versions.toml's `dadb`), used only for
    // AdbKeyChannel's key-pair generation — see its doc comment. This is a
    // separate Gradle build with no shared version catalog (see
    // settings.gradle.kts), so the coordinate is repeated explicitly rather
    // than referenced via `libs.dadb`.
    implementation("dev.mobile:dadb:1.2.8")

    testImplementation("junit:junit:4.13.2")
    // Android's org.json is a stub in JVM unit tests (same reason as the main
    // app's app/build.gradle.kts) — the real implementation is only present
    // on-device; this is test-only, production code uses the on-device one.
    testImplementation("org.json:json:20240303")
}

// Kotlin coverage gate for this module (BladeWatch-ncbb.2 — the first Kotlin
// code in the Flutter APK's own android/ source set). Same ratchet policy as
// the main app's gate: baseline at the real first measurement, raise only
// when justified. See docs/build-and-operations.md.
kover {
    reports {
        total {
            filters {
                excludes {
                    // Flutter's own generated plugin-registration glue — never
                    // hand-written, not something this project maintains.
                    classes("io.flutter.plugins.GeneratedPluginRegistrant")
                    // FlutterActivity subclass: Android-framework-bound (needs a
                    // real FlutterEngine), not unit-testable without Robolectric,
                    // which this refactor deliberately does not use. Keep this
                    // class thin (wiring only) and put all real logic in plain
                    // Kotlin classes under ipc/, auth/, daemon/, config/
                    // instead, which ARE unit-tested.
                    classes("net.bladewatch.bladewatch_ui.MainActivity")
                    // ConnectivityManager/WifiManager-bound diagnostic probe, same
                    // reason as PackageInstallerBridge above. See its own doc
                    // comment; verified on-device in BladeWatch-imh6.
                    classes("net.bladewatch.bladewatch_ui.network.NetworkInfoChannel")
                    // LocationManager-bound GPS probe, same reason as
                    // NetworkInfoChannel above. See its own doc comment;
                    // verified on-device in BladeWatch-imh6. Wildcarded to
                    // also catch the anonymous LocationListener's synthetic
                    // `LocationServiceChannel$listener$1` class.
                    classes("net.bladewatch.bladewatch_ui.location.LocationServiceChannel*")
                    // BladeWatch-yz1e.10 (Live View texture plugin):
                    // MediaCodec/Surface-bound H.264 decoder, same reason as
                    // every class above — android.media.MediaCodec is a stub
                    // in JVM unit tests. All decision logic (frame counting,
                    // presentation-timestamp calculation, state tracking,
                    // argument validation) lives in LiveViewTexturePlugin
                    // instead, which IS unit-tested to 100% against a fake
                    // of the FrameDecoder interface this class implements.
                    // See both classes' own doc comments; verified on-device
                    // in BladeWatch-imh6.
                    classes("net.bladewatch.bladewatch_ui.liveview.MediaCodecFrameDecoder")
                }
            }
            verify {
                rule {
                    minBound(100)
                }
            }
        }
    }
}

// BladeWatch-ncbb.5: Dart test + coverage gate. Registered on this module
// (not the main app's app/build.gradle.kts) so the daemon APK stays
// buildable without the Flutter toolchain installed — this module already
// requires it unconditionally (the flutter-gradle-plugin above needs
// local.properties' flutter.sdk just to resolve compileSdk/ndkVersion), so
// shelling out to the same `flutter` binary here adds no new dependency.
val flutterSdkPath: String = run {
    val props = Properties()
    val localProps = rootProject.file("local.properties")
    if (localProps.exists()) localProps.inputStream().use { stream -> props.load(stream) }
    props.getProperty("flutter.sdk") ?: System.getenv("FLUTTER_ROOT") ?: "flutter"
}
val flutterBin: String = if (flutterSdkPath == "flutter") "flutter" else "$flutterSdkPath/bin/flutter"
val flutterUiDir = rootProject.projectDir.parentFile!! // flutter_ui/

tasks.register<Exec>("flutterTestCoverage") {
    description = "Run flutter test --coverage for flutter_ui"
    group = "verification"
    workingDir = flutterUiDir
    commandLine(flutterBin, "test", "--coverage")
}

tasks.register<Exec>("checkFlutterCoverage") {
    description = "Fail the build if flutter_ui's Dart line coverage (lib/gen excluded) is below threshold"
    group = "verification"
    dependsOn("flutterTestCoverage")
    workingDir = flutterUiDir.parentFile // repo root
    commandLine("tools/check_flutter_coverage.sh")
}

// Follows the main app's validateI18nCatalogs/validateAndroidStrings hook
// pattern: a verification task wired into the lifecycle so `check` (and
// therefore CI) cannot silently skip it.
tasks.named("check") { dependsOn("checkFlutterCoverage") }

// BladeWatch-rdtj.10: packages/bladewatch_rpc (the Connect client + generated
// messages, extracted from flutter_ui/lib/{rpc,gen/bladewatch} so the companion
// app can share them) is gated on ITS OWN tests. Without this the extraction
// would have silently dropped that code out of every gate: flutter_ui's lcov only
// reports flutter_ui's own files. 100 = the measured figure at extraction
// (381/381), and like every gate here it may only ever be raised.
val rpcPackageDir = flutterUiDir.parentFile.resolve("packages/bladewatch_rpc")

tasks.register<Exec>("rpcTestCoverage") {
    description = "Run flutter test --coverage for packages/bladewatch_rpc"
    group = "verification"
    workingDir = rpcPackageDir
    commandLine(flutterBin, "test", "--coverage")
}

tasks.register<Exec>("checkRpcCoverage") {
    description = "Fail the build if bladewatch_rpc's Dart line coverage (lib/gen excluded) is below threshold"
    group = "verification"
    dependsOn("rpcTestCoverage")
    workingDir = flutterUiDir.parentFile // repo root
    commandLine("tools/check_flutter_coverage.sh", "100", "packages/bladewatch_rpc")
}

tasks.named("check") { dependsOn("checkRpcCoverage") }

// BladeWatch-rdtj.10: the fourth gate, for companion/ (the phone/desktop app).
// Registered here with the other Dart gates because this is the only Gradle
// build that already requires the Flutter toolchain, and the one whose wrapper
// the release workflow has. 98 = the floor of 299/305 lines (98.03%) measured
// once rdtj.8's transport landed; it started at 83, the scaffold's 5/6. Raised
// as the companion grows, never lowered.
val companionDir = flutterUiDir.parentFile.resolve("companion")

tasks.register<Exec>("companionTestCoverage") {
    description = "Run flutter test --coverage for companion"
    group = "verification"
    workingDir = companionDir
    commandLine(flutterBin, "test", "--coverage")
}

tasks.register<Exec>("checkCompanionCoverage") {
    description = "Fail the build if the companion's Dart line coverage is below threshold"
    group = "verification"
    dependsOn("companionTestCoverage")
    workingDir = flutterUiDir.parentFile // repo root
    commandLine("tools/check_flutter_coverage.sh", "98", "companion")
}

tasks.named("check") { dependsOn("checkCompanionCoverage") }

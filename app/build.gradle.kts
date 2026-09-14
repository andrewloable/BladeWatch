import java.security.MessageDigest

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlinx.kover)
}

fun sha256Hex(file: File): String {
    val digest = MessageDigest.getInstance("SHA-256")
    file.inputStream().use { input ->
        val buffer = ByteArray(8192)
        while (true) {
            val read = input.read(buffer)
            if (read <= 0) break
            digest.update(buffer, 0, read)
        }
    }
    return digest.digest().joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
}

fun hasExpectedSha256(file: File, expectedSha256: String): Boolean =
    file.exists() && sha256Hex(file).equals(expectedSha256, ignoreCase = true)

fun verifySha256(file: File, expectedSha256: String, label: String) {
    val actual = sha256Hex(file)
    if (!actual.equals(expectedSha256, ignoreCase = true)) {
        throw org.gradle.api.GradleException(
            "$label checksum mismatch. Expected $expectedSha256, got $actual"
        )
    }
}

fun org.gradle.api.Project.downloadVerified(
    url: String,
    dest: File,
    expectedSha256: String,
    label: String
) {
    dest.parentFile.mkdirs()
    ant.invokeMethod("get", mapOf("src" to url, "dest" to dest.absolutePath))
    if (!dest.exists() || dest.length() == 0L) {
        throw org.gradle.api.GradleException("$label download failed: $url")
    }
    verifySha256(dest, expectedSha256, label)
}

fun org.gradle.api.Project.ensureDownloadedVerified(
    url: String,
    dest: File,
    expectedSha256: String,
    label: String
) {
    if (dest.exists()) {
        if (hasExpectedSha256(dest, expectedSha256)) return
        println("$label exists but checksum changed; redownloading")
        dest.delete()
    }
    downloadVerified(url, dest, expectedSha256, label)
}

val openh264Version = "2.6.0"
val openh264ArchiveSha256 = "c702d68c9c8db492a43c1d73a497cea5f31ae5d23e330dcb13bd28cab1dbbf2a"
val openh264LibrarySha256 = "4d9bc54d2d38e53eb7bd551ec61acb8ad8320d8b957bda751cfdbdcbfabc3b07"
val openh264HeaderSha256 = mapOf(
    "codec_api.h" to "21f29b20c24f7c7946f2e243d0bc2532fb3542f6c28af338209477e70d9036c9",
    "codec_app_def.h" to "a40581a24263866dca19911928f7bc4eb354ff78d9dd56dbf0f55fc4fd923726",
    "codec_def.h" to "f974d269b5935e8dc7265b8bfc02f60e5185b4d6165d30541d2758a4506f1979",
    "codec_ver.h" to "9a241e20b7c9221a5786cccd9eae3afed91afba3525b5b9b16c2101976516f94",
)

// Auto-download OpenH264 from Cisco's official binary releases
tasks.register("downloadOpenH264") {
    val openh264Dir = file("src/main/cpp/openh264")
    val proj = project
    doLast {
        // Cisco's official binary URLs - only arm64-v8a for BYD cars
        val abiMap = mapOf(
            "arm64-v8a" to "https://ciscobinary.openh264.org/libopenh264-${openh264Version}-android-arm64.8.so.bz2"
            // Removed armeabi-v7a to reduce APK size
        )
        
        abiMap.forEach { (abi, url) ->
            val libDir = file("${openh264Dir}/lib/${abi}")
            libDir.mkdirs()
            
            val soFile = file("${libDir}/libopenh264.so")
            if (soFile.exists() && hasExpectedSha256(soFile, openh264LibrarySha256)) {
                println("✓ OpenH264 verified for ${abi}")
            } else {
                if (soFile.exists()) {
                    println("OpenH264 ${abi} exists but checksum changed; redownloading")
                    soFile.delete()
                }
                println("Downloading OpenH264 ${openh264Version} for ${abi}...")
                val bzFile = file("${libDir}/temp.bz2")
                val extractedFile = file("${libDir}/temp")
                if (extractedFile.exists()) extractedFile.delete()

                proj.downloadVerified(url, bzFile, openh264ArchiveSha256, "OpenH264 ${abi} archive")
                ant.invokeMethod("bunzip2", mapOf("src" to bzFile.absolutePath))
                if (!extractedFile.renameTo(soFile)) {
                    throw org.gradle.api.GradleException("Failed to install OpenH264 for ${abi}")
                }
                verifySha256(soFile, openh264LibrarySha256, "OpenH264 ${abi} library")
                println("✓ OpenH264 downloaded and verified for ${abi}")
            }
        }
        
        // Download headers from Cisco's GitHub
        val includeDir = file("${openh264Dir}/include/wels")
        includeDir.mkdirs()
        listOf("codec_api.h", "codec_app_def.h", "codec_def.h", "codec_ver.h").forEach { h ->
            val f = file("${includeDir}/${h}")
            proj.ensureDownloadedVerified(
                "https://raw.githubusercontent.com/cisco/openh264/v${openh264Version}/codec/api/wels/${h}",
                f,
                openh264HeaderSha256.getValue(h),
                "OpenH264 header ${h}"
            )
        }
    }
}

tasks.matching { it.name.contains("CMake") || it.name.contains("ExternalNative") }.configureEach {
    dependsOn("downloadOpenH264", "downloadOpenCV")
}

// OpenCV-mobile version for surveillance module (minimal build, ~3MB vs ~20MB)
// https://github.com/nihui/opencv-mobile
val opencvMobileTag = "v31"
val opencvMobileVersion = "4.10.0"
val opencvMobileArchiveSha256 = "1fd97600f3ed7a0ea17fbd6d009bb9902eec9d968e7b74d5141285b6d7ce3412"
val opencvMobileStaticLibSha256 = mapOf(
    "libopencv_core.a" to "a9ceca2c36c3a44fe245870cd75a32bd0f33bbb0ef8513e021fe79cfe1f8704d",
    "libopencv_imgproc.a" to "13b2237e250f5399162d5b1a3ce141f8307c4d484d83c8e14325f87bee32339f",
    "libopencv_video.a" to "0c438e88067b5b24c477e1e23d7be5afb91fa6cf10a5061530aa9c3fcb62350c",
)
tasks.register("downloadOpenCV") {
    val opencvDir = file("src/main/cpp/opencv")
    val proj = project
    doLast {
        val libDir = file("${opencvDir}/lib/arm64-v8a")
        libDir.mkdirs()
        val includeDir = file("${opencvDir}/include")
        
        val staticLibsVerified = opencvMobileStaticLibSha256.all { (name, sha256) ->
            hasExpectedSha256(file("${libDir}/${name}"), sha256)
        }
        
        if (!staticLibsVerified) {
            println("Downloading opencv-mobile ${opencvMobileVersion} for Android...")
            
            // Correct URL format: /releases/download/vVERSION/
            val zipUrl = "https://github.com/nihui/opencv-mobile/releases/download/${opencvMobileTag}/opencv-mobile-${opencvMobileVersion}-android.zip"
            val zipFile = file("${opencvDir}/opencv-mobile-android.zip")
            
            try {
                // Download opencv-mobile
                println("Downloading from: $zipUrl")
                proj.downloadVerified(zipUrl, zipFile, opencvMobileArchiveSha256, "opencv-mobile archive")
                
                if (zipFile.exists() && zipFile.length() > 100000) {
                    println("Extracting opencv-mobile (${zipFile.length() / 1024 / 1024}MB)...")
                    
                    ant.invokeMethod("unzip", mapOf(
                        "src" to zipFile.absolutePath,
                        "dest" to opencvDir.absolutePath
                    ))
                    
                    // List extracted contents for debugging
                    opencvDir.listFiles()?.forEach { println("  Found: ${it.name}") }
                    
                    // opencv-mobile extracts to opencv-mobile-VERSION-android/
                    val extractedDir = file("${opencvDir}/opencv-mobile-${opencvMobileVersion}-android")
                    
                    if (extractedDir.exists()) {
                        // Copy arm64-v8a static libs
                        val extractedLibDir = file("${extractedDir}/sdk/native/staticlibs/arm64-v8a")
                        if (extractedLibDir.exists()) {
                            extractedLibDir.listFiles()?.forEach { f ->
                                println("  Copying lib: ${f.name}")
                                f.copyTo(file("${libDir}/${f.name}"), overwrite = true)
                            }
                            opencvMobileStaticLibSha256.forEach { (name, sha256) ->
                                verifySha256(file("${libDir}/${name}"), sha256, "opencv-mobile ${name}")
                            }
                            println("✓ opencv-mobile libraries copied")
                        } else {
                            throw org.gradle.api.GradleException("Lib dir not found: ${extractedLibDir}")
                        }
                        
                        // Copy headers
                        val extractedInclude = file("${extractedDir}/sdk/native/jni/include")
                        if (extractedInclude.exists()) {
                            if (includeDir.exists()) includeDir.deleteRecursively()
                            extractedInclude.copyRecursively(includeDir, overwrite = true)
                            println("✓ opencv-mobile headers copied")
                        } else {
                            throw org.gradle.api.GradleException("Include dir not found: ${extractedInclude}")
                        }
                        
                        // Cleanup
                        zipFile.delete()
                        extractedDir.deleteRecursively()
                        
                        println("✓ opencv-mobile ${opencvMobileVersion} installed (~3MB vs ~20MB)")
                    } else {
                        throw org.gradle.api.GradleException(
                            "Extracted dir not found: ${extractedDir}. Available: ${opencvDir.listFiles()?.map { it.name }}"
                        )
                    }
                } else {
                    throw org.gradle.api.GradleException("opencv-mobile download failed or file too small: ${zipFile.length()} bytes")
                }
            } catch (e: Exception) {
                throw org.gradle.api.GradleException("opencv-mobile setup failed: ${e.message}", e)
            }
        } else {
            println("✓ opencv-mobile verified at ${libDir}")
        }
    }
}

// Task to extract web assets to /data/local/tmp/web on device
// Run: ./gradlew :app:extractWebAssets
tasks.register("extractWebAssets") {
    description = "Extracts web assets from APK to /data/local/tmp/web on connected device"
    group = "deployment"
    doLast {
        fun run(vararg cmd: String) {
            ProcessBuilder(*cmd).inheritIO().start().waitFor()
        }
        val webSrcDir = file("src/main/assets/web")
        if (!webSrcDir.exists()) {
            println("⚠ No web assets found at ${webSrcDir}")
            return@doLast
        }

        println("Extracting web assets to device...")

        run("adb", "shell", "mkdir", "-p", "/data/local/tmp/web/shared")
        run("adb", "shell", "mkdir", "-p", "/data/local/tmp/web/local")

        webSrcDir.walkTopDown().filter { it.isFile }.forEach { file ->
            val relativePath = file.relativeTo(webSrcDir).path
            val targetPath = "/data/local/tmp/web/${relativePath}"
            println("  → ${relativePath}")
            run("adb", "push", file.absolutePath, targetPath)
        }

        println("✓ Web assets extracted to /data/local/tmp/web/")
    }
}

// Embed the current git branch in the APK filename so builds from different
// branches are always distinguishable (e.g. bladewatch-flutter-refactor-arm64-v8a-debug.apk).
val gitBranch: String = try {
    val proc = ProcessBuilder("git", "rev-parse", "--abbrev-ref", "HEAD")
        .directory(rootProject.projectDir)
        .start()
    proc.inputStream.bufferedReader().readLine()?.trim()
        ?.replace(Regex("[^A-Za-z0-9._-]"), "-")
        ?: "unknown"
} catch (_: Exception) { "unknown" }

android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_FILE") ?: "release.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            keyPassword = System.getenv("KEY_PASSWORD") ?: ""
            keyAlias = System.getenv("KEY_ALIAS") ?: "key0"
        }
    }
    namespace = "net.bladewatch.app"
    compileSdk = 36
    ndkVersion = "26.1.10909125"

    defaultConfig {
        applicationId = "net.bladewatch.app"
        minSdk = 25
        targetSdk = 25
        versionCode = 10010
        versionName = "1.0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        
        // Note: abiFilters removed - using splits.abi instead for size optimization
        
        externalNativeBuild { cmake { cppFlags += "-std=c++17" } }
    }

    buildFeatures {
        buildConfig = true
    }

    lint {
        // This stops the build from failing due to the old targetSdk 28
        checkReleaseBuilds = false
        abortOnError = false
        disable += "ExpiredTargetSdkVersion"
    }
    
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            // Enable minification and shrinking for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Auto-detect if DaemonLogConfig has any logging flags enabled.
            // When ALL flags are false (production): include proguard-rules-strip-logs.pro
            //   → R8 strips all log calls from bytecode
            // When ANY flag is true (debug build): exclude proguard-rules-strip-logs.pro
            //   → log calls stay in bytecode, DaemonLogConfig controls which tags write to disk
            val logConfigFile = file("src/main/java/com/loabletech/bladewatch/logging/DaemonLogConfig.java") // path unchanged — dir rename not required
            val loggingEnabled = if (logConfigFile.exists()) {
                val content = logConfigFile.readText()
                val enableAllMatch = Regex("""public static final boolean ENABLE_ALL\s*=\s*true""").containsMatchIn(content)
                val anyFlagTrue = Regex("""public static final boolean (?!ANY_LOGGING_ENABLED)\w+\s*=\s*true""").containsMatchIn(content)
                enableAllMatch || anyFlagTrue
            } else false
            
            val proguardFilesList = mutableListOf(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                file("proguard-rules.pro")
            )
            if (loggingEnabled) {
                // Logging enabled: do NOT include strip-logs → log calls survive R8
                println("⚠ DaemonLogConfig: Logging ENABLED — DaemonLogger file logging kept, console still stripped")
            } else {
                // Production: include strip-logs → R8 removes all log calls
                proguardFilesList.add(file("proguard-rules-strip-logs.pro"))
            }
            proguardFiles(*proguardFilesList.toTypedArray())
            
            // Sign only when a keystore is actually available (env KEYSTORE_FILE
            // or a local release.jks). Otherwise build an UNSIGNED release APK
            // (app-arm64-v8a-release-unsigned.apk) to be signed later with
            // apksigner. This keeps signed CI/release builds working unchanged
            // while allowing an unsigned local build without the keystore.
            signingConfig = if (file(System.getenv("KEYSTORE_FILE") ?: "release.jks").exists())
                signingConfigs.getByName("release")
            else
                null
            
            // GitHub release channel for update checks.
            buildConfigField("String", "UPDATE_CHANNEL", "\"alpha\"")

            // APK signing-cert SHA-256 for self-integrity check (uy93.10).
            // Set via CI env var RELEASE_CERT_SHA256 (hex, lowercase).
            // Empty string = dev/unsigned build = check disabled.
            val certSha = System.getenv("RELEASE_CERT_SHA256") ?: ""
            buildConfigField("String", "RELEASE_CERT_SHA256", "\"$certSha\"")
        }
        debug {
            isMinifyEnabled = false

            // GitHub release channel for update checks.
            buildConfigField("String", "UPDATE_CHANNEL", "\"alpha\"")

            // Dev builds: no expected cert — check always disabled.
            buildConfigField("String", "RELEASE_CERT_SHA256", "\"\"")
        }
    }
    
    // Split APKs by ABI - creates smaller APKs per architecture
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a")  // Only arm64 for BYD
            isUniversalApk = false  // Don't create universal APK
        }
    }
    
    // Rename APK outputs to include the git branch:
    //   bladewatch-<branch>-arm64-v8a-<buildtype>.apk
    applicationVariants.all {
        val variant = this
        outputs.all {
            val out = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            out.outputFileName = "bladewatch-${gitBranch}-arm64-v8a-${variant.buildType.name}.apk"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    sourceSets {
        getByName("main") {
            // Tell Gradle to pick up .so files from your custom download folder
            jniLibs.srcDirs("src/main/cpp/openh264/lib")
        }
    }
    kotlinOptions { jvmTarget = "11" }
    
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
                "META-INF/*.kotlin_module"
            )
        }
        // Exclude unnecessary native libs from dependencies
        jniLibs {
            // CRITICAL: Compresses .so files in the APK (saves ~20MB+)
            useLegacyPackaging = true

            // Keep only arm64-v8a (You already have this, but good to keep)
            excludes += listOf(
                "lib/armeabi-v7a/**",
                "lib/x86/**",
                "lib/x86_64/**"
            )
        }
    }
}

/*
 * BYD SDK Stubs Architecture:
 * 
 * The classes in android.hardware.bydauto.* are compile-time stubs that allow
 * the code to compile without the actual BYD SDK JAR.
 * 
 * At runtime on BYD devices:
 * - The real BYD SDK classes are loaded by the boot classloader (higher priority)
 * - Our managers (RadarManager, BodyworkManager) use REFLECTION to get instances
 * - Class.forName() returns the real class from the system framework, not our stub
 * - The stubs in our APK are never actually instantiated
 * 
 * This works because:
 * 1. Boot classloader classes take precedence over app classes
 * 2. We use reflection: Class.forName("android.hardware.bydauto.radar.BYDAutoRadarDevice")
 * 3. getInstance() is called via reflection on the real class
 */

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    
    // Navigation
    implementation(libs.androidx.navigation.fragment.ktx)
    implementation(libs.androidx.navigation.ui.ktx)
    
    // Lifecycle & ViewModel
    implementation(libs.androidx.lifecycle.viewmodel.ktx)
    implementation(libs.androidx.lifecycle.livedata.ktx)
    
    // QR Code generation
    implementation(libs.zxing.core)

    // OSMDroid map tiles for the Location screen
    implementation(libs.osmdroid.android)
    
    // RTMP streaming client for pushing to MediaMTX
    implementation(libs.rtmp.client)
    
    // ADB client for daemon launching
    implementation(libs.dadb)
    
    // WebSocket server for zero-latency H.264 streaming
    implementation("org.java-websocket:Java-WebSocket:1.5.4")
    

    
    implementation(libs.androidx.work.runtime.ktx)
    
    // NOTE: the Vehicle hero renders via three.js in an embedded WebView
    // (web/hero/hero.html). Filament was tried for a native port but the BYD
    // head unit's Adreno 610 GL driver (V@415.0) crashes after minutes of
    // continuous gltfio rendering — do not reintroduce it for the hero.

    // TensorFlow Lite for AI inference (replaces NCNN)
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0")  // GPU acceleration
    implementation("org.tensorflow:tensorflow-lite-gpu-api:2.14.0")  // GPU API interfaces
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
    
    // OkHttp for the OTA updater HTTP client
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    
    // Encrypted SharedPreferences for secure token/owner storage
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    
    // H2 Database - Pure Java embedded SQL (no native dependencies, no .so files)
    // Works for UID 2000 because it's 100% Java bytecode - no Android framework needed
    implementation("com.h2database:h2:2.2.224")

    // Protobuf runtime for generated ConnectRPC message classes
    // Version must match the protoc/remote plugin version (4.35.0 = protoc 33.x / buf remote v4.35)
    implementation("com.google.protobuf:protobuf-java:4.35.0")

    // ConnectRPC Kotlin runtime + OkHttp transport + Java protobuf serialization
    implementation(libs.connectrpc.kotlin)
    implementation(libs.connectrpc.kotlin.okhttp)
    implementation(libs.connectrpc.kotlin.google.java.ext)

    testImplementation(libs.junit)
    // JsonFormat (proto <-> JSON) for the Connect wire-parity contract tests.
    // Mirrors how the connect-kotlin Google-Java JSON strategy serializes/parses.
    testImplementation("com.google.protobuf:protobuf-java-util:4.35.0")
    // Android's org.json is a stub in JVM unit tests; use the real implementation.
    testImplementation("org.json:json:20240303")
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
}

// Regenerate protobuf stubs from proto/. Generated files are committed to the repo,
// so this task is optional — run manually when .proto files change.
// Usage: ./gradlew generateConnectProtos
tasks.register<Exec>("generateConnectProtos") {
    description = "Regenerate Java + TypeScript stubs from proto/ using buf generate"
    group = "codegen"
    workingDir = rootProject.file("proto")
    commandLine("buf", "generate")
}

// Build the Angular web UI and copy the output into app assets.
// The dist output is checked in at web/dist and is also generated here so
// the APK always contains a fresh build when Node.js is available.
tasks.register<Exec>("buildAngularWebUI") {
    description = "Build the Angular web UI and copy dist to app/src/main/assets/web/angular/"
    group = "build"
    workingDir = rootProject.file("web")
    commandLine("npm", "run", "build")
    doLast {
        // Clear stale hashed chunks from previous builds so old assets (and any
        // pre-rebrand colors baked into them) never ship in the APK.
        delete(file("src/main/assets/web/angular"))
        copy {
            from(rootProject.file("web/dist"))
            into(file("src/main/assets/web/angular"))
        }
    }
    // Skip if npm / Node is not on PATH — the committed dist is used instead.
    isIgnoreExitValue = false
    onlyIf {
        try {
            ProcessBuilder("npm", "--version").start().waitFor() == 0
        } catch (e: Exception) {
            logger.warn("buildAngularWebUI: npm not found — skipping Angular build")
            false
        }
    }
}
// Hook into preBuild so Angular is compiled before any variant's assets are packaged.
tasks.named("preBuild") { dependsOn("buildAngularWebUI") }

// Fail the build if any web i18n catalog is invalid JSON or is missing keys that
// en.json has. The catalog URLs are served unhashed and a corrupt/partial catalog
// renders the whole SPA as raw keys ("dashboard.this_week"), so this MUST be caught
// before packaging rather than at runtime on the head unit. Catches the exact class
// of bug that smart-quote delimiters / unescaped quotes introduce.
tasks.register("validateI18nCatalogs") {
    description = "Validate web i18n catalogs: valid JSON + full key parity with en.json"
    group = "verification"
    val i18nDir = file("src/main/assets/web/i18n")
    doLast {
        val slurper = groovy.json.JsonSlurper()
        fun flatten(prefix: String, obj: Any?, out: MutableSet<String>) {
            if (obj is Map<*, *>) {
                for ((k, v) in obj) {
                    val kp = if (prefix.isEmpty()) k.toString() else "$prefix.$k"
                    if (v is Map<*, *>) flatten(kp, v, out) else out.add(kp)
                }
            }
        }
        val enFile = i18nDir.resolve("en.json")
        if (!enFile.exists()) throw GradleException("i18n: en.json missing at ${enFile.path}")
        val enKeys = sortedSetOf<String>()
        try {
            flatten("", slurper.parse(enFile), enKeys)
        } catch (e: Exception) {
            throw GradleException("i18n: en.json is not valid JSON — ${e.message}")
        }
        val catalogs = i18nDir.listFiles { f -> f.name.endsWith(".json") }?.sortedBy { it.name } ?: emptyList()
        val problems = mutableListOf<String>()
        for (f in catalogs) {
            val parsed = try {
                slurper.parse(f)
            } catch (e: Exception) {
                problems.add("${f.name}: INVALID JSON — ${e.message}"); continue
            }
            if (f.name == "en.json") continue
            val keys = sortedSetOf<String>()
            flatten("", parsed, keys)
            val missing = enKeys - keys
            if (missing.isNotEmpty()) {
                problems.add("${f.name}: ${missing.size} key(s) missing vs en.json (e.g. ${missing.take(5).joinToString(", ")})")
            }
        }
        if (problems.isNotEmpty()) {
            throw GradleException("i18n catalog validation FAILED:\n" + problems.joinToString("\n") { "  - $it" })
        }
        logger.lifecycle("i18n: ${catalogs.size} web catalogs valid, full key parity with en.json ✓")
    }
}
// Validate before any variant's assets are packaged.
tasks.named("preBuild") { dependsOn("validateI18nCatalogs") }

// Fail the build if the Android string catalogs (res/values*/strings.xml, 624 keys
// across 17 locales) are malformed, have an unescaped apostrophe (the Android-XML
// equivalent of the smart-quote footgun that hit the web i18n catalogs above), or a
// locale is missing a key that values/strings.xml has. Every string key added by
// hand across 17 files invites exactly this class of silent gap.
tasks.register("validateAndroidStrings") {
    description = "Validate res/values*/strings.xml: key parity with values/strings.xml, valid XML, escaped apostrophes"
    group = "verification"
    val resDir = file("src/main/res")

    fun hasUnescapedApostrophe(text: String): Boolean {
        var inQuotes = false
        var i = 0
        while (i < text.length) {
            val c = text[i]
            if (c == '\\') {
                i += 2 // an escaped char (\' , \" , \n, ...) is never itself a footgun
                continue
            }
            if (c == '"') {
                inQuotes = !inQuotes
            } else if (c == '\'' && !inQuotes) {
                return true
            }
            i++
        }
        return false
    }

    // keys == null means the file failed to parse — callers must not treat that
    // as "zero keys" (which would falsely report every master key as missing).
    data class ParsedStrings(val keys: Set<String>?, val problems: List<String>,
                             val values: Map<String, String> = emptyMap())

    // Every %1$s / %2$d / %s / %d a value uses. A translation that drops one
    // silently loses the number or name it was supposed to show; one that
    // invents a slot throws at format time. Neither is caught by key parity.
    fun formatSlots(text: String): List<String> =
        Regex("""%(?:\d+\\$)?[sd]""").findAll(text).map { it.value }.sorted().toList()

    fun parseStrings(f: File): ParsedStrings {
        val doc = try {
            javax.xml.parsers.DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(f)
        } catch (e: Exception) {
            return ParsedStrings(null, listOf("malformed XML — ${e.message}"))
        }
        val problems = mutableListOf<String>()
        val keys = mutableSetOf<String>()
        val values = mutableMapOf<String, String>()
        val nodes = doc.getElementsByTagName("string")
        for (i in 0 until nodes.length) {
            val el = nodes.item(i) as org.w3c.dom.Element
            if (el.getAttribute("translatable") == "false") continue
            val name = el.getAttribute("name")
            keys.add(name)
            values[name] = el.textContent ?: ""
            if (hasUnescapedApostrophe(el.textContent ?: "")) {
                problems.add("$name: unescaped apostrophe (use \\' or wrap the whole value in double quotes)")
            }
        }
        return ParsedStrings(keys, problems, values)
    }

    doLast {
        val masterFile = resDir.resolve("values/strings.xml")
        if (!masterFile.exists()) throw GradleException("Android strings: values/strings.xml missing at ${masterFile.path}")
        val master = parseStrings(masterFile)
        if (master.problems.isNotEmpty() || master.keys == null) {
            throw GradleException(
                "Android strings validation FAILED in values/strings.xml:\n" +
                    master.problems.joinToString("\n") { "  - $it" }
            )
        }
        val masterKeys = master.keys

        // values-night is a theme (dark-mode colors), not a locale.
        val localeDirs = resDir.listFiles { f -> f.isDirectory && f.name.startsWith("values-") && f.name != "values-night" }
            ?.sortedBy { it.name } ?: emptyList()

        val problems = mutableListOf<String>()
        for (dir in localeDirs) {
            val f = dir.resolve("strings.xml")
            if (!f.exists()) continue
            val parsed = parseStrings(f)
            for (p in parsed.problems) problems.add("${dir.name}/strings.xml: $p")
            // A parse failure already reported above; comparing keys against an
            // empty set here would just misreport every master key as "missing".
            if (parsed.keys != null) {
                val missing = masterKeys - parsed.keys
                if (missing.isNotEmpty()) {
                    problems.add(
                        "${dir.name}/strings.xml: ${missing.size} key(s) missing vs values/strings.xml " +
                            "(${missing.sorted().take(5).joinToString(", ")}${if (missing.size > 5) ", …" else ""})"
                    )
                }
                // Format-slot parity (BladeWatch-1yqg): a Spanish value had lost
                // its %1$s outright, so the clip count never rendered.
                for ((k, v) in parsed.values) {
                    val want = formatSlots(master.values[k] ?: continue)
                    val got = formatSlots(v)
                    if (want != got) {
                        problems.add("${dir.name}/strings.xml: $k has slots $got, English has $want")
                    }
                }
            }
        }

        if (problems.isNotEmpty()) {
            throw GradleException("Android strings validation FAILED:\n" + problems.joinToString("\n") { "  - $it" })
        }
        logger.lifecycle("Android strings: ${localeDirs.size} locales, full key parity with values/strings.xml (${masterKeys.size} keys), valid XML, matching format slots, no unescaped apostrophes ✓")
    }
}
tasks.named("preBuild") { dependsOn("validateAndroidStrings") }

// Fail the build if the Flutter ARB catalogs (flutter_ui/lib/l10n/app_*.arb,
// ported from res/values*/strings.xml in BladeWatch-ncbb.3 — see
// tools/i18n/xml_to_arb.py) are malformed JSON or a locale is missing a key
// that the app_en.arb template has. Same failure mode as the two checks
// above, same fix.
tasks.register("validateArbCatalogs") {
    description = "Validate flutter_ui/lib/l10n/*.arb: valid JSON + full key parity with app_en.arb"
    group = "verification"
    val arbDir = file("../flutter_ui/lib/l10n")
    doLast {
        val slurper = groovy.json.JsonSlurper()
        fun keysOf(obj: Any?): Set<String> {
            @Suppress("UNCHECKED_CAST")
            val map = obj as? Map<String, Any?> ?: return emptySet()
            return map.keys.filter { !it.startsWith("@") }.toSortedSet()
        }
        // The argument names app_en.arb declares for a value: {arg1} and the
        // leading name of an ICU form such as {count, plural, ...}. Read from
        // ENGLISH only, so ICU branch bodies in a translation are never
        // mistaken for placeholders.
        fun placeholdersIn(v: String): List<String> =
            Regex("""\{(\w+)[,}]""").findAll(v).map { it.groupValues[1] }.distinct().toList()

        val templateFile = arbDir.resolve("app_en.arb")
        if (!templateFile.exists()) throw GradleException("ARB: app_en.arb missing at ${templateFile.path}")
        val templateKeys = try {
            keysOf(slurper.parse(templateFile))
        } catch (e: Exception) {
            throw GradleException("ARB: app_en.arb is not valid JSON — ${e.message}")
        }
        @Suppress("UNCHECKED_CAST")
        fun stringValuesOf(obj: Any?): Map<String, String> =
            (obj as? Map<String, Any?>)?.entries
                ?.filter { !it.key.startsWith("@") && it.value is String }
                ?.associate { it.key to it.value as String } ?: emptyMap()

        val templateValues = stringValuesOf(slurper.parse(templateFile))
        val arbFiles = arbDir.listFiles { f -> f.name.endsWith(".arb") }?.sortedBy { it.name } ?: emptyList()
        val problems = mutableListOf<String>()
        for (f in arbFiles) {
            val parsed = try {
                slurper.parse(f)
            } catch (e: Exception) {
                problems.add("${f.name}: INVALID JSON — ${e.message}"); continue
            }
            if (f.name == "app_en.arb") continue
            val keys = keysOf(parsed)
            val missing = templateKeys - keys
            val extra = keys - templateKeys
            if (missing.isNotEmpty()) {
                problems.add("${f.name}: ${missing.size} key(s) missing vs app_en.arb (e.g. ${missing.take(5).joinToString(", ")})")
            }
            if (extra.isNotEmpty()) {
                problems.add("${f.name}: ${extra.size} extra key(s) not in app_en.arb (e.g. ${extra.take(5).joinToString(", ")})")
            }
            // Placeholder parity (BladeWatch-1yqg). Only the "English slot is
            // missing" direction is checked: a translation that drops {arg1}
            // silently shows no count at all, and nothing else catches it.
            // The opposite direction needs no check here — gen-l10n already
            // fails the build on a placeholder app_en.arb does not declare.
            val values = stringValuesOf(parsed)
            for ((k, want) in templateValues) {
                val got = values[k] ?: continue
                val lost = placeholdersIn(want).filter { !got.contains("{$it") }
                if (lost.isNotEmpty()) {
                    problems.add("${f.name}: $k drops placeholder(s) ${lost.joinToString(", ") { "{$it}" }}")
                }
            }
        }
        // Letterless values must be byte-identical (BladeWatch-1yqg). A value
        // with no letters — "$", "[TAG]", "12:34:56", "—", "1" — has nothing to
        // translate, so any difference is corruption rather than localisation.
        // It is worth failing on because of WHAT came back: the pass returned
        // Europarl corpus fragments ("2 - Les Etats membres", "3 El Parlamento
        // Europeo") for these keys, i.e. the model emitted training data when
        // handed nothing translatable.
        fun letterless(v: String): Boolean {
            val stripped = v.replace(Regex("""\{[^}]*\}"""), "").trim()
            return stripped.isEmpty() || stripped.none { it.isLetter() }
        }
        for (f in arbFiles) {
            if (f.name == "app_en.arb") continue
            val values = stringValuesOf(slurper.parse(f))
            for ((k, want) in templateValues) {
                if (!letterless(want)) continue
                val got = values[k] ?: continue
                if (got != want) {
                    problems.add("${f.name}: $k should be exactly ${'"'}$want${'"'} (nothing to translate), got ${'"'}$got${'"'}")
                }
            }
        }

        // Plural-shape parity (BladeWatch-i4ap). If the English value is an ICU
        // plural then every locale's value must be one too. gen-l10n builds each
        // method's signature from the TEMPLATE, so a locale that supplies a plain
        // string where app_en.arb has a plural still compiles — it just renders
        // that string verbatim and the count silently disappears, or the noun never
        // agrees. That is exactly what shipped: dashboard_trips_count was a plain
        // "{arg1} trips", so English read "1 trips" and Russian could carry only one
        // of its three forms.
        //
        // Structural, so it fails rather than warns: "is this value declared as a
        // plural" has no judgement in it and no false positive to argue about. It
        // deliberately does NOT check that the CATEGORIES match — ru needs few/many
        // where en does not, and ja/zh/th correctly have no numeral agreement at all,
        // so demanding identical category sets would be wrong in both directions.
        fun isIcuPlural(v: String): Boolean =
            Regex("""\{\s*\w+\s*,\s*plural\s*,""").containsMatchIn(v)
        for (f in arbFiles) {
            if (f.name == "app_en.arb") continue
            val values = stringValuesOf(slurper.parse(f))
            for ((k, want) in templateValues) {
                if (!isIcuPlural(want)) continue
                val got = values[k] ?: continue
                if (!isIcuPlural(got)) {
                    problems.add(
                        "${f.name}: $k is a plain string but app_en.arb declares it an ICU " +
                        "plural — the count will not agree. Use {argN, plural, one{..} other{..}}"
                    )
                }
            }
        }

        // Mixed-script check (BladeWatch-1yqg): simplified characters had leaked
        // into app_zh_TW, so seven strings read as mainland text to a Taiwanese
        // user. Each character below has a distinct traditional form, so any
        // occurrence is wrong by construction — there is no false positive to
        // argue about, which is why this fails rather than warns.
        val simplifiedOnly = "设备选择关闭开录视频图数据语汉时间层页网络连断应处显删载传输转动态检测监报声" +
            "车辆电压灯门锁键摄机统权认证级严误调试结确记单双总类别组线进运远达过还这说长见东马问头" +
            "实现点学对会样发员务无书变让请询题验编码准败华丰临举义乐习乡亲价众优伟传伤体余" +
            "俭修个们从仓仅凤仪价仿伙伪传伞坏块坚坛垒够奋妆妇妈娱娘婴嫒宁宝实审宪宫宽宾寝对寻导寿将尔尘尝"
        val simpSet = simplifiedOnly.toSet()
        val tw = arbDir.resolve("app_zh_TW.arb")
        if (tw.exists()) {
            for ((k, v) in stringValuesOf(slurper.parse(tw))) {
                val found = v.filter { it in simpSet }.toSortedSet()
                if (found.isNotEmpty()) {
                    problems.add("app_zh_TW.arb: $k mixes simplified characters (${found.joinToString("")})")
                }
            }
        }

        if (problems.isNotEmpty()) {
            throw GradleException("ARB catalog validation FAILED:\n" + problems.joinToString("\n") { "  - $it" })
        }
        logger.lifecycle("ARB: ${arbFiles.size} catalogs valid, full key parity and placeholder parity with app_en.arb (${templateKeys.size} keys) ✓")

        // BladeWatch-aklv: key parity says nothing about VALUES. A catalog can
        // carry every key while its text is still English, and that is the
        // actual state of several locales — which is invisible to the check
        // above and only shows up on the head unit.
        //
        // A WARNING, never a failure: there is a real backlog, and failing the
        // build would block every unrelated change until it is cleared. The
        // point is that the number is visible and trending down.
        // Values that SHOULD read identically everywhere: pure placeholders,
        // URLs, and text with no letters at all (separators, ellipses).
        fun alwaysIdentical(v: String): Boolean {
            val stripped = v.replace(Regex("\\{[^}]*\\}"), "").trim()
            return stripped.isEmpty() || v.startsWith("http") || !stripped.any { it.isLetter() }
        }

        // Keys reviewed key-by-key against every locale that still shows them
        // and confirmed to be intentionally identical (BladeWatch-aklv): the
        // product name, unit symbols, acronyms, the short status badges the
        // native overlay also renders untranslated, and loanwords that really
        // are the correct word in the Latin-script locales (German "Status",
        // French "Surveillance", Dutch "Score", Spanish "Error"...).
        //
        // Exempting them is what makes the remaining count meaningful — a number
        // that is mostly brand names can never be argued down to zero, so nobody
        // would watch it. Adding a key here is a claim that it is correct in
        // EVERY locale; check before you add one, because it silences the key
        // everywhere and a genuine gap then ships unnoticed. This set was built
        // by inspecting the actual value in each locale, not by pattern.
        val intentionallyIdentical = setOf(
            // Product and brand
            "app_name", "cd_brand_logo", "settings_hero_overline", "settings_footer_format",
            "status_overlay_notif_title", "settings_about_source_value",
            "daemon_name_zrok", "tunnel_label_zrok",
            // Unit symbols and unit-only formats
            "vehicle_dialog_capacity_suffix", "trips_stat_kwh", "trips_stat_kwh_per_100km",
            "dashboard_insight_kwh_format", "dashboard_vehicle_summary",
            "dashboard_trips_distance_km", "dashboard_trips_distance_mi",
            "dashboard_insight_hours", "dashboard_insight_minutes",
            "settings_recording_limit_minutes", "surveillance_seconds_value",
            "surveillance_safe_locations_zone_label",
            // Acronyms shown as-is on the head unit, matching native
            "performance_temperature_na", "performance_cpu_title", "performance_gpu_title",
            "clip_label_url", "cd_qr", "vehicle_tab_adas", "vehicle_dialog_summary_soh",
            "recording_lib_camera_badge", "log_entry_default_tag",
            "dialog_ok", "vehicle_tyre_ok", "diagnostics_network_ethernet",
            "vehicle_dialog_soh_source_live", "vehicle_dialog_soh_source_nominal",
            "adb_output_header",
            // Status badges the floating overlay draws untranslated (REC / TRIP)
            "overlay_rec_inactive_label", "overlay_trip_inactive_label",
            // Online / Offline — the loanword pair, correct in de, it, nb, nl
            "diagnostics_metric_online", "diagnostics_tunnel_state_online",
            "diagnostics_tunnel_state_offline", "diagnostics_network_offline",
            "diagnostics_camera_value_offline", "dashboard_tunnel_online",
            "dashboard_tunnel_offline",
            // Loanwords that are the correct word in the Latin-script locales
            "performance_memory_app", "performance_memory_total", "performance_threads_label",
            "settings_recording_tab_status", "surveillance_general_status",
            "settings_about_version_label", "recording_lib_filter_button",
            "recording_lib_filter_button_active", "recording_lib_filter_section_type",
            "recording_lib_chip_type_normal", "recording_lib_chip_person",
            "surveillance_detection_object_person", "video_player_legend_person",
            "recordings_segment_dashcam", "recordings_segment_dashcam_count",
            "diagnostics_network_tunnel_label", "surveillance_preset_garage",
            "settings_section_daemons", "settings_section_surveillance",
            "recordings_segment_surveillance", "recordings_segment_surveillance_count",
            "soh_dialog_model_label", "vehicle_dialog_model_label",
            "vehicle_dialog_summary_model", "rail_dashboard", "rail_diagnostics",
            "camera_option_2", "camera_option_3", "camera_option_4", "camera_option_5",
            "diagnostics_camera_value_camera_n", "startup_daemon_camera",
            "recording_lib_clip_count_one", "settings_privacy_storage_count_format",
            "trips_score_label", "log_header_source", "live_error_fmt", "trips_load_error",
            "surveillance_tab_general", "settings_recording_tab_capture",
            "dashboard_trips_label_distance", "trips_detail_distance",
            "trips_dna_anticipation", "surveillance_deterrent_horn",
        )
        // This count is 0 today (BladeWatch-aklv closed it out), so it is a real
        // signal rather than background noise: anything it reports is either a
        // new English string awaiting translation, or a locale that regressed.
        // It WARNS and never fails — adding an English key legitimately comes
        // before its translations, and blocking that would just teach people to
        // paste English into all 17 catalogs to get a build.
        val untranslated = mutableListOf<String>()
        for (f in arbFiles) {
            if (f.name == "app_en.arb") continue
            val values = stringValuesOf(slurper.parse(f))
            val same = templateValues.filter { (k, v) ->
                values[k] == v && !alwaysIdentical(v) && k !in intentionallyIdentical
            }.keys
            if (same.isNotEmpty()) {
                untranslated.add("${f.name}: ${same.size} — ${same.sorted().joinToString(", ")}")
            }
        }
        if (untranslated.isNotEmpty()) {
            logger.warn(
                "ARB: values identical to English (BladeWatch-aklv). Translate them, or — if " +
                    "the word really is the same in that language — add the key to " +
                    "intentionallyIdentical in this file with a reason:\n" +
                    untranslated.joinToString("\n") { "  ! $it" },
            )
        }
    }
}
tasks.named("preBuild") { dependsOn("validateArbCatalogs") }

// Kotlin coverage gate (BladeWatch-ncbb.5). koverVerify fails the build below
// minBound — baselined against the existing ~20-file/~3,100 LOC suite under
// app/src/test/java/com/loabletech/bladewatch/, see docs/build-and-operations.md
// for the current figure and the ratchet policy (may only ever go up).
// Excludes: generated ConnectRPC/protobuf code, and the android.hardware.*/
// android.os.* BYD SDK compile-time stubs — real classes are loaded at runtime
// via reflection from the boot classloader (see "BYD SDK Stub Pattern" in
// CLAUDE.md), so the stub bodies in this APK are never instantiated and are
// not testable by design.
kover {
    reports {
        total {
            filters {
                excludes {
                    // connect-kotlin/protobuf generated code (RPC clients + message
                    // classes, ~1,100 files) — all live flat under this one package.
                    packages("net.bladewatch.app.grpc.v1")
                    // BYD SDK compile-time stubs (android.hardware.*, android.os.*,
                    // including nested sub-packages like android.hardware.bydauto.power) —
                    // real classes are loaded at runtime via reflection from the boot
                    // classloader, so these stub bodies are never instantiated.
                    packages("android.hardware", "android.os")
                }
            }
            verify {
                rule {
                    // Baseline measured 2026-09-12 against the existing ~20-file JVM
                    // suite: 1020/48610 lines covered (~2.10%) after excluding
                    // generated protobuf and the BYD stubs above. Floor of that
                    // real figure — raise this as tests are added; never lower it.
                    minBound(2)
                }
            }
        }
    }
}

// ── Android-only enforcement (BladeWatch-7965.5) ──────────────────────────────
//
// The Flutter UI targets exactly one thing: an arm64 Android head unit (BYD
// DiLink v3, API 29). iOS, macOS, Windows, Linux and web are not targets.
//
// `flutter create` scaffolds all six platforms, and they REGENERATE: running
// `flutter create .`, some `flutter pub get` paths, or adding a plugin that runs
// platform scaffolding will silently recreate them. They then invite someone to
// "fix" an iOS build that should not exist, and a plugin that supports only
// desktop/web resolves fine on a dev machine and fails only at APK build time.
//
// Deliberately a FILESYSTEM CHECK ONLY, with no `flutter` invocation: the main
// app must still build on a machine with no Flutter toolchain installed.
tasks.register("validateFlutterAndroidOnly") {
    description = "Fail the build if non-Android Flutter platform directories reappear under flutter_ui/"
    group = "verification"
    val flutterRoot = file("../flutter_ui")
    val forbidden = listOf("ios", "macos", "windows", "linux", "web")
    doLast {
        val present = forbidden.filter { flutterRoot.resolve(it).isDirectory }
        if (present.isNotEmpty()) {
            throw GradleException(
                buildString {
                    append("Flutter platform validation FAILED — this project is Android-only.\n")
                    present.forEach { append("  - found flutter_ui/$it\n") }
                    append("\nDelete the directory (rm -rf flutter_ui/<name>) and do NOT run\n")
                    append("`flutter create` inside flutter_ui/ — it re-scaffolds every platform.\n")
                    append("The in-car UI ships only as the arm64 Android APK net.bladewatch.flutter.\n")
                    append("Note: web/ at the REPO ROOT is the Angular SPA and is unrelated — this\n")
                    append("check only looks inside flutter_ui/.")
                }
            )
        }
        logger.lifecycle("Flutter: Android-only ✓ (none of ${forbidden.joinToString(", ")} present under flutter_ui/)")
    }
}
tasks.named("preBuild") { dependsOn("validateFlutterAndroidOnly") }

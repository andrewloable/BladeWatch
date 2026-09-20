import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The privileged MethodChannel surface must agree on both sides, exactly.
///
/// Dart calls `PlatformChannel.invoke('<group>', '<method>')` and the Kotlin
/// side dispatches on the single string `"<group>.<method>"`. Neither compiler
/// sees the other, so a rename on one side is caught only at runtime — and on
/// the Dart side that surfaces as a `MissingPluginException` on the car, on
/// whichever screen needed it.
///
/// This is the same drift that had already happened one layer down, at the RPC
/// boundary: seven Dart wrappers outlived the daemon handlers they called
/// (BladeWatch-y3fl). That one went unnoticed because dead wrappers still
/// compile. This guard exists so the channel layer cannot repeat it.
///
/// Unlike the RPC surface, this one is checked in BOTH directions. An RPC the
/// Flutter app never calls is legitimate — the Angular SPA in `web/` is a second
/// client of the same daemon. A channel method has exactly one caller, the Dart
/// in this same APK, so an unreferenced handler is genuinely dead code.
void main() {
  (Directory, Directory)? locate() {
    for (final (dart, kotlin) in [
      ('lib', 'android/app/src/main/kotlin'),
      ('flutter_ui/lib', 'flutter_ui/android/app/src/main/kotlin'),
    ]) {
      final d = Directory(dart);
      final k = Directory(kotlin);
      if (d.existsSync() && k.existsSync()) return (d, k);
    }
    return null;
  }

  test('the Dart and Kotlin channel surfaces match exactly', () {
    final roots = locate();
    expect(roots, isNotNull, reason: 'could not locate both lib/ and the Kotlin source root');
    final (dartRoot, kotlinRoot) = roots!;

    // `(?:<.*?>)?` with dotAll: the type argument can nest angle brackets and
    // wrap across lines, e.g. `.invoke<Map<Object?, Object?>?>(\n 'location',`.
    // A naive `<[^>]*>` stops at the first '>' and silently misses those calls.
    final invocation = RegExp(r"\.invoke\s*(?:<.*?>)?\s*\(\s*'(\w+)'\s*,\s*'(\w+)'", dotAll: true);
    final called = <String, String>{};
    for (final f in dartRoot.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      for (final m in invocation.allMatches(f.readAsStringSync())) {
        called['${m.group(1)}.${m.group(2)}'] = f.uri.pathSegments.last;
      }
    }

    final handled = <String>{};
    for (final f in kotlinRoot.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.kt')) continue;
      handled.addAll(RegExp(r'^\s*"([\w.]+)"\s*->', multiLine: true)
          .allMatches(f.readAsStringSync())
          .map((m) => m.group(1)!));
    }

    expect(called, isNotEmpty, reason: 'found no invoke() call sites — has the bridge moved?');
    expect(handled, isNotEmpty, reason: 'found no Kotlin handlers — has MainActivity moved?');

    final unhandled = called.keys.where((k) => !handled.contains(k)).toList()..sort();
    expect(
      unhandled.map((k) => '$k (${called[k]})'),
      isEmpty,
      reason: 'Dart invokes these but no Kotlin branch handles them. Each is a '
          'MissingPluginException on the device, on whichever screen calls it.',
    );

    final dead = (handled.difference(called.keys.toSet()).toList()..sort());
    expect(
      dead,
      isEmpty,
      reason: 'Kotlin handles these but no Dart code invokes them. This channel '
          'has exactly one caller, so they are dead — delete them, or wire up '
          'the Dart side that was meant to call them.',
    );
  });

  /// The privileged IPC contract, which crosses APK boundaries.
  ///
  /// The Flutter APK's Kotlin puts a `"cmd"` string into a JSON object and sends
  /// it over loopback to the daemon, whose `TcpCommandServer.processCommand`
  /// switches on that string. This is the highest-stakes of the three string
  /// contracts — it carries secret reads/writes and daemon control — and it is
  /// the only one where the two sides ship in DIFFERENT APKs, so they can be
  /// updated independently on a device and drift without any build ever failing.
  ///
  /// Only one direction is meaningful: every command the UI sends must be one
  /// the daemon handles. The reverse is expected — the daemon also serves
  /// `camera`, `ping` and `shutdown` to callers that are not this app.
  ///
  /// In Dart rather than as a Gradle test on purpose. CLAUDE.md's "Gradle
  /// up-to-date blindness" note applies squarely here: a JVM test reading source
  /// trees that are not on its classpath will not re-run when they change, so it
  /// can pass against a mutation unless every tree is declared as an explicit
  /// input. `flutter test` re-runs unconditionally, so the guard cannot go stale.
  test('every IPC command the UI sends is one the daemon handles', () {
    var kotlinRoot = Directory('android/app/src/main/kotlin');
    var daemonBase = '../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer';
    if (!kotlinRoot.existsSync()) {
      kotlinRoot = Directory('flutter_ui/android/app/src/main/kotlin');
      daemonBase = 'app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer';
    }
    // Resolve the daemon file in whichever language it is written in today. The server layer is
    // migrating to Kotlin (BladeWatch-9rut); a guard that keeps asking for a '.java' that no
    // longer exists stops guarding without ever failing.
    final asJava = File('$daemonBase.java');
    final asKotlin = File('$daemonBase.kt');
    expect(asJava.existsSync() && asKotlin.existsSync(), isFalse,
        reason: 'both TcpCommandServer.java and .kt exist — a half-finished conversion; '
            'this guard would read the stale copy');
    final daemonFile = asJava.existsSync() ? asJava : asKotlin;
    expect(kotlinRoot.existsSync() && daemonFile.existsSync(), isTrue,
        reason: 'could not locate the Kotlin root and TcpCommandServer');

    // [A-Za-z_]+, not [a-z_]+: the daemon mixes snake_case ("secret_get") and
    // camelCase ("daemonStatus", "tunnelStatus") command names. A lowercase-only
    // pattern silently skipped 2 of the 15 commands on BOTH sides, so a rename of
    // either would have been reported as "all clear" -- a guard that cannot fail.
    // Both dispatch shapes: Java's `case "start":` and Kotlin's `"start" -> {`. Matching only
    // one would make this guard pass vacuously the moment the daemon file converts.
    final daemonSource = daemonFile.readAsStringSync();
    final handled = <String>{
      for (final m in RegExp(r'^\s*case\s+"([A-Za-z_]+)"\s*:', multiLine: true)
          .allMatches(daemonSource))
        m.group(1)!,
      for (final m in RegExp(r'^\s*"([A-Za-z_]+)"\s*->', multiLine: true)
          .allMatches(daemonSource))
        m.group(1)!,
    };
    expect(handled, isNotEmpty, reason: 'no case labels found — has the dispatch changed shape?');

    final sent = <String, String>{};
    final put = RegExp(r'"cmd"\s*,\s*"([A-Za-z_]+)"');
    for (final f in kotlinRoot.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.kt')) continue;
      for (final m in put.allMatches(f.readAsStringSync())) {
        sent[m.group(1)!] = f.uri.pathSegments.last;
      }
    }
    expect(sent, isNotEmpty, reason: 'no IPC commands found — has the send convention changed?');

    final unhandled = sent.keys.where((c) => !handled.contains(c)).toList()..sort();
    expect(
      unhandled.map((c) => '$c (${sent[c]})'),
      isEmpty,
      reason: 'The UI sends these IPC commands but the daemon has no case for '
          'them. The daemon answers an unknown command rather than throwing, so '
          'this fails silently at runtime with a refusal the UI reports as an '
          'ordinary error.',
    );
  });

  /// The single most consequential string in the system.
  ///
  /// `MainActivity.kt` in this APK holds `SERVICE_HOST_ACTIVITY` as a literal and
  /// starts it by explicit component name on first `onResume`. That call is the
  /// ONLY thing that runs the daemon host's bootstrap on this head unit: BYD's
  /// `ssc_skip` suppresses broadcasts to the app package, so `BootReceiver` never
  /// fires after a cold boot (verified by a real reboot), and Phase 4 removed the
  /// launcher entry.
  ///
  /// If that literal ever stops naming an exported activity, `startActivity`
  /// throws `ActivityNotFoundException`/`SecurityException` — and `wakeServiceHost`
  /// catches it and logs a WARNING, because the Flutter UI must still open when the
  /// daemon host is missing. So the whole daemon stack would silently never start,
  /// with nothing in the logs above warning level to say why.
  ///
  /// `ServiceHostManifestTest` pins the manifest end (declared + exported) but
  /// cannot see this APK's copy of the string. This checks the two agree.
  test('the service-host activity this APK wakes is declared and exported', () {
    var kotlin = File('android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/MainActivity.kt');
    var manifest = File('../app/src/main/AndroidManifest.xml');
    if (!kotlin.existsSync()) {
      kotlin = File('flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/MainActivity.kt');
      manifest = File('app/src/main/AndroidManifest.xml');
    }
    expect(kotlin.existsSync() && manifest.existsSync(), isTrue,
        reason: 'could not locate MainActivity.kt and the service host manifest');

    final src = kotlin.readAsStringSync();
    String literal(String name) {
      final m = RegExp('$name\\s*=\\s*"([^"]+)"').firstMatch(src);
      expect(m, isNotNull, reason: '$name is no longer a string literal in MainActivity.kt');
      return m!.group(1)!;
    }

    final pkg = literal('SERVICE_HOST_PACKAGE');
    final activity = literal('SERVICE_HOST_ACTIVITY');
    expect(activity, startsWith(pkg),
        reason: 'the activity must live in the service host package to be wakeable');

    final m = manifest.readAsStringSync();
    final at = m.indexOf('android:name="$activity"');
    expect(at, greaterThan(0),
        reason: 'MainActivity.kt wakes "$activity", but the service host manifest '
            'declares no such activity. startActivity would throw, wakeServiceHost '
            'would swallow it, and no daemon would ever start on this head unit.');

    // The declaration runs to the next '>' -- these are self-closing <activity/> tags.
    final end = m.indexOf('>', at);
    expect(end, greaterThan(at));
    expect(
      m.substring(at, end),
      contains('android:exported="true"'),
      reason: '"$activity" is declared but NOT exported. A cross-package explicit '
          'start needs it exported, so waking the service host would fail with a '
          'SecurityException that wakeServiceHost only logs as a warning.',
    );
  });

  /// The two APKs must report the same versionName.
  ///
  /// They are installed as a pair and the About screen reads this value through
  /// package_info_plus, so a mismatch means the driver sees one version while the
  /// daemon host is another — and a bug report would name the wrong build.
  ///
  /// It lives in two files unavoidably. BladeWatch versions have FOUR parts
  /// ("1.3.2.0") and a pubspec version must be valid semver: `version: 1.3.2.0+13200`
  /// is rejected by pub outright, so `flutter.versionName` can only ever yield
  /// "1.3.0". flutter_ui/android/app/build.gradle.kts therefore writes versionName
  /// out explicitly, which is a copy of the one in app/build.gradle.kts. This pins
  /// the copy.
  test('both APKs declare the same versionName', () {
    var host = File('../app/build.gradle.kts');
    var ui = File('android/app/build.gradle.kts');
    if (!host.existsSync()) {
      host = File('app/build.gradle.kts');
      ui = File('flutter_ui/android/app/build.gradle.kts');
    }
    expect(host.existsSync() && ui.existsSync(), isTrue,
        reason: 'could not locate both build.gradle.kts files');

    String versionName(File f) {
      final m = RegExp(r'versionName\s*=\s*"([^"]+)"').firstMatch(f.readAsStringSync());
      expect(m, isNotNull, reason: '${f.path} declares no literal versionName');
      return m!.group(1)!;
    }

    final a = versionName(host);
    final b = versionName(ui);
    expect(
      b,
      a,
      reason: 'app/build.gradle.kts says "$a" but the Flutter APK says "$b". '
          'Update both, and keep pubspec.yaml\'s build number in step with '
          'app/build.gradle.kts\'s versionCode.',
    );
  });
}

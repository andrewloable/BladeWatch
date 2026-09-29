import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// What this device calls itself, for the car's "Paired devices" list (owner request 2026-09-27):
/// the computer's name on macOS and Windows, the device name on Android (else its make and model),
/// the device name on iOS -- iOS 16 and later answer just "iPhone" without Apple's user-assigned
/// device name entitlement -- and the host name on Linux. [fallback] when the platform says
/// nothing usable. [read] replaces the platform query in tests.
Future<String> deviceName(String fallback, {Future<String?> Function()? read}) async {
  try {
    final name = (await (read ?? _read)())?.trim() ?? '';
    return name.isEmpty ? fallback : name;
  } catch (_) {
    return fallback;
  }
}

Future<String?> _read() async {
  final info = DeviceInfoPlugin();
  return switch (Platform.operatingSystem) {
    'macos' => (await info.macOsInfo).computerName,
    'windows' => (await info.windowsInfo).computerName,
    'ios' => (await info.iosInfo).name,
    'android' => _android(await info.androidInfo),
    _ => Platform.localHostname,
  };
}

String _android(AndroidDeviceInfo a) => a.name.trim().isNotEmpty ? a.name : '${a.manufacturer} ${a.model}';

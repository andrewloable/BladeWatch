import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show ChangeNotifier;

/// The 17 languages BladeWatch ships translations for — ground truth:
/// `LocaleManager.SUPPORTED` (native). Deliberately narrower than
/// `AppLocalizations.supportedLocales`, which also lists bare `pt`/`zh`
/// entries Flutter's own l10n tool adds as internal resolution fallbacks for
/// their regional variants — native never treats those as separately
/// selectable languages, and neither does this list.
const List<String> kSupportedLocaleTags = [
  'en', 'zh-CN', 'zh-TW', 'pt-BR', 'es', 'de', 'fr', 'it', //
  'nb', 'nl', 'ja', 'ko', 'th', 'vi', 'hi', 'tr', 'ru',
];

/// Sentinel persisted when the user picks "Auto (follow system)" — ground
/// truth: `LocaleManager.AUTO_TAG`.
const String kAutoLocaleTag = 'auto';

Locale parseLocaleTag(String tag) {
  final dash = tag.indexOf('-');
  return dash < 0 ? Locale(tag) : Locale(tag.substring(0, dash), tag.substring(dash + 1));
}

/// Narrow abstraction over the persisted locale value — the controller's
/// only test seam. [FileLocaleStore] is the real implementation.
abstract class LocaleStore {
  Future<String?> readRaw();
  /// Returns whether the tag reached disk.
  Future<bool> writeRaw(String tag);
}

/// Real [LocaleStore] — ground truth: `LocaleManager.java`, which must keep
/// pointing at the same file: the daemon, the native UI and this app are three
/// readers of one contract, and the contract IS the path.
///
/// `/storage/emulated/0/BladeWatch/data/locale`, NOT the old
/// `/data/local/tmp/.bladewatch/locale` (BladeWatch-vcur). That directory is
/// `0771 shell:shell`, so the app UID can traverse in and read but cannot
/// create anything — every write from either in-car UI failed, silently, and
/// the chosen language came back English on the next launch. This directory is
/// created by `setupStorageDirectories()`, both APKs already write
/// `bladewatch_config.json` into it, and the daemon can read it because shell
/// is in `sdcard_rw`.
///
/// [legacyPath] is still READ so a device whose web UI persisted a language
/// keeps it — the web picker goes through the daemon, which runs as shell and
/// so could always write the old location.
///
/// Covered by a real-file integration test (`file_locale_store_test.dart`),
/// the same approach `raw_http_sender_test.dart`/`io_live_socket_test.dart`
/// use for their own thin real-I/O wrappers, against a temp path rather than
/// the real device paths (which don't exist on a dev machine).
class FileLocaleStore implements LocaleStore {
  final String path;
  final String legacyPath;

  const FileLocaleStore([
    this.path = '/storage/emulated/0/BladeWatch/data/locale',
    this.legacyPath = '/data/local/tmp/.bladewatch/locale',
  ]);

  static Future<String?> _read(String p) async {
    try {
      final file = File(p);
      if (!await file.exists()) return null;
      final content = (await file.readAsString()).trim();
      return content.isEmpty ? null : content;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readRaw() async => await _read(path) ?? await _read(legacyPath);

  /// Returns whether the tag reached disk. It really can fail — that is the
  /// whole of BladeWatch-vcur — so the caller is expected to look.
  @override
  Future<bool> writeRaw(String tag) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(tag);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// App-wide active locale — BladeWatch-yz1e.11. Ground truth:
/// `LanguagePickerDialog.kt` + `LocaleManager.java`. Native recreates the
/// host Activity on every locale change so its Fragments rehydrate in the
/// new language; this port needs no such workaround; `MaterialApp` simply
/// rebuilds under a `Locale` change like any other reactive value, driven by
/// this `ChangeNotifier`.
class LocaleController extends ChangeNotifier {
  LocaleController({required LocaleStore store}) : _store = store; // ignore: prefer_initializing_formals

  final LocaleStore _store;

  String? _rawTag;

  /// The raw persisted value: `null` (never chosen) or [kAutoLocaleTag] both
  /// mean "follow system"; otherwise one of [kSupportedLocaleTags]. Exposed
  /// so the picker can show which row is current — ground truth:
  /// `LanguagePickerDialog.buildRows()`'s own `rawCurrent` parameter.
  String? get rawTag => _rawTag;

  bool get isAuto => _rawTag == null || _rawTag == kAutoLocaleTag;

  /// `null` tells `MaterialApp` to resolve from the platform locale itself —
  /// exactly the "Auto" behaviour, with no extra resolution logic needed
  /// here.
  Locale? get locale => isAuto ? null : parseLocaleTag(_rawTag!);

  Future<void> load() async {
    final raw = await _store.readRaw();
    _rawTag = (raw == kAutoLocaleTag || kSupportedLocaleTags.contains(raw)) ? raw : null;
    notifyListeners();
  }

  /// Whether the last [select] reached disk. False means the language is
  /// applied for this session only and will be gone on the next launch — the
  /// picker shows that rather than letting the user find out later
  /// (BladeWatch-vcur).
  bool get lastPersistSucceeded => _lastPersistSucceeded;
  bool _lastPersistSucceeded = true;

  /// Persists [tag] ([kAutoLocaleTag] or one of [kSupportedLocaleTags]).
  /// Applies immediately — the UI should not wait on the disk — then records
  /// whether persisting actually worked.
  Future<void> select(String tag) async {
    if (tag == _rawTag) return;
    _rawTag = tag;
    notifyListeners();
    _lastPersistSucceeded = await _store.writeRaw(tag);
    if (!_lastPersistSucceeded) notifyListeners();
  }
}

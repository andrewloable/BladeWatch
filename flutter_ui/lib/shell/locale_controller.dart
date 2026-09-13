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
  Future<void> writeRaw(String tag);
}

/// Real [LocaleStore] — ground truth: `LocaleManager.java`. Reads/writes a
/// plain UTF-8 text file at `/data/local/tmp/.bladewatch/locale`, the same
/// path native's own Kotlin/Java UI code reads and writes *directly* (no
/// IPC — this is deliberately not app-private storage). Native explicitly
/// calls `setReadable(true, false)`/relies on the directory's default
/// world-executable permissions to make this file readable and writable by
/// both processes despite living outside either app's private data
/// directory; the Flutter and main APKs share a UID
/// (`android:sharedUserId="net.bladewatch.app"` in both manifests), so the
/// same file is equally reachable from here via plain `dart:io`.
///
/// Covered by a real-file integration test (`file_locale_store_test.dart`),
/// the same approach `raw_http_sender_test.dart`/`io_live_socket_test.dart`
/// use for their own thin real-I/O wrappers, against a temp path rather than
/// the real `/data/local/tmp` (which doesn't exist on a dev machine).
class FileLocaleStore implements LocaleStore {
  final String path;

  const FileLocaleStore([this.path = '/data/local/tmp/.bladewatch/locale']);

  @override
  Future<String?> readRaw() async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final content = (await file.readAsString()).trim();
      return content.isEmpty ? null : content;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeRaw(String tag) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(tag);
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

  /// Persists [tag] ([kAutoLocaleTag] or one of [kSupportedLocaleTags]).
  /// Applies immediately (optimistic) and persists fire-and-forget — ground
  /// truth: `LocaleManager.set()` itself has no failure/revert path either,
  /// just a caught-and-logged exception.
  Future<void> select(String tag) async {
    if (tag == _rawTag) return;
    _rawTag = tag;
    notifyListeners();
    await _store.writeRaw(tag);
  }
}

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

/// Currency display and the ISO 4217 code catalogue.
///
/// **No symbol table is shipped.** Symbols, their placement, the spacing around them and the
/// number of decimal digits all vary by currency and by locale — JPY has no minor unit, many
/// European locales put the symbol after the amount. `intl` already carries ICU's rules for
/// all of it, so this delegates rather than reimplementing a subset badly.
///
/// The catalogue is a generated asset (`tools/gen-currencies.mjs`), not a hand-typed list.
class Currency {
  Currency._();

  /// Fallback when nothing is configured. Matches the web UI and the daemon.
  static const String defaultCode = 'USD';

  static const String _assetPath = 'assets/iso4217.json';

  static List<String>? _cachedCodes;

  /// Whether [value] has the shape of an ISO 4217 code: exactly three ASCII letters.
  ///
  /// This is the same structural rule the daemon applies in `TripConfig.setCurrency`, and it
  /// is deliberately a SHAPE test rather than a catalogue lookup: formatting must be
  /// synchronous and must not depend on the asset having loaded. A well-formed code that ICU
  /// does not recognise still formats sensibly — `intl` falls back to showing the code itself.
  static bool isIsoCodeShaped(String value) {
    if (value.length != 3) return false;
    for (final unit in value.codeUnits) {
      final isUpper = unit >= 0x41 && unit <= 0x5A;
      final isLower = unit >= 0x61 && unit <= 0x7A;
      if (!isUpper && !isLower) return false;
    }
    return true;
  }

  /// Format [amount] in [currency] for display.
  ///
  /// An ISO-shaped code is formatted through ICU, so a JPY amount shows no decimals and a
  /// EUR amount follows the active locale's placement.
  ///
  /// Anything else — a bare symbol like `$` or a label like `kr` from a config predating the
  /// currency picker — renders exactly as it always did: the stored string, a space, then the
  /// amount to two decimals. Historical trips must not change appearance just because the
  /// settings screen grew a picker.
  ///
  /// Returns an empty string when there is nothing to show, so callers can test one condition
  /// rather than duplicating the empty/zero logic.
  static String format(double amount, String? currency, {String? locale}) {
    final code = currency?.trim() ?? '';
    if (code.isEmpty) return '';

    if (!isIsoCodeShaped(code)) {
      // Legacy free text — preserve the original rendering byte for byte.
      return '$code ${amount.toStringAsFixed(2)}';
    }

    try {
      return NumberFormat.simpleCurrency(
        locale: locale,
        name: code.toUpperCase(),
      ).format(amount);
    } catch (_) {
      // ICU refused the code for this locale. Degrade to the legacy shape rather than
      // showing the user nothing.
      return '${code.toUpperCase()} ${amount.toStringAsFixed(2)}';
    }
  }

  /// The ISO 4217 codes offered by the picker, loaded from the generated asset.
  ///
  /// Cached after the first load — the list is static for the life of the build.
  ///
  /// Falls back to a small set of common codes if the asset is missing or malformed. That is
  /// deliberately not an empty list: an empty picker would leave an owner unable to change
  /// their currency at all, which is worse than a short list they can still use.
  static Future<List<String>> codes() async {
    final cached = _cachedCodes;
    if (cached != null) return cached;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['codes'] as List<dynamic>).cast<String>();
      if (list.isEmpty) throw const FormatException('empty catalogue');
      _cachedCodes = list;
      return list;
    } catch (_) {
      const fallback = <String>[
        'AUD', 'CAD', 'CHF', 'CNY', 'EUR', 'GBP', 'HKD', 'IDR', 'INR', 'JPY',
        'KRW', 'MYR', 'NZD', 'PHP', 'SGD', 'THB', 'TWD', 'USD', 'VND', 'ZAR',
      ];
      _cachedCodes = fallback;
      return fallback;
    }
  }

  /// The options a picker must offer, given the currently-stored [current] value.
  ///
  /// **The current value is ALWAYS present exactly once.** `DropdownButtonFormField` asserts
  /// that its value matches exactly one item, so a stored value missing from the catalogue
  /// crashes the settings sheet outright. That is not hypothetical: a config predating the
  /// picker holds a bare symbol like `$` or a label like `kr`, neither of which is an ISO
  /// code, and the crash would land on precisely the owners whose settings most need changing.
  ///
  /// A legacy value is prepended rather than appended so it is visible without scrolling 162
  /// entries, and it disappears from the list as soon as the owner picks a real code.
  static List<String> optionsFor(String current, List<String>? catalogue) {
    final trimmed = current.trim();
    if (catalogue == null || catalogue.isEmpty) {
      return trimmed.isEmpty ? const <String>[defaultCode] : <String>[trimmed];
    }
    if (trimmed.isEmpty || catalogue.contains(trimmed)) return catalogue;
    return <String>[trimmed, ...catalogue];
  }

  /// Reset the cache. Test-only.
  static void resetCacheForTest() => _cachedCodes = null;
}

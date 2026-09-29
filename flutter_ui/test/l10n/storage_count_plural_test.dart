import 'dart:ui' show Locale;

import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-ug53: seven more count-bearing keys were plain strings, so each one
/// rendered "1 clips" / "1 recordings" / "1 events" on a device holding exactly one,
/// and Russian could only ever carry a single one of its three forms.
///
/// These assert grammar, not wording: the singular case comes first because
/// "1 clips" is the bug a reader actually notices.
void main() {
  group('the storage count keys are real ICU plurals', () {
    test('English uses the singular noun for exactly one', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(l10n.recording_lib_clip_count(1), '1 clip');
      expect(l10n.recording_lib_clip_count(2), '2 clips');
      expect(l10n.recording_lib_clip_count(0), '0 clips');

      expect(l10n.settings_recording_storage_files(1), '1 recording');
      expect(l10n.settings_recording_storage_files(4), '4 recordings');

      expect(l10n.settings_privacy_storage_count_format_plural(1), '1 clip');
      expect(l10n.settings_privacy_storage_count_format_plural(9), '9 clips');

      expect(l10n.surveillance_storage_files(1), '1 event');
      expect(l10n.surveillance_storage_files(7), '7 events');
    });

    // Two placeholders: only arg1 is the count. arg2 is a formatted size and must
    // survive untouched in every branch.
    test('the two-placeholder lines keep arg2 intact', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(l10n.diagnostics_storage_used_line(1, '2.1 GB'), '1 clip · 2.1 GB used');
      expect(l10n.diagnostics_storage_used_line(12, '2.1 GB'), '12 clips · 2.1 GB used');

      expect(l10n.dashboard_insight_storage_milestone(1, '500 MB'), '1 clip · 500 MB recorded');
      expect(l10n.dashboard_insight_storage_milestone(3, '500 MB'), '3 clips · 500 MB recorded');
    });

    /// The trap this key set: `log_header_truncated` contains the noun TWICE —
    /// once in the fixed literal "last 10000 lines", which is the truncation limit
    /// and is ALWAYS plural, and once after {arg1}. A blanket singular/plural
    /// substitution inflects both and produces "last 10000 line", which is wrong at
    /// every count. Only the occurrence tied to the placeholder may change.
    test('only the counted noun inflects, not the fixed 10000 limit', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(l10n.log_header_truncated(1),
          'NOTE: Log truncated to last 10000 lines (total: 1 line)');
      expect(l10n.log_header_truncated(25000),
          'NOTE: Log truncated to last 10000 lines (total: 25000 lines)');

      for (final n in [1, 2, 5, 11, 21, 10000]) {
        expect(l10n.log_header_truncated(n), contains('last 10000 lines'),
            reason: 'the 10000 limit is a literal and must stay plural at n=$n');
      }
    });

    // The three-way split is the whole reason this issue was filed. Russian selects
    // one for 1, few for 2-4, many for 5+ — and again many for 11-14, the case a
    // hand-rolled `n < 5` rule gets wrong.
    test('Russian selects one / few / many by CLDR rules', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ru'));

      expect(l10n.recording_lib_clip_count(1), '1 клип');
      expect(l10n.recording_lib_clip_count(3), '3 клипа');
      expect(l10n.recording_lib_clip_count(5), '5 клипов');
      expect(l10n.recording_lib_clip_count(11), '11 клипов');
      expect(l10n.recording_lib_clip_count(21), '21 клип');
      expect(l10n.recording_lib_clip_count(22), '22 клипа');

      expect(l10n.settings_recording_storage_files(1), '1 запись');
      expect(l10n.settings_recording_storage_files(2), '2 записи');
      expect(l10n.settings_recording_storage_files(5), '5 записей');

      expect(l10n.surveillance_storage_files(1), '1 событие');
      expect(l10n.surveillance_storage_files(2), '2 события');
      expect(l10n.surveillance_storage_files(5), '5 событий');
    });

    test('Russian inflects the two-placeholder lines too, keeping arg2', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ru'));

      expect(l10n.diagnostics_storage_used_line(1, '2,1 ГБ'), '1 клип · занято 2,1 ГБ');
      expect(l10n.diagnostics_storage_used_line(3, '2,1 ГБ'), '3 клипа · занято 2,1 ГБ');
      expect(l10n.diagnostics_storage_used_line(5, '2,1 ГБ'), '5 клипов · занято 2,1 ГБ');
    });

    // Languages with no count agreement after a numeral must still be declared as
    // plurals, so gen-l10n emits a selector and the key keeps one shape everywhere.
    // Asserting they are STABLE across counts is the point: a future "fix" that
    // invents a singular form here would be wrong, not an improvement.
    test('languages without numeral agreement render one stable form', () async {
      for (final tag in ['ja', 'ko', 'zh', 'th', 'vi', 'tr']) {
        final l10n = await AppLocalizations.delegate.load(Locale(tag));
        String noun(String s) => s.replaceAll(RegExp(r'\d+'), '');

        expect(noun(l10n.recording_lib_clip_count(1)),
            noun(l10n.recording_lib_clip_count(7)),
            reason: '$tag must not invent a singular for clips');
        expect(noun(l10n.surveillance_storage_files(1)),
            noun(l10n.surveillance_storage_files(7)),
            reason: '$tag must not invent a singular for events');
        expect(noun(l10n.settings_recording_storage_files(1)),
            noun(l10n.settings_recording_storage_files(7)),
            reason: '$tag must not invent a singular for recordings');
      }
    });

    // Every locale must render every key without throwing, and must actually
    // interpolate both placeholders. A branch that dropped arg2 would otherwise
    // only surface on a device set to that language.
    test('every locale renders every key with both placeholders', () async {
      const locales = [
        'en', 'de', 'es', 'fr', 'it', 'nl', 'nb', 'pt', 'ru',
        'hi', 'ja', 'ko', 'th', 'tr', 'vi', 'zh',
      ];
      for (final tag in locales) {
        final l10n = await AppLocalizations.delegate.load(Locale(tag));
        for (final n in [1, 2, 5]) {
          expect(l10n.recording_lib_clip_count(n), contains('$n'), reason: tag);
          expect(l10n.settings_recording_storage_files(n), contains('$n'), reason: tag);
          expect(l10n.settings_privacy_storage_count_format_plural(n), contains('$n'), reason: tag);
          expect(l10n.surveillance_storage_files(n), contains('$n'), reason: tag);

          final used = l10n.diagnostics_storage_used_line(n, 'XYZ');
          expect(used, contains('$n'), reason: tag);
          expect(used, contains('XYZ'), reason: '$tag dropped arg2 from the used line');

          final milestone = l10n.dashboard_insight_storage_milestone(n, 'XYZ');
          expect(milestone, contains('$n'), reason: tag);
          expect(milestone, contains('XYZ'), reason: '$tag dropped arg2 from the milestone');

          expect(l10n.log_header_truncated(n), contains('10000'),
              reason: '$tag lost the truncation limit');
        }
      }
    });
  });
}

import 'dart:ui' show Locale;

import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-i4ap: `dashboard_trips_count` used to be a plain string, `"{arg1} trips"`,
/// so the Dashboard hero read "1 trips" in English and Russian could only ever carry one
/// of its three forms (it shipped the "many" form, rendering "3 поездок" where Russian
/// wants "3 поездки").
///
/// These assert the grammar, not the wording. The singular case is first because
/// "1 trips" is the bug a reader actually notices.
void main() {
  group('dashboard_trips_count is a real ICU plural', () {
    test('English uses the singular noun for exactly one trip', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.dashboard_trips_count(1), '1 trip');
      expect(l10n.dashboard_trips_count(0), '0 trips');
      expect(l10n.dashboard_trips_count(3), '3 trips');
    });

    // The three-way split is the whole reason this issue was filed. Russian selects
    // one for 1, few for 2-4, many for 5+ (and again for 11-14, which is the case a
    // naive `n < 5` hand-rolled rule gets wrong).
    test('Russian selects one / few / many by CLDR rules', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ru'));
      expect(l10n.dashboard_trips_count(1), '1 поездка');
      expect(l10n.dashboard_trips_count(3), '3 поездки');
      expect(l10n.dashboard_trips_count(5), '5 поездок');
      expect(l10n.dashboard_trips_count(11), '11 поездок');
      expect(l10n.dashboard_trips_count(21), '21 поездка');
      expect(l10n.dashboard_trips_count(22), '22 поездки');
    });

    // Languages with no count agreement after a numeral must still be declared as
    // plurals, so gen-l10n emits a selector and the key keeps one shape everywhere.
    // Asserting they are STABLE across counts is the point: a future "fix" that
    // invents a singular form here would be wrong, not an improvement.
    test('languages without numeral agreement render one stable form', () async {
      for (final tag in ['ja', 'ko', 'zh', 'th', 'vi', 'tr']) {
        final l10n = await AppLocalizations.delegate.load(Locale(tag));
        // Compare what is left once the number itself is removed, since the two
        // renderings differ by the count and nothing else is allowed to change.
        String noun(int n) => l10n.dashboard_trips_count(n).replaceAll(RegExp(r'\d+'), '');
        expect(
          noun(1),
          noun(7),
          reason: '$tag should not inflect the noun for count',
        );
        expect(l10n.dashboard_trips_count(1), contains('1'));
      }
    });

    // Every shipped locale must resolve to something that actually interpolates the
    // count -- a plural whose branches dropped {arg1} would silently render "trips".
    test('every locale interpolates the count in both singular and plural', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(l10n.dashboard_trips_count(1), contains('1'),
            reason: '$locale dropped the count in the singular branch');
        expect(l10n.dashboard_trips_count(42), contains('42'),
            reason: '$locale dropped the count in the plural branch');
      }
    });
  });
}
